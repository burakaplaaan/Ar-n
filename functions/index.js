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
  "ad_watch",
  "feature_open",
]);
const _kWidgetKinds = new Set([
  "quote",
  "prayer",
  "combo",
  "tracking",
  "zikir",
]);
/** Reklam / özellik günlük özetinde kullanılan sabit anahtarlar. */
const _kProductFeatures = new Set([
  "explore",
  "zikir",
  "prayer_alarm",
  "widget",
  "hilal_duel",
  "prayer_circle",
  "qibla",
  "healing",
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

/** İstanbul takvim gününü ±N gün kaydırır (Türkiye sürekli UTC+3). */
function _shiftIstanbulDayKey(dayKey, deltaDays) {
  const noonMs = Date.parse(`${dayKey}T12:00:00+03:00`);
  if (!Number.isFinite(noonMs)) return dayKey;
  return _istanbulDayKey(noonMs + deltaDays * 86400000);
}

function _validatedProductFeature(rawFeature) {
  const value = String(rawFeature || "").trim();
  if (!_kProductFeatures.has(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz özellik kimliği.");
  }
  return value;
}

function _emptyDayUsage() {
  return {
    ads: {
      watches: 0,
      byFeature: Object.fromEntries(
        [..._kProductFeatures].map((f) => [f, { watches: 0 }]),
      ),
    },
    features: {
      users: 0,
      byFeature: Object.fromEntries(
        [..._kProductFeatures].map((f) => [f, { users: 0 }]),
      ),
    },
  };
}

function _accumulateDayUsage(target, data) {
  const ads = data?.ads || {};
  const features = data?.features || {};
  target.ads.watches += Number(ads.watches) || 0;
  const adsBy = ads.byFeature || {};
  for (const feature of _kProductFeatures) {
    target.ads.byFeature[feature].watches +=
      Number(adsBy[feature]?.watches) || 0;
  }
  target.features.users += Number(features.users) || 0;
  const featBy = features.byFeature || {};
  for (const feature of _kProductFeatures) {
    target.features.byFeature[feature].users +=
      Number(featBy[feature]?.users) || 0;
  }
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

/**
 * Havuzdan seçilmiş bir ayeti gerçekten gönderir: delivery kaydı oluşturur,
 * `current_moment`'ı yazar, FCM push'unu atar ve item'ın `lastSentDate`'ini
 * günceller. Hem otomatik günlük akış (`sendScheduledNotifications`) hem de
 * manuel "Bugün gönder" akışı (`scheduleForceSendToday`) bu ortak fonksiyonu
 * kullanır — davranış (başlık/gövde/kanal/current_moment) tutarlı kalır.
 *
 * Item bulunamazsa `{ ok: false }` döner (throw etmez); FCM gönderimi
 * başarısız olursa delivery "failed" olarak işaretlenip hata fırlatılır.
 */
async function _dispatchPoolItemPush(db, messaging, {
  itemId,
  sendAtHour,
  sendAtMin,
  nowMs,
  todayStr,
  source,
}) {
  const itemRef = db.collection("admin_ntf_pool").doc(itemId);
  const itemSnap = await itemRef.get();
  if (!itemSnap.exists) {
    return { ok: false, reason: "item-not-found" };
  }

  const data = itemSnap.data();
  // clockStr: item'ın kayıtlı hour:minute'i (= surah:ayet); "ayet dönüşüm"
  // konsepti korunsun diye gerçek gönderim saatiyle örtüşür.
  const clockStr = `${String(sendAtHour).padStart(2, "0")}:${String(sendAtMin).padStart(2, "0")}`;
  const hasSurahData = data.surahNumber != null && data.verseNumber != null;
  const ntfTitle = `Saat ${clockStr}`;

  let ntfBody = (data.notificationBody || "").toString().trim();
  if (!ntfBody) {
    const teaserTexts = await loadTeaserTexts(db);
    ntfBody = teaserTexts[Math.floor(Math.random() * teaserTexts.length)];
  }

  const expiresAtMs = nowMs + 5 * 60 * 1000;
  const deliveryRef = await _createNotificationDelivery(db, {
    source,
    poolItemId: itemId,
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
    console.error(`[${source}] current_moment yazılamadı:`, err);
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

  await itemRef.update({
    lastSentDate: todayStr,
    lastSentAt: FieldValue.serverTimestamp(),
  });

  console.log(
    `[${source}] Gönderildi ${clockStr}` +
    `${hasSurahData ? ` (Sure ${data.surahNumber}:${data.verseNumber})` : ""}` +
    ` — "${String(data.text || "").slice(0, 60)}"`
  );

  return { ok: true, clockStr, data, deliveryRef, fcmMessageId };
}

/**
 * "Bugün gönder" manuel override planını (`admin_ntf_config/today_plan_manual`)
 * kontrol eder ve saati geldiyse gönderir.
 *
 * KASITLI TASARIM: Bu akış günün normal otomatik planından (`today_plan`) ve
 * global 7 günlük döngü sayacından (`admin_ntf_config/schedule.lastAutoSentDate`)
 * TAMAMEN bağımsızdır. Ne o sayacı günceller ne de günün normal planını
 * değiştirir — ikisi kendi takviminde ayrı ayrı devam eder. Böylece admin
 * "bugün ekstra bir tane at" dediğinde otomatik döngü bozulmaz.
 */
async function _processManualForceSendToday(db, messaging, {
  nowMs,
  currentMinuteOfDay,
  todayStr,
}) {
  const manualPlanRef = db.collection("admin_ntf_config").doc("today_plan_manual");
  const manualPlanSnap = await manualPlanRef.get();
  if (!manualPlanSnap.exists) return;
  const manualPlan = manualPlanSnap.data();
  if (!manualPlan || manualPlan.date !== todayStr || manualPlan.sent === true) {
    return;
  }

  const manualMinuteOfDay =
    typeof manualPlan.sendAtMinuteOfDay === "number"
      ? manualPlan.sendAtMinuteOfDay
      : (Number(manualPlan.sendAtHour) * 60 + Number(manualPlan.sendAtMin));
  const gracePeriod = 3;

  if (currentMinuteOfDay < manualMinuteOfDay) {
    console.log(
      `[Manuel] Bugün gönder bekleniyor. Plan: ${manualMinuteOfDay} dk, şu an: ${currentMinuteOfDay} dk.`
    );
    return;
  }

  if (currentMinuteOfDay > manualMinuteOfDay + gracePeriod) {
    await manualPlanRef.set(
      { sent: true, missedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    console.log(
      "[Manuel] Bugün gönder penceresi geçti (muhtemelen fonksiyon bir süre çalışmadı). Plan kapatıldı."
    );
    return;
  }

  // Aynı dakikada paralel scheduler instance'larında çift gönderimi engelle
  // (otomatik akıştaki claim mekanizmasıyla aynı desen, ayrı bir claim dokümanı).
  const claimRef = db.collection("admin_ntf_config").doc("today_plan_manual_claim");
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
      claimPlanItemId === String(manualPlan.itemId || "");
    if (alreadyClaimed) return false;
    tx.set(
      claimRef,
      {
        planDate: todayStr,
        planItemId: String(manualPlan.itemId || ""),
        claimedAtMs: nowMs,
        claimedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return true;
  });
  if (!claimOk) {
    console.log("[Manuel] Manuel plan claim başka instance tarafından alındı, atlandı.");
    return;
  }

  const result = await _dispatchPoolItemPush(db, messaging, {
    itemId: manualPlan.itemId,
    sendAtHour: manualPlan.sendAtHour,
    sendAtMin: manualPlan.sendAtMin,
    nowMs,
    todayStr,
    source: "manual_today",
  });

  if (!result.ok) {
    console.error("[Manuel] Manuel planlanan item bulunamadı:", manualPlan.itemId);
    await manualPlanRef.set({ sent: true }, { merge: true });
    return;
  }

  // NOT: `admin_ntf_config/schedule.lastAutoSentDate` KASITLI olarak
  // güncellenmiyor — bkz. fonksiyon başındaki tasarım notu.
  await manualPlanRef.set({ sent: true, sentAtMs: nowMs }, { merge: true });
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
    let feature = null;
    const isAdWatch = event === "ad_watch";
    const isFeatureOpen = event === "feature_open";
    if (event.startsWith("content_")) {
      cardId = _validatedCardId(req.data?.cardId);
      await _assertKnownContentCard(db, cardId);
      entity = cardId;
    }
    if (event === "widget_first_use" || event === "widget_unlock") {
      kind = _validatedWidgetKind(req.data?.kind);
      entity = kind;
    }
    if (isAdWatch || isFeatureOpen) {
      feature = _validatedProductFeature(req.data?.feature);
      entity = feature;
    }
    const dedupeRef = isAdWatch ? null : db.collection(
      "admin_metric_event_dedupe",
    ).doc(_dedupeId([dayKey, event, installHash, entity]));
    const rateScope = isAdWatch ? "ad" : "product";
    const rateLimit = isAdWatch ? 120 : 300;
    const rateRef = _rateLimitRef(db, dayKey, installHash, rateScope);
    let counted = false;
    let accepted = false;

    await db.runTransaction(async (tx) => {
      const reads = [tx.get(rateRef)];
      if (dedupeRef) reads.push(tx.get(dedupeRef));
      if (event.startsWith("widget_")) reads.push(tx.get(installRef));
      const snapshots = await Promise.all(reads);
      const rateSnap = snapshots[0];
      const dedupeSnap = dedupeRef ? snapshots[1] : null;
      const installSnap = event.startsWith("widget_") ?
        snapshots[dedupeRef ? 2 : 1] : null;
      if (dedupeSnap?.exists) {
        accepted = true;
        return;
      }

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

      _applyRateLimit(tx, rateSnap, rateRef, rateLimit);
      counted = true;
      accepted = true;
      if (dedupeRef) {
        tx.create(dedupeRef, {
          event,
          dayKey,
          entity,
          expiresAt: Timestamp.fromMillis(Date.now() + 120 * 86400000),
          createdAt: FieldValue.serverTimestamp(),
        });
      }

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
      } else if (isAdWatch) {
        dailyUpdate.ads = {
          watches: FieldValue.increment(1),
          byFeature: {
            [feature]: {
              watches: FieldValue.increment(1),
            },
          },
        };
      } else if (isFeatureOpen) {
        dailyUpdate.features = {
          users: FieldValue.increment(1),
          byFeature: {
            [feature]: {
              users: FieldValue.increment(1),
            },
          },
        };
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

    const todayKey = _istanbulDayKey(now);
    const yesterdayKey = _shiftIstanbulDayKey(todayKey, -1);
    const todayUsage = _emptyDayUsage();
    const yesterdayUsage = _emptyDayUsage();
    for (const doc of dailySnap.docs) {
      const data = doc.data() || {};
      const dayKey = String(data.dayKey || "").trim() ||
        String(doc.id || "").slice(0, 10);
      if (dayKey === todayKey) _accumulateDayUsage(todayUsage, data);
      if (dayKey === yesterdayKey) _accumulateDayUsage(yesterdayUsage, data);
    }

    return {
      days,
      generatedAtMs: now,
      dayBoundary: "Europe/Istanbul",
      today: {
        dayKey: todayKey,
        ...todayUsage,
      },
      yesterday: {
        dayKey: yesterdayKey,
        ...yesterdayUsage,
      },
      daily: dailySnap.docs.map((doc) => ({
        id: doc.id,
        dayKey: doc.data().dayKey || String(doc.id || "").slice(0, 10),
        content: doc.data().content || {},
        notifications: doc.data().notifications || {},
        widgets: doc.data().widgets || {},
        ads: doc.data().ads || {},
        features: doc.data().features || {},
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
      productFeatures: [..._kProductFeatures],
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
function _normalizedWidgetUnlockHours(raw) {
  return Number.isSafeInteger(raw) && raw >= 1 && raw <= 72 ? raw : 24;
}

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
    const previousUnlockHoursRaw = before?.data()?.unlockHours;
    const previousUnlockHours =
      _normalizedWidgetUnlockHours(previousUnlockHoursRaw);
    const requestedUnlockHours = after.data()?.unlockHours;
    const unlockHours = _normalizedWidgetUnlockHours(requestedUnlockHours);

    // Not/audit alanı gibi erişim davranışını değiştirmeyen yazılar push üretmesin.
    if (before?.exists === true && after?.exists === true &&
        previousLocked === locked &&
        previousUnlockHours === unlockHours) {
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
        unlockHours: String(unlockHours),
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
      `[WidgetGlobalLock] locked=${locked} unlockHours=${unlockHours} revision=${revision} messageId=${messageId}`,
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
      // ── 0. Manuel "Bugün gönder" override'ı ────────────────────────────────
      // Bu, aşağıdaki global 7 günlük döngüden tamamen bağımsız çalışır; bir
      // hata olsa da normal otomatik akışı etkilememesi için ayrı try/catch.
      try {
        await _processManualForceSendToday(db, messaging, {
          nowMs,
          currentMinuteOfDay,
          todayStr,
        });
      } catch (err) {
        console.error("[Manuel] Bugün gönder işlenirken hata:", err);
      }

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

      const result = await _dispatchPoolItemPush(db, messaging, {
        itemId: plan.itemId,
        sendAtHour: plan.sendAtHour,
        sendAtMin: plan.sendAtMin,
        nowMs,
        todayStr,
        source: "auto",
      });

      if (!result.ok) {
        console.error("[Havuz] Planlanan item bulunamadı:", plan.itemId);
        await planRef.set({ sent: true }, { merge: true });
        return;
      }

      // Planı kapat
      await planRef.set(
        { sent: true, sentAtMs: nowMs },
        { merge: true }
      );

      // Global timer'ı güncelle
      await db
        .collection("admin_ntf_config")
        .doc("schedule")
        .set({ lastAutoSentDate: todayStr }, { merge: true });
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
// scheduleForceSendToday — admin panelinden tetiklenen "Bugün gönder" isteği.
//
// `sendMomentVerseNow`'dan farkı: anında göndermez. Havuzdaki etkin ayetler
// arasından bugün için saati henüz geçmemiş EN YAKIN olanı seçer ve
// `admin_ntf_config/today_plan_manual` dokümanına yazar; o saat gelince
// `sendScheduledNotifications` (bkz. `_processManualForceSendToday`) bunu
// otomatik olarak gönderir — cihazda beklerken kapatmaya gerek yoktur.
//
// Bu akış global 7 günlük döngüden (`admin_ntf_config/schedule`) ve günün
// normal otomatik planından (`today_plan`) TAMAMEN bağımsızdır: ne o
// döngünün sayacını sıfırlar ne de günün normal planını değiştirir; ikisi
// kendi takviminde ayrı devam eder. minRepeatDays cooldown'u da kasıtlı
// olarak bypass eder (bu bilinçli bir manuel gönderim isteğidir).
//
// Yetki: yalnızca admin.
// ─────────────────────────────────────────────────────────────────────────────
exports.scheduleForceSendToday = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
  },
  async (req) => {
    await assertCallerIsAdmin(req);

    const db = getFirestore();
    const nowMs = Date.now();
    const istNow = new Date(
      new Date(nowMs).toLocaleString("en-US", { timeZone: "Europe/Istanbul" })
    );
    const todayStr = `${istNow.getFullYear()}-${String(istNow.getMonth() + 1).padStart(2, "0")}-${String(istNow.getDate()).padStart(2, "0")}`;
    const currentMinuteOfDay = istNow.getHours() * 60 + istNow.getMinutes();

    const manualPlanRef = db.collection("admin_ntf_config").doc("today_plan_manual");
    const existingSnap = await manualPlanRef.get();
    const existing = existingSnap.exists ? existingSnap.data() : null;
    if (existing && existing.date === todayStr && existing.sent !== true) {
      throw new HttpsError(
        "already-exists",
        "Bugün için zaten beklemede bir manuel gönderim var."
      );
    }

    const poolSnap = await db
      .collection("admin_ntf_pool")
      .where("enabled", "==", true)
      .get();
    if (poolSnap.empty) {
      throw new HttpsError("failed-precondition", "Havuzda etkin ayet yok.");
    }

    const upcoming = poolSnap.docs
      .map((doc) => {
        const d = doc.data();
        const h = Number(d.hour);
        const m = Number(d.minute);
        return { doc, data: d, h, m, minuteOfDay: h * 60 + m };
      })
      .filter(
        (it) =>
          Number.isFinite(it.h) &&
          Number.isFinite(it.m) &&
          it.minuteOfDay > currentMinuteOfDay,
      )
      .sort((a, b) => a.minuteOfDay - b.minuteOfDay);

    if (upcoming.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Bugün için saati henüz geçmemiş uygun ayet kalmadı.",
      );
    }

    const chosen = upcoming[0];
    const email = (req.auth.token && req.auth.token.email) || "";

    await manualPlanRef.set({
      date: todayStr,
      itemId: chosen.doc.id,
      sendAtHour: chosen.h,
      sendAtMin: chosen.m,
      sendAtMinuteOfDay: chosen.minuteOfDay,
      sent: false,
      requestedAt: FieldValue.serverTimestamp(),
      requestedBy: email,
    });

    console.log(
      `[Manuel] Bugün gönder planlandı: itemId=${chosen.doc.id}, saat=` +
      `${String(chosen.h).padStart(2, "0")}:${String(chosen.m).padStart(2, "0")}`
    );

    return {
      ok: true,
      itemId: chosen.doc.id,
      sendAtHour: chosen.h,
      sendAtMin: chosen.m,
      surahName: chosen.data.surahName || "",
      text: chosen.data.text || "",
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

// ─────────────────────────────────────────────────────────────────────────────
// Dua Halkası — App Check korumalı, kurulum-kimliğine göre anonim topluluk.
//
// İstemci koleksiyonlara doğrudan yazamaz. Metin/PII kontrolü, tekil "dua
// ettim", sayaç ve 24 saatlik ömür yalnız Cloud Functions üzerinden yönetilir.
// ─────────────────────────────────────────────────────────────────────────────
const _kPrayerRequestTtlMs = 24 * 60 * 60 * 1000;
const _kPrayerDeviceTtlMs = 45 * 24 * 60 * 60 * 1000;
const _kPrayerRewardProofTtlMs = 15 * 60 * 1000;
const _kPrayerPolicyVersion = 1;
// AdMob SSV callback `ad_unit` alanında tam `ca-app-pub-.../...` değeri değil,
// reklam biriminin yalnızca sayısal son bölümü gönderilir.
const _kRewardedAdUnitIds = new Set([
  "4189851009",
  "3207941824",
]);
const _kPrayerCategories = new Set([
  "health",
  "family",
  "peace",
  "education",
  "work",
  "general",
]);

function _validatedPrayerLocale(raw) {
  const value = String(raw || "").trim().toLowerCase();
  return ["tr", "en", "ar"].includes(value) ? value : "tr";
}

function _validatedPrayerCategory(raw) {
  const value = String(raw || "").trim().toLowerCase();
  if (!_kPrayerCategories.has(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz dua kategorisi.");
  }
  return value;
}

function _validatedPrayerRequestId(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{16,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz istek kimliği.");
  }
  return value;
}

function _validatedPrayerDocumentId(raw) {
  const value = String(raw || "").trim();
  if (!/^[a-f0-9]{32}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz dua kimliği.");
  }
  return value;
}

function _validatedPrayerProofId(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9]{20,64}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz ödül kanıtı.");
  }
  return value;
}

function _assertPrayerPolicyAccepted(rawVersion) {
  if (Number(rawVersion) !== _kPrayerPolicyVersion) {
    throw new HttpsError(
      "failed-precondition",
      "Topluluk kurallarını kabul etmeniz gerekiyor.",
    );
  }
  return _kPrayerPolicyVersion;
}

function _assertPrayerAuth(req) {
  if (!req.auth?.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Dua Halkası için güvenli oturum oluşturulamadı.",
    );
  }
  return String(req.auth.uid);
}

function _prayerAuthHash(uid) {
  return crypto.createHash("sha256").update(`auth:${uid}`).digest("hex");
}

function _prayerSessionMatchesInstall(uid, claimedInstall, installHash) {
  if (!String(uid).startsWith("prayer_")) return true;
  return uid === `prayer_${installHash.substring(0, 48)}` &&
    claimedInstall === installHash;
}

function _validatedPrayerBindingSecretHash(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{32,128}$/.test(value)) {
    throw new HttpsError(
      "invalid-argument",
      "Geçersiz kurulum güvenlik anahtarı.",
    );
  }
  return crypto.createHash("sha256")
    .update(`prayer-binding:${value}`)
    .digest("hex");
}

function _prayerInstallationRef(db, installHash) {
  // v1 kayıtlarında binding secret yoktu. Güvensiz "ilk gelen secret'ı yazar"
  // migrasyonu yerine temiz bir v2 namespace kullanılır; feature henüz genel
  // yayına çıkmadığı için eski test binding'leri bilinçli olarak geçersizdir.
  return db.collection("prayer_installations").doc(`v2_${installHash}`);
}

async function _assertPrayerInstallationBinding(db, req, installHash) {
  const uid = _assertPrayerAuth(req);
  const bindingSecretHash = _validatedPrayerBindingSecretHash(
    req.data?.bindingSecret,
  );
  const isPrayerSession = uid.startsWith("prayer_");
  if (isPrayerSession) {
    const claimedInstall = String(
      req.auth?.token?.prayerInstallation || "",
    );
    if (!_prayerSessionMatchesInstall(uid, claimedInstall, installHash)) {
      throw new HttpsError(
        "permission-denied",
        "Dua Halkası oturumu bu kuruluma ait değil.",
      );
    }
  }
  const authHash = _prayerAuthHash(uid);
  const ref = _prayerInstallationRef(db, installHash);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const expiresAt = Timestamp.fromMillis(now + 180 * 86400000);
    if (!snap.exists) {
      tx.create(ref, {
        authHash,
        bindingSecretHash,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
      return;
    }
    const data = snap.data() || {};
    const storedSecretHash = String(data.bindingSecretHash || "");
    if (storedSecretHash !== bindingSecretHash) {
      throw new HttpsError(
        "permission-denied",
        "Bu kurulumun güvenlik anahtarı doğrulanamadı.",
      );
    }
    if (data.authHash !== authHash) {
      // Aynı fiziksel kurulum daha sonra Google/Apple hesabına bağlanabilir
      // veya hesaptan çıkıp deterministik prayer_* oturumuna dönebilir.
      // installHash yüksek entropili yerel sırdır; App Check + doğrulanmış auth
      // ile gelen bu geçişe izin verilir. prayer_* token'ları yukarıda ayrıca
      // uid + custom-claim ile installHash'e kriptografik olarak bağlanır.
      const previous = Array.isArray(data.previousAuthHashes)
        ? data.previousAuthHashes.filter((value) =>
          typeof value === "string" && value.length === 64)
        : [];
      if (typeof data.authHash === "string" && data.authHash.length === 64) {
        previous.push(data.authHash);
      }
      tx.update(ref, {
        authHash,
        bindingSecretHash,
        previousAuthHashes: [...new Set(previous)].slice(-4),
        authRotatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
      return;
    }
    const storedExpiryMs = data.expiresAt?.toMillis?.() || 0;
    if (storedExpiryMs < now + 30 * 86400000) {
      tx.update(ref, {
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    }
  });
  return authHash;
}

function _prayerIpHash(req) {
  const forwarded = String(req.rawRequest?.headers?.["x-forwarded-for"] || "");
  const ip = forwarded.split(",")[0].trim() ||
    String(req.rawRequest?.ip || "unknown");
  return crypto.createHash("sha256").update(`ip:${ip}`).digest("hex");
}

function _premiumRecordActive(data) {
  if (data?.active !== true) return false;
  const expiresAt = data?.expiresAt;
  return expiresAt == null || (expiresAt?.toMillis?.() || 0) > Date.now();
}

async function _isPrayerPremiumCaller(db, req) {
  const uid = _assertPrayerAuth(req);
  const direct = await db.collection("premium_entitlements").doc(uid).get();
  if (_premiumRecordActive(direct.data())) return true;
  const email = String(req.auth?.token?.email || "").trim().toLowerCase();
  if (!email) return false;
  const invite = await db.collection("premium_invites").doc(email).get();
  return _premiumRecordActive(invite.data());
}

// JS `\b` word-boundary is ASCII-only: it does not treat Turkish letters
// (ç, ö, ı, ş, ğ, ü) as word characters. That silently breaks `\bword\b`
// matching whenever `word` starts or ends with one of those letters (e.g.
// "ödeme", "piç", "apartmanı" would never match). This builds an equivalent
// boundary using Unicode letter/number/underscore classes so the forbidden
// word list is enforced correctly regardless of script.
function _turkishSafeWordListPattern(words) {
  const escaped = words.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  return new RegExp(
    `(?<![\\p{L}\\p{N}_])(?:${escaped.join("|")})(?![\\p{L}\\p{N}_])`,
    "iu",
  );
}

function _validatedPrayerText(raw) {
  const value = String(raw || "")
    .replace(/\s+/g, " ")
    .trim();
  if (value.length < 8 || value.length > 420) {
    throw new HttpsError(
      "invalid-argument",
      "Dua talebi 8–420 karakter arasında olmalıdır.",
    );
  }
  const forbiddenPatterns = [
    /https?:\/\/|www\./i,
    /\bTR\d{24}\b/i,
    /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i,
    /(?:^|\s)@[A-Za-z0-9_.-]{2,}/,
    /(?:\+?\d[\d\s().-]{7,}\d)/,
    _turkishSafeWordListPattern([
      "iban", "whatsapp", "telegram", "instagram", "telefon", "phone",
      "ödeme", "payment",
    ]),
    _turkishSafeWordListPattern([
      "adresim", "address", "sokak", "mahallesi", "caddesi", "apartmanı",
    ]),
    _turkishSafeWordListPattern([
      "orospu", "sikik", "sikeyim", "sik", "amına", "piç", "ibne", "kahpe",
      "fuck", "bitch", "nigger", "cunt", "whore", "faggot",
      "قحبة", "كس", "شرموطة", "منيوك", "كافر",
    ]),
  ];
  if (forbiddenPatterns.some((pattern) => pattern.test(value))) {
    throw new HttpsError(
      "invalid-argument",
      "İletişim, ödeme veya bağlantı bilgisi paylaşmayın.",
    );
  }
  return value;
}

function _prayerWindowKey(nowMs = Date.now()) {
  return Math.floor(nowMs / (5 * 60 * 1000));
}

async function _assertPrayerWriteRate(db, ownerHash, scope, limit) {
  const windowKey = _prayerWindowKey();
  const ref = db.collection("prayer_rate_limits")
    .doc(`${ownerHash}_${scope}_${windowKey}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = Number(snap.data()?.count) || 0;
    if (count >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        "Çok hızlı işlem yapıldı. Kısa süre sonra tekrar deneyin.",
      );
    }
    tx.set(ref, {
      count: FieldValue.increment(1),
      expiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

async function _assertPrayerCallerRates(db, req, installHash, scope, limit) {
  const authHash = await _assertPrayerInstallationBinding(
    db,
    req,
    installHash,
  );
  const ipHash = _prayerIpHash(req);
  await Promise.all([
    _assertPrayerWriteRate(db, authHash, `${scope}_auth`, limit),
    _assertPrayerWriteRate(db, installHash, `${scope}_install`, limit),
    _assertPrayerWriteRate(db, ipHash, `${scope}_ip`, limit * 3),
  ]);
  return authHash;
}

let _adMobVerifierKeysCache = { expiresAtMs: 0, keys: new Map() };
async function _adMobVerifierKey(keyId) {
  const now = Date.now();
  if (now >= _adMobVerifierKeysCache.expiresAtMs) {
    const response = await fetch(
      "https://www.gstatic.com/admob/reward/verifier-keys.json",
    );
    if (!response.ok) {
      throw new Error(`AdMob verifier keys HTTP ${response.status}`);
    }
    const body = await response.json();
    const keys = new Map();
    for (const item of Array.isArray(body?.keys) ? body.keys : []) {
      if (item?.keyId != null && item?.pem) {
        keys.set(String(item.keyId), String(item.pem));
      }
    }
    _adMobVerifierKeysCache = {
      expiresAtMs: now + 60 * 60 * 1000,
      keys,
    };
  }
  return _adMobVerifierKeysCache.keys.get(String(keyId)) || null;
}

function _verifyAdMobSsvSignature(rawQuery, pem) {
  try {
    const signatureMarker = "&signature=";
    const signatureIndex = String(rawQuery || "").lastIndexOf(signatureMarker);
    if (signatureIndex <= 0 || !pem) return false;
    const signedContent = rawQuery.substring(0, signatureIndex);
    const params = new URLSearchParams(rawQuery);
    const signature = String(params.get("signature") || "");
    if (!signature) return false;
    return crypto.verify(
      "sha256",
      Buffer.from(signedContent, "utf8"),
      pem,
      Buffer.from(signature, "base64url"),
    );
  } catch (_) {
    return false;
  }
}

function _decodePrayerRewardCustomData(raw) {
  try {
    const decoded = Buffer.from(String(raw || ""), "base64url")
      .toString("utf8");
    const data = JSON.parse(decoded);
    if (data?.version !== 1) return null;
    return { proofId: _validatedPrayerProofId(data?.proofId) };
  } catch (_) {
    return null;
  }
}

function _decodeQuizRewardCustomData(raw) {
  try {
    const decoded = Buffer.from(String(raw || ""), "base64url")
      .toString("utf8");
    const data = JSON.parse(decoded);
    if (data?.version !== 2 || data?.kind !== "quiz") return null;
    return { proofId: _validatedPrayerProofId(data?.proofId) };
  } catch (_) {
    return null;
  }
}

function _validatedPrayerCursorMs(raw) {
  const value = Number(raw);
  return Number.isSafeInteger(value) && value > 0 ? value : null;
}

function _isPrayerMilestone(count) {
  return Number.isInteger(count) && count > 0 && count % 5 === 0;
}

function _prayerNotificationJobId(documentId, count) {
  return `${documentId}_${count}`;
}

function _prayerNotificationCopy(locale, count) {
  if (locale === "ar") {
    return {
      title: "حلقة الدعاء",
      body: `${count} أشخاص شاركوا دعاءك.`,
    };
  }
  if (locale === "en") {
    return {
      title: "Prayer Circle",
      body: `${count} people joined your prayer.`,
    };
  }
  return {
    title: "Dua Halkası",
    body: `${count} kişi dua talebine eşlik etti.`,
  };
}

const _kPrayerNotificationMaxAttempts = 12;

async function _deliverPrayerNotificationJob(jobRef) {
  const db = getFirestore();
  let job = null;
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(jobRef);
    if (!snap.exists || snap.data()?.status !== "pending") return false;
    const data = snap.data() || {};
    const claimedUntilMs = data.claimedUntil?.toMillis?.() || 0;
    if (claimedUntilMs > Date.now()) return false;
    const expiresAtMs = data.expiresAt?.toMillis?.() || 0;
    const attemptsSoFar = Number(data.attempts) || 0;
    if (
      (expiresAtMs && expiresAtMs <= Date.now()) ||
      attemptsSoFar >= _kPrayerNotificationMaxAttempts
    ) {
      tx.update(jobRef, {
        status: "expired",
        claimedUntil: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return false;
    }
    job = data;
    tx.update(jobRef, {
      status: "pending",
      claimedUntil: Timestamp.fromMillis(Date.now() + 2 * 60 * 1000),
      attempts: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed || !job) return false;

  const ownerHash = String(job.ownerHash || "");
  const deviceRef = db.collection("prayer_devices").doc(ownerHash);
  try {
    const deviceSnap = await deviceRef.get();
    const device = deviceSnap.data() || {};
    const token = String(device.token || "");
    const tokenExpiryMs = device.expiresAt?.toMillis?.() || 0;
    if (!token || tokenExpiryMs <= Date.now()) {
      await jobRef.set({
        status: "pending",
        waitingReason: "device_unavailable",
        claimedUntil: Timestamp.fromMillis(Date.now() + 15 * 60 * 1000),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return false;
    }
    const count = Number(job.count) || 0;
    const locale = _validatedPrayerLocale(device.locale || job.locale);
    const copy = _prayerNotificationCopy(locale, count);
    const messageId = await getMessaging().send({
      token,
      notification: copy,
      data: {
        type: "prayer_circle",
        requestId: String(job.requestId || ""),
        count: String(count),
      },
      android: {
        notification: {
          channelId: "arin_prayer_circle",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: { payload: { aps: { sound: "default" } } },
    });
    await jobRef.set({
      status: "sent",
      messageId,
      claimedUntil: null,
      sentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  } catch (error) {
    const code = String(error?.code || "");
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-registration-token")
    ) {
      await deviceRef.delete().catch(() => {});
    }
    await jobRef.set({
      status: "pending",
      claimedUntil: Timestamp.fromMillis(
        Date.now() +
          Math.min(60, Math.max(1, Number(job.attempts) || 1)) * 60 * 1000,
      ),
      lastError: String(error?.message || error).slice(0, 300),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true }).catch(() => {});
    console.error("[PrayerCircle] notification job failed:", error);
    return false;
  }
}

// TEMP (emülatör): Play Integrity emülatörde fail. Mağaza öncesi true yap.
const ENFORCE_PRAYER_APP_CHECK = false;

exports.createPrayerSession = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    const installHash = _validatedInstallHash(req.data?.installId);
    const bindingSecretHash = _validatedPrayerBindingSecretHash(
      req.data?.bindingSecret,
    );
    const db = getFirestore();
    const ipHash = _prayerIpHash(req);
    await Promise.all([
      _assertPrayerWriteRate(db, installHash, "session_install", 5),
      _assertPrayerWriteRate(db, ipHash, "session_ip", 30),
    ]);
    const installationRef = _prayerInstallationRef(db, installHash);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(installationRef);
      const expiresAt = Timestamp.fromMillis(Date.now() + 180 * 86400000);
      if (!snap.exists) {
        tx.create(installationRef, {
          bindingSecretHash,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          expiresAt,
        });
        return;
      }
      if (snap.data()?.bindingSecretHash !== bindingSecretHash) {
        throw new HttpsError(
          "permission-denied",
          "Bu kurulumun güvenlik anahtarı doğrulanamadı.",
        );
      }
      tx.update(installationRef, {
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    });
    const uid = `prayer_${installHash.substring(0, 48)}`;
    const customToken = await getAuth().createCustomToken(uid, {
      prayerInstallation: installHash,
    });
    return { ok: true, customToken };
  },
);

exports.checkPrayerPremium = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    const installHash = _validatedInstallHash(req.data?.installId);
    const db = getFirestore();
    await _assertPrayerInstallationBinding(db, req, installHash);
    return { ok: true, premium: await _isPrayerPremiumCaller(db, req) };
  },
);

exports.beginPrayerSubmission = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    const uid = _assertPrayerAuth(req);
    const ownerHash = _validatedInstallHash(req.data?.installId);
    const requestId = _validatedPrayerRequestId(req.data?.requestId);
    const policyVersion = _assertPrayerPolicyAccepted(
      req.data?.policyVersion,
    );
    const text = _validatedPrayerText(req.data?.text);
    const category = _validatedPrayerCategory(req.data?.category);
    const locale = _validatedPrayerLocale(req.data?.locale);
    const db = getFirestore();
    const authHash = await _assertPrayerCallerRates(
      db,
      req,
      ownerHash,
      "begin",
      20,
    );
    if (await _isPrayerPremiumCaller(db, req)) {
      return { ok: true, premium: true };
    }

    const proofRef = db.collection("prayer_reward_proofs").doc();
    const nowMs = Date.now();
    const expiresAtMs = nowMs + _kPrayerRewardProofTtlMs;
    await proofRef.set({
      ownerHash,
      authHash,
      authUid: uid,
      requestId,
      text,
      category,
      locale,
      policyVersion,
      policyAcceptedAt: Timestamp.fromMillis(nowMs),
      status: "pending",
      createdAt: Timestamp.fromMillis(nowMs),
      expiresAt: Timestamp.fromMillis(expiresAtMs),
    });
    const customData = Buffer.from(JSON.stringify({
      version: 1,
      proofId: proofRef.id,
    }), "utf8").toString("base64url");
    return {
      ok: true,
      premium: false,
      proofId: proofRef.id,
      customData,
      expiresAtMs,
    };
  },
);

exports.rewardedAdSsv = onRequest(
  {
    region: "europe-west1",
    memory: "256MiB",
  },
  async (req, res) => {
    try {
      if (req.method !== "GET") {
        res.status(405).send("Method Not Allowed");
        return;
      }
      const rawQuery = String(req.originalUrl || "").split("?").slice(1)
        .join("?");
      const signature = String(req.query.signature || "");
      const keyId = String(req.query.key_id || "");
      const pem = await _adMobVerifierKey(keyId);
      if (!pem || !signature) {
        res.status(400).send("Unknown verifier key");
        return;
      }
      const verified = _verifyAdMobSsvSignature(rawQuery, pem);
      if (!verified) {
        console.warn("[PrayerCircle SSV] invalid signature");
        res.status(400).send("Invalid signature");
        return;
      }

      const adUnit = String(req.query.ad_unit || "");
      const transactionId = String(req.query.transaction_id || "");
      const timestampMs = Number(req.query.timestamp);
      const prayerReward = _decodePrayerRewardCustomData(
        req.query.custom_data,
      );
      const quizReward = _decodeQuizRewardCustomData(req.query.custom_data);
      const reward = prayerReward || quizReward;
      if (!reward) {
        // Aynı rewarded unit widget gibi başka yüzeylerde de kullanılır.
        res.status(200).send("Ignored");
        return;
      }
      if (
        !_kRewardedAdUnitIds.has(adUnit) ||
        !/^[A-Za-z0-9_-]{8,256}$/.test(transactionId) ||
        !Number.isSafeInteger(timestampMs) ||
        Math.abs(Date.now() - timestampMs) > 24 * 60 * 60 * 1000
      ) {
        res.status(400).send("Invalid reward data");
        return;
      }

      const db = getFirestore();
      const proofCollection = quizReward
        ? "quiz_reward_proofs"
        : "prayer_reward_proofs";
      const transactionCollection = quizReward
        ? "quiz_reward_transactions"
        : "prayer_reward_transactions";
      const proofRef = db.collection(proofCollection)
        .doc(reward.proofId);
      const transactionRef = db.collection(transactionCollection)
        .doc(crypto.createHash("sha256").update(transactionId).digest("hex"));
      await db.runTransaction(async (tx) => {
        const [proofSnap, transactionSnap] = await Promise.all([
          tx.get(proofRef),
          tx.get(transactionRef),
        ]);
        if (transactionSnap.exists) return;
        if (!proofSnap.exists) {
          throw new Error("Reward proof not found");
        }
        const proof = proofSnap.data() || {};
        const proofExpiryMs = proof.expiresAt?.toMillis?.() || 0;
        if (
          proof.status !== "pending" ||
          proofExpiryMs <= Date.now()
        ) {
          throw new Error("Reward proof mismatch or expired");
        }
        tx.create(transactionRef, {
          proofId: reward.proofId,
          expiresAt: Timestamp.fromMillis(Date.now() + 30 * 86400000),
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(proofRef, {
          status: "rewarded",
          transactionHash: transactionRef.id,
          rewardedAt: FieldValue.serverTimestamp(),
          // SSV gecikmeli gelebilir; claim penceresini ödül anından uzat.
          expiresAt: Timestamp.fromMillis(Date.now() + 10 * 60_000),
        });
      });
      res.status(200).send("OK");
    } catch (error) {
      console.error("[PrayerCircle SSV] failed:", error);
      res.status(500).send("Retry");
    }
  },
);

exports.registerPrayerDevice = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    _assertPrayerAuth(req);
    const ownerHash = _validatedInstallHash(req.data?.installId);
    const db = getFirestore();
    await _assertPrayerInstallationBinding(db, req, ownerHash);
    const token = String(req.data?.token || "").trim();
    if (token.length < 32 || token.length > 4096) {
      throw new HttpsError("invalid-argument", "Geçersiz bildirim kimliği.");
    }
    const platform = ["android", "ios"].includes(req.data?.platform)
      ? req.data.platform
      : "other";
    await db.collection("prayer_devices").doc(ownerHash).set({
      token,
      platform,
      locale: _validatedPrayerLocale(req.data?.locale),
      expiresAt: Timestamp.fromMillis(Date.now() + _kPrayerDeviceTtlMs),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    const pendingJobs = await db.collection("prayer_notification_jobs")
      .where("ownerHash", "==", ownerHash)
      .where("status", "==", "pending")
      .limit(20)
      .get();
    for (const job of pendingJobs.docs) {
      await job.ref.set({
        claimedUntil: Timestamp.fromMillis(0),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      await _deliverPrayerNotificationJob(job.ref);
    }
    return { ok: true };
  },
);

exports.listPrayerRequests = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    _assertPrayerAuth(req);
    const installHash = _validatedInstallHash(req.data?.installId);
    const db = getFirestore();
    await _assertPrayerInstallationBinding(db, req, installHash);
    const cursorMs = _validatedPrayerCursorMs(req.data?.cursorExpiresAtMs);
    const focusRequestId = req.data?.focusRequestId == null
      ? null
      : _validatedPrayerDocumentId(req.data.focusRequestId);
    const mineOnly = req.data?.mineOnly === true;
    const now = Timestamp.now();
    let query = mineOnly
      ? db.collection("prayer_request_owners")
        .where("ownerHash", "==", installHash)
        .where("expiresAt", ">", now)
        .orderBy("expiresAt", "desc")
        .orderBy(FieldPath.documentId(), "desc")
        .limit(40)
      : db.collection("prayer_requests")
        .where("status", "==", "active")
        .where("expiresAt", ">", now)
        .orderBy("expiresAt", "desc")
        .orderBy(FieldPath.documentId(), "desc")
        .limit(40);
    if (cursorMs) {
      const cursorRequestId = _validatedPrayerDocumentId(
        req.data?.cursorRequestId,
      );
      query = query.startAfter(
        Timestamp.fromMillis(cursorMs),
        cursorRequestId,
      );
    }
    const snap = await query.get();
    const ownRequestIds = new Set(
      mineOnly ? snap.docs.map((doc) => doc.id) : [],
    );
    let resultDocs = [...snap.docs];
    if (mineOnly && resultDocs.length > 0) {
      const requestRefs = resultDocs.map((owner) =>
        db.collection("prayer_requests").doc(owner.id));
      resultDocs = (await db.getAll(...requestRefs)).filter((doc) => {
        const data = doc.data() || {};
        return doc.exists &&
          data.status === "active" &&
          (data.expiresAt?.toMillis?.() || 0) > Date.now();
      });
    }
    if (!mineOnly && focusRequestId && !cursorMs &&
        !resultDocs.some((doc) => doc.id === focusRequestId)) {
      const focus = await db.collection("prayer_requests")
        .doc(focusRequestId)
        .get();
      const focusData = focus.data() || {};
      if (
        focus.exists &&
        focusData.status === "active" &&
        (focusData.expiresAt?.toMillis?.() || 0) > Date.now()
      ) {
        resultDocs.unshift(focus);
      }
    }
    const items = resultDocs.map((doc) => {
      const data = doc.data() || {};
      return {
        id: doc.id,
        text: String(data.text || "").slice(0, 420),
        category: _validatedPrayerCategory(data.category),
        prayerCount: Math.max(0, Number(data.prayerCount) || 0),
        createdAtMs: data.createdAt?.toMillis?.() || 0,
        expiresAtMs: data.expiresAt?.toMillis?.() || 0,
        isMine: ownRequestIds.has(doc.id),
      };
    }).sort((a, b) =>
      b.expiresAtMs - a.expiresAtMs || b.id.localeCompare(a.id));
    const last = snap.docs[snap.docs.length - 1];
    return {
      ok: true,
      items,
      nextCursorExpiresAtMs: snap.size === 40
        ? last?.data()?.expiresAt?.toMillis?.() || null
        : null,
      nextCursorRequestId: snap.size === 40 ? last?.id || null : null,
    };
  },
);

exports.reportPrayerRequest = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    _assertPrayerAuth(req);
    const installHash = _validatedInstallHash(req.data?.installId);
    const documentId = _validatedPrayerDocumentId(req.data?.requestId);
    const db = getFirestore();
    const authHash = await _assertPrayerCallerRates(
      db,
      req,
      installHash,
      "report",
      10,
    );
    const requestRef = db.collection("prayer_requests").doc(documentId);
    const ownerRef = db.collection("prayer_request_owners").doc(documentId);
    const installReportRef = requestRef.collection("reports")
      .doc(`i_${installHash}`);
    const authReportRef = requestRef.collection("reports")
      .doc(`a_${authHash}`);
    let reported = false;
    let alreadyReported = false;
    let hidden = false;
    await db.runTransaction(async (tx) => {
      const [requestSnap, ownerSnap, installReport, authReport] =
        await Promise.all([
          tx.get(requestRef),
          tx.get(ownerRef),
          tx.get(installReportRef),
          tx.get(authReportRef),
        ]);
      if (!requestSnap.exists || !ownerSnap.exists) {
        throw new HttpsError("not-found", "Dua talebi bulunamadı.");
      }
      const owner = ownerSnap.data() || {};
      if (owner.ownerHash === installHash || owner.authHash === authHash) {
        throw new HttpsError(
          "failed-precondition",
          "Kendi talebinizi bildiremezsiniz.",
        );
      }
      if (installReport.exists || authReport.exists) {
        alreadyReported = true;
        return;
      }
      const data = requestSnap.data() || {};
      if (
        data.status !== "active" ||
        (data.expiresAt?.toMillis?.() || 0) <= Date.now()
      ) {
        throw new HttpsError("failed-precondition", "Dua talebinin süresi doldu.");
      }
      reported = true;
      const reportCount = (Number(data.reportCount) || 0) + 1;
      hidden = reportCount >= 10;
      const reportData = {
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: data.expiresAt,
      };
      tx.create(installReportRef, reportData);
      tx.create(authReportRef, reportData);
      tx.update(requestRef, {
        reportCount,
        status: hidden ? "review" : "active",
      });
    });
    return { ok: true, reported: reported || alreadyReported, hidden };
  },
);

exports.createPrayerRequest = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    const uid = _assertPrayerAuth(req);
    const ownerHash = _validatedInstallHash(req.data?.installId);
    const requestId = _validatedPrayerRequestId(req.data?.requestId);
    const policyVersion = _assertPrayerPolicyAccepted(
      req.data?.policyVersion,
    );
    const db = getFirestore();
    const authHash = await _assertPrayerCallerRates(
      db,
      req,
      ownerHash,
      "create",
      20,
    );
    const premium = await _isPrayerPremiumCaller(db, req);
    const proofId = premium
      ? null
      : _validatedPrayerProofId(req.data?.proofId);

    const documentId = _dedupeId([ownerHash, requestId]).substring(0, 32);
    const requestRef = db.collection("prayer_requests").doc(documentId);
    const ownerRef = db.collection("prayer_request_owners").doc(documentId);
    const proofRef = proofId
      ? db.collection("prayer_reward_proofs").doc(proofId)
      : null;
    const nowMs = Date.now();
    const expiresAtMs = nowMs + _kPrayerRequestTtlMs;
    let created = false;

    await db.runTransaction(async (tx) => {
      const [existing, proofSnap] = await Promise.all([
        tx.get(requestRef),
        proofRef ? tx.get(proofRef) : Promise.resolve(null),
      ]);
      if (existing.exists) return;
      let text;
      let category;
      let locale;
      if (premium) {
        text = _validatedPrayerText(req.data?.text);
        category = _validatedPrayerCategory(req.data?.category);
        locale = _validatedPrayerLocale(req.data?.locale);
      } else {
        if (!proofSnap?.exists) {
          throw new HttpsError(
            "failed-precondition",
            "Reklam ödülü henüz doğrulanmadı.",
          );
        }
        const proof = proofSnap.data() || {};
        const proofExpiryMs = proof.expiresAt?.toMillis?.() || 0;
        if (
          proof.status !== "rewarded" ||
          proof.ownerHash !== ownerHash ||
          proof.authHash !== authHash ||
          proof.authUid !== uid ||
          proof.requestId !== requestId ||
          proof.policyVersion !== policyVersion ||
          proofExpiryMs <= nowMs
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Reklam ödülü henüz doğrulanmadı.",
          );
        }
        text = _validatedPrayerText(proof.text);
        category = _validatedPrayerCategory(proof.category);
        locale = _validatedPrayerLocale(proof.locale);
      }
      created = true;
      tx.create(requestRef, {
        id: documentId,
        text,
        category,
        locale,
        prayerCount: 0,
        status: "active",
        createdAt: Timestamp.fromMillis(nowMs),
        expiresAt: Timestamp.fromMillis(expiresAtMs),
      });
      tx.create(ownerRef, {
        ownerHash,
        authHash,
        policyVersion,
        policyAcceptedAt: Timestamp.fromMillis(nowMs),
        createdAt: Timestamp.fromMillis(nowMs),
        expiresAt: Timestamp.fromMillis(expiresAtMs),
      });
      if (proofRef) {
        tx.update(proofRef, {
          status: "consumed",
          consumedAt: FieldValue.serverTimestamp(),
          requestDocumentId: documentId,
        });
      }
    });

    return {
      ok: true,
      created,
      id: documentId,
      expiresAtMs,
    };
  },
);

exports.prayForRequest = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    _assertPrayerAuth(req);
    const installHash = _validatedInstallHash(req.data?.installId);
    const documentId = _validatedPrayerDocumentId(req.data?.requestId);
    const db = getFirestore();
    const authHash = await _assertPrayerCallerRates(
      db,
      req,
      installHash,
      "pray",
      120,
    );

    const requestRef = db.collection("prayer_requests").doc(documentId);
    const ownerRef = db.collection("prayer_request_owners").doc(documentId);
    const installReactionRef = requestRef.collection("reactions")
      .doc(`i_${installHash}`);
    const authReactionRef = requestRef.collection("reactions")
      .doc(`a_${authHash}`);
    let counted = false;
    let count = 0;
    let ownerHash = "";
    let locale = "tr";
    let notificationJobRef = null;

    await db.runTransaction(async (tx) => {
      const [
        requestSnap,
        ownerSnap,
        installReactionSnap,
        authReactionSnap,
      ] = await Promise.all([
        tx.get(requestRef),
        tx.get(ownerRef),
        tx.get(installReactionRef),
        tx.get(authReactionRef),
      ]);
      if (!requestSnap.exists || !ownerSnap.exists) {
        throw new HttpsError("not-found", "Dua talebi bulunamadı.");
      }
      const data = requestSnap.data() || {};
      const expiryMs = data.expiresAt?.toMillis?.() || 0;
      if (data.status !== "active" || expiryMs <= Date.now()) {
        throw new HttpsError("failed-precondition", "Dua talebinin süresi doldu.");
      }
      ownerHash = String(ownerSnap.data()?.ownerHash || "");
      const ownerAuthHash = String(ownerSnap.data()?.authHash || "");
      locale = _validatedPrayerLocale(data.locale);
      if (ownerHash === installHash || ownerAuthHash === authHash) {
        throw new HttpsError(
          "failed-precondition",
          "Kendi dua talebinize eşlik edemezsiniz.",
        );
      }
      count = Number(data.prayerCount) || 0;
      if (installReactionSnap.exists || authReactionSnap.exists) return;
      counted = true;
      count += 1;
      const reactionData = {
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: data.expiresAt,
      };
      tx.create(installReactionRef, reactionData);
      tx.create(authReactionRef, reactionData);
      tx.update(requestRef, { prayerCount: FieldValue.increment(1) });
      if (_isPrayerMilestone(count)) {
        notificationJobRef = db.collection("prayer_notification_jobs")
          .doc(_prayerNotificationJobId(documentId, count));
        tx.create(notificationJobRef, {
          requestId: documentId,
          ownerHash,
          locale,
          count,
          status: "pending",
          attempts: 0,
          claimedUntil: Timestamp.fromMillis(0),
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: Timestamp.fromMillis(Date.now() + 7 * 86400000),
        });
      }
    });

    if (notificationJobRef) {
      await _deliverPrayerNotificationJob(notificationJobRef);
    }

    return { ok: true, counted, prayerCount: count };
  },
);

exports.deletePrayerRequest = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    _assertPrayerAuth(req);
    const ownerHash = _validatedInstallHash(req.data?.installId);
    const documentId = _validatedPrayerDocumentId(req.data?.requestId);
    const db = getFirestore();
    await _assertPrayerInstallationBinding(db, req, ownerHash);
    const requestRef = db.collection("prayer_requests").doc(documentId);
    const ownerRef = db.collection("prayer_request_owners").doc(documentId);
    const ownerSnap = await ownerRef.get();
    if (!ownerSnap.exists || ownerSnap.data()?.ownerHash !== ownerHash) {
      throw new HttpsError("permission-denied", "Bu talebi silemezsiniz.");
    }
    await _deleteCollectionInBatches(requestRef.collection("reactions"));
    await _deleteCollectionInBatches(requestRef.collection("reports"));
    await Promise.all([requestRef.delete(), ownerRef.delete()]);
    return { ok: true };
  },
);

// Yönetici (Dua Halkası) moderasyon silmesi — sahiplik farketmeksizin,
// uygunsuz/kural dışı içeriği kaldırmak için. `assertCallerIsAdmin` gerçek
// oturum açmış (Google/Apple) admin e-postası veya `admin_users` rolünü
// kontrol eder; kurulum bazlı "prayer session" bunun yerine geçemez.
exports.adminDeletePrayerRequest = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    enforceAppCheck: ENFORCE_PRAYER_APP_CHECK,
  },
  async (req) => {
    await assertCallerIsAdmin(req);
    const documentId = _validatedPrayerDocumentId(req.data?.requestId);
    const db = getFirestore();
    const requestRef = db.collection("prayer_requests").doc(documentId);
    const ownerRef = db.collection("prayer_request_owners").doc(documentId);
    const requestSnap = await requestRef.get();
    if (!requestSnap.exists) {
      throw new HttpsError("not-found", "Dua talebi bulunamadı.");
    }
    await _deleteCollectionInBatches(requestRef.collection("reactions"));
    await _deleteCollectionInBatches(requestRef.collection("reports"));
    await Promise.all([requestRef.delete(), ownerRef.delete()]);
    console.log(
      `[PrayerCircle] Admin ${req.auth.uid} deleted request ${documentId}`,
    );
    return { ok: true };
  },
);

exports.deliverPrayerNotifications = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    region: "europe-west1",
  },
  async () => {
    const snap = await getFirestore().collection("prayer_notification_jobs")
      .where("status", "==", "pending")
      .where("claimedUntil", "<=", Timestamp.now())
      .orderBy("claimedUntil")
      .limit(100)
      .get();
    for (const job of snap.docs) {
      await _deliverPrayerNotificationJob(job.ref);
    }
  },
);

exports.cleanupExpiredPrayerRequests = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    region: "europe-west1",
  },
  async () => {
    const db = getFirestore();
    let deleted = 0;
    while (true) {
      const snap = await db.collection("prayer_requests")
        .where("expiresAt", "<=", Timestamp.now())
        .limit(200)
        .get();
      if (snap.empty) break;
      for (const doc of snap.docs) {
        await _deleteCollectionInBatches(doc.ref.collection("reactions"));
        await _deleteCollectionInBatches(doc.ref.collection("reports"));
        await Promise.all([
          db.collection("prayer_request_owners").doc(doc.id).delete()
            .catch(() => {}),
          doc.ref.delete(),
        ]);
        deleted += 1;
      }
      if (snap.size < 200) break;
    }
    if (deleted > 0) {
      console.log(`[PrayerCircle] expired deleted=${deleted}`);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Test-only export surface — exposes pure Dua Halkası (Prayer Circle) helper
// functions for unit testing without touching Firestore/FCM. This is a plain
// object (not a function), so the Firebase CLI's trigger-discovery step
// (which only recognizes `onCall`/`onSchedule`/`onRequest`/`onDocumentWritten`
// wrapped exports) ignores it entirely — it is never deployed as a Cloud
// Function and has zero effect on production behavior or the deployed export
// surface. Do not add DB/network-touching functions here.
// ─────────────────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV === "test") {
  exports._testables = {
    validatedPrayerText: _validatedPrayerText,
    validatedPrayerCategory: _validatedPrayerCategory,
    validatedPrayerLocale: _validatedPrayerLocale,
    validatedPrayerRequestId: _validatedPrayerRequestId,
    validatedPrayerDocumentId: _validatedPrayerDocumentId,
    validatedPrayerProofId: _validatedPrayerProofId,
    decodePrayerRewardCustomData: _decodePrayerRewardCustomData,
    decodeQuizRewardCustomData: _decodeQuizRewardCustomData,
    dedupeId: _dedupeId,
    prayerNotificationCopy: _prayerNotificationCopy,
    isPrayerMilestone: _isPrayerMilestone,
    prayerNotificationJobId: _prayerNotificationJobId,
    validatedPrayerCursorMs: _validatedPrayerCursorMs,
    assertPrayerAuth: _assertPrayerAuth,
    prayerSessionMatchesInstall: _prayerSessionMatchesInstall,
    validatedPrayerBindingSecretHash: _validatedPrayerBindingSecretHash,
    premiumRecordActive: _premiumRecordActive,
    verifyAdMobSsvSignature: _verifyAdMobSsvSignature,
    assertPrayerPolicyAccepted: _assertPrayerPolicyAccepted,
    normalizedWidgetUnlockHours: _normalizedWidgetUnlockHours,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Bilgi Düellosu — admin can yönetimi
//   • Herkese +1 can + broadcast_all FCM (tıklanınca düello açılır)
//   • Belirli ownerHash'e N can
// ─────────────────────────────────────────────────────────────────────────────
const _kQuizOwnerHashRe = /^[a-f0-9]{64}$/i;

exports.adminGrantQuizHeartsAll = onCall(
  {
    region: "europe-west1",
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  async (req) => {
    await assertCallerIsAdmin(req);
    const db = getFirestore();
    const messaging = getMessaging();

    let updated = 0;
    let lastDoc = null;
    // quiz_players üzerinde sayfalı increment — tek batch limiti aşılmasın.
    while (true) {
      let q = db
        .collection("quiz_players")
        .orderBy(FieldPath.documentId())
        .limit(400);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.set(
          doc.ref,
          {
            adHearts: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        updated += 1;
      }
      await batch.commit();
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < 400) break;
    }

    const title = "Bilgi Düellosu · +1 can";
    const body =
      "Herkese 1 can verildi! Şimdi bilginle herkesi yen — düelloya gir.";
    let fcmMessageId = null;
    let fcmOk = true;
    let fcmError = null;
    try {
      fcmMessageId = await messaging.send({
        topic: "broadcast_all",
        notification: { title, body },
        data: {
          type: "hilal_duel",
          reason: "admin_heart_grant_all",
        },
        android: {
          notification: {
            channelId: "arin_hilal_duel",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: { payload: { aps: { sound: "default" } } },
      });
    } catch (err) {
      // Canlar yazıldıktan sonra FCM düşse bile audit ve partial-success dön;
      // aksi halde admin yeniden basınca ikinci +1 riski oluşur.
      fcmOk = false;
      fcmError = String(err?.message || err).slice(0, 300);
      console.error("[adminGrantQuizHeartsAll] FCM failed:", err);
    }

    const email = (req.auth?.token?.email || "").toString().toLowerCase();
    await db.collection("admin_audit").add({
      action: "quiz_hearts_grant_all",
      targetType: "quiz_players",
      targetId: "all",
      uid: req.auth?.uid || null,
      email: email || null,
      afterCount: updated,
      details: {
        amount: 1,
        fcmOk,
        fcmMessageId,
        fcmError,
        title,
        body,
      },
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      updated,
      fcmOk,
      fcmMessageId,
      fcmError,
      title,
      body,
    };
  },
);

exports.adminGrantQuizHeartsOne = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
  },
  async (req) => {
    await assertCallerIsAdmin(req);
    const ownerHash = String(req.data?.ownerHash || "").trim().toLowerCase();
    const amountRaw = Number(req.data?.amount);
    const amount = Number.isFinite(amountRaw)
      ? Math.floor(amountRaw)
      : NaN;
    if (!_kQuizOwnerHashRe.test(ownerHash)) {
      throw new HttpsError(
        "invalid-argument",
        "ownerHash 64 karakter hex olmalı (installId SHA-256).",
      );
    }
    if (!Number.isFinite(amount) || amount < 1 || amount > 20) {
      throw new HttpsError(
        "invalid-argument",
        "amount 1 ile 20 arasında olmalı.",
      );
    }

    const db = getFirestore();
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const beforeSnap = await playerRef.get();
    const beforeHearts = beforeSnap.exists
      ? Math.max(0, Math.floor(Number(beforeSnap.data()?.adHearts) || 0))
      : 0;

    await playerRef.set(
      {
        adHearts: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const email = (req.auth?.token?.email || "").toString().toLowerCase();
    await db.collection("admin_audit").add({
      action: "quiz_hearts_grant_one",
      targetType: "quiz_player",
      targetId: ownerHash,
      uid: req.auth?.uid || null,
      email: email || null,
      beforeCount: beforeHearts,
      afterCount: beforeHearts + amount,
      details: { amount },
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      ownerHash,
      amount,
      beforeHearts,
      afterHearts: beforeHearts + amount,
      existed: beforeSnap.exists,
    };
  },
);

// Hilal Düellosu ayrı bir modülde tutulur; büyük oyun akışı mevcut bildirim ve
// Dua Halkası fonksiyonlarının bakım yüzeyini büyütmez.
const quizModule = require("./quiz");
Object.assign(exports, quizModule.functions);
if (process.env.NODE_ENV === "test") {
  Object.assign(exports._testables, quizModule.testables);
}
