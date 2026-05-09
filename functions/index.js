// Arın — Cloud Functions
// Her dakika çalışır (Avrupa/İstanbul):
//   1. Bekleyen manuel bildirimleri (admin_scheduled_notifications) gönderir.
//      Manuel bildirim gönderilince havuz timer'ı sıfırlanır.
//   2. admin_ntf_pool'dan o dakikaya uyan bir öğeyi rastgele seçerek gönderir.
//      Gönderim sıklığı ve tekrar süresi admin_ntf_config/schedule'dan okunur.

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// İki YYYY-MM-DD stringi arasındaki tam gün farkı (b - a)
function daysBetween(a, b) {
  const da = new Date(a);
  const db = new Date(b);
  return Math.floor((db - da) / 86400000);
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
    const now = Timestamp.now();
    const nowMs = now.toMillis();

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

    // ── 1. Manuel zamanlanmış bildirimler ────────────────────────────────────
    let manualSentCount = 0;
    try {
      const manualSnap = await db
        .collection("admin_scheduled_notifications")
        .where("status", "==", "pending")
        .where("scheduledAt", "<=", now)
        .get();

      for (const doc of manualSnap.docs) {
        const data = doc.data();
        try {
          await messaging.send({
            topic: "broadcast_all",
            notification: {
              title: data.title || "Arın",
              body: data.body || "",
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
          await doc.ref.update({
            status: "sent",
            sentAt: FieldValue.serverTimestamp(),
          });
          manualSentCount++;
          console.log(`[Manuel] Gönderildi: ${doc.id}`);
        } catch (err) {
          console.error(`[Manuel] Gönderilemedi ${doc.id}:`, err);
          await doc.ref.update({
            status: "failed",
            errorMessage: String(err.message || err),
          });
        }
      }

      // Manuel bildirim gönderildiyse havuz timer'ını sıfırla
      if (manualSentCount > 0) {
        await db
          .collection("admin_ntf_config")
          .doc("schedule")
          .set({ lastAutoSentDate: todayStr }, { merge: true });
        console.log(`[Manuel] ${manualSentCount} bildirim gönderildi; havuz timer sıfırlandı.`);
      }
    } catch (err) {
      console.error("[Manuel] Bildirimler okunurken hata:", err);
    }

    // ── 2. Havuz bildirimleri (sıklık + tekrar kontrolü) ─────────────────────
    try {
      // Config'i oku
      const configSnap = await db
        .collection("admin_ntf_config")
        .doc("schedule")
        .get();
      const config = configSnap.exists ? configSnap.data() : {};
      const sendEveryNDays = config.sendEveryNDays ?? 3;
      const minRepeatDays = config.minRepeatDays ?? 60;
      const lastAutoSentDate = config.lastAutoSentDate ?? null;

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

      // minRepeatDays geçmemiş öğeleri filtrele
      const eligible = poolSnap.docs.filter((doc) => {
        const lastSentDate = doc.data().lastSentDate;
        if (!lastSentDate) return true;
        return daysBetween(lastSentDate, todayStr) >= minRepeatDays;
      });

      if (eligible.length === 0) {
        console.log(
          `[Havuz] Tüm eşleşen öğeler ${minRepeatDays} günlük tekrar süresi içinde. Atlandı.`
        );
        return;
      }

      // Rastgele seç
      const chosen = eligible[Math.floor(Math.random() * eligible.length)];
      const data = chosen.data();

      await messaging.send({
        topic: "broadcast_all",
        notification: {
          title: data.title || "Arın",
          body: data.text || "",
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
        `[Havuz] Gönderildi ${istHour}:${String(istMin).padStart(2, "0")} ` +
        `— "${String(data.text || "").slice(0, 60)}"`
      );
    } catch (err) {
      console.error("[Havuz] Hata:", err);
    }
  }
);
