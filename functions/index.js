// Arın — Cloud Functions
// Her dakika çalışır (Avrupa/İstanbul).
// İki aşamalı havuz bildirimi:
//   1. Gün değişince pool'dan rastgele uygun bir ayet seçilir ve o ayetin
//      kendi hour:minute değeri bugünün gönderim saati olarak planlanır
//      (admin_ntf_config/today_plan). Böylece her gün farklı bir ayet farklı
//      bir saatte gelir — aynı item hep 06:12'de gelmez.
//   2. Planlanan dakikaya gelinince bildirim gönderilir. Saat = ayet referansı.
//      Seçilen ayet bilgisi admin_ntf_config/current_moment'a yazılır;
//      kullanıcı bildirimi tıklayarak 5 dakika içinde ayeti görebilir.

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const crypto = require("crypto");
const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldPath,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

const _kNotificationClaimTtlMs = 5 * 60 * 1000;

// İki YYYY-MM-DD stringi arasındaki tam gün farkı (b - a)
function daysBetween(a, b) {
  const da = new Date(a);
  const db = new Date(b);
  return Math.floor((db - da) / 86400000);
}

// Bildirim gövdesi — her seferinde farklı bir mesaj seçilir.
// Asıl liste Firestore `admin_ntf_config/teasers.texts` dizisinden okunur ve
// admin panelinden yönetilir; aşağıdaki sabit yalnızca o döküman boş/hatalı
// olduğunda fallback olarak devreye girer.
const _defaultTeaserTexts = [
  "Bu vaktin sende bırakacağı izi merak ediyor musun?",
  "Bu an sana ne söylüyor? Az sonra kayboluyor",
  "Bu vakit senin için indi",
  "Şu an tam seni arıyor",
  "Bu vaktin senin üzerindeki etkisini merak ediyor musun?",
  "Bu anın sende bırakacağı iz... Şimdi aç",
  "Bu an geçmeden bir bak",
  "Seninle buluşmak için bir an var",
];
const _kPremiumProductIds = new Set([
  "arin_premium_monthly_launch",
  "arin_premium_yearly_launch",
]);
const _kValidRcEnvironments = new Set(["PRODUCTION"]);
function _safeEqual(a, b) {
  const sa = String(a || "");
  const sb = String(b || "");
  if (sa.length !== sb.length) return false;
  let diff = 0;
  for (let i = 0; i < sa.length; i++) {
    diff |= sa.charCodeAt(i) ^ sb.charCodeAt(i);
  }
  return diff === 0;
}

async function _deleteCollectionInBatches(query, batchSize = 400) {
  const db = getFirestore();
  while (true) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) break;
    let batch = db.batch();
    let n = 0;
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
      n += 1;
      if (n >= batchSize) {
        await batch.commit();
        batch = db.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }
}

async function _purgeUserDataByUid(db, uid) {
  const userRef = db.collection("users").doc(uid);
  await _deleteCollectionInBatches(userRef.collection("habits"));
  await _deleteCollectionInBatches(userRef.collection("habit_logs"));
  await userRef.collection("zikir_matik").doc("state").delete().catch(() => {});
  await userRef.collection("user_backup").doc("state").delete().catch(() => {});
  await userRef.delete().catch(() => {});
  await db.collection("premium_entitlements").doc(uid).delete().catch(() => {});
}

async function _purgePremiumInviteByEmail(db, email) {
  const normalized = String(email || "").trim().toLowerCase();
  if (!normalized) return;
  await db.collection("premium_invites").doc(normalized).delete().catch(() => {});
}

function _extractBaseProductId(productId) {
  if (!productId || typeof productId !== "string") return null;
  return productId.split(":")[0];
}

function _eventHasPremiumEntitlement(event) {
  const ids = event && event.entitlement_ids;
  return Array.isArray(ids) && ids.includes("premium");
}

function _resolveActiveUntilMs(event) {
  const grace = Number(event.grace_period_expiration_at_ms);
  if (Number.isFinite(grace) && grace > 0) return grace;
  const expiry = Number(event.expiration_at_ms);
  if (Number.isFinite(expiry) && expiry > 0) return expiry;
  return null;
}

async function _isStaleForUid({ db, uid, eventTsMs }) {
  const docRef = db.collection("premium_entitlements").doc(uid);
  const snap = await docRef.get();
  const lastEventTsRaw = Number(snap.data()?.lastEventTimestampMs);
  return Number.isFinite(lastEventTsRaw) && lastEventTsRaw > eventTsMs;
}

async function _assertNotStaleForUid({ db, uid, eventTsMs }) {
  try {
    return await _isStaleForUid({ db, uid, eventTsMs });
  } catch (e) {
    throw new Error(`[RC Webhook] stale-check failed for ${uid}: ${e?.message || e}`);
  }
}

function _isPremiumSubscriptionEvent(event) {
  const rawProductId = event && event.product_id;
  const baseProductId = _extractBaseProductId(rawProductId);
  if (
    (rawProductId && _kPremiumProductIds.has(rawProductId)) ||
    (baseProductId && _kPremiumProductIds.has(baseProductId))
  ) {
    return true;
  }
  return _eventHasPremiumEntitlement(event);
}

/**
 * `admin_ntf_config/teasers` dökümanından yönetilebilir teaser listesini okur.
 * Hata/eksik halinde sabit fallback'e döner; bildirim akışı bozulmaz.
 */
async function loadTeaserTexts(db) {
  try {
    const snap = await db.collection("admin_ntf_config").doc("teasers").get();
    const arr = snap.exists ? snap.data().texts : null;
    if (Array.isArray(arr)) {
      const cleaned = arr
        .map((s) => (typeof s === "string" ? s.trim() : ""))
        .filter((s) => s.length > 0);
      if (cleaned.length > 0) return cleaned;
    }
  } catch (err) {
    console.error("[Teasers] okunamadı, fallback kullanılıyor:", err);
  }
  return _defaultTeaserTexts;
}

// firestore.rules ile birebir aynı tam-erişim e-posta listesi.
// Bu liste değişirse iki yer birden güncellenmelidir.
const _kFullAccessEmails = [
  "burakmelihkuzi@gmail.com",
  "brkkpl5@gmail.com",
  "seyirteknikerr@gmail.com",
];

/**
 * Çağıran kullanıcının admin olup olmadığını firestore.rules'taki `isAdmin()`
 * mantığını taklit ederek kontrol eder:
 *   1) E-posta tam-erişim listesinde mi?
 *   2) `admin_users/{uid}` dökümanı var mı? (varsa `role` boş ise 'content'
 *      varsayılır; bu da admin sayar.)
 *   3) `admin_invites/{email}` dökümanında geçerli bir role var mı?
 *
 * Custom claim sistemde tanımlı değil; bu yüzden Firestore üzerinden okuyoruz.
 */
async function assertCallerIsAdmin(req) {
  const auth = req.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Giriş yapılmamış.");
  }
  const uid = auth.uid;
  const email = (auth.token && auth.token.email)
    ? String(auth.token.email).toLowerCase()
    : null;

  if (email && _kFullAccessEmails.includes(email)) return;

  const db = getFirestore();
  try {
    const userSnap = await db.collection("admin_users").doc(uid).get();
    if (userSnap.exists) {
      const role = (userSnap.data().role || "content").trim();
      if (["content", "manager", "developer"].includes(role)) return;
    }
  } catch (err) {
    console.error("[Admin] admin_users okunamadı:", err);
  }

  if (email) {
    try {
      const inviteSnap = await db.collection("admin_invites").doc(email).get();
      if (inviteSnap.exists) {
        const role = String(inviteSnap.data().role || "").trim();
        if (["content", "manager", "developer"].includes(role)) return;
      }
    } catch (err) {
      console.error("[Admin] admin_invites okunamadı:", err);
    }
  }

  throw new HttpsError("permission-denied", "Sadece admin tetikleyebilir.");
}

