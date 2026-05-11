// Arın — Cloud Functions
// Her dakika çalışır (Avrupa/İstanbul):
//   1. Bekleyen manuel bildirimleri (admin_scheduled_notifications) gönderir.
//      Manuel bildirim gönderilince havuz timer'ı sıfırlanır.
//   2. admin_ntf_pool'dan o dakikaya uyan bir öğeyi rastgele seçerek gönderir.
//      Gönderim sıklığı ve tekrar süresi admin_ntf_config/schedule'dan okunur.
//      Seçilen ayet bilgisi admin_ntf_config/current_moment'a yazılır;
//      kullanıcı bildirimi tıklayarak 5 dakika içinde ayeti görebilir.

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

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

    // İstanbul saatini hesapla
    const nowDate = new Date(nowMs);
    const istNow = new Date(
      nowDate.toLocaleString("en-US", { timeZone: "Europe/Istanbul" })
    );
    const istHour = istNow.getHours();
    const istMin = istNow.getMinutes();
    const year = istNow.getFullYear();
    const month = String(istNow.getMonth() + 1).padStart(2, "0");
    const day = String(istNow.getDate()).padStart(2, "0");
    const todayStr = `${year}-${month}-${day}`;

    // ── Havuz bildirimleri (sıklık + tekrar kontrolü) ────────────────────────
    // Not: Eski "admin_scheduled_notifications" manuel yayın bloğu, yeni admin
    // panelinde özellik kaldırıldığı için silindi (gereksiz Firestore index
    // hatası üretiyordu). Manuel gönderim artık `sendMomentVerseNow` callable
    // üzerinden yapılır.
    try {
      // Config'i oku
      const configSnap = await db
        .collection("admin_ntf_config")
        .doc("schedule")
        .get();
      const config = configSnap.exists ? configSnap.data() : {};
      const autoEnabled = config.autoEnabled !== false; // default: true
      const sendEveryNDays = config.sendEveryNDays ?? 3;
      const minRepeatDays = config.minRepeatDays ?? 60;
      const lastAutoSentDate = config.lastAutoSentDate ?? null;

      if (!autoEnabled) {
        console.log("[Havuz] Otomatik gönderim kapalı (autoEnabled=false).");
        return;
      }

      // Yeterince gün geçti mi?
      const daysSinceLast = lastAutoSentDate
        ? daysBetween(lastAutoSentDate, todayStr)
        : 9999;

      if (daysSinceLast < sendEveryNDays) {
        console.log(
          `[Havuz] Henüz erken: ${daysSinceLast}/${sendEveryNDays} gün. Atlandı.`
        );
        return;
      }

      // O dakikaya uyan, etkin öğeleri al
      const poolSnap = await db
        .collection("admin_ntf_pool")
        .where("hour", "==", istHour)
        .where("minute", "==", istMin)
        .where("enabled", "==", true)
        .get();

      if (poolSnap.empty) {
        console.log(
          `[Havuz] ${istHour}:${String(istMin).padStart(2, "0")} için eşleşen öğe yok.`
        );
        return;
      }

      // minRepeatDays filtresi — her öğe kendi `minRepeatDays`'i ile (yoksa
      // global ayar ile) cooldown'a tabi tutulur. Böylece bir ayet 7 günde
      // bir, diğeri 60 günde bir gelebilir.
      const eligible = poolSnap.docs.filter((doc) => {
        const d = doc.data();
        const lastSentDate = d.lastSentDate;
        if (!lastSentDate) return true;
        const itemMinRepeat = Number.isFinite(d.minRepeatDays)
          ? Number(d.minRepeatDays)
          : minRepeatDays;
        return daysBetween(lastSentDate, todayStr) >= itemMinRepeat;
      });

      if (eligible.length === 0) {
        console.log(
          `[Havuz] Tüm eşleşen öğeler kendi tekrar penceresi içinde. Atlandı.`
        );
        return;
      }

      // Rastgele seç
      const chosen = eligible[Math.floor(Math.random() * eligible.length)];
      const data = chosen.data();

      // Bildirim başlığı: saat ve ayet koordinatı yan yana — aynı rakamların
      // iki kez görünmesi "saat = ayet" mantığını kullanıcıya görsel olarak
      // anlatır. Ek bir açıklama metni gerekmez.
      //   Örn: "21:05 · Kur'an 21:5"
      const clockStr = `${String(istHour).padStart(2, "0")}:${String(istMin).padStart(2, "0")}`;
      const hasSurahData =
        data.surahNumber != null && data.verseNumber != null;
      const ntfTitle = hasSurahData
        ? `${clockStr} · Kur'an ${data.surahNumber}:${data.verseNumber}`
        : (data.title || "Arın");

      // Gövde önceliği:
      //   1) Ayetin kendi `notificationBody` alanı (admin manuel yazdıysa)
      //   2) Aksi halde hazır metin havuzundan rastgele bir teaser
      // Havuz da boşsa, `loadTeaserTexts` zaten fallback sabit listeye düşer.
      let ntfBody = (data.notificationBody || "").toString().trim();
      if (!ntfBody) {
        const teaserTexts = await loadTeaserTexts(db);
        ntfBody =
          teaserTexts[Math.floor(Math.random() * teaserTexts.length)];
      }

      // Ayetin 5 dakikalık geçerlilik penceresini Firestore'a yaz.
      // Uygulama tıklandığında bu dökümanı okuyarak süre kontrolü yapar.
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
            clockStr: clockStr,
            sentAtMs: nowMs,
            expiresAtMs: expiresAtMs,
          });
      } catch (err) {
        console.error("[Havuz] current_moment yazılamadı:", err);
      }

      await messaging.send({
        topic: "broadcast_all",
        notification: {
          title: ntfTitle,
          body: ntfBody,
        },
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

      // Öğenin son gönderim tarihini güncelle
      await chosen.ref.update({
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
    const ntfTitle = hasSurahData
      ? (clockStr
          ? `${clockStr} · Kur'an ${data.surahNumber}:${data.verseNumber}`
          : `Kur'an ${data.surahNumber}:${data.verseNumber}`)
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
    const ntfTitle = surahNumber != null && verseNumber != null
      ? `TEST · ${clockStr} · Kur'an ${surahNumber}:${verseNumber}`
      : `TEST · ${clockStr}`;

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
