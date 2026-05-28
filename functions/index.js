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
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

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

      // ── 6. Gönder ──────────────────────────────────────────────────────────
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
          });
      } catch (err) {
        console.error("[Havuz] current_moment yazılamadı:", err);
      }

      await messaging.send({
        topic: "broadcast_all",
        notification: { title: ntfTitle, body: ntfBody },
        data: {
          type: "moment_verse",
          sentAtMs: String(nowMs),
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
        });
    } catch (err) {
      console.error("[ManualSend] current_moment yazılamadı:", err);
      throw new HttpsError("internal", "current_moment yazılamadı.");
    }

    try {
      await messaging.send({
        topic: "broadcast_all",
        notification: { title: ntfTitle, body: ntfBody },
        data: {
          type: "moment_verse",
          sentAtMs: String(nowMs),
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
        });
    } catch (err) {
      console.error("[Test] current_moment yazılamadı:", err);
      throw new HttpsError("internal", "current_moment yazılamadı.");
    }

    try {
      await messaging.send({
        topic: "broadcast_all",
        notification: { title: ntfTitle, body: ntfBody },
        data: {
          type: "moment_verse",
          sentAtMs: String(nowMs),
          isTest: "true",
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
    const authHeader = req.headers.authorization || "";
    if (authHeader !== secret) {
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