// ─────────────────────────────────────────────────────────────────────────────
// Ürün performans metrikleri — yalnızca anonim kurulum hash'i ve sayısal
// aggregate'ler tutulur. E-posta, UID, içerik metni ve konum yazılmaz.
// ─────────────────────────────────────────────────────────────────────────────

const _kMetricEvents = new Set([
  "content_view",
  "content_like",
  "content_save",
  "widget_active",
  "widget_first_use",
  "widget_churned",
  "widget_returned",
  "widget_unlock",
]);
const _kWidgetKinds = new Set([
  "quote",
  "prayer",
  "combo",
  "tracking",
  "zikir",
]);

function _istanbulDayKey(ms = Date.now()) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(ms));
  const values = Object.fromEntries(
    parts.filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value]),
  );
  return `${values.year}-${values.month}-${values.day}`;
}

function _validatedInstallHash(rawInstallId) {
  const value = String(rawInstallId || "").trim();
  if (!/^[A-Za-z0-9_-]{16,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz kurulum kimliği.");
  }
  return crypto.createHash("sha256").update(value).digest("hex");
}

function _validatedCardId(rawCardId) {
  const value = String(rawCardId || "").trim();
  if (!value || value.length > 160 || value.includes("/")) {
    throw new HttpsError("invalid-argument", "Geçersiz içerik kimliği.");
  }
  return value;
}

function _validatedWidgetKind(rawKind) {
  const value = String(rawKind || "").trim();
  if (!_kWidgetKinds.has(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz widget türü.");
  }
  return value;
}

function _dedupeId(parts) {
  return crypto
    .createHash("sha256")
    .update(parts.join("|"))
    .digest("hex");
}

function _metricShardId(installHash) {
  return String(parseInt(installHash.substring(0, 4), 16) % 20)
    .padStart(2, "0");
}

function _dailyMetricRef(db, dayKey, installHash) {
  const shardId = _metricShardId(installHash);
  return db.collection("admin_metric_daily_shards")
    .doc(`${dayKey}_${shardId}`);
}

function _rateLimitRef(db, dayKey, installHash, scope) {
  return db.collection("admin_metric_rate_limits")
    .doc(`${dayKey}_${installHash}_${scope}`);
}

function _applyRateLimit(tx, snapshot, ref, limit) {
  const count = Number(snapshot.data()?.count) || 0;
  if (count >= limit) {
    throw new HttpsError(
      "resource-exhausted",
      "Günlük metrik kotası aşıldı.",
    );
  }
  tx.set(ref, {
    count: FieldValue.increment(1),
    expiresAt: Timestamp.fromMillis(Date.now() + 3 * 86400000),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

let _contentCatalogCache = { expiresAtMs: 0, ids: new Set() };
async function _assertKnownContentCard(db, cardId) {
  const now = Date.now();
  if (now >= _contentCatalogCache.expiresAtMs) {
    const snap = await db.collection("app_public").doc("inspiration_cards").get();
    const rawItems = snap.data()?.items;
    const ids = new Set();
    if (Array.isArray(rawItems)) {
      for (const item of rawItems) {
        const id = String(item?.id || "").trim();
        if (id) ids.add(id);
      }
    }
    _contentCatalogCache = {
      expiresAtMs: now + 5 * 60 * 1000,
      ids,
    };
  }
  if (!_contentCatalogCache.ids.has(cardId)) {
    throw new HttpsError("not-found", "İçerik kataloğunda kart bulunamadı.");
  }
}

async function _createNotificationDelivery(db, {
  source,
  poolItemId,
  title,
  body,
  sentAtMs,
  isTest = false,
}) {
  const audienceSnap = await db
    .collection("admin_metric_audience_members")
    .where("expiresAt", ">=", Timestamp.now())
    .count()
    .get();
  const audienceEstimate = audienceSnap.data().count;
  const ref = db.collection("admin_ntf_deliveries").doc();
  await ref.set({
    deliveryId: ref.id,
    source,
    poolItemId: poolItemId || null,
    title: String(title || "").slice(0, 180),
    body: String(body || "").slice(0, 500),
    sentAtMs,
    isTest: isTest === true,
    audienceEstimate,
    topic: "broadcast_all",
    status: "preparing",
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref;
}

exports.syncAnalyticsAudience = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: true,
  },
  async (req) => {
    const installHash = _validatedInstallHash(req.data?.installId);
    const active = req.data?.active === true;
    const platform = ["android", "ios"].includes(req.data?.platform)
      ? req.data.platform
      : "other";
    const db = getFirestore();
    const memberRef = db
      .collection("admin_metric_audience_members")
      .doc(installHash);
    const dayKey = _istanbulDayKey();
    const rateRef = _rateLimitRef(db, dayKey, installHash, "audience");

    await db.runTransaction(async (tx) => {
      const rateSnap = await tx.get(rateRef);
      _applyRateLimit(tx, rateSnap, rateRef, 100);
      tx.set(memberRef, {
        active,
        platform,
        expiresAt: Timestamp.fromMillis(
          active ? Date.now() + 35 * 86400000 : Date.now(),
        ),
        lastSeenAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return { ok: true };
  },
);

exports.recordNotificationClick = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: true,
  },
  async (req) => {
    const installHash = _validatedInstallHash(req.data?.installId);
    const deliveryId = String(req.data?.deliveryId || "").trim();
    if (!/^[A-Za-z0-9_-]{8,128}$/.test(deliveryId)) {
      throw new HttpsError("invalid-argument", "Geçersiz bildirim kimliği.");
    }

    const db = getFirestore();
    const deliveryRef = db.collection("admin_ntf_deliveries").doc(deliveryId);
    const clickRef = deliveryRef.collection("clicks").doc(installHash);
    const clickShardRef = db
      .collection("admin_ntf_delivery_click_shards")
      .doc(`${deliveryId}_${_metricShardId(installHash)}`);
    const dayKey = _istanbulDayKey();
    const dailyRef = _dailyMetricRef(db, dayKey, installHash);
    const rateRef = _rateLimitRef(db, dayKey, installHash, "notification");
    let counted = false;

    await db.runTransaction(async (tx) => {
      const [deliverySnap, clickSnap, rateSnap] = await Promise.all([
        tx.get(deliveryRef),
        tx.get(clickRef),
        tx.get(rateRef),
      ]);
      if (!deliverySnap.exists) {
        throw new HttpsError("not-found", "Bildirim kaydı bulunamadı.");
      }
      if (clickSnap.exists) return;
      _applyRateLimit(tx, rateSnap, rateRef, 100);
      counted = true;
      tx.create(clickRef, {
        clickedAt: FieldValue.serverTimestamp(),
      });
      tx.set(clickShardRef, {
        deliveryId,
        shardId: _metricShardId(installHash),
        clicks: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      tx.set(dailyRef, {
        dayKey,
        shardId: _metricShardId(installHash),
        notifications: {
          clicks: FieldValue.increment(1),
        },
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return { ok: true, counted };
  },
);

exports.recordProductMetric = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: true,
  },
  async (req) => {
    const event = String(req.data?.event || "").trim();
    if (!_kMetricEvents.has(event)) {
      throw new HttpsError("invalid-argument", "Desteklenmeyen metrik.");
    }
    const installHash = _validatedInstallHash(req.data?.installId);
    const dayKey = _istanbulDayKey();
    const db = getFirestore();
    const dailyRef = _dailyMetricRef(db, dayKey, installHash);
    const installRef = db
      .collection("admin_widget_installations")
      .doc(installHash);
    const widgetSummaryRef = db
      .collection("admin_widget_summary")
      .doc("current");

    let entity = "all";
    let cardId = null;
    let kind = null;
    if (event.startsWith("content_")) {
      cardId = _validatedCardId(req.data?.cardId);
      await _assertKnownContentCard(db, cardId);
      entity = cardId;
    }
    if (event === "widget_first_use" || event === "widget_unlock") {
      kind = _validatedWidgetKind(req.data?.kind);
      entity = kind;
    }
    const dedupeRef = db.collection("admin_metric_event_dedupe").doc(
      _dedupeId([dayKey, event, installHash, entity]),
    );
    const rateRef = _rateLimitRef(db, dayKey, installHash, "product");
    let counted = false;
    let accepted = false;

    await db.runTransaction(async (tx) => {
      const reads = [tx.get(dedupeRef), tx.get(rateRef)];
      if (event.startsWith("widget_")) reads.push(tx.get(installRef));
      const snapshots = await Promise.all(reads);
      const dedupeSnap = snapshots[0];
      const rateSnap = snapshots[1];
      if (dedupeSnap.exists) {
        accepted = true;
        return;
      }

      const installSnap = event.startsWith("widget_") ? snapshots[2] : null;
      const installData = installSnap?.data() || {};
      if (event === "widget_first_use" &&
          installData.kinds?.[kind]?.firstSeenAt != null) {
        accepted = true;
        return;
      }
      if (event === "widget_active" &&
          (!installSnap?.exists || installData.firstSeenAt == null)) {
        return;
      }
      if (event === "widget_churned") {
        if (!installSnap?.exists) return;
        if (installData.status === "churned") {
          accepted = true;
          return;
        }
      }
      if (event === "widget_returned" &&
          installData.status !== "churned") {
        if (installData.status === "active" &&
            installData.returnedAt != null) {
          accepted = true;
        }
        return;
      }

      _applyRateLimit(tx, rateSnap, rateRef, 300);
      counted = true;
      accepted = true;
      tx.create(dedupeRef, {
        event,
        dayKey,
        entity,
        expiresAt: Timestamp.fromMillis(Date.now() + 120 * 86400000),
        createdAt: FieldValue.serverTimestamp(),
      });

      const dailyUpdate = {
        dayKey,
        shardId: _metricShardId(installHash),
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (event.startsWith("content_")) {
        const metric = event.substring("content_".length);
        dailyUpdate.content = {
          [metric + "s"]: FieldValue.increment(1),
        };
        const contentRef = db.collection("admin_content_metric_shards").doc(
          `${_dedupeId([cardId]).substring(0, 24)}_` +
          _metricShardId(installHash),
        );
        tx.set(contentRef, {
          cardId,
          shardId: _metricShardId(installHash),
          [metric + "s"]: FieldValue.increment(1),
          lastEventAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (event === "widget_active") {
        dailyUpdate.widgets = {
          activeUsers: FieldValue.increment(1),
        };
        const finalWidgetActiveUpdate = {
          lastActiveAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (installSnap?.data()?.status !== "churned") {
          finalWidgetActiveUpdate.status = "active";
        }
        tx.set(installRef, finalWidgetActiveUpdate, { merge: true });
        const activeSummaryShardRef = db
          .collection("admin_widget_summary_shards")
          .doc(_metricShardId(installHash));
        tx.set(activeSummaryShardRef, {
          shardId: _metricShardId(installHash),
          activeUserDays: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (event === "widget_first_use") {
        const firstEver = installSnap?.exists !== true;
        dailyUpdate.widgets = {
          firstUses: FieldValue.increment(1),
          newUsers: FieldValue.increment(firstEver ? 1 : 0),
          byKind: {
            [kind]: {
              firstUses: FieldValue.increment(1),
            },
          },
        };
        tx.set(installRef, {
          firstSeenAt: installSnap?.data()?.firstSeenAt ||
            FieldValue.serverTimestamp(),
          lastActiveAt: FieldValue.serverTimestamp(),
          status: installSnap?.data()?.status === "churned" ?
            "churned" : "active",
          kinds: {
            [kind]: {
              firstSeenAt: FieldValue.serverTimestamp(),
            },
          },
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(widgetSummaryRef, {
          totalEverUsers: firstEver ? FieldValue.increment(1) :
            FieldValue.increment(0),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (event === "widget_churned") {
        dailyUpdate.widgets = {
          churned: FieldValue.increment(1),
        };
        tx.set(installRef, {
          status: "churned",
          churnedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(widgetSummaryRef, {
          currentChurned: FieldValue.increment(1),
          totalChurned: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (event === "widget_returned") {
        dailyUpdate.widgets = {
          returned: FieldValue.increment(1),
        };
        tx.set(installRef, {
          status: "active",
          returnedAt: FieldValue.serverTimestamp(),
          lastActiveAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(widgetSummaryRef, {
          currentChurned: FieldValue.increment(-1),
          totalReturned: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (event === "widget_unlock") {
        dailyUpdate.widgets = {
          unlocks: FieldValue.increment(1),
          byKind: {
            [kind]: {
              unlocks: FieldValue.increment(1),
            },
          },
        };
        tx.set(widgetSummaryRef, {
          totalUnlocks: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      tx.set(dailyRef, dailyUpdate, { merge: true });
    });
    return { ok: true, counted, accepted };
  },
);

exports.getAdminPerformance = onCall(
  {
    region: "europe-west1",
    memory: "512MiB",
    enforceAppCheck: true,
  },
  async (req) => {
    await assertCallerIsAdmin(req);
    const requestedDays = Number(req.data?.days);
    const days = requestedDays === 30 ? 30 : 7;
    const now = Date.now();
    const fromMs = now - (days - 1) * 86400000;
    const fromDay = _istanbulDayKey(fromMs);
    const db = getFirestore();

    const [
      dailySnap,
      deliveriesSnap,
      contentSnap,
      widgetSummarySnap,
      audienceSnap,
      active7Snap,
      active30Snap,
      inspireCatalogSnap,
      widgetSummaryShardsSnap,
    ] = await Promise.all([
      db.collection("admin_metric_daily_shards")
        .where("dayKey", ">=", fromDay)
        .orderBy("dayKey")
        .get(),
      db.collection("admin_ntf_deliveries")
        .orderBy("sentAtMs", "desc")
        .limit(50)
        .get(),
      db.collection("admin_content_metric_shards")
        .get(),
      db.collection("admin_widget_summary").doc("current").get(),
      db.collection("admin_metric_audience_members")
        .where("expiresAt", ">=", Timestamp.now())
        .count()
        .get(),
      db.collection("admin_widget_installations")
        .where("lastActiveAt", ">=", Timestamp.fromMillis(now - 7 * 86400000))
        .count()
        .get(),
      db.collection("admin_widget_installations")
        .where("lastActiveAt", ">=", Timestamp.fromMillis(now - 30 * 86400000))
        .count()
        .get(),
      db.collection("app_public").doc("inspiration_cards").get(),
      db.collection("admin_widget_summary_shards").get(),
    ]);

    const deliveryClickTotals = new Map();
    const deliveryIds = deliveriesSnap.docs.map((doc) => doc.id);
    for (let i = 0; i < deliveryIds.length; i += 30) {
      const chunk = deliveryIds.slice(i, i + 30);
      if (chunk.length === 0) continue;
      const shardSnap = await db
        .collection("admin_ntf_delivery_click_shards")
        .where("deliveryId", "in", chunk)
        .get();
      for (const shard of shardSnap.docs) {
        const data = shard.data();
        const id = String(data.deliveryId || "");
        deliveryClickTotals.set(
          id,
          (deliveryClickTotals.get(id) || 0) + (Number(data.clicks) || 0),
        );
      }
    }

    const contentLabels = new Map();
    const rawItems = inspireCatalogSnap.data()?.items;
    if (Array.isArray(rawItems)) {
      for (const item of rawItems) {
        const id = String(item?.id || "").trim();
        if (!id) continue;
        contentLabels.set(id, String(item?.tr || "").trim().slice(0, 120));
      }
    }
    const contentTotals = new Map();
    for (const doc of contentSnap.docs) {
      const data = doc.data();
      const cardId = String(data.cardId || "").trim();
      if (!cardId) continue;
      const current = contentTotals.get(cardId) || {
        id: cardId,
        label: contentLabels.get(cardId) || "",
        views: 0,
        likes: 0,
        saves: 0,
      };
      current.views += Number(data.views) || 0;
      current.likes += Number(data.likes) || 0;
      current.saves += Number(data.saves) || 0;
      contentTotals.set(cardId, current);
    }
    const topContent = [...contentTotals.values()]
      .sort((a, b) => b.views - a.views)
      .slice(0, 30);
    const activeUserDays = widgetSummaryShardsSnap.docs.reduce(
      (sum, doc) => sum + (Number(doc.data().activeUserDays) || 0),
      0,
    );

    return {
      days,
      generatedAtMs: now,
      daily: dailySnap.docs.map((doc) => ({
        id: doc.id,
        content: doc.data().content || {},
        notifications: doc.data().notifications || {},
        widgets: doc.data().widgets || {},
      })),
      deliveries: deliveriesSnap.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          source: data.source || "",
          title: data.title || "",
          body: data.body || "",
          sentAtMs: Number(data.sentAtMs) || 0,
          isTest: data.isTest === true,
          audienceEstimate: Number(data.audienceEstimate) || 0,
          uniqueClicks: deliveryClickTotals.get(doc.id) || 0,
          status: data.status || "",
        };
      }),
      content: topContent,
      widgets: {
        totalEverUsers:
          Number(widgetSummarySnap.data()?.totalEverUsers) || 0,
        currentChurned:
          Math.max(0, Number(widgetSummarySnap.data()?.currentChurned) || 0),
        totalChurned:
          Number(widgetSummarySnap.data()?.totalChurned) || 0,
        totalReturned:
          Number(widgetSummarySnap.data()?.totalReturned) || 0,
        totalUnlocks:
          Number(widgetSummarySnap.data()?.totalUnlocks) || 0,
        activeUserDays,
        active7: active7Snap.data().count,
        active30: active30Snap.data().count,
      },
      notificationAudience: audienceSnap.data().count,
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// syncGlobalWidgetLock — app_public/widget_global_lock değiştiğinde görünür
// bildirim üretmeden tüm cihazlara yeni override durumunu yollar.
//
// Mesaj bir revision taşır. FCM teslim sırası garanti etmediği için istemci
// daha eski revision'ı reddeder; retry/duplicate teslimler idempotent kalır.
// Premium istisnası cihazdaki native widget provider tarafından uygulanır.
// ─────────────────────────────────────────────────────────────────────────────
exports.syncGlobalWidgetLock = onDocumentWritten(
  {
    document: "app_public/widget_global_lock",
    region: "europe-west1",
    memory: "256MiB",
    retry: true,
  },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    // Silme işlemi beklenmeyen toplu unlock üretmemeli. Kilit yalnızca açıkça
    // `locked: false` yazılarak kaldırılır.
    if (after?.exists !== true) return;
    const previousLocked =
      before?.exists === true && before.data()?.locked === true;
    const locked = after.data()?.locked === true;

    // Not/audit alanı gibi kilit durumunu değiştirmeyen yazılar push üretmesin.
    if (before?.exists === true && after?.exists === true &&
        previousLocked === locked) {
      return;
    }

    const storedRevision = Number(after?.data()?.revision);
    if (!Number.isSafeInteger(storedRevision) || storedRevision <= 0) {
      console.warn("[WidgetGlobalLock] revision eksik/geçersiz, push atlandı");
      return;
    }
    const revision = storedRevision;
    const note = String(after.data()?.note || "").trim().slice(0, 500);

    const messageId = await getMessaging().send({
      topic: "widget_gate_all",
      data: {
        type: "widget_global_lock",
        locked: locked ? "1" : "0",
        revision: String(revision),
        note,
      },
      android: {
        priority: "high",
        ttl: 24 * 60 * 60 * 1000,
      },
      apns: {
        headers: {
          "apns-push-type": "background",
          "apns-priority": "5",
        },
        payload: {
          aps: {
            contentAvailable: true,
          },
        },
      },
    });

    console.log(
      `[WidgetGlobalLock] locked=${locked} revision=${revision} messageId=${messageId}`,
    );
  },
);

exports.sendScheduledNotifications = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    region: "europe-west1",
  },
  async (_event) => {
    const db = getFirestore();
    const messaging = getMessaging();
    const nowMs = Date.now();

    const istNow = new Date(
      new Date(nowMs).toLocaleString("en-US", { timeZone: "Europe/Istanbul" })
    );
    const istHour = istNow.getHours();
    const istMin = istNow.getMinutes();
    const year = istNow.getFullYear();
    const month = String(istNow.getMonth() + 1).padStart(2, "0");
    const day = String(istNow.getDate()).padStart(2, "0");
    const todayStr = `${year}-${month}-${day}`;
    const currentMinuteOfDay = istHour * 60 + istMin;

    // İki aşamalı planlama:
    //   1. Gün değişince (veya ilk uygun anda) pool'dan rastgele uygun bir ayet
    //      seçilir ve o ayetin kendi hour:minute'i o günün gönderim zamanı olur.
    //      Seçim admin_ntf_config/today_plan dokümanına yazılır.
    //   2. Her dakika: today_plan'daki saat gelince bildirim gönderilir.
    //
    // Böylece her gün farklı item seçilir (06:12 ile 12:10 sırayla gelir)
    // ve seçilen item tam kendi saatinde (06:12 → 06:12'de) ateşlenir.

    try {
      // ── 1. Config ──────────────────────────────────────────────────────────
      const configSnap = await db
        .collection("admin_ntf_config")
        .doc("schedule")
        .get();
      const config = configSnap.exists ? configSnap.data() : {};
      const autoEnabled = config.autoEnabled !== false;
      const sendEveryNDays = config.sendEveryNDays ?? 3;
      const minRepeatDays = config.minRepeatDays ?? 60;
      const lastAutoSentDate = config.lastAutoSentDate ?? null;

      if (!autoEnabled) {
        console.log("[Havuz] Otomatik gönderim kapalı (autoEnabled=false).");
        return;
      }

      // ── 2. Global cooldown ─────────────────────────────────────────────────
      const daysSinceLast = lastAutoSentDate
        ? daysBetween(lastAutoSentDate, todayStr)
        : 9999;

      if (daysSinceLast < sendEveryNDays) {
        console.log(
          `[Havuz] Henüz erken: ${daysSinceLast}/${sendEveryNDays} gün. Atlandı.`
        );
        return;
      }

      // ── 3. Bugünün planını oku ─────────────────────────────────────────────
      const planRef = db.collection("admin_ntf_config").doc("today_plan");
      const planSnap = await planRef.get();
      const plan = planSnap.exists ? planSnap.data() : null;

      // Bugün için plan zaten kapatıldı mı? (gönderildi veya pencere geçti)
      if (plan && plan.date === todayStr && plan.sent === true) {
        console.log(
          plan.missedAt
            ? "[Havuz] Bugünün gönderim penceresi geçmişti (missed)."
            : "[Havuz] Bugün zaten gönderildi."
        );
        return;
      }

      // ── 4. Plan yoksa yeni plan oluştur ────────────────────────────────────
      // Her item kendi hour:minute'iyle gelir; sadece saati henüz geçmemiş
      // ve minRepeatDays koşulunu sağlayan item'lar adaydır.
      if (!plan || plan.date !== todayStr) {
        const poolSnap = await db
          .collection("admin_ntf_pool")
          .where("enabled", "==", true)
          .get();

        if (poolSnap.empty) {
          console.log("[Havuz] Pool boş. Plan oluşturulamadı.");
          return;
        }

        const eligible = poolSnap.docs.filter((doc) => {
          const d = doc.data();
          const itemH = Number(d.hour);
          const itemM = Number(d.minute);
          if (!Number.isFinite(itemH) || !Number.isFinite(itemM)) return false;
          // Saati bugün için geçmemiş olmalı (en az 1 dk ileri)
          if (itemH * 60 + itemM <= currentMinuteOfDay) return false;
          // minRepeatDays kontrolü
          if (!d.lastSentDate) return true;
          const itemMinRepeat = Number.isFinite(d.minRepeatDays)
            ? Number(d.minRepeatDays)
            : minRepeatDays;
          return daysBetween(d.lastSentDate, todayStr) >= itemMinRepeat;
        });

        if (eligible.length === 0) {
          console.log(
            "[Havuz] Bugün için uygun öğe yok (tümü geçti veya cooldown). Yarın denenecek."
          );
          return;
        }

        const chosen = eligible[Math.floor(Math.random() * eligible.length)];
        const chosenData = chosen.data();
        const sendAtHour = Number(chosenData.hour);
        const sendAtMin = Number(chosenData.minute);
        const sendAtMinuteOfDay = sendAtHour * 60 + sendAtMin;

        await planRef.set({
          date: todayStr,
          itemId: chosen.id,
          sendAtHour,
          sendAtMin,
          sendAtMinuteOfDay,
          sent: false,
          createdAtMinuteOfDay: currentMinuteOfDay,
          createdAt: FieldValue.serverTimestamp(),
        });

        const ph = String(sendAtHour).padStart(2, "0");
        const pm = String(sendAtMin).padStart(2, "0");
        console.log(
          `[Havuz] Plan oluşturuldu: itemId=${chosen.id}, gönderim=${ph}:${pm}`
        );
        return;
      }

      // ── 5. Plan var — saat geldi mi? ───────────────────────────────────────
      // sendAtMinuteOfDay alanı yeni plan formatında; eski planlar için fallback.
      const planMinuteOfDay =
        typeof plan.sendAtMinuteOfDay === "number"
          ? plan.sendAtMinuteOfDay
          : (Number(plan.sendAtHour) * 60 + Number(plan.sendAtMin));
      const gracePeriod = 3; // dakika toleransı — gecikmiş tetikler için

      if (currentMinuteOfDay < planMinuteOfDay) {
        console.log(
          `[Havuz] Bekleniyor. Plan: ${planMinuteOfDay} dk, şu an: ${currentMinuteOfDay} dk.`
        );
        return;
      }

      if (currentMinuteOfDay > planMinuteOfDay + gracePeriod) {
        await planRef.set(
          { sent: true, missedAt: FieldValue.serverTimestamp() },
          { merge: true }
        );
        console.log(
          `[Havuz] Gönderim penceresi geçti (plan=${planMinuteOfDay}, şu an=${currentMinuteOfDay}). Plan kapatıldı.`
        );
        return;
      }

      // ── 6. Gönder (atomik claim) ──────────────────────────────────────────
      // Aynı dakikada paralel scheduler instance'larında çift gönderimi engelle.
      const claimRef = db.collection("admin_ntf_config").doc("today_plan_claim");
      const claimOk = await db.runTransaction(async (tx) => {
        const claimSnap = await tx.get(claimRef);
        const claim = claimSnap.exists ? claimSnap.data() || {} : {};
        const claimedAtMs = Number(claim.claimedAtMs || 0);
        const claimPlanDate = String(claim.planDate || "");
        const claimPlanItemId = String(claim.planItemId || "");
        const stillFresh = nowMs - claimedAtMs < _kNotificationClaimTtlMs;
        const alreadyClaimed =
          stillFresh &&
          claimPlanDate === todayStr &&
          claimPlanItemId === String(plan.itemId || "");
        if (alreadyClaimed) {
          return false;
        }
        tx.set(
          claimRef,
          {
            planDate: todayStr,
            planItemId: String(plan.itemId || ""),
            claimedAtMs: nowMs,
            claimedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return true;
      });
      if (!claimOk) {
        console.log("[Havuz] Plan claim başka instance tarafından alındı, atlandı.");
        return;
      }

      const itemSnap = await db
        .collection("admin_ntf_pool")
        .doc(plan.itemId)
        .get();

      if (!itemSnap.exists) {
        console.error("[Havuz] Planlanan item bulunamadı:", plan.itemId);
        await planRef.set({ sent: true }, { merge: true });
        return;
      }

      const data = itemSnap.data();

      // clockStr: plan'a kaydedilen saat (= item'ın hour:minute = surah:ayet).
      // Gerçek gönderim saatiyle örtüşür — "ayet dönüşüm" konsepti korunur.
      const clockStr = `${String(plan.sendAtHour).padStart(2, "0")}:${String(plan.sendAtMin).padStart(2, "0")}`;

      const hasSurahData = data.surahNumber != null && data.verseNumber != null;
      const ntfTitle = `Saat ${clockStr}`;

      let ntfBody = (data.notificationBody || "").toString().trim();
      if (!ntfBody) {
        const teaserTexts = await loadTeaserTexts(db);
        ntfBody = teaserTexts[Math.floor(Math.random() * teaserTexts.length)];
      }

      const expiresAtMs = nowMs + 5 * 60 * 1000;
      const deliveryRef = await _createNotificationDelivery(db, {
        source: "auto",
        poolItemId: plan.itemId,
        title: ntfTitle,
        body: ntfBody,
        sentAtMs: nowMs,
      });
      try {
        await db
          .collection("admin_ntf_config")
          .doc("current_moment")
          .set({
            surahNumber: data.surahNumber ?? null,
            surahName: data.surahName ?? "",
            verseNumber: data.verseNumber ?? null,
            verseText: data.text ?? "",
            ref: data.ref ?? "",
            clockStr,
            sentAtMs: nowMs,
            expiresAtMs,
            deliveryId: deliveryRef.id,
          });
      } catch (err) {
        console.error("[Havuz] current_moment yazılamadı:", err);
      }

      let fcmMessageId;
      try {
        fcmMessageId = await messaging.send({
          topic: "broadcast_all",
          notification: { title: ntfTitle, body: ntfBody },
          data: {
            type: "moment_verse",
            sentAtMs: String(nowMs),
            deliveryId: deliveryRef.id,
          },
          android: {
            notification: {
              channelId: "arin_ntf_broadcast",
              priority: "high",
              defaultSound: true,
            },
          },
          apns: {
            payload: { aps: { sound: "default" } },
          },
        });
      } catch (err) {
        await deliveryRef.set({
          status: "failed",
          error: String(err?.message || err).slice(0, 300),
          failedAt: FieldValue.serverTimestamp(),
        }, { merge: true }).catch(() => {});
        throw err;
      }
      await deliveryRef.set({
        status: "sent",
        fcmMessageId,
        sentAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      // Planı kapat
      await planRef.set(
        { sent: true, sentAtMs: nowMs },
        { merge: true }
      );

      // Item'ın son gönderim tarihini güncelle
      await itemSnap.ref.update({
        lastSentDate: todayStr,
        lastSentAt: FieldValue.serverTimestamp(),
      });

      // Global timer'ı güncelle
      await db
        .collection("admin_ntf_config")
        .doc("schedule")
        .set({ lastAutoSentDate: todayStr }, { merge: true });

      console.log(
        `[Havuz] Gönderildi ${clockStr}` +
        `${hasSurahData ? ` (Sure ${data.surahNumber}:${data.verseNumber})` : ""}` +
        ` — "${String(data.text || "").slice(0, 60)}"`
      );
    } catch (err) {
      console.error("[Havuz] Hata:", err);
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// sendMomentVerseNow — admin panelinden tetiklenen anlık moment-verse push.
//
// Admin pool item'ında "▶ Şimdi gönder" butonuna basar; bu callable function
// ilgili pool dökümanını okur, `current_moment`'a 5 dakikalık geçerlilik
// penceresiyle yazar ve `broadcast_all` topic'ine moment-verse tipi bildirim
// atar. Saat:dakika eşleşmesi VE sıklık/tekrar cooldown'ları bypass edilir;
// `lastSentDate` yine güncellenir ki sonraki otomatik gönderimler bu öğeyi
// `minRepeatDays` boyunca atlasın (bu gerçek bir manuel gönderim sayılır).
//
// NOT: Sadece TEST amaçlı tetiklemek için `sendTestNotification` kullan —
// cooldown'u bozmaz.
//
// Yetki: yalnızca admin (firestore.rules ile aynı 3-katmanlı kontrol).
// ─────────────────────────────────────────────────────────────────────────────
exports.sendMomentVerseNow = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
  },
  async (req) => {
    await assertCallerIsAdmin(req);

    const poolItemId = (req.data && req.data.poolItemId) || "";
    if (!poolItemId || typeof poolItemId !== "string") {
      throw new HttpsError("invalid-argument", "poolItemId zorunlu.");
    }

    const db = getFirestore();
    const messaging = getMessaging();

    const itemRef = db.collection("admin_ntf_pool").doc(poolItemId);
    const itemSnap = await itemRef.get();
    if (!itemSnap.exists) {
      throw new HttpsError("not-found", "Pool öğesi bulunamadı.");
    }
    const data = itemSnap.data() || {};

    const nowMs = Date.now();
    const expiresAtMs = nowMs + 5 * 60 * 1000;

    // Saat:dakika öğenin kayıtlı saatinden alınır; "anlık" tetikte de
    // kullanıcıya tutarlı görünmesi için (kullanıcının ekranında ayet listede
    // hangi saate atanmışsa o görünsün).
    const hour = Number(data.hour);
    const minute = Number(data.minute);
    const clockStr =
      Number.isFinite(hour) && Number.isFinite(minute)
        ? `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`
        : "";

    const hasSurahData =
      data.surahNumber != null && data.verseNumber != null;
    const ntfTitle = clockStr
      ? `Saat ${clockStr}`
      : (data.title || "Arın");

    // Manuel gönderimde de aynı öncelik: önce item.notificationBody, yoksa
    // havuzdan rastgele teaser.
    let ntfBody = (data.notificationBody || "").toString().trim();
    if (!ntfBody) {
      const teaserTexts = await loadTeaserTexts(db);
      ntfBody = teaserTexts[Math.floor(Math.random() * teaserTexts.length)];
    }

    const deliveryRef = await _createNotificationDelivery(db, {
      source: "manual",
      poolItemId,
      title: ntfTitle,
      body: ntfBody,
      sentAtMs: nowMs,
    });

    // current_moment dokümanını yaz — kullanıcı tıkladığında MomentVersePage
    // bu dökümanı okuyup süre kontrolü yapacak.
    try {
      await db
        .collection("admin_ntf_config")
        .doc("current_moment")
        .set({
          surahNumber: data.surahNumber ?? null,
          surahName: data.surahName ?? "",
          verseNumber: data.verseNumber ?? null,
          verseText: data.text ?? "",
          ref: data.ref ?? "",
          clockStr: clockStr,
          sentAtMs: nowMs,
          expiresAtMs: expiresAtMs,
          deliveryId: deliveryRef.id,
        });
    } catch (err) {
      console.error("[ManualSend] current_moment yazılamadı:", err);
      throw new HttpsError("internal", "current_moment yazılamadı.");
    }

    try {
      const fcmMessageId = await messaging.send({
        topic: "broadcast_all",
        notification: { title: ntfTitle, body: ntfBody },
        data: {
          type: "moment_verse",
          sentAtMs: String(nowMs),
          deliveryId: deliveryRef.id,
        },
        android: {
          notification: {
            channelId: "arin_ntf_broadcast",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });
      await deliveryRef.set({
        status: "sent",
        fcmMessageId,
        sentAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (err) {
      await deliveryRef.set({
        status: "failed",
        error: String(err?.message || err).slice(0, 300),
        failedAt: FieldValue.serverTimestamp(),
      }, { merge: true }).catch(() => {});
      console.error("[ManualSend] FCM gönderim hatası:", err);
      throw new HttpsError("internal", `FCM gönderilemedi: ${err.message || err}`);
    }

    // Pool item'ın son gönderim tarihini güncelle (cooldown penceresi başlasın).
    const istNow = new Date(
      new Date(nowMs).toLocaleString("en-US", { timeZone: "Europe/Istanbul" })
    );
    const todayStr = `${istNow.getFullYear()}-${String(istNow.getMonth() + 1).padStart(2, "0")}-${String(istNow.getDate()).padStart(2, "0")}`;
    try {
      await itemRef.update({
        lastSentDate: todayStr,
        lastSentAt: FieldValue.serverTimestamp(),
        lastManualSentAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.warn("[ManualSend] lastSentDate güncellenemedi (push gönderildi):", err);
    }

    console.log(
      `[ManualSend] Gönderildi ${clockStr}` +
      `${hasSurahData ? ` (Sure ${data.surahNumber}:${data.verseNumber})` : ""}` +
      ` — "${String(data.text || "").slice(0, 60)}"`
    );

    return {
      ok: true,
      sentAtMs: nowMs,
      expiresAtMs: expiresAtMs,
      title: ntfTitle,
      body: ntfBody,
      deliveryId: deliveryRef.id,
    };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// sendTestNotification — yalnızca test amaçlı kullanılan callable.
//
// Admin panelden "Test Bildirimi Gönder" butonuna basar. Amaç: push akışının
// (FCM token + APNs + Android channel + uygulama içi yönlendirme) çalıştığını
// hiç ayet eklemeden ve saat:dakika beklemeden doğrulamak.
//
// Davranış:
//   • Sabit bir test ayeti kullanır (default fallback) VEYA çağrıda
//     `poolItemId` verilirse o pool öğesindeki içeriği test eder.
//   • `broadcast_all` topic'ine push atar (başlık `TEST · ...`).
//   • `current_moment` dökümanını 5 dakikalık pencereyle yazar ki kullanıcı
//     bildirime tıklayınca MomentVersePage de açılsın → uçtan uca akış test
//     edilebilir.
//   • Pool'a DOKUNMAZ: ne `lastSentDate` ne `lastAutoSentDate` güncellenir,
//     cooldown'lar bozulmaz.
//
// Yetki: yalnızca admin.
// ─────────────────────────────────────────────────────────────────────────────
exports.sendTestNotification = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
  },
  async (req) => {
    await assertCallerIsAdmin(req);

    const db = getFirestore();
    const messaging = getMessaging();

    const nowMs = Date.now();
    const expiresAtMs = nowMs + 5 * 60 * 1000;

    // İsteğe bağlı: var olan bir pool öğesini test et.
    const poolItemId =
      (req.data && typeof req.data.poolItemId === "string")
        ? req.data.poolItemId
        : "";

    let surahNumber = null;
    let surahName = "";
    let verseNumber = null;
    let verseText = "";
    let ref = "";
    let clockStr = "";
    let bodyFromItem = "";

    if (poolItemId) {
      try {
        const snap = await db
          .collection("admin_ntf_pool")
          .doc(poolItemId)
          .get();
        if (snap.exists) {
          const d = snap.data() || {};
          surahNumber = d.surahNumber ?? null;
          surahName = d.surahName ?? "";
          verseNumber = d.verseNumber ?? null;
          verseText = d.text ?? "";
          ref = d.ref ?? "";
          bodyFromItem = (d.notificationBody || "").toString().trim();
          const hh = Number(d.hour);
          const mm = Number(d.minute);
          if (Number.isFinite(hh) && Number.isFinite(mm)) {
            clockStr = `${String(hh).padStart(2, "0")}:${String(mm).padStart(2, "0")}`;
          }
        }
      } catch (err) {
        console.error("[Test] poolItem okunamadı:", err);
      }
    }

    // Pool öğesi yoksa varsayılan test içerikleri.
    if (!verseText) {
      surahNumber = 21;
      surahName = "Enbiyâ (test)";
      verseNumber = 5;
      verseText = "Bu bir test ayetidir. Bildirim akışı çalışıyor.";
      ref = "TEST";
    }

    // clockStr boşsa (pool item yok veya item'da saat tanımlı değil), cihazın
    // şu anki İstanbul saatini koy. Böylece test bildirimi başlığı her zaman
    // gerçek bildirim formatıyla aynı görünür: "🌙 21:25 · Kur'an 21:5".
    if (!clockStr) {
      const istNowForClock = new Date(
        new Date(nowMs).toLocaleString("en-US", { timeZone: "Europe/Istanbul" }),
      );
      const hh = String(istNowForClock.getHours()).padStart(2, "0");
      const mm = String(istNowForClock.getMinutes()).padStart(2, "0");
      clockStr = `${hh}:${mm}`;
    }

    // Test başlığı: gerçek bildirim ile aynı format. "TEST · " prefix'i
    // admin'in gerçek bildirimden ayırt etmesi için.
    const ntfTitle = clockStr
      ? `TEST · Saat ${clockStr}`
      : "TEST · Arın";

    // Gövde önceliği: item.notificationBody > teaser havuzu > sabit metin
    let ntfBody = bodyFromItem;
    if (!ntfBody) {
      const teaserTexts = await loadTeaserTexts(db);
      ntfBody = teaserTexts.length
        ? teaserTexts[Math.floor(Math.random() * teaserTexts.length)]
        : "Bu bir test bildirimidir.";
    }

    const deliveryRef = await _createNotificationDelivery(db, {
      source: "test",
      poolItemId,
      title: ntfTitle,
      body: ntfBody,
      sentAtMs: nowMs,
      isTest: true,
    });

    // current_moment dökümanı — kullanıcı bildirime tıklarsa MomentVersePage
    // bu içeriği gösterir.
    try {
      await db
        .collection("admin_ntf_config")
        .doc("current_moment")
        .set({
          surahNumber,
          surahName,
          verseNumber,
          verseText,
          ref,
          clockStr,
          sentAtMs: nowMs,
          expiresAtMs,
          isTest: true,
          deliveryId: deliveryRef.id,
        });
    } catch (err) {
      console.error("[Test] current_moment yazılamadı:", err);
      throw new HttpsError("internal", "current_moment yazılamadı.");
    }

    try {
      const fcmMessageId = await messaging.send({
        topic: "broadcast_all",
        notification: { title: ntfTitle, body: ntfBody },
        data: {
          type: "moment_verse",
          sentAtMs: String(nowMs),
          isTest: "true",
          deliveryId: deliveryRef.id,
        },
        android: {
          notification: {
            channelId: "arin_ntf_broadcast",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });
      await deliveryRef.set({
        status: "sent",
        fcmMessageId,
        sentAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (err) {
      await deliveryRef.set({
        status: "failed",
        error: String(err?.message || err).slice(0, 300),
        failedAt: FieldValue.serverTimestamp(),
      }, { merge: true }).catch(() => {});
      console.error("[Test] FCM gönderim hatası:", err);
      throw new HttpsError(
        "internal",
        `Test bildirimi gönderilemedi: ${err.message || err}`,
      );
    }

    console.log(
      `[Test] Gönderildi — title="${ntfTitle}", body="${ntfBody}"` +
      (poolItemId ? ` (poolItemId=${poolItemId})` : " (default)"),
    );

    return {
      ok: true,
      sentAtMs: nowMs,
      expiresAtMs,
      title: ntfTitle,
      body: ntfBody,
      deliveryId: deliveryRef.id,
    };
  }
);

// ─── RevenueCat Webhook ───────────────────────────────────────────────────────
//
// RevenueCat Dashboard → Project Settings → Integrations → Webhooks:
//   URL: https://<region>-<project-id>.cloudfunctions.net/revenuecatWebhook
//   Authorization: <REVENUECAT_WEBHOOK_SECRET> (ortam değişkeni ile set edilir)
//
// Firebase secret eklemek için:
//   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
//
// Desteklenen olaylar:
//   INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE, UNCANCELLATION → active = true
//   CANCELLATION, BILLING_ISSUE                               → expiry'e göre active
//   EXPIRATION                                                → active = false
//   TRANSFER                                                  → from pasif / to aktif
//
// app_user_id = Firebase UID (PurchaseService.initialize içinde logIn ile set edilir)
exports.revenuecatWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: ["REVENUECAT_WEBHOOK_SECRET"],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // ── Yetki doğrulaması ────────────────────────────────────────────────
    const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
    if (!secret) {
      console.error("[RC Webhook] Secret eksik, fail-closed");
      res.status(500).send("Webhook not configured");
      return;
    }
    const authHeader = String(req.headers.authorization || "").trim();
    const normalizedAuth = authHeader.toLowerCase().startsWith("bearer ")
      ? authHeader.slice(7).trim()
      : authHeader;
    const headerOk = _safeEqual(normalizedAuth, secret);
    if (!headerOk) {
      console.warn("[RC Webhook] Authorization geçersiz — istek reddedildi");
      res.status(401).send("Unauthorized");
      return;
    }

    const event = req.body?.event;
    if (!event) {
      res.status(400).send("Bad Request: event missing");
      return;
    }

    if (!_kValidRcEnvironments.has(String(event.environment || ""))) {
      console.log(
        `[RC Webhook] Ortam atlandı: ${String(event.environment || "unknown")}`,
      );
      res.status(200).json({ ok: true, skipped: true, environment: true });
      return;
    }

    const db = getFirestore();
    const now = Timestamp.now();
    const nowMs = Date.now();
    const eventTsMsRaw = Number(event.event_timestamp_ms);
    if (!Number.isFinite(eventTsMsRaw) || eventTsMsRaw <= 0) {
      console.warn("[RC Webhook] event_timestamp_ms geçersiz, event atlandı");
      res.status(200).json({ ok: true, skipped: true, badTimestamp: true });
      return;
    }
    const eventTsMs = eventTsMsRaw;

    // E-postayı önce RevenueCat subscriber_attributes'dan dene,
    // yoksa Firebase Auth'dan çek.
    let email = null;
    const type = event.type;
    const productId = event.product_id ?? null;

    if (type === "TRANSFER") {
      if (!_isPremiumSubscriptionEvent(event)) {
        console.log("[RC Webhook] TRANSFER premium değil, atlandı");
        res.status(200).json({ ok: true, skipped: true });
        return;
      }
      const transferredFrom = Array.isArray(event.transferred_from)
        ? event.transferred_from
        : [];
      const transferredTo = Array.isArray(event.transferred_to)
        ? event.transferred_to
        : [];
      const expiresAtMs = event.expiration_at_ms;
      const activeUntilMs = _resolveActiveUntilMs(event);
      const expiresAt = activeUntilMs ? Timestamp.fromMillis(activeUntilMs) : null;
      const isActiveUntilExpiry = activeUntilMs ? activeUntilMs > nowMs : false;
      const writes = [];
      for (const fromUid of transferredFrom) {
        if (!fromUid || String(fromUid).startsWith("$RCAnonymousID")) continue;
        const normalizedUid = String(fromUid);
        const stale = await _assertNotStaleForUid({
          db,
          uid: normalizedUid,
          eventTsMs,
        });
        if (stale) continue;
        writes.push(
          db.collection("premium_entitlements").doc(normalizedUid).set(
            {
              active: false,
              source: "revenuecat",
              productId: _extractBaseProductId(productId) ?? productId,
              platform: event.store ?? null,
              updatedAt: now,
              lastEventTimestampMs: eventTsMs,
            },
            { merge: true },
          ),
        );
      }
      for (const toUid of transferredTo) {
        if (!toUid || String(toUid).startsWith("$RCAnonymousID")) continue;
        const normalizedUid = String(toUid);
        const stale = await _assertNotStaleForUid({
          db,
          uid: normalizedUid,
          eventTsMs,
        });
        if (stale) continue;
        writes.push(
          db.collection("premium_entitlements").doc(normalizedUid).set(
            {
              active: isActiveUntilExpiry,
              source: "revenuecat",
              productId: _extractBaseProductId(productId) ?? productId,
              platform: event.store ?? null,
              expiresAt,
              updatedAt: now,
              lastEventTimestampMs: eventTsMs,
            },
            { merge: true },
          ),
        );
      }
      if (writes.length > 0) {
        await Promise.all(writes);
      }
      console.log(
        `[RC Webhook] TRANSFER işlendi from=${transferredFrom.length} to=${transferredTo.length}`,
      );
      res.status(200).json({ ok: true });
      return;
    }

    const uid = event.app_user_id;
    if (!uid || uid.startsWith("$RCAnonymousID")) {
      // Anonim kullanıcı — Firestore'a yazma.
      console.log("[RC Webhook] Anonim kullanıcı, atlandı:", uid);
      res.status(200).json({ ok: true, skipped: true });
      return;
    }
    const docRef = db.collection("premium_entitlements").doc(uid);

    try {
      const rcEmail = event.subscriber_attributes?.$email?.value;
      if (rcEmail && rcEmail.trim().length > 0) {
        email = rcEmail.trim().toLowerCase();
      } else {
        const userRecord = await getAuth().getUser(uid);
        email = userRecord.email?.trim().toLowerCase() ?? null;
      }
    } catch (e) {
      console.warn("[RC Webhook] E-posta alınamadı:", e?.message);
    }

    const stale = await _assertNotStaleForUid({ db, uid, eventTsMs });
    if (stale) {
      console.log(
        `[RC Webhook] Eski event atlandı uid=${uid} eventTs=${eventTsMs}`,
      );
      res.status(200).json({ ok: true, skipped: true, stale: true });
      return;
    }

    const activeTypes = new Set([
      "INITIAL_PURCHASE",
      "RENEWAL",
      "PRODUCT_CHANGE",
      "UNCANCELLATION",
    ]);
    const inactiveTypes = new Set(["EXPIRATION"]);

    // Sadece premium abonelik SKU'ları entitlement günceller.
    // Destek ürünleri (tip/non-subscription) bu koleksiyonu etkilememeli.
    if (!_isPremiumSubscriptionEvent(event)) {
      console.log(
        `[RC Webhook] Premium olmayan ürün atlandı: ${productId ?? "null"} (${type})`
      );
      res.status(200).json({ ok: true, skipped: true });
      return;
    }

    if (activeTypes.has(type)) {
      const expiresAtMs = event.expiration_at_ms;
      await docRef.set(
        {
          active: true,
          source: "revenuecat",
          email: email,
          productId: _extractBaseProductId(productId) ?? productId,
          platform: event.store ?? null,
          expiresAt: expiresAtMs
            ? Timestamp.fromMillis(expiresAtMs)
            : null,
          updatedAt: now,
          lastEventTimestampMs: eventTsMs,
        },
        { merge: true },
      );
      console.log(`[RC Webhook] ${type} → ${uid} (${email ?? "e-posta yok"}) premium aktif edildi`);
    } else if (inactiveTypes.has(type)) {
      await docRef.set(
        {
          active: false,
          source: "revenuecat",
          email: email,
          updatedAt: now,
          lastEventTimestampMs: eventTsMs,
        },
        { merge: true },
      );
      console.log(`[RC Webhook] ${type} → ${uid} (${email ?? "e-posta yok"}) premium pasif edildi`);
    } else if (type === "CANCELLATION" || type === "BILLING_ISSUE") {
      const activeUntilMs = _resolveActiveUntilMs(event);
      if (!activeUntilMs) {
        console.log(
          `[RC Webhook] ${type} expiry/grace yok, event atlandı uid=${uid}`,
        );
        res.status(200).json({ ok: true, skipped: true, noExpiry: true });
        return;
      }
      const isActiveUntilExpiry = activeUntilMs > nowMs;
      await docRef.set(
        {
          active: isActiveUntilExpiry,
          source: "revenuecat",
          email: email,
          productId: _extractBaseProductId(productId) ?? productId,
          platform: event.store ?? null,
          expiresAt: Timestamp.fromMillis(activeUntilMs),
          updatedAt: now,
          lastEventTimestampMs: eventTsMs,
        },
        { merge: true },
      );
      console.log(
        `[RC Webhook] ${type} → ${uid} (${email ?? "e-posta yok"}) durum güncellendi (active=${isActiveUntilExpiry})`
      );
    } else {
      console.log(`[RC Webhook] Bilinmeyen olay tipi: ${type} — atlandı`);
    }

    res.status(200).json({ ok: true });
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// cleanupDeletedUserData — Firebase Auth'tan silinmiş kullanıcıların Firestore
// kalıntılarını temizler. Böylece hesap silme akışında auth önce silinse bile
// kullanıcı verileri kalıcı olarak tutulmaz.
// ─────────────────────────────────────────────────────────────────────────────
exports.cleanupDeletedUserData = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    region: "europe-west1",
  },
  async () => {
    const db = getFirestore();
    const auth = getAuth();
// Sadece explicit queue. `users` tablosu üzerinde tam scan yapılması
    // rate limit ve maliyet açısından güvenli değil, o nedenle queue tek yetkili kaynaktır.
    let queueProcessed = 0;

    // 1) Explicit deletion queue (client writes before auth delete)
    let lastQueueDoc = null;
    while (true) {
      let queueQuery = db
        .collection("account_deletion_queue")
        .where("status", "==", "pending")
        .orderBy(FieldPath.documentId())
        .limit(250);
      if (lastQueueDoc) {
        queueQuery = queueQuery.startAfter(lastQueueDoc.id);
      }
      const queueSnap = await queueQuery.get();
      if (queueSnap.empty) break;
      for (const q of queueSnap.docs) {
        const data = q.data() || {};
        const uid = String(data.uid || q.id);
        const email = data.email || null;
        let authUserExists = true;
        try {
          await auth.getUser(uid);
        } catch (e) {
          if (e?.code === "auth/user-not-found") {
            authUserExists = false;
          } else {
            console.error(
              `[CleanupDeletedUserData] queue auth lookup failed uid=${uid}:`,
              e,
            );
            continue;
          }
        }
        if (authUserExists) {
          // Auth kaydı hâlâ varsa purge yapma. Kuyruk pending kalır, bir sonraki
          // çalışmada kullanıcı gerçekten silinmişse işlenecek.
          continue;
        }
        await _purgeUserDataByUid(db, uid);
        await _purgePremiumInviteByEmail(db, email);
        // Veri başarıyla silindiğinde kuyruk dokümanını da sileriz ki e-posta
        // veya UID sunucuda kalıcı olarak tutulmasın (GDPR).
        await q.ref.delete();
        queueProcessed += 1;
      }
      lastQueueDoc = queueSnap.docs[queueSnap.docs.length - 1];
      if (queueSnap.size < 250) break;
    }

    if (queueProcessed > 0) {
      console.log(
        `[CleanupDeletedUserData] queueProcessed=${queueProcessed}`,
      );
    }
  },
);
