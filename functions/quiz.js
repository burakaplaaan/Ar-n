const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");

const questions = require("./data/islamic_quiz_questions.json");
const questionsAr = require("./data/islamic_quiz_questions_ar.json");

const REGION = "europe-west1";
// TEMP (emülatör): Play Integrity emülatörde fail → Unauthenticated.
// Mağaza / prod öncesi mutlaka true yap.
const ENFORCE_APP_CHECK = false;
const ROUND_COUNT = 7;
/** Oyuncu başına hatırlanan soru tavanı — banka bitene kadar tekrar yok. */
const SEEN_QUESTION_IDS_CAP = questions.length;
const ROUND_DURATION_MS = 20_000;
/**
 * Deadline sonrası cevap kabul / otomatik timeout öncesi ortak tolerans.
 * Poll `deadline`'da timeout yazıp submit'in grace penceresini yutmasın.
 */
const ANSWER_GRACE_MS = 1_500;
/** Tur sonucu şıklar üzerinde gösterilirken sonraki soruya geçmeden önce bekleme. */
const ROUND_REVEAL_MS = 2_600;
/** Şimdilik son seviye; ödüller buna göre kilitlenir. */
const MAX_LEVEL = 10;
/** Maçı yarıda terk cezası (hilal). Eksi bakiyeye düşebilir. */
const FORFEIT_PENALTY = 5;
const WEEKLY_TOP_LIMIT = 20;
/** Botlar sıralamada görünür ama şişmez; haftalık tavan düşük. */
const BOT_WEEKLY_CAP = 6;
const BOT_WEEKLY_GAIN_CAP = 1;
const WEEKLY_TTL_MS = 21 * 24 * 60 * 60_000;
/** Haftalık kapanış: insan 1/2/3 Premium günleri (zaten Premium ise verilmez). */
const HILAL_WEEKLY_PREMIUM_DAYS_BY_RANK = Object.freeze({ 1: 14, 2: 7, 3: 3 });
/** Geriye uyum / test: 1. sıra gün sayısı. */
const HILAL_WEEKLY_PREMIUM_DAYS = HILAL_WEEKLY_PREMIUM_DAYS_BY_RANK[1];
const HILAL_WEEKLY_PREMIUM_MS = HILAL_WEEKLY_PREMIUM_DAYS * 24 * 60 * 60_000;
const HILAL_WEEKLY_REWARDS_COLLECTION = "quiz_weekly_rewards";
const HILAL_WEEKLY_PREMIUM_SOURCE = "hilal_weekly_top";
const HILAL_WEEKLY_PREMIUM_PRODUCT_PREFIX = "hilal_duel_weekly_";
/** Top-3 rekabet push: aynı oyuncuya en az 12s'de bir. */
const TOP3_RIVALRY_COOLDOWN_MS = 12 * 60 * 60_000;
/** Üstteki oyuncuya "yaklaşıyor" uyarısı için hilal farkı. */
const TOP3_CLOSE_THREAT_HILAL_GAP = 3;
/** Engajman push: en az 3 günde bir; bunaltmaz. */
const ENGAGEMENT_COOLDOWN_MS = 3 * 24 * 60 * 60_000;
/** Son maçtan sonra en az 36 saat sessizlik. */
const ENGAGEMENT_MIN_IDLE_MS = 36 * 60 * 60_000;
/** 14 günden eski oyuncuya tekrar yazma. */
const ENGAGEMENT_MAX_IDLE_MS = 14 * 24 * 60 * 60_000;
/** Lobiyi açmış ama hiç oynamamış: ilk teşvik için min profil yaşı. */
const ENGAGEMENT_NEVER_PLAYED_MIN_AGE_MS = 24 * 60 * 60_000;
/** Hiç oynamamışa 30 günden sonra tekrar yazma. */
const ENGAGEMENT_NEVER_PLAYED_MAX_AGE_MS = 30 * 24 * 60 * 60_000;
const ENGAGEMENT_BATCH_LIMIT = 60;
/** Admin “herkese can” — hiç oynamayan ilk açılışta claim eder. */
const PROMO_HEARTS_DOC = "promo_hearts";
const PROMO_HEARTS_COLLECTION = "quiz_config";
const QUIZ_DEVICE_TTL_MS = 45 * 24 * 60 * 60_000;
/** Meydan okuma: davetten itibaren toplam süre. Dolarsa kimseye puan yok. */
const CHALLENGE_TTL_MS = 24 * 60 * 60_000;
/** Biten meydan okuma lobide bu kadar süre sonuç olarak kalsın. */
const CHALLENGE_INBOX_COMPLETED_MS = 48 * 60 * 60_000;
/**
 * Bota meydan okunduğunda cevap gecikmesi.
 * Bot bilinçli zayıf oynar (yalnızca 1 doğru) — liderlik tablosunu ezmesin.
 */
const CHALLENGE_BOT_DELAY_MS = 12 * 60 * 60_000;
/** Bitişe bu kadar kala rakibe hatırlatma push'u. */
const CHALLENGE_REMINDER_BEFORE_MS = 2 * 60 * 60_000;
/** Challenge dokümanı geçmişte görünsün; TTL silmesi 7 gün sonra. */
const CHALLENGE_DOC_TTL_MS = 7 * 24 * 60 * 60_000;
/** Aynı anda bekleyen giden meydan okuma limiti. */
const CHALLENGE_MAX_ACTIVE_OUTGOING = 3;
const QUEUE_WAIT_MS = 15_000;
/** Mantıksal terk: bu süreden sonra waiting kuyruk iade edilir. */
const QUEUE_ABANDON_MS = 10 * 60_000;
/** Waiting doc TTL yedeği — iade job'u önce çalışsın diye uzun tutulur. */
const QUEUE_WAITING_TTL_MS = 7 * 24 * 60 * 60_000;
const QUEUE_IDLE_TTL_MS = 24 * 60 * 60_000;
const MATCH_EXPIRY_MS = 24 * 60 * 60_000;
const REWARD_PROOF_TTL_MS = 10 * 60_000;
const RATE_WINDOW_MS = 5 * 60_000;
const INSTALL_TTL_MS = 180 * 86400000;
// Yalnızca ilk ad — soyadlı tam isimler botları çok belli ediyordu.
const BOT_NAMES = [
  "Ahmet",
  "Ayşe",
  "Mehmet",
  "Zeynep",
  "Mustafa",
  "Elif",
  "Ömer",
  "Merve",
  "Yusuf",
  "Fatma",
  "Emine",
  "İbrahim",
];

/** Bot görünen adı: soyadı düş (eski haftalık kayıtlarda da). */
function _botDisplayName(raw) {
  const trimmed = String(raw || "")
    .replace(/\s+/gu, " ")
    .trim();
  if (!trimmed) return "Oyuncu";
  const first = trimmed.split(" ")[0] || trimmed;
  return first.slice(0, 32);
}

function _assertQuestionBank() {
  if (!Array.isArray(questions) || questions.length !== 1000) {
    throw new Error("Hilal Düellosu question bank must contain 1000 questions.");
  }
  const ids = new Set();
  for (const item of questions) {
    if (
      typeof item?.id !== "string" ||
      ids.has(item.id) ||
      typeof item?.question !== "string" ||
      !Array.isArray(item?.options) ||
      item.options.length !== 4 ||
      !Number.isInteger(item?.correctIndex) ||
      item.correctIndex < 0 ||
      item.correctIndex > 3 ||
      ![1, 2, 3].includes(item?.difficulty)
    ) {
      throw new Error(`Invalid Hilal Düellosu question: ${item?.id || "unknown"}`);
    }
    ids.add(item.id);
  }
}

function _assertArabicQuestionBank() {
  if (!questionsAr || typeof questionsAr !== "object") {
    throw new Error("Hilal Düellosu Arabic question bank is missing.");
  }
  for (const item of questions) {
    const ar = questionsAr[item.id];
    if (
      !ar ||
      typeof ar.question !== "string" ||
      ar.question.trim().length < 8 ||
      !Array.isArray(ar.options) ||
      ar.options.length !== 4 ||
      typeof ar.category !== "string" ||
      typeof ar.explanation !== "string"
    ) {
      throw new Error(`Invalid Arabic Hilal Düellosu question: ${item.id}`);
    }
  }
}

_assertQuestionBank();
_assertArabicQuestionBank();
const QUESTION_BY_ID = new Map(questions.map((item) => [item.id, item]));
const QUESTION_AR_BY_ID = new Map(Object.entries(questionsAr));

function _sha256(value) {
  return crypto.createHash("sha256").update(String(value), "utf8").digest("hex");
}

function _validatedInstallHash(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{16,160}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz kurulum kimliği.");
  }
  return _sha256(value);
}

function _validatedBindingSecretHash(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{32,160}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz güvenlik anahtarı.");
  }
  return _sha256(value);
}

function _validatedName(raw) {
  const value = String(raw || "")
    .replace(/\s+/gu, " ")
    .trim();
  if (value.length < 2 || value.length > 32) {
    throw new HttpsError("invalid-argument", "İsim 2-32 karakter olmalıdır.");
  }
  if (/[\u0000-\u001f\u007f<>]/u.test(value)) {
    throw new HttpsError("invalid-argument", "İsim geçersiz karakter içeriyor.");
  }
  return value;
}

function _validatedDocumentId(raw, label = "kayıt") {
  const value = String(raw || "").trim();
  if (!/^[a-f0-9]{32}$/.test(value)) {
    throw new HttpsError("invalid-argument", `Geçersiz ${label} kimliği.`);
  }
  return value;
}

/** quiz_players doküman kimliği (sha256 hex). Bot id'leri bu deseni tutmaz. */
function _validatedOwnerHash(raw) {
  const value = String(raw || "").trim().toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz oyuncu kimliği.");
  }
  return value;
}

/** Haftalık listedeki sabit bot kimliği: bot_ + 20 hex. */
function _isBotId(raw) {
  return /^bot_[a-f0-9]{20}$/.test(String(raw || "").trim().toLowerCase());
}

/** İnsan (64 hex) veya bot (bot_…) rakip kimliği. */
function _validatedOpponentId(raw) {
  const value = String(raw || "").trim().toLowerCase();
  if (/^[a-f0-9]{64}$/.test(value)) return value;
  if (_isBotId(value)) return value;
  throw new HttpsError("invalid-argument", "Geçersiz oyuncu kimliği.");
}

function _validatedProofId(raw) {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9]{20,64}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz reklam kanıtı.");
  }
  return value;
}

function _istanbulDayKey(now = new Date()) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}

function levelForHilals(rawHilals) {
  const hilals = Math.max(0, Math.floor(Number(rawHilals) || 0));
  let level = 1;
  let floor = 0;
  let nextCost = 40;
  while (hilals >= floor + nextCost && level < MAX_LEVEL) {
    floor += nextCost;
    level += 1;
    nextCost = 40 + (level - 1) * 15;
  }
  if (level >= MAX_LEVEL) {
    return {
      level: MAX_LEVEL,
      levelFloorHilals: floor,
      nextLevelHilals: floor,
      maxLevel: true,
    };
  }
  return {
    level,
    levelFloorHilals: floor,
    nextLevelHilals: floor + nextCost,
    maxLevel: false,
  };
}

/** Hedef seviyenin taban hilali (admin seviye ayarı). */
function hilalsFloorForLevel(rawLevel) {
  const target = Math.max(1, Math.min(MAX_LEVEL, Math.floor(Number(rawLevel) || 1)));
  let level = 1;
  let floor = 0;
  let nextCost = 40;
  while (level < target) {
    floor += nextCost;
    level += 1;
    nextCost = 40 + (level - 1) * 15;
  }
  return floor;
}

/** İstanbul takvimine göre haftanın Pazartesi günü (YYYYMMDD). */
function weekIdIstanbul(now = new Date()) {
  const dayKey = _istanbulDayKey(now);
  const [year, month, day] = dayKey.split("-").map((value) => Number(value));
  const utc = new Date(Date.UTC(year, month - 1, day));
  const dow = utc.getUTCDay();
  const fromMonday = (dow + 6) % 7;
  utc.setUTCDate(utc.getUTCDate() - fromMonday);
  const y = utc.getUTCFullYear();
  const m = String(utc.getUTCMonth() + 1).padStart(2, "0");
  const d = String(utc.getUTCDate()).padStart(2, "0");
  return `${y}${m}${d}`;
}

/** Bir önceki İstanbul haftasının Pazartesi kimliği (kapanmış hafta). */
function previousWeekIdIstanbul(now = new Date()) {
  const current = weekIdIstanbul(now);
  const y = Number(current.slice(0, 4));
  const m = Number(current.slice(4, 6));
  const d = Number(current.slice(6, 8));
  const utc = new Date(Date.UTC(y, m - 1, d));
  utc.setUTCDate(utc.getUTCDate() - 7);
  const py = utc.getUTCFullYear();
  const pm = String(utc.getUTCMonth() + 1).padStart(2, "0");
  const pd = String(utc.getUTCDate()).padStart(2, "0");
  return `${py}${pm}${pd}`;
}

/** Misafir quiz_* uid'leri Premium entitlement alamaz. */
function isGrantablePremiumUid(uid) {
  const value = String(uid || "").trim();
  return value.length > 0 && !value.startsWith("quiz_");
}

/**
 * Mevcut sürenin üzerine ekle (stack). Süresiz aktif kayıtta null döner.
 * Pasif / süresi dolmuş kayıtlarda taban = now.
 *
 * Not: `existingExpiresAtMs === null` süresiz demektir; `0` / NaN yok sayılır.
 */
function computePremiumExtendExpiresAtMs({
  existingActive,
  existingExpiresAtMs,
  nowMs,
  grantMs,
}) {
  const grant = Math.max(0, Math.floor(Number(grantMs) || 0));
  const now = Math.max(0, Math.floor(Number(nowMs) || 0));
  if (existingActive === true && existingExpiresAtMs == null) {
    return null;
  }
  const existing = Math.max(0, Math.floor(Number(existingExpiresAtMs) || 0));
  const base = existingActive === true && existing > now ? existing : now;
  return base + grant;
}

/**
 * Haftalık ödül bonus bitişi: ana süre + önceki hilal bonus üzerinden stack.
 * RC webhook `expiresAt`/`active` ezse bile `hilalWeeklyBonusExpiresAt` kalır.
 * Süresiz aktif → null.
 */
function computeHilalWeeklyBonusExpiresAtMs({
  nowMs,
  grantMs,
  existingActive,
  existingExpiresAtMs,
  existingBonusExpiresAtMs,
}) {
  if (existingActive === true && existingExpiresAtMs == null) {
    return null;
  }
  const now = Math.max(0, Math.floor(Number(nowMs) || 0));
  const grant = Math.max(0, Math.floor(Number(grantMs) || 0));
  const main = existingActive === true
    ? Math.max(0, Math.floor(Number(existingExpiresAtMs) || 0))
    : 0;
  const bonus = Math.max(0, Math.floor(Number(existingBonusExpiresAtMs) || 0));
  return Math.max(now, main, bonus) + grant;
}

function hilalWeeklyPremiumDaysForRank(rank) {
  const key = Math.floor(Number(rank) || 0);
  return Math.max(0, Math.floor(Number(HILAL_WEEKLY_PREMIUM_DAYS_BY_RANK[key]) || 0));
}

function hilalWeeklyPremiumMsForRank(rank) {
  return hilalWeeklyPremiumDaysForRank(rank) * 24 * 60 * 60_000;
}

/**
 * Kapalı haftanın insan sıralaması (bot / excluded / 0 hilal elenir).
 * Lobideki insan sıralamasıyla aynı sıra: hilal ↓, isim tr.
 */
function pickWeeklyHumanTop(entries, limit = 3) {
  const cap = Math.max(0, Math.floor(Number(limit) || 0));
  const rows = (Array.isArray(entries) ? entries : [])
    .map((row) => {
      const ownerHash = String(row?.ownerHash || "").trim().toLowerCase();
      const isBot = row?.isBot === true || ownerHash.startsWith("bot_");
      return {
        ownerHash,
        name: String(row?.name || "Oyuncu").slice(0, 32),
        weeklyHilals: Math.floor(Number(row?.weeklyHilals) || 0),
        isBot,
        leaderboardExcluded: row?.leaderboardExcluded === true,
      };
    })
    .filter((row) => (
      row.ownerHash &&
      !row.isBot &&
      !row.leaderboardExcluded &&
      row.weeklyHilals > 0
    ));
  if (rows.length === 0 || cap <= 0) return [];
  return _orderWeeklyLeaderboard(rows).slice(0, cap);
}

/** Geriye uyum: insan birincisi. */
function pickWeeklyHumanWinner(entries) {
  return pickWeeklyHumanTop(entries, 1)[0] || null;
}

/** Premium kaydı `nowMs` anında aktif mi? (süresiz / bonus dahil). */
function premiumActiveAt(data, nowMs = Date.now()) {
  if (!data) return false;
  const now = Math.max(0, Math.floor(Number(nowMs) || 0));
  const bonusMs = data.hilalWeeklyBonusExpiresAt?.toMillis?.() || 0;
  if (bonusMs > now) return true;
  if (data.active !== true) return false;
  const expiresAt = data.expiresAt;
  return expiresAt == null || (expiresAt?.toMillis?.() || 0) > now;
}

function isLifetimePremium(data) {
  return data?.active === true && data?.expiresAt == null;
}

function emptyCosmetics() {
  return {
    avatarFrame: false,
    avatarFrameTier: 0,
    avatarGlow: false,
    title: null,
    specialHilalIcon: false,
    nameAccentFaint: false,
    nameAccentSoft: false,
    nameAccent: false,
  };
}

function cosmeticsForLevel(rawLevel) {
  const level = Math.max(1, Math.min(MAX_LEVEL, Math.floor(Number(rawLevel) || 1)));
  return {
    avatarFrame: level >= 3,
    avatarFrameTier: level >= 4 ? 2 : level >= 3 ? 1 : 0,
    avatarGlow: level >= 6,
    title: level >= 10 ? "İlim Dostu" : level >= 9 ? "Müderris" : level >= 5 ? "Talebe" : null,
    specialHilalIcon: level >= 8,
    nameAccentFaint: level >= 6,
    nameAccentSoft: level >= 7,
    nameAccent: level >= 10,
  };
}

function cosmeticsDocFields(cosmetics) {
  return {
    title: cosmetics.title,
    avatarFrame: cosmetics.avatarFrame === true,
    avatarFrameTier: Math.max(0, Math.floor(Number(cosmetics.avatarFrameTier) || 0)),
    avatarGlow: cosmetics.avatarGlow === true,
    specialHilalIcon: cosmetics.specialHilalIcon === true,
    nameAccentFaint: cosmetics.nameAccentFaint === true,
    nameAccentSoft: cosmetics.nameAccentSoft === true,
    nameAccent: cosmetics.nameAccent === true,
  };
}

function _decoratePlayer(player) {
  const level = Math.max(1, Math.floor(Number(player?.level) || 1));
  const cosmetics = cosmeticsForLevel(level);
  return {
    id: String(player?.id || ""),
    name: String(player?.name || "Oyuncu").slice(0, 32),
    hilals: Math.floor(Number(player?.hilals) || 0),
    level,
    isBot: player?.isBot === true,
    badge: null,
    ...cosmetics,
  };
}

function _weeklyEntryRef(db, weekId, ownerHash) {
  return db.collection("quiz_weekly").doc(weekId).collection("entries").doc(ownerHash);
}

/**
 * Tx içinde: oyuncu + haftalık skor mutlak yazılır (delta uygulanır).
 * Okumalar çağıran tarafından önceden yapılmış olmalı.
 */
function _writeHilalDelta(tx, {
  playerRef,
  weeklyRef,
  playerSnap,
  weeklySnap,
  delta,
  name,
  weekId,
  matchesCompletedInc = 0,
}) {
  const safeDelta = Math.floor(Number(delta) || 0);
  const prevHilals = Math.floor(Number(playerSnap.data()?.hilals) || 0);
  const nextHilals = prevHilals + safeDelta;
  const progression = levelForHilals(nextHilals);
  const cosmetics = cosmeticsForLevel(progression.level);
  const displayName = String(
    name || playerSnap.data()?.name || "Arın Oyuncusu",
  ).slice(0, 32);
  let weeklyHilals = safeDelta;
  if (weeklySnap.exists) {
    weeklyHilals = Math.floor(Number(weeklySnap.data()?.weeklyHilals) || 0) +
      safeDelta;
  }
  const prevData = playerSnap.data() || {};
  const prevMatches = Math.max(
    0,
    Math.floor(Number(prevData.matchesCompleted) || 0),
  );
  const matchInc = Math.max(0, matchesCompletedInc);
  const prevWeekId = String(prevData.weekId || "");
  const prevWeeklyMatches = prevWeekId === weekId
    ? Math.max(0, Math.floor(Number(prevData.weeklyMatches) || 0))
    : 0;
  const nextWeeklyMatches = prevWeeklyMatches + matchInc;
  const excluded = prevData.leaderboardExcluded === true;
  const playerPatch = {
    name: excluded
      ? String(prevData.name || "Oyuncu").slice(0, 32)
      : displayName,
    hilals: nextHilals,
    weekId,
    // Moderasyon: listeden atılan oyuncu haftalık skor biriktirmesin.
    weeklyHilals: excluded ? 0 : weeklyHilals,
    weeklyMatches: excluded ? 0 : nextWeeklyMatches,
    matchesCompleted: prevMatches + matchInc,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (matchInc > 0) {
    playerPatch.lastMatchAt = FieldValue.serverTimestamp();
  }
  tx.set(playerRef, playerPatch, { merge: true });
  if (excluded) {
    if (weeklySnap.exists) {
      tx.delete(weeklyRef);
    }
    return { nextHilals, weeklyHilals: 0, level: progression.level };
  }
  const prevWeeklyMatchCount = weeklySnap.exists
    ? Math.max(0, Math.floor(Number(weeklySnap.data()?.matchesPlayed) || 0))
    : 0;
  tx.set(weeklyRef, {
    ownerHash: playerRef.id,
    name: displayName,
    weeklyHilals,
    matchesPlayed: prevWeeklyMatchCount + matchInc,
    level: progression.level,
    isBot: false,
    ...cosmeticsDocFields(cosmetics),
    updatedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + WEEKLY_TTL_MS),
  }, { merge: true });
  return { nextHilals, weeklyHilals, level: progression.level };
}

/** Bot id'si isme sabit — aynı "Elif" haftalıkta tek satır. */
function _stableBotId(name) {
  return `bot_${_sha256(`hilal_bot:${_botDisplayName(name)}`).slice(0, 20)}`;
}

/**
 * Botları haftalık listede tutar; kazanç ve tavan düşük (hep altlarda).
 * quiz_players yazılmaz.
 */
function _writeBotWeeklyDelta(tx, {
  weeklyRef,
  weeklySnap,
  delta,
  name,
  level,
  botId,
}) {
  const gain = Math.max(
    0,
    Math.min(BOT_WEEKLY_GAIN_CAP, Math.floor(Number(delta) || 0)),
  );
  const displayName = _botDisplayName(name);
  if (gain <= 0 && weeklySnap.exists) {
    // Yine de isim/level tazele.
    tx.set(weeklyRef, {
      name: displayName,
      level: Math.max(1, Math.floor(Number(level) || 1)),
      isBot: true,
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + WEEKLY_TTL_MS),
    }, { merge: true });
    return;
  }
  const prev = weeklySnap.exists
    ? Math.floor(Number(weeklySnap.data()?.weeklyHilals) || 0)
    : 0;
  const weeklyHilals = Math.min(BOT_WEEKLY_CAP, prev + Math.max(gain, 1));
  const safeLevel = Math.max(1, Math.min(3, Math.floor(Number(level) || 1)));
  tx.set(weeklyRef, {
    ownerHash: botId,
    name: displayName,
    weeklyHilals,
    level: safeLevel,
    isBot: true,
    ...cosmeticsDocFields(emptyCosmetics()),
    updatedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + WEEKLY_TTL_MS),
  }, { merge: true });
}

/** İnsanlar üstte, botlar altta; skor kendi gruplarında. */
function _orderWeeklyLeaderboard(entries) {
  const humans = entries
    .filter((row) => row.isBot !== true)
    .sort((a, b) => {
      if (b.weeklyHilals !== a.weeklyHilals) {
        return b.weeklyHilals - a.weeklyHilals;
      }
      return String(a.name).localeCompare(String(b.name), "tr");
    });
  const bots = entries
    .filter((row) => row.isBot === true)
    .sort((a, b) => {
      if (b.weeklyHilals !== a.weeklyHilals) {
        return b.weeklyHilals - a.weeklyHilals;
      }
      return String(a.name).localeCompare(String(b.name), "tr");
    });
  return [...humans, ...bots].map((row, index) => ({
    ...row,
    rank: index + 1,
  }));
}

function _validatedQuizLocale(raw) {
  const value = String(raw || "").trim().toLowerCase();
  if (value.startsWith("tr")) return "tr";
  if (value.startsWith("ar")) return "ar";
  if (value.startsWith("en")) return "en";
  return "tr";
}

function _requestLocale(req) {
  return _validatedQuizLocale(req?.data?.locale);
}

/**
 * Admin global can bağışı: oyuncu henüz claim etmediyse kaç can eklenir.
 * Ara grant’ler kaçırıldıysa yalnız son `amount` verilir (çift yazımı önler).
 */
function pendingPromoHeartsGain({ claimedSeq, promoSeq, amount }) {
  const claimed = Math.max(0, Math.floor(Number(claimedSeq) || 0));
  const seq = Math.max(0, Math.floor(Number(promoSeq) || 0));
  const add = Math.max(0, Math.floor(Number(amount) || 0));
  if (seq <= 0 || add <= 0 || claimed >= seq) return 0;
  return Math.min(20, add);
}

/**
 * Engajman push adayı mı?
 * - never_played: lobiyi açmış, 0 maç, 1g–30g profil yaşı, 3g cooldown
 * - oynayan: 36s–14g idle, 3g cooldown → rank_drop | comeback
 */
function decideQuizEngagement({
  matchesCompleted,
  lastMatchAtMs,
  lastPushAtMs,
  nowMs,
  currentRank,
  bestWeeklyRank,
  lastKnownWeeklyRank = 0,
  createdAtMs = 0,
}) {
  const now = Math.floor(Number(nowMs) || 0);
  const lastPush = Math.floor(Number(lastPushAtMs) || 0);
  if (lastPush > 0 && now - lastPush < ENGAGEMENT_COOLDOWN_MS) {
    return { send: false, reason: null };
  }
  const matches = Math.floor(Number(matchesCompleted) || 0);
  if (matches < 1) {
    const created = Math.floor(Number(createdAtMs) || 0);
    if (!created) return { send: false, reason: null };
    const age = now - created;
    if (
      age < ENGAGEMENT_NEVER_PLAYED_MIN_AGE_MS ||
      age > ENGAGEMENT_NEVER_PLAYED_MAX_AGE_MS
    ) {
      return { send: false, reason: null };
    }
    return { send: true, reason: "never_played" };
  }
  const lastMatch = Math.floor(Number(lastMatchAtMs) || 0);
  if (!lastMatch) return { send: false, reason: null };
  const idle = now - lastMatch;
  if (idle < ENGAGEMENT_MIN_IDLE_MS || idle > ENGAGEMENT_MAX_IDLE_MS) {
    return { send: false, reason: null };
  }
  const rank = Math.floor(Number(currentRank) || 0);
  const best = Math.floor(Number(bestWeeklyRank) || 0);
  const known = Math.floor(Number(lastKnownWeeklyRank) || 0);
  const peak = best > 0 ? best : known;
  if (rank > 0 && peak > 0 && rank > peak) {
    return { send: true, reason: "rank_drop" };
  }
  return { send: true, reason: "comeback" };
}

function quizEngagementCopy(locale, reason) {
  const lang = _validatedQuizLocale(locale);
  if (reason === "never_played") {
    if (lang === "ar") {
      return {
        title: "تحدي المعرفة بانتظارك",
        body: "7 أسئلة · 20 ثانية — جرّب أول مباراة الآن، قد تكون لديك قلب هدية.",
      };
    }
    if (lang === "en") {
      return {
        title: "Knowledge Duel is waiting",
        body: "7 questions · 20 seconds — try your first match; a gift heart may be ready.",
      };
    }
    return {
      title: "Bilgi Düellosu seni bekliyor",
      body: "7 soru · 20 sn — ilk maçını dene; hediye canın hazır olabilir.",
    };
  }
  if (reason === "rank_drop") {
    if (lang === "ar") {
      return {
        title: "ترتيبك انخفض",
        body: "عد إلى تحدي المعرفة واستعد مكانك في قائمة الأسبوع.",
      };
    }
    if (lang === "en") {
      return {
        title: "Your rank dropped",
        body: "Jump back into Knowledge Duel and climb the weekly board.",
      };
    }
    return {
      title: "Sıralaman düştü",
      body: "Bilgi Düellosu’na dön, haftalık listede yerini geri al.",
    };
  }
  if (lang === "ar") {
    return {
      title: "تحدي المعرفة بانتظارك",
      body: "مباراة واحدة تكفي للعودة — لا تدع منافسك يتقدم.",
    };
  }
  if (lang === "en") {
    return {
      title: "Knowledge Duel misses you",
      body: "One match is enough — don’t let your rival pull ahead.",
    };
  }
  return {
    title: "Bilgi Düellosu seni bekliyor",
    body: "Tek maç yeter — rakibin öne geçmesin, hemen oyna.",
  };
}

function quizTop3RivalryCopy(locale, reason, { name = "Rakip" } = {}) {
  const lang = _validatedQuizLocale(locale);
  const rival = String(name || "Rakip").slice(0, 24);
  if (reason === "overtaken") {
    if (lang === "ar") {
      return {
        title: "تجاوزك منافس",
        body: `${rival} تقدّم عليك في ترتيب الأسبوع — استعد مكانك.`,
      };
    }
    if (lang === "en") {
      return {
        title: "You've been overtaken",
        body: `${rival} just passed you on the weekly board — climb back.`,
      };
    }
    return {
      title: "Sıran kaydı",
      body: `${rival} haftalık listede seni geçti — yerini geri al.`,
    };
  }
  if (lang === "ar") {
    return {
      title: "منافس يقترب",
      body: `${rival} يقترب من ترتيبك — لا تترك الصدارة.`,
    };
  }
  if (lang === "en") {
    return {
      title: "Rival closing in",
      body: `${rival} is close on the weekly board — hold your spot.`,
    };
  }
  return {
    title: "Rakip yaklaşıyor",
    body: `${rival} haftalık sırana yetişiyor — yerini koru.`,
  };
}

/**
 * Maç sonrası top-3 rekabet: kime hangi push?
 * - overtaken: aktör üst sıraya çıktı / geçti → alttaki insan
 * - close_threat: aktör üsttekine ≤ gap hilal → üstteki insan
 * Engajman (idle) push'tan ayrı cooldown.
 */
function decideTop3RivalryNotifications({
  actorOwnerHash,
  actorName,
  actorRank,
  actorHilals,
  board,
  lastPushAtByOwner = {},
  nowMs,
  cooldownMs = TOP3_RIVALRY_COOLDOWN_MS,
  closeGap = TOP3_CLOSE_THREAT_HILAL_GAP,
}) {
  const actor = String(actorOwnerHash || "").trim().toLowerCase();
  const rank = Math.floor(Number(actorRank) || 0);
  const hilals = Math.floor(Number(actorHilals) || 0);
  const now = Math.max(0, Math.floor(Number(nowMs) || 0));
  const cool = Math.max(0, Math.floor(Number(cooldownMs) || 0));
  const gap = Math.max(0, Math.floor(Number(closeGap) || 0));
  if (!actor || rank <= 0 || hilals <= 0 || rank > 4) return [];

  const rows = (Array.isArray(board) ? board : [])
    .map((row, index) => ({
      ownerHash: String(row?.ownerHash || "").trim().toLowerCase(),
      name: String(row?.name || "Oyuncu").slice(0, 32),
      weeklyHilals: Math.floor(Number(row?.weeklyHilals) || 0),
      rank: Math.floor(Number(row?.rank) || (index + 1)),
    }))
    .filter((row) => row.ownerHash && !row.ownerHash.startsWith("bot_"));

  const out = [];
  const seen = new Set();
  const cooled = (ownerHash) => {
    const last = Math.floor(Number(lastPushAtByOwner[ownerHash]) || 0);
    return last > 0 && now - last < cool;
  };
  const push = (ownerHash, reason, name) => {
    if (!ownerHash || ownerHash === actor || seen.has(ownerHash)) return;
    if (cooled(ownerHash)) return;
    seen.add(ownerHash);
    out.push({
      ownerHash,
      reason,
      actorName: String(name || actorName || "Rakip").slice(0, 32),
    });
  };

  if (rank <= 3) {
    for (const row of rows) {
      if (row.ownerHash === actor) continue;
      // Yalnız bir alt sıra: yeni geçen oyuncu hemen alttakini geçti.
      if (row.rank === rank + 1 && row.weeklyHilals < hilals) {
        push(row.ownerHash, "overtaken", actorName);
      }
    }
  }

  if (rank >= 2 && rank <= 4) {
    const above = rows.find((row) => row.rank === rank - 1);
    if (
      above &&
      above.ownerHash !== actor &&
      above.weeklyHilals >= hilals &&
      above.weeklyHilals - hilals <= gap
    ) {
      push(above.ownerHash, "close_threat", actorName);
    }
  }

  return out;
}

async function _computeWeeklyRank(db, weekId, ownerHash, weeklyHilals) {
  const hilals = Math.floor(Number(weeklyHilals) || 0);
  try {
    // Lobideki gibi yalnız insanlar: bot / excluded sıra şişirmez.
    const higher = await _weeklyEntryRef(db, weekId, ownerHash).parent
      .where("weeklyHilals", ">", hilals)
      .limit(120)
      .get();
    let count = 0;
    for (const doc of higher.docs) {
      const data = doc.data() || {};
      const id = String(doc.id || "").trim().toLowerCase();
      if (!id || data.isBot === true || id.startsWith("bot_")) continue;
      if (data.leaderboardExcluded === true) continue;
      count += 1;
    }
    return count + 1;
  } catch (_) {
    return hilals !== 0 ? 1 : 0;
  }
}

function _bestWeeklyRankPatch(playerData, weekId, weeklyRank) {
  const rank = Math.floor(Number(weeklyRank) || 0);
  if (rank <= 0) return null;
  const prevWeek = String(playerData?.bestWeeklyRankWeekId || "");
  const prevBest = Math.floor(Number(playerData?.bestWeeklyRank) || 0);
  if (prevWeek !== weekId || prevBest <= 0 || rank < prevBest) {
    return {
      bestWeeklyRank: rank,
      bestWeeklyRankWeekId: weekId,
      lastKnownWeeklyRank: rank,
    };
  }
  return { lastKnownWeeklyRank: rank };
}

function determineWinner(playerA, playerB) {
  if (playerA.correct !== playerB.correct) {
    return playerA.correct > playerB.correct ? "a" : "b";
  }
  if (playerA.elapsedMs !== playerB.elapsedMs) {
    return playerA.elapsedMs < playerB.elapsedMs ? "a" : "b";
  }
  return "draw";
}

function hilalAward(correct, won, draw = false) {
  return Math.max(0, correct) * 2 +
    (won ? 5 : 0) +
    (draw ? 2 : 0) +
    (correct === ROUND_COUNT ? 3 : 0);
}

/**
 * Meydan okuma bonus hilali: yenilen rakip davet anında sıralamada
 * kazanandan daha yukarıdaysa ekstra puan (üst sıradakini devirme ödülü).
 * rank 0 = sıralamasız. Bonus yalnız kazanana.
 */
function challengeRankBonus(winnerRank, loserRank) {
  const winner = Math.max(0, Math.floor(Number(winnerRank) || 0));
  const loser = Math.max(0, Math.floor(Number(loserRank) || 0));
  if (loser <= 0) return 0;
  if (winner > 0 && loser >= winner) return 0;
  if (loser <= 3) return 5;
  if (loser <= 10) return 3;
  return 2;
}

/** challengeDeadlineMs; yoksa createdAt/updatedAt + TTL (eski kayıtlar). */
function challengeDeadlineMsOf(challenge) {
  const direct = Math.floor(Number(challenge?.challengeDeadlineMs) || 0);
  if (direct > 0) return direct;
  const base = _timestampMs(challenge?.createdAt) ||
    _timestampMs(challenge?.updatedAt) ||
    0;
  return base > 0 ? base + CHALLENGE_TTL_MS : 0;
}

const CHALLENGE_OPEN_STATUSES = new Set([
  "challenger_playing",
  "awaiting_opponent",
  "opponent_playing",
]);

/** Meydan okuma süresi doldu mu? Dolarsa kimse puan alamaz. */
function challengeIsExpired(challenge, nowMs = Date.now()) {
  const deadline = challengeDeadlineMsOf(challenge);
  if (deadline <= 0) return false;
  const status = String(challenge?.status || "");
  if (status === "completed" || status === "expired") return false;
  return nowMs > deadline;
}

/** createQuizChallenge açık-kota: süresi dolmuş davet sayılmaz. */
function isCountableOpenChallenge(data, nowMs = Date.now()) {
  if (!CHALLENGE_OPEN_STATUSES.has(String(data?.status || ""))) return false;
  return !challengeIsExpired(data, nowMs);
}

/** Kota / çift davet: tx içi taze snap'lerden say. */
function tallyCountableChallenges(rows, ownerHash, opponentId, nowMs = Date.now()) {
  let outgoingOpen = 0;
  let hasOpenPair = false;
  const openOutgoingIds = [];
  const self = String(ownerHash || "");
  const other = String(opponentId || "");
  for (const row of rows) {
    const id = String(row?.id || "");
    const data = row?.data && typeof row.data === "object" ? row.data : row;
    if (!isCountableOpenChallenge(data, nowMs)) continue;
    if (String(data.challengerId || "") === self) {
      outgoingOpen += 1;
      if (id) openOutgoingIds.push(id);
    }
    if (self && other) {
      const ids = [
        String(data.challengerId || ""),
        String(data.challengedId || ""),
      ];
      if (ids.includes(self) && ids.includes(other)) {
        hasOpenPair = true;
      }
    }
  }
  return { outgoingOpen, hasOpenPair, openOutgoingIds };
}

function openPeerChallengeId(playerData, peerId) {
  const peers = playerData?.openChallengePeers;
  if (!peers || typeof peers !== "object" || Array.isArray(peers)) return "";
  return String(peers[String(peerId || "")] || "").trim();
}

function challengeInboxOutcome(status, winnerId, ownerHash) {
  if (String(status || "") !== "completed") return null;
  const winner = String(winnerId || "");
  if (!winner) return "draw";
  return winner === ownerHash ? "won" : "lost";
}

/** listQuizChallenges: açık + 48s bitmiş sonuç; expired gizlenir. */
function shouldListChallengeInInbox(fresh, nowMs = Date.now()) {
  const status = String(fresh?.status || "");
  if (status === "expired") return false;
  if (challengeIsExpired(fresh, nowMs)) return false;
  if (status === "completed") {
    const finishedAt = _timestampMs(fresh.updatedAt) ||
      _timestampMs(fresh.completedAt) ||
      0;
    if (finishedAt > 0 && nowMs - finishedAt > CHALLENGE_INBOX_COMPLETED_MS) {
      return false;
    }
    return true;
  }
  return CHALLENGE_OPEN_STATUSES.has(status);
}

/** Meydan okuma push metinleri (tr/en/ar). */
function quizChallengeCopy(locale, kind, params = {}) {
  const lang = _validatedQuizLocale(locale);
  const name = String(params.name || "").slice(0, 32) || (
    lang === "tr" ? "Bir oyuncu" : lang === "ar" ? "لاعب" : "A player"
  );
  const copies = {
    invited: {
      tr: {
        title: "Bilgi Düellosu · Meydan okuma!",
        body: `${name} sana meydan okudu. 24 saatin var — 7 soru, 20 saniye.`,
      },
      en: {
        title: "Knowledge Duel · Challenge!",
        body: `${name} challenged you. You have 24 hours — 7 questions, 20 seconds.`,
      },
      ar: {
        title: "مبارزة المعرفة · تحدٍّ!",
        body: `${name} تحداك. أمامك 24 ساعة — 7 أسئلة، 20 ثانية.`,
      },
    },
    reminder: {
      tr: {
        title: "Bilgi Düellosu · Son 2 saat!",
        body: `${name} cevabını bekliyor. Süre dolarsa kimse puan alamaz.`,
      },
      en: {
        title: "Knowledge Duel · Last 2 hours!",
        body: `${name} is waiting for your answer. If time runs out, no one scores.`,
      },
      ar: {
        title: "مبارزة المعرفة · آخر ساعتين!",
        body: `${name} بانتظار إجابتك. إذا انتهى الوقت فلن يحصل أحد على نقاط.`,
      },
    },
    won: {
      tr: {
        title: "Bilgi Düellosu · Kazandın!",
        body: `${name} ile meydan okuma bitti — sen kazandın. Sonucu gör.`,
      },
      en: {
        title: "Knowledge Duel · You won!",
        body: `Your challenge with ${name} ended — you won. See the result.`,
      },
      ar: {
        title: "مبارزة المعرفة · فزت!",
        body: `انتهى التحدي مع ${name} — لقد فزت. شاهد النتيجة.`,
      },
    },
    lost: {
      tr: {
        title: "Bilgi Düellosu · Sonuç belli",
        body: `${name} ile meydan okuma bitti. Rövanş için hazır mısın?`,
      },
      en: {
        title: "Knowledge Duel · Result is in",
        body: `Your challenge with ${name} ended. Ready for a rematch?`,
      },
      ar: {
        title: "مبارزة المعرفة · النتيجة جاهزة",
        body: `انتهى التحدي مع ${name}. هل أنت مستعد للثأر؟`,
      },
    },
    draw: {
      tr: {
        title: "Bilgi Düellosu · Berabere!",
        body: `${name} ile meydan okuma berabere bitti. Sonucu gör.`,
      },
      en: {
        title: "Knowledge Duel · Draw!",
        body: `Your challenge with ${name} ended in a draw. See the result.`,
      },
      ar: {
        title: "مبارزة المعرفة · تعادل!",
        body: `انتهى التحدي مع ${name} بالتعادل. شاهد النتيجة.`,
      },
    },
  };
  const table = copies[kind] || copies.invited;
  return table[lang] || table.tr;
}

/** Erken gönderim istismarı: tur başlamadan cevap kabul edilmez. */
function canAcceptAnswer(nowMs, roundStartedAtMs, deadlineMs) {
  const start = Number(roundStartedAtMs) || 0;
  const deadline = Number(deadlineMs) || 0;
  const now = Number(nowMs) || 0;
  if (now < start) return { ok: false, reason: "not_started" };
  if (now > deadline + ANSWER_GRACE_MS) return { ok: false, reason: "expired" };
  return { ok: true, reason: "ok" };
}

/** Eksik cevaplar ancak grace bitince timeout'a çevrilir (submit ile aynı pencere). */
function shouldAutoTimeoutAnswers(nowMs, deadlineMs) {
  const deadline = Number(deadlineMs) || 0;
  const now = Number(nowMs) || 0;
  if (deadline <= 0) return false;
  return now > deadline + ANSWER_GRACE_MS;
}

function isTimeoutAnswer(answer) {
  if (!answer || typeof answer !== "object") return false;
  return !Number.isInteger(Number(answer.choice)) || Number(answer.choice) < 0;
}

/** Skor kaynağı: saklanan `correct` bayrağı değil, choice ≡ correctIndex. */
function isChoiceCorrect(choice, questionId) {
  const question = QUESTION_BY_ID.get(questionId);
  const index = Number(choice);
  return Boolean(question) &&
    Number.isInteger(index) &&
    index >= 0 &&
    index === question.correctIndex;
}

/** Poll'un yazdığı `choice: -1` grace içinde gerçek cevapla değiştirilebilir mi? */
function canReplaceTimeoutAnswer(existing, nowMs, roundStartedAtMs, deadlineMs) {
  if (!isTimeoutAnswer(existing)) return false;
  return canAcceptAnswer(nowMs, roundStartedAtMs, deadlineMs).ok;
}

function allPlayersAnswered(players, answers) {
  return Array.isArray(players) &&
    players.length === 2 &&
    players.every((player) => Boolean(answers?.[player.id]));
}

/** Firestore Timestamp / Date / epoch ms / {_seconds} → ms; yoksa 0. */
function _timestampMs(value) {
  if (value == null) return 0;
  if (typeof value.toMillis === "function") {
    const ms = Number(value.toMillis());
    return Number.isFinite(ms) ? ms : 0;
  }
  if (value instanceof Date) {
    const ms = value.getTime();
    return Number.isFinite(ms) ? ms : 0;
  }
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim() !== "") {
    const asNum = Number(value);
    if (Number.isFinite(asNum)) return asNum;
  }
  const seconds = Number(value._seconds ?? value.seconds);
  if (Number.isFinite(seconds)) {
    const nanos = Number(value._nanoseconds ?? value.nanoseconds) || 0;
    return seconds * 1000 + Math.floor(nanos / 1e6);
  }
  return 0;
}

function queueAbandonAtMs(queue) {
  const activeUntil = _timestampMs(queue?.activeUntil) ||
    Number(queue?.activeUntilMs) ||
    0;
  if (activeUntil > 0) return activeUntil;
  const queuedAt = _timestampMs(queue?.queuedAt) || Number(queue?.queuedAtMs) || 0;
  return queuedAt > 0 ? queuedAt + QUEUE_ABANDON_MS : 0;
}

/** Waiting kuyruk iade edilmeli mi? (TTL silmeden önce) */
function shouldRefundAbandonedQueue(queue, nowMs = Date.now()) {
  if (!queue || queue.status !== "waiting") return false;
  if (queue.refunded === true) return false;
  const heartSource = String(queue.heartSource || "");
  if (!heartSource || heartSource === "premium") return false;
  const abandonAt = queueAbandonAtMs(queue);
  return abandonAt > 0 && nowMs >= abandonAt;
}

function isAdFundedQueue(queue) {
  return queue?.status === "waiting" &&
    queue.heartSource === "ad" &&
    typeof queue.heartChargeId === "string" &&
    queue.heartChargeId.length > 0;
}

function isPremiumFundedQueue(queue) {
  return queue?.status === "waiting" &&
    queue.heartSource === "premium" &&
    !queue.heartChargeId;
}

function isFundedQueue(queue) {
  return isAdFundedQueue(queue) || isPremiumFundedQueue(queue);
}

function isValidChargedAdLedger(queue, charge) {
  const ownerHash = String(queue?.ownerHash || "").trim();
  return isAdFundedQueue(queue) &&
    ownerHash.length > 0 &&
    charge?.ownerHash === ownerHash &&
    charge?.heartSource === "ad" &&
    charge?.status === "charged";
}

function isValidQueueFunding(queue, charge = null) {
  return isPremiumFundedQueue(queue) ||
    isValidChargedAdLedger(queue, charge);
}

async function _isQueueFundingValidInTransaction(tx, db, queue) {
  if (isPremiumFundedQueue(queue)) return true;
  if (!isAdFundedQueue(queue)) return false;
  const chargeSnap = await tx.get(
    db.collection("quiz_heart_charges").doc(queue.heartChargeId),
  );
  return isValidChargedAdLedger(
    queue,
    chargeSnap.exists ? chargeSnap.data() : null,
  );
}

/** Saf/unit-test dostu iade kararı (FieldValue yok). */
function describeHeartRefund(heartSource) {
  if (heartSource === "ad") {
    return { type: "ad", incrementAdHearts: 1 };
  }
  if (heartSource === "free") {
    return { type: "free", clearFreeHeartUsedDay: true };
  }
  return { type: "none" };
}

function buildHeartRefundPlayerUpdates(heartSource) {
  const plan = describeHeartRefund(heartSource);
  if (plan.type === "ad") {
    return { adHearts: FieldValue.increment(1) };
  }
  if (plan.type === "free") {
    return { freeHeartUsedDay: FieldValue.delete() };
  }
  return {};
}

function _premiumRecordActive(data) {
  return premiumActiveAt(data, Date.now());
}

async function _isPremiumCaller(db, req) {
  const uid = String(req.auth?.uid || "");
  if (!uid) return false;
  const direct = await db.collection("premium_entitlements").doc(uid).get();
  if (_premiumRecordActive(direct.data())) return true;
  const email = String(req.auth?.token?.email || "").trim().toLowerCase();
  if (!email) return false;
  const invite = await db.collection("premium_invites").doc(email).get();
  return _premiumRecordActive(invite.data());
}

/**
 * Soft admin check for quiz callables (throws yok).
 * index.js `assertCallerIsAdmin` / firestore.rules ile aynı kaynaklar.
 */
const _QUIZ_FULL_ACCESS_EMAILS = new Set([
  "burakmelihkuzi@gmail.com",
  "brkkpl5@gmail.com",
  "seyirteknikerr@gmail.com",
]);

async function _quizCallerIsAdmin(db, req) {
  const auth = req.auth;
  if (!auth?.uid) return false;
  const email = String(auth.token?.email || "").trim().toLowerCase();
  if (email && _QUIZ_FULL_ACCESS_EMAILS.has(email)) return true;
  try {
    const userSnap = await db.collection("admin_users").doc(auth.uid).get();
    if (userSnap.exists) {
      const role = String(userSnap.data()?.role || "content").trim();
      if (["content", "manager", "developer"].includes(role)) return true;
    }
  } catch (err) {
    console.error("[HilalDuel] admin_users check failed", err);
  }
  if (!email) return false;
  try {
    const inviteSnap = await db.collection("admin_invites").doc(email).get();
    if (inviteSnap.exists) {
      const role = String(inviteSnap.data()?.role || "").trim();
      if (["content", "manager", "developer"].includes(role)) return true;
    }
  } catch (err) {
    console.error("[HilalDuel] admin_invites check failed", err);
  }
  return false;
}

/** ownerHash → aktif premium mi (entitlement veya invite). */
async function _premiumFlagsForOwnerHashes(db, ownerHashes) {
  const flags = new Map();
  const unique = [...new Set(
    ownerHashes.map((h) => String(h || "").trim().toLowerCase()).filter(Boolean),
  )];
  if (unique.length === 0) return flags;
  const installSnaps = await db.getAll(
    ...unique.map((h) => db.collection("quiz_installations").doc(h)),
  );
  const uidByHash = new Map();
  for (const snap of installSnaps) {
    if (!snap.exists) continue;
    const uid = String(snap.data()?.authUid || "").trim();
    if (!uid || uid.startsWith("quiz_")) continue;
    uidByHash.set(snap.id, uid);
  }
  const uniqueUids = [...new Set(uidByHash.values())];
  if (uniqueUids.length === 0) return flags;
  const entSnaps = await db.getAll(
    ...uniqueUids.map((uid) => db.collection("premium_entitlements").doc(uid)),
  );
  const premiumUids = new Set();
  const needInvite = [];
  for (let i = 0; i < uniqueUids.length; i += 1) {
    if (_premiumRecordActive(entSnaps[i].data())) {
      premiumUids.add(uniqueUids[i]);
    } else {
      needInvite.push(uniqueUids[i]);
    }
  }
  await Promise.all(needInvite.map(async (uid) => {
    try {
      const user = await getAuth().getUser(uid);
      const email = String(user.email || "").trim().toLowerCase();
      if (!email) return;
      const invite = await db.collection("premium_invites").doc(email).get();
      if (_premiumRecordActive(invite.data())) premiumUids.add(uid);
    } catch (_) {
      // Auth kullanıcısı yoksa premium değil say.
    }
  }));
  for (const [hash, uid] of uidByHash.entries()) {
    flags.set(hash, premiumUids.has(uid));
  }
  return flags;
}

function _publicProfile(ownerHash, data = {}) {
  const hilals = Math.floor(Number(data.hilals) || 0);
  const progression = levelForHilals(hilals);
  const cosmetics = cosmeticsForLevel(progression.level);
  const premium = data.premium === true;
  const adHearts = adHeartBalance(data);
  const weekId = String(data.weekId || weekIdIstanbul());
  const weeklyHilals = data.weekId === weekIdIstanbul()
    ? Math.floor(Number(data.weeklyHilals) || 0)
    : 0;
  return {
    ownerHash,
    name: String(data.name || "Arın Oyuncusu"),
    hilals,
    ...progression,
    ...cosmetics,
    weekId: weekIdIstanbul(),
    weeklyHilals,
    weeklyRank: Math.max(0, Math.floor(Number(data.weeklyRank) || 0)),
    hearts: premium ? 999 : adHearts,
    premium,
  };
}

function adHeartBalance(data = {}) {
  return Math.max(0, Math.floor(Number(data.adHearts) || 0));
}

function _quizIpHash(req) {
  const forwarded = String(req.rawRequest?.headers?.["x-forwarded-for"] || "");
  const ip = forwarded.split(",")[0].trim() ||
    String(req.rawRequest?.ip || "unknown");
  return _sha256(`quiz_ip:${ip}`);
}

function _quizWindowKey(nowMs = Date.now()) {
  return Math.floor(nowMs / RATE_WINDOW_MS);
}

async function _assertQuizWriteRate(db, key, scope, limit) {
  const windowKey = _quizWindowKey();
  const ref = db.collection("quiz_rate_limits")
    .doc(`${key}_${scope}_${windowKey}`);
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
      expiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60_000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

async function _assertQuizCallerRates(db, req, ownerHash, scope, limit) {
  const authKey = _sha256(`quiz_auth:${req.auth?.uid || "anon"}`);
  const ipHash = _quizIpHash(req);
  await Promise.all([
    _assertQuizWriteRate(db, authKey, `${scope}_auth`, limit),
    _assertQuizWriteRate(db, ownerHash, `${scope}_install`, limit),
    _assertQuizWriteRate(db, ipHash, `${scope}_ip`, limit * 3),
  ]);
}

async function _assertInstallation(db, req) {
  if (!req.auth?.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Hilal Düellosu için güvenli oturum gerekli.",
    );
  }
  const ownerHash = _validatedInstallHash(req.data?.installId);
  const bindingSecretHash = _validatedBindingSecretHash(req.data?.bindingSecret);
  const authUid = String(req.auth.uid);
  const claimed = String(req.auth.token?.quizInstallation || "");
  // Yalnızca quiz_* custom-token oturumları claim ile bağlanır.
  // Google/Apple (ve Dua Halkası prayer_* ) hesapları installId+binding ile bağlanır.
  if (authUid.startsWith("quiz_")) {
    if (
      claimed !== ownerHash ||
      authUid !== `quiz_${ownerHash.substring(0, 48)}`
    ) {
      throw new HttpsError("permission-denied", "Oturum kuruluma ait değil.");
    }
  } else if (claimed && claimed !== ownerHash) {
    throw new HttpsError("permission-denied", "Oturum kuruluma ait değil.");
  }
  const ref = db.collection("quiz_installations").doc(ownerHash);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const expiresAt = Timestamp.fromMillis(Date.now() + INSTALL_TTL_MS);
    // Dua Halkası gibi: Google/Apple ile gelen ilk çağrıda kurulum kaydı
    // createQuizSession olmadan da oluşturulabilir.
    if (!snap.exists) {
      tx.create(ref, {
        bindingSecretHash,
        authUid,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
      return;
    }
    const data = snap.data() || {};
    if (String(data.bindingSecretHash || "") !== bindingSecretHash) {
      throw new HttpsError("permission-denied", "Kurulum doğrulanamadı.");
    }
    const previousAuthUid = String(data.authUid || "");
    if (previousAuthUid && previousAuthUid !== authUid) {
      const previous = Array.isArray(data.previousAuthUids)
        ? data.previousAuthUids.filter((item) => typeof item === "string")
        : [];
      if (!previous.includes(previousAuthUid)) previous.push(previousAuthUid);
      tx.update(ref, {
        authUid,
        previousAuthUids: previous.slice(-8),
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
      return;
    }
    if (!previousAuthUid) {
      tx.update(ref, {
        authUid,
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    } else {
      tx.update(ref, {
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    }
  });
  return { ownerHash, authUid };
}

function normalizeQuestionIdList(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  const seen = new Set();
  for (const item of raw) {
    const id = String(item || "").trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
  }
  return out;
}

function mergeSeenQuestionIds(existing, added, cap = SEEN_QUESTION_IDS_CAP) {
  const safeCap = Math.max(ROUND_COUNT, Math.floor(Number(cap) || SEEN_QUESTION_IDS_CAP));
  const merged = normalizeQuestionIdList([
    ...normalizeQuestionIdList(existing),
    ...normalizeQuestionIdList(added),
  ]);
  if (merged.length <= safeCap) return merged;
  return merged.slice(merged.length - safeCap);
}

function _shuffleInPlace(list) {
  for (let i = list.length - 1; i > 0; i -= 1) {
    const j = crypto.randomInt(i + 1);
    const tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}

/**
 * Tek havuz: zorluk kotası / kolay→zor sıra yok.
 * excludeIds: bu oyuncunun (PvP'de her iki insanın) gördüğü sorular —
 * önce hiç çıkmayanlar, havuz bitince en eskiler tekrar eder.
 * Maç sırası karışık; chip için difficulty payload'da kalır.
 */
function _pickQuestions(excludeIds = []) {
  const excludeList = normalizeQuestionIdList(
    Array.isArray(excludeIds) ? excludeIds : [],
  );
  const exclude = new Set(excludeList);
  const unseen = [];
  const seenById = new Map();
  for (const item of questions) {
    const id = String(item?.id || "").trim();
    if (!id) continue;
    if (exclude.has(id)) seenById.set(id, item);
    else unseen.push(item);
  }
  _shuffleInPlace(unseen);
  const selected = unseen.slice(0, ROUND_COUNT);
  if (selected.length < ROUND_COUNT) {
    const used = new Set(selected.map((item) => item.id));
    const oldestFirst = [];
    for (const id of excludeList) {
      const item = seenById.get(id);
      if (!item || used.has(item.id)) continue;
      oldestFirst.push(item);
      used.add(item.id);
    }
    for (const item of seenById.values()) {
      if (used.has(item.id)) continue;
      oldestFirst.push(item);
      used.add(item.id);
    }
    selected.push(...oldestFirst.slice(0, ROUND_COUNT - selected.length));
  }
  _shuffleInPlace(selected);
  return selected.slice(0, ROUND_COUNT).map((item) => item.id);
}

/**
 * İnsan benzeri bot planı:
 * - Kolay (1): çoğu doğru, daha hızlı
 * - Orta (2): karışık
 * - Zor (3): sık yanılır, bilmeyince daha geç cevaplar
 * Seviye doğruluğu hafifçe kaydırır (şişirmez).
 */
function _botPlan(questionIds, playerLevel) {
  const level = Math.max(1, Math.floor(Number(playerLevel) || 1));
  const levelBoost = Math.min(0.08, (level - 1) * 0.01);
  return questionIds.map((questionId) => {
    const question = QUESTION_BY_ID.get(questionId);
    if (!question) {
      return { choice: 0, elapsedMs: crypto.randomInt(5_000, 12_000) };
    }
    const difficulty = [1, 2, 3].includes(question.difficulty)
      ? question.difficulty
      : 2;
    let accuracy;
    if (difficulty === 1) {
      accuracy = 0.93 + levelBoost * 0.4; // ~%93–96 kolay bilir
    } else if (difficulty === 2) {
      accuracy = 0.55 + levelBoost;
    } else {
      accuracy = 0.26 + levelBoost; // zor: çoğu zaman bilmez
    }
    accuracy = Math.min(0.97, Math.max(0.18, accuracy));
    const isCorrect = crypto.randomInt(10_000) < Math.round(accuracy * 10_000);
    let choice = question.correctIndex;
    if (!isCorrect) {
      const alternatives = [0, 1, 2, 3]
        .filter((index) => index !== question.correctIndex);
      choice = alternatives[crypto.randomInt(alternatives.length)];
    }
    let elapsedMs;
    if (difficulty === 1) {
      elapsedMs = isCorrect
        ? crypto.randomInt(2_800, 6_800)
        : crypto.randomInt(6_000, 11_500);
    } else if (difficulty === 2) {
      elapsedMs = isCorrect
        ? crypto.randomInt(4_200, 10_500)
        : crypto.randomInt(7_500, 14_500);
    } else {
      elapsedMs = isCorrect
        ? crypto.randomInt(6_500, 13_500)
        : crypto.randomInt(9_500, 17_800);
    }
    elapsedMs = Math.min(ROUND_DURATION_MS - 500, Math.max(2_200, elapsedMs));
    return { choice, elapsedMs };
  });
}

function _isChallengeBotOpponent(challenge) {
  return challenge?.challengedIsBot === true ||
    _isBotId(challenge?.challengedId);
}

/** Bot cevap penceresinin challenge TTL'sini ezmemesi için minimum deadline. */
function _challengeBotMinDeadlineMs(respondAfterMs, currentDeadlineMs) {
  const respondAfter = Math.floor(Number(respondAfterMs) || 0);
  const minDeadline = respondAfter + 5 * 60_000;
  const current = Math.floor(Number(currentDeadlineMs) || 0);
  return current > 0 && current >= minDeadline ? current : minDeadline;
}

/**
 * Admin otomatik meydan okuma: 7 sorudan rastgele 3–5 doğru, kalanı yanlış.
 * Karşı tarafı kışkırtmak için inandırıcı ama ezici olmayan skor.
 */
function _adminChallengeAutoPlan(questionIds) {
  const ids = Array.isArray(questionIds) ? questionIds : [];
  if (ids.length === 0) return [];
  const wantCorrect = Math.min(ids.length, 3 + crypto.randomInt(3));
  const order = ids.map((_, index) => index);
  for (let i = order.length - 1; i > 0; i -= 1) {
    const j = crypto.randomInt(i + 1);
    const swap = order[i];
    order[i] = order[j];
    order[j] = swap;
  }
  const correctRounds = new Set(order.slice(0, wantCorrect));
  return ids.map((questionId, index) => {
    const question = QUESTION_BY_ID.get(questionId);
    const correctIndex = Number.isInteger(question?.correctIndex)
      ? question.correctIndex
      : 0;
    const isCorrect = correctRounds.has(index);
    let choice = correctIndex;
    if (!isCorrect) {
      const alternatives = [0, 1, 2, 3].filter((i) => i !== correctIndex);
      choice = alternatives.length > 0
        ? alternatives[crypto.randomInt(alternatives.length)]
        : (correctIndex + 1) % 4;
    }
    const elapsedMs = isCorrect
      ? crypto.randomInt(3_500, 12_000)
      : crypto.randomInt(6_000, 16_000);
    return {
      choice,
      elapsedMs: Math.min(ROUND_DURATION_MS - 500, Math.max(2_200, elapsedMs)),
      correct: isCorrect,
    };
  });
}

function _applyAdminAutoChallengeToDoc(doc, ownerHash, nowMs) {
  const plan = _adminChallengeAutoPlan(doc.questionIds);
  const answers = {};
  for (let round = 0; round < ROUND_COUNT; round += 1) {
    const step = plan[round] || {
      choice: -1,
      elapsedMs: ROUND_DURATION_MS,
      correct: false,
    };
    answers[String(round)] = {
      [ownerHash]: {
        choice: step.choice,
        elapsedMs: step.elapsedMs,
        correct: step.correct === true,
      },
    };
  }
  const last = plan[ROUND_COUNT - 1] || { choice: -1, elapsedMs: 0 };
  doc.answers = answers;
  doc.status = "awaiting_opponent";
  doc.activePlayerId = null;
  doc.currentRound = 0;
  doc.roundStartedAtMs = 0;
  doc.deadlineMs = 0;
  doc.adminAutoPlay = true;
  doc.invitedPushSent = true;
  doc.lastResolution = {
    round: ROUND_COUNT - 1,
    choices: { [ownerHash]: last.choice },
    elapsedMs: { [ownerHash]: last.elapsedMs },
  };
  if (_isChallengeBotOpponent(doc)) {
    const respondAfter = nowMs + CHALLENGE_BOT_DELAY_MS;
    doc.botRespondAfterMs = respondAfter;
    const nextDeadline = _challengeBotMinDeadlineMs(
      respondAfter,
      doc.challengeDeadlineMs,
    );
    if (nextDeadline !== Number(doc.challengeDeadlineMs)) {
      doc.challengeDeadlineMs = nextDeadline;
    }
  }
  return {
    answers: doc.answers,
    status: doc.status,
    activePlayerId: FieldValue.delete(),
    currentRound: 0,
    roundStartedAtMs: 0,
    deadlineMs: 0,
    adminAutoPlay: true,
    invitedPushSent: true,
    lastResolution: doc.lastResolution,
    updatedAt: Timestamp.fromMillis(nowMs),
    ...(doc.botRespondAfterMs
      ? {
        botRespondAfterMs: doc.botRespondAfterMs,
        challengeDeadlineMs: doc.challengeDeadlineMs,
      }
      : {}),
  };
}

/**
 * Meydan okuma bot cevabı: tur başına tam 1 doğru, geri kalanı yanlış.
 * Canlı eşleşmedeki botlardan bilinçli olarak daha zayıf.
 */
function _challengeBotWeakPlan(questionIds) {
  const ids = Array.isArray(questionIds) ? questionIds : [];
  if (ids.length === 0) return [];
  const correctRound = crypto.randomInt(ids.length);
  return ids.map((questionId, index) => {
    const question = QUESTION_BY_ID.get(questionId);
    const correctIndex = Number.isInteger(question?.correctIndex)
      ? question.correctIndex
      : 0;
    const isCorrect = index === correctRound;
    let choice = correctIndex;
    if (!isCorrect) {
      const alternatives = [0, 1, 2, 3].filter((i) => i !== correctIndex);
      choice = alternatives.length > 0
        ? alternatives[crypto.randomInt(alternatives.length)]
        : (correctIndex + 1) % 4;
    }
    const elapsedMs = isCorrect
      ? crypto.randomInt(4_000, 11_000)
      : crypto.randomInt(7_000, 16_000);
    return {
      choice,
      elapsedMs: Math.min(ROUND_DURATION_MS - 500, Math.max(2_200, elapsedMs)),
      correct: isCorrect,
    };
  });
}

/**
 * Bot cevabı zamanı.
 * İnsan yokken planlanan süreyi bekler.
 * İnsan cevapladıysa aynı istekte yazılır — yoksa "Cevapladı" görünüp reveal
 * için 1–5 sn poll bekleniyordu.
 */
function _botReadyAtMs({
  roundStartedAtMs,
  plannedElapsedMs,
  deadlineMs,
  nowMs,
  humanAnswered,
  humanElapsedMs,
}) {
  const start = Math.max(0, Math.floor(Number(roundStartedAtMs) || 0));
  const planned = start + Math.max(0, Math.floor(Number(plannedElapsedMs) || 8_000));
  const deadline = Math.max(
    start + 1_000,
    Math.floor(Number(deadlineMs) || (start + ROUND_DURATION_MS)),
  );
  const now = Math.max(0, Math.floor(Number(nowMs) || 0));
  if (!humanAnswered) {
    return Math.min(planned, deadline - 200);
  }
  // humanElapsedMs API uyumu için kalır; submit anında tur çözülsün.
  return Math.min(now, deadline - 200);
}

/** Bot elapsedMs: erken resolve'da plan; zamanında cevapta duvar saati tavanı. */
function _botAnswerElapsedMs({
  planElapsedMs,
  nowMs,
  roundStartedAtMs,
  humanAnswered,
}) {
  const planned = Math.min(
    ROUND_DURATION_MS,
    Math.max(800, Math.floor(Number(planElapsedMs) || ROUND_DURATION_MS)),
  );
  if (humanAnswered) return planned;
  const roundStart = Math.max(0, Math.floor(Number(roundStartedAtMs) || 0));
  const wall = Math.max(0, Math.floor(Number(nowMs) || 0) - roundStart);
  return Math.min(ROUND_DURATION_MS, Math.max(800, Math.min(planned, wall || planned)));
}

function _questionPayload(questionId, includeAnswer = false, locale = "tr") {
  const question = QUESTION_BY_ID.get(questionId);
  if (!question) throw new Error(`Question not found: ${questionId}`);
  const lang = _validatedQuizLocale(locale);
  const ar = lang === "ar" ? QUESTION_AR_BY_ID.get(questionId) : null;
  const pick = (field) => {
    if (ar && ar[field] != null && String(ar[field]).length > 0) return ar[field];
    return question[field];
  };
  return {
    id: question.id,
    category: pick("category"),
    difficulty: [1, 2, 3].includes(question.difficulty) ? question.difficulty : 2,
    question: pick("question"),
    options: pick("options"),
    ...(includeAnswer
      ? {
          correctIndex: question.correctIndex,
          explanation: pick("explanation"),
          source: pick("source"),
        }
      : {}),
  };
}

function _answerFor(match, round, ownerHash) {
  return match.answers?.[String(round)]?.[ownerHash] || null;
}

function _nextVersion(match) {
  return Math.max(0, Math.floor(Number(match.version) || 0)) + 1;
}

/**
 * lastResolution.choices → bakış açısına göre sabit alanlar.
 * Yok = null (challenge solo / henüz cevap yok).
 * Timeout = -1. Geçerli şık = 0..3.
 */
function _perspectiveResolutionChoices(lastResolution, ownerHash, opponentId) {
  const raw = lastResolution?.choices && typeof lastResolution.choices === "object"
    ? lastResolution.choices
    : {};
  const read = (id) => {
    if (id == null || id === "") return null;
    if (!Object.prototype.hasOwnProperty.call(raw, id)) return null;
    const value = Number(raw[id]);
    return Number.isInteger(value) ? value : null;
  };
  return {
    selfChoice: read(ownerHash),
    opponentChoice: read(opponentId),
  };
}

function _serializeLastResolution(
  match,
  lastResolution,
  ownerHash,
  opponentId,
  locale = "tr",
) {
  if (!lastResolution) return null;
  const perspective = _perspectiveResolutionChoices(
    lastResolution,
    ownerHash,
    opponentId,
  );
  return {
    round: Number(lastResolution.round) || 0,
    // Ham map (geriye uyumluluk) + bakış açısı alanları.
    choices: lastResolution.choices || {},
    elapsedMs: lastResolution.elapsedMs || {},
    selfChoice: perspective.selfChoice,
    opponentChoice: perspective.opponentChoice,
    question: _questionPayload(
      match.questionIds[lastResolution.round],
      true,
      locale,
    ),
  };
}

function _serializeMatch(matchId, match, ownerHash, locale = "tr") {
  const selfIndex = match.players.findIndex((player) => player.id === ownerHash);
  if (selfIndex < 0) {
    throw new HttpsError("permission-denied", "Bu karşılaşmaya erişemezsiniz.");
  }
  const opponentIndex = selfIndex === 0 ? 1 : 0;
  const opponentId = match.players[opponentIndex].id;
  const currentRound = Math.min(
    Math.max(0, Number(match.currentRound) || 0),
    ROUND_COUNT - 1,
  );
  const selfAnswer = _answerFor(match, currentRound, ownerHash);
  const opponentAnswer = _answerFor(match, currentRound, opponentId);
  const lastResolution = match.lastResolution || null;
  return {
    id: matchId,
    status: match.status,
    version: Math.max(0, Math.floor(Number(match.version) || 0)),
    currentRound,
    totalRounds: ROUND_COUNT,
    roundStartedAtMs: Number(match.roundStartedAtMs) || 0,
    deadlineMs: Number(match.deadlineMs) || 0,
    self: _decoratePlayer(match.players[selfIndex]),
    opponent: _decoratePlayer(match.players[opponentIndex]),
    question: match.status === "completed"
      ? null
      : _questionPayload(match.questionIds[currentRound], false, locale),
    selfAnswered: Boolean(selfAnswer),
    opponentAnswered: Boolean(opponentAnswer),
    doubled: match.doubledBy?.[ownerHash] === true,
    lastResolution: _serializeLastResolution(
      match,
      lastResolution,
      ownerHash,
      opponentId,
      locale,
    ),
    result: match.result || null,
  };
}

function _idleQueuePatch(nowMs = Date.now()) {
  return {
    status: "idle",
    matchId: FieldValue.delete(),
    heartSource: FieldValue.delete(),
    heartChargeId: FieldValue.delete(),
    activeUntil: FieldValue.delete(),
    refunded: true,
    updatedAt: Timestamp.fromMillis(nowMs),
    expiresAt: Timestamp.fromMillis(nowMs + QUEUE_IDLE_TTL_MS),
  };
}

/**
 * Tek seferlik can iadesi. heartChargeId ledger üzerinden idempotent.
 * Transaction içinde çağrılmalıdır; charge + player + queue okumaları tx'de olmalı.
 */
async function _refundQueueHeartInTransaction(tx, db, {
  queueRef,
  queue,
  playerRef,
  nowMs = Date.now(),
}) {
  if (!queue || queue.status !== "waiting") {
    return { refunded: false, reason: "not_waiting" };
  }
  if (queue.refunded === true) {
    tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
    return { refunded: false, reason: "already_refunded_flag" };
  }
  const heartSource = String(queue.heartSource || "");
  const heartChargeId = String(queue.heartChargeId || "").trim();
  if (!heartSource || heartSource === "premium") {
    tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
    return { refunded: false, reason: "no_charge" };
  }
  if (!heartChargeId) {
    // Ledger'sız reklam kuyruğu kanıtlanamaz; adHearts üretme. Eski ücretsiz
    // kuyrukta yalnız artık kullanılmayan günlük alan temizlenebilir.
    const playerUpdates = heartSource === "free"
      ? buildHeartRefundPlayerUpdates(heartSource)
      : {};
    if (Object.keys(playerUpdates).length > 0) {
      tx.set(playerRef, {
        ...playerUpdates,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
    return { refunded: false, reason: "missing_charge_ledger" };
  }

  const chargeRef = db.collection("quiz_heart_charges").doc(heartChargeId);
  const chargeSnap = await tx.get(chargeRef);
  const charge = chargeSnap.data() || {};
  const chargeStatus = String(charge.status || "");
  if (chargeStatus === "refunded" || chargeStatus === "consumed_by_match") {
    tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
    return { refunded: false, reason: "charge_locked" };
  }
  const expectedOwner = String(queue.ownerHash || queueRef.id);
  if (
    !chargeSnap.exists ||
    chargeStatus !== "charged" ||
    charge.ownerHash !== expectedOwner ||
    charge.heartSource !== heartSource
  ) {
    tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
    return { refunded: false, reason: "invalid_charge_ledger" };
  }
  const playerUpdates = buildHeartRefundPlayerUpdates(heartSource);
  if (Object.keys(playerUpdates).length > 0) {
    tx.set(playerRef, {
      ...playerUpdates,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  tx.set(chargeRef, {
    ownerHash: queue.ownerHash || queueRef.id,
    heartSource,
    status: "refunded",
    refundedAt: FieldValue.serverTimestamp(),
    createdAt: charge.createdAt || FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(nowMs + 30 * 86400000),
  }, { merge: true });
  tx.set(queueRef, _idleQueuePatch(nowMs), { merge: true });
  return { refunded: true, reason: "refunded", heartSource };
}

async function _createMatchInTransaction({
  tx,
  db,
  firstQueue,
  secondQueue,
  bot = false,
  ownerHashOverride = null,
  chargeRecordsPreRead = null,
}) {
  const firstOwner = String(
    ownerHashOverride || firstQueue.ownerHash || "",
  ).trim();
  if (!firstOwner) {
    throw new HttpsError("failed-precondition", "Kuyruk sahibi eksik.");
  }
  const firstHilals = Math.max(0, Math.floor(Number(firstQueue.hilals) || 0));
  const firstLevel = Math.max(1, Math.floor(Number(firstQueue.level) || 1));
  const matchId = crypto.randomBytes(16).toString("hex");
  const matchRef = db.collection("quiz_matches").doc(matchId);
  const nowMs = Date.now();
  const queuesForCharges = bot ? [firstQueue] : [firstQueue, secondQueue];
  const firstPlayer = {
    id: firstOwner,
    name: String(firstQueue.name || "Arın Oyuncusu").slice(0, 32),
    hilals: firstHilals,
    level: firstLevel,
    isBot: false,
  };
  const secondPlayer = bot
    ? (() => {
      const botName = _botDisplayName(
        BOT_NAMES[crypto.randomInt(BOT_NAMES.length)],
      );
      return {
        id: _stableBotId(botName),
        name: botName,
        hilals: Math.max(0, firstHilals + crypto.randomInt(-20, 21)),
        level: Math.max(1, Math.min(3, firstLevel + crypto.randomInt(-1, 2))),
        isBot: true,
      };
    })()
    : {
        id: String(secondQueue.ownerHash || "").trim(),
        name: String(secondQueue.name || "Arın Oyuncusu").slice(0, 32),
        hilals: Math.max(0, Math.floor(Number(secondQueue.hilals) || 0)),
        level: Math.max(1, Math.floor(Number(secondQueue.level) || 1)),
        isBot: false,
      };
  if (!secondPlayer.id) {
    throw new HttpsError("failed-precondition", "Rakip kimliği eksik.");
  }
  const firstPlayerRef = db.collection("quiz_players").doc(firstOwner);
  const secondPlayerRef = secondPlayer.isBot
    ? null
    : db.collection("quiz_players").doc(secondPlayer.id);
  // Firestore tx: tüm okumalar yazmalardan önce.
  const chargeRefs = [];
  for (const queue of queuesForCharges) {
    if (isPremiumFundedQueue(queue)) continue;
    const chargeId = String(queue?.heartChargeId || "").trim();
    if (!chargeId) {
      throw new HttpsError("failed-precondition", "Can harcama kaydı eksik.");
    }
    const ref = db.collection("quiz_heart_charges").doc(chargeId);
    let charge = chargeRecordsPreRead?.get(chargeId);
    if (charge == null) {
      const snap = await tx.get(ref);
      charge = snap.exists ? snap.data() : null;
    }
    if (!isValidChargedAdLedger(queue, charge)) {
      throw new HttpsError("failed-precondition", "Can harcama kaydı geçersiz.");
    }
    chargeRefs.push(ref);
  }
  const firstPlayerSnap = await tx.get(firstPlayerRef);
  const secondPlayerSnap = secondPlayerRef
    ? await tx.get(secondPlayerRef)
    : null;
  const questionIds = _pickQuestions([
    ...normalizeQuestionIdList(firstPlayerSnap.data()?.seenQuestionIds),
    ...normalizeQuestionIdList(secondPlayerSnap?.data()?.seenQuestionIds),
  ]);
  const match = {
    players: [firstPlayer, secondPlayer],
    questionIds,
    currentRound: 0,
    roundStartedAtMs: nowMs,
    deadlineMs: nowMs + ROUND_DURATION_MS,
    answers: {},
    lastResolution: null,
    status: "playing",
    version: 1,
    botPlan: bot ? _botPlan(questionIds, firstLevel) : null,
    createdAt: Timestamp.fromMillis(nowMs),
    updatedAt: Timestamp.fromMillis(nowMs),
    expiresAt: Timestamp.fromMillis(nowMs + MATCH_EXPIRY_MS),
  };
  tx.create(matchRef, match);
  const matchedQueue = {
    status: "matched",
    matchId,
    // Maçta can tüketildi; iade edilmez.
    refunded: true,
    heartSource: FieldValue.delete(),
    heartChargeId: FieldValue.delete(),
    activeUntil: FieldValue.delete(),
    updatedAt: Timestamp.fromMillis(nowMs),
    expiresAt: Timestamp.fromMillis(nowMs + QUEUE_IDLE_TTL_MS),
  };
  tx.set(
    db.collection("quiz_queue").doc(firstOwner),
    matchedQueue,
    { merge: true },
  );
  if (!bot) {
    tx.set(
      db.collection("quiz_queue").doc(secondPlayer.id),
      matchedQueue,
      { merge: true },
    );
  }
  for (const chargeRef of chargeRefs) {
    tx.set(chargeRef, {
      status: "consumed_by_match",
      matchId,
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(nowMs + 30 * 86400000),
    }, { merge: true });
  }
  tx.set(firstPlayerRef, {
    seenQuestionIds: mergeSeenQuestionIds(
      firstPlayerSnap.data()?.seenQuestionIds,
      questionIds,
    ),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (secondPlayerRef) {
    tx.set(secondPlayerRef, {
      seenQuestionIds: mergeSeenQuestionIds(
        secondPlayerSnap.data()?.seenQuestionIds,
        questionIds,
      ),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  return { matchId, match };
}

function _matchPlayerStats(match) {
  return match.players.map((player) => {
    let correct = 0;
    let elapsedMs = 0;
    for (let round = 0; round < ROUND_COUNT; round += 1) {
      const answer = _answerFor(match, round, player.id);
      if (!answer) {
        elapsedMs += ROUND_DURATION_MS;
        continue;
      }
      if (isChoiceCorrect(answer.choice, match.questionIds?.[round])) {
        correct += 1;
      }
      elapsedMs += Number(answer.elapsedMs) || 0;
    }
    return { id: player.id, correct, elapsedMs };
  });
}

async function _completeMatch(tx, db, matchRef, match, options = {}) {
  if (match.completedAwarded === true) {
    match.status = "completed";
    return;
  }
  const forfeitBy = options.forfeitBy ? String(options.forfeitBy) : null;
  const stats = _matchPlayerStats(match);
  let winnerId = null;
  if (forfeitBy) {
    const remaining = match.players.find((player) => player.id !== forfeitBy);
    winnerId = remaining ? remaining.id : null;
  } else {
    const outcome = determineWinner(stats[0], stats[1]);
    winnerId = outcome === "a"
      ? stats[0].id
      : outcome === "b"
        ? stats[1].id
        : null;
  }

  const weekId = weekIdIstanbul();
  const humans = match.players.filter((player) => !player.isBot);
  const bots = match.players.filter((player) => player.isBot === true);
  const playerRefs = humans.map((player) =>
    db.collection("quiz_players").doc(player.id)
  );
  const humanWeeklyRefs = humans.map((player) =>
    _weeklyEntryRef(db, weekId, player.id)
  );
  const botWeeklyRefs = bots.map((player) =>
    _weeklyEntryRef(db, weekId, player.id)
  );
  // Firestore: tüm okumalar yazmalardan önce.
  const playerSnaps = [];
  const humanWeeklySnaps = [];
  const botWeeklySnaps = [];
  for (const ref of playerRefs) playerSnaps.push(await tx.get(ref));
  for (const ref of humanWeeklyRefs) humanWeeklySnaps.push(await tx.get(ref));
  for (const ref of botWeeklyRefs) botWeeklySnaps.push(await tx.get(ref));

  const awards = {};
  for (let index = 0; index < match.players.length; index += 1) {
    const player = match.players[index];
    const stat = stats[index];
    if (forfeitBy && player.id === forfeitBy) {
      awards[player.id] = -FORFEIT_PENALTY;
      continue;
    }
    const award = hilalAward(
      stat.correct,
      winnerId === player.id,
      !forfeitBy && winnerId == null,
    );
    awards[player.id] = award;
  }

  for (let h = 0; h < humans.length; h += 1) {
    const player = humans[h];
    const delta = awards[player.id] || 0;
    _writeHilalDelta(tx, {
      playerRef: playerRefs[h],
      weeklyRef: humanWeeklyRefs[h],
      playerSnap: playerSnaps[h],
      weeklySnap: humanWeeklySnaps[h],
      delta,
      name: player.name,
      weekId,
      matchesCompletedInc: 1,
    });
  }
  for (let b = 0; b < bots.length; b += 1) {
    const player = bots[b];
    _writeBotWeeklyDelta(tx, {
      weeklyRef: botWeeklyRefs[b],
      weeklySnap: botWeeklySnaps[b],
      delta: Math.max(0, awards[player.id] || 0),
      name: player.name,
      level: player.level,
      botId: player.id,
    });
  }

  match.status = "completed";
  match.completedAwarded = true;
  match.top3RivalryPending = true;
  match.version = _nextVersion(match);
  match.result = {
    winnerId,
    forfeitBy,
    players: stats.map((stat) => ({
      ...stat,
      hilalsAwarded: awards[stat.id],
    })),
  };
  match.updatedAt = Timestamp.now();
  tx.set(matchRef, {
    status: match.status,
    result: match.result,
    completedAwarded: true,
    top3RivalryPending: true,
    version: match.version,
    updatedAt: match.updatedAt,
  }, { merge: true });
  for (const player of match.players) {
    if (player.isBot) continue;
    tx.set(
      db.collection("quiz_queue").doc(player.id),
      _idleQueuePatch(Date.now()),
      { merge: true },
    );
  }
}

async function _resolveRoundIfReady(tx, db, matchRef, match, nowMs) {
  if (match.status !== "playing") return;
  const round = Number(match.currentRound) || 0;
  const key = String(round);
  const answers = { ...(match.answers?.[key] || {}) };
  const bot = match.players.find((player) => player.isBot);
  const humanAnswered = match.players.some(
    (player) => !player.isBot && Boolean(answers[player.id]),
  );
  if (bot && !answers[bot.id]) {
    const plan = match.botPlan?.[round];
    if (plan) {
      const human = match.players.find((player) => !player.isBot);
      const humanElapsedMs = human && answers[human.id]
        ? Number(answers[human.id].elapsedMs) || 0
        : 0;
      const dueAt = _botReadyAtMs({
        roundStartedAtMs: match.roundStartedAtMs,
        plannedElapsedMs: plan.elapsedMs,
        deadlineMs: match.deadlineMs,
        nowMs,
        humanAnswered,
        humanElapsedMs,
      });
      if (nowMs >= dueAt) {
        const question = QUESTION_BY_ID.get(match.questionIds[round]);
        // İnsan erken bitirdiyse bot hemen yazılır ama skor için planlanan süre kalır
        // (hiz beraberliğinde insan haksız yere kaybetmesin).
        const elapsedMs = _botAnswerElapsedMs({
          planElapsedMs: plan.elapsedMs,
          nowMs,
          roundStartedAtMs: match.roundStartedAtMs,
          humanAnswered,
        });
        answers[bot.id] = {
          choice: plan.choice,
          elapsedMs,
          correct: plan.choice === question.correctIndex,
        };
      }
    }
  }
  if (shouldAutoTimeoutAnswers(nowMs, match.deadlineMs)) {
    for (const player of match.players) {
      if (!answers[player.id]) {
        answers[player.id] = {
          choice: -1,
          elapsedMs: ROUND_DURATION_MS,
          correct: false,
        };
      }
    }
  }
  // Süreyi bekleme: iki oyuncunun cevabı geldiği anda tur çözülür.
  if (allPlayersAnswered(match.players, answers)) {
    match.answers = { ...(match.answers || {}), [key]: answers };
    match.lastResolution = {
      round,
      choices: {
        [match.players[0].id]: answers[match.players[0].id].choice,
        [match.players[1].id]: answers[match.players[1].id].choice,
      },
      elapsedMs: {
        [match.players[0].id]: answers[match.players[0].id].elapsedMs,
        [match.players[1].id]: answers[match.players[1].id].elapsedMs,
      },
    };
    match.version = _nextVersion(match);
    if (round >= ROUND_COUNT - 1) {
      await _completeMatch(tx, db, matchRef, match);
      tx.set(matchRef, {
        answers: match.answers,
        lastResolution: match.lastResolution,
        version: match.version,
      }, { merge: true });
      return;
    }
    match.currentRound = round + 1;
    // İstemci ~ROUND_REVEAL_MS reveal gösterir; süre o bitince 20'den başlasın.
    // Erken submit istemcide retry edilir; butonlar roundStartedAtMs ile kilitlenmez.
    match.roundStartedAtMs = nowMs + ROUND_REVEAL_MS;
    match.deadlineMs = match.roundStartedAtMs + ROUND_DURATION_MS;
    tx.set(matchRef, {
      answers: match.answers,
      lastResolution: match.lastResolution,
      currentRound: match.currentRound,
      roundStartedAtMs: match.roundStartedAtMs,
      deadlineMs: match.deadlineMs,
      version: match.version,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  } else if (Object.keys(answers).length > 0) {
    match.answers = { ...(match.answers || {}), [key]: answers };
    match.version = _nextVersion(match);
    tx.set(matchRef, {
      [`answers.${key}`]: answers,
      version: match.version,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
}

function _queueStatusPayload(queue) {
  if (!queue) return { status: "idle" };
  if (queue.status === "matched" && queue.matchId) {
    return { status: "matched", matchId: String(queue.matchId) };
  }
  if (queue.status === "waiting") {
    const queuedAtMs = _timestampMs(queue.queuedAt) || Date.now();
    return {
      status: "waiting",
      queuedAtMs,
    };
  }
  return { status: "idle" };
}

const createQuizSession = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const ownerHash = _validatedInstallHash(req.data?.installId);
    const bindingSecretHash = _validatedBindingSecretHash(req.data?.bindingSecret);
    const db = getFirestore();
    await _assertQuizWriteRate(db, ownerHash, "session_install", 10);
    await _assertQuizWriteRate(db, _quizIpHash(req), "session_ip", 40);
    const ref = db.collection("quiz_installations").doc(ownerHash);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const expiresAt = Timestamp.fromMillis(Date.now() + INSTALL_TTL_MS);
      if (!snap.exists) {
        tx.create(ref, {
          bindingSecretHash,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          expiresAt,
        });
        return;
      }
      if (snap.data()?.bindingSecretHash !== bindingSecretHash) {
        throw new HttpsError("permission-denied", "Kurulum doğrulanamadı.");
      }
      tx.update(ref, {
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    });
    const customToken = await getAuth().createCustomToken(
      `quiz_${ownerHash.substring(0, 48)}`,
      { quizInstallation: ownerHash },
    );
    return { ok: true, customToken };
  },
);

const getQuizProfile = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "profile", 40);
    const name = _validatedName(req.data?.name);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const queueRef = db.collection("quiz_queue").doc(ownerHash);

    // Claim-on-reentry: terk edilmiş waiting kuyruğu iade et.
    await db.runTransaction(async (tx) => {
      const queueSnap = await tx.get(queueRef);
      const queue = queueSnap.data() || null;
      const fundingValid = queue?.status === "waiting"
        ? await _isQueueFundingValidInTransaction(tx, db, queue)
        : true;
      if (
        shouldRefundAbandonedQueue(queue, Date.now()) ||
        (queue?.status === "waiting" && !fundingValid)
      ) {
        await _refundQueueHeartInTransaction(tx, db, {
          queueRef,
          queue,
          playerRef,
        });
      }
    });

    const promoRef = db
      .collection(PROMO_HEARTS_COLLECTION)
      .doc(PROMO_HEARTS_DOC);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(playerRef);
      const promoSnap = await tx.get(promoRef);
      const promoSeq = Math.floor(Number(promoSnap.data()?.seq) || 0);
      const promoAmount = Math.max(0, Math.floor(Number(promoSnap.data()?.amount) || 0));
      if (!snap.exists) {
        const gift = pendingPromoHeartsGain({
          claimedSeq: 0,
          promoSeq,
          amount: promoAmount,
        });
        tx.create(playerRef, {
          name,
          hilals: 0,
          adHearts: gift,
          claimedPromoHeartSeq: promoSeq > 0 ? promoSeq : 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }
      const data = snap.data() || {};
      const claimed = Math.floor(Number(data.claimedPromoHeartSeq) || 0);
      const gift = pendingPromoHeartsGain({
        claimedSeq: claimed,
        promoSeq,
        amount: promoAmount,
      });
      const patch = {
        name,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (gift > 0) {
        patch.adHearts = FieldValue.increment(gift);
        patch.claimedPromoHeartSeq = promoSeq;
      }
      tx.update(playerRef, patch);
    });
    const [snap, queueSnap] = await Promise.all([
      playerRef.get(),
      queueRef.get(),
    ]);
    let queuePayload = _queueStatusPayload(queueSnap.data());
    if (queuePayload.status === "matched" && queuePayload.matchId) {
      const matchSnap = await db.collection("quiz_matches")
        .doc(queuePayload.matchId)
        .get();
      if (!matchSnap.exists || matchSnap.data()?.status !== "playing") {
        queuePayload = { status: "idle" };
      }
    }
    const weekId = weekIdIstanbul();
    const playerData = snap.data() || {};
    const weeklyHilals = playerData.weekId === weekId
      ? Math.floor(Number(playerData.weeklyHilals) || 0)
      : 0;
    let weeklyRank = 0;
    if (weeklyHilals !== 0 || playerData.weekId === weekId) {
      weeklyRank = await _computeWeeklyRank(db, weekId, ownerHash, weeklyHilals);
    }
    const matchesCompleted = Math.floor(Number(playerData.matchesCompleted) || 0);
    if (matchesCompleted >= 1 && weeklyRank > 0) {
      const rankPatch = _bestWeeklyRankPatch(playerData, weekId, weeklyRank);
      if (rankPatch) {
        await playerRef.set(rankPatch, { merge: true });
      }
    }
    return {
      ok: true,
      profile: _publicProfile(ownerHash, {
        ...playerData,
        weekId,
        weeklyHilals,
        weeklyRank,
        premium: await _isPremiumCaller(db, req),
      }),
      queue: queuePayload,
    };
  },
);

const beginQuizReward = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash, authUid } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "begin_reward", 15);
    const purpose = req.data?.purpose === "double" ? "double" : "heart";
    const matchId = purpose === "double"
      ? _validatedDocumentId(req.data?.matchId, "karşılaşma")
      : null;
    if (matchId) {
      const match = await db.collection("quiz_matches").doc(matchId).get();
      if (
        !match.exists ||
        match.data()?.status !== "completed" ||
        !match.data()?.players?.some((player) => player.id === ownerHash)
      ) {
        throw new HttpsError("failed-precondition", "Karşılaşma tamamlanmadı.");
      }
      if (match.data()?.doubledBy?.[ownerHash] === true) {
        throw new HttpsError("already-exists", "Bu ödül zaten ikiye katlandı.");
      }
    }
    const proofRef = db.collection("quiz_reward_proofs").doc();
    const expiresAtMs = Date.now() + REWARD_PROOF_TTL_MS;
    await proofRef.set({
      ownerHash,
      authUid,
      purpose,
      matchId,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(expiresAtMs),
    });
    const customData = Buffer.from(JSON.stringify({
      version: 2,
      kind: "quiz",
      proofId: proofRef.id,
    }), "utf8").toString("base64url");
    return { ok: true, proofId: proofRef.id, customData, expiresAtMs };
  },
);

const claimQuizReward = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash, authUid } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "claim_reward", 20);
    const proofId = _validatedProofId(req.data?.proofId);
    const proofRef = db.collection("quiz_reward_proofs").doc(proofId);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const outcome = await db.runTransaction(async (tx) => {
      const proofSnap = await tx.get(proofRef);
      if (!proofSnap.exists) {
        throw new HttpsError("not-found", "Reklam ödülü bulunamadı.");
      }
      const proof = proofSnap.data() || {};
      if (proof.ownerHash !== ownerHash || proof.authUid !== authUid) {
        throw new HttpsError("permission-denied", "Ödül bu kuruluma ait değil.");
      }

      // Kayıp yanıt sonrası idempotent başarı (ikinci increment yok).
      if (proof.status === "consumed") {
        return {
          purpose: proof.purpose,
          hilalsAdded: Math.max(0, Number(proof.hilalsAdded) || 0),
          alreadyClaimed: true,
        };
      }

      if ((proof.expiresAt?.toMillis?.() || 0) <= Date.now()) {
        throw new HttpsError("deadline-exceeded", "Reklam kanıtının süresi doldu.");
      }
      if (proof.status !== "rewarded") {
        throw new HttpsError("failed-precondition", "Reklam henüz doğrulanmadı.");
      }

      let hilalsAdded = 0;
      if (proof.purpose === "double") {
        const matchRef = db.collection("quiz_matches").doc(proof.matchId);
        const matchSnap = await tx.get(matchRef);
        const match = matchSnap.data() || {};
        const result = match.result?.players?.find(
          (player) => player.id === ownerHash,
        );
        if (!matchSnap.exists || match.status !== "completed" || !result) {
          throw new HttpsError("failed-precondition", "Maç ödülü bulunamadı.");
        }
        if (match.doubledBy?.[ownerHash] === true) {
          tx.update(proofRef, {
            status: "consumed",
            hilalsAdded: 0,
            alreadyDoubled: true,
            consumedAt: FieldValue.serverTimestamp(),
          });
          return {
            purpose: "double",
            hilalsAdded: 0,
            alreadyClaimed: true,
          };
        }
        hilalsAdded = Math.max(0, Number(result.hilalsAwarded) || 0);
        // Terk cezası (negatif) ikiye katlanmaz.
        if (hilalsAdded <= 0) {
          tx.set(matchRef, {
            [`doubledBy.${ownerHash}`]: true,
            version: _nextVersion(match),
          }, { merge: true });
          hilalsAdded = 0;
        } else {
          const weekId = weekIdIstanbul();
          const weeklyRef = _weeklyEntryRef(db, weekId, ownerHash);
          const playerSnap = await tx.get(playerRef);
          const weeklySnap = await tx.get(weeklyRef);
          tx.set(matchRef, {
            [`doubledBy.${ownerHash}`]: true,
            version: _nextVersion(match),
          }, { merge: true });
          _writeHilalDelta(tx, {
            playerRef,
            weeklyRef,
            playerSnap,
            weeklySnap,
            delta: hilalsAdded,
            name: playerSnap.data()?.name,
            weekId,
            matchesCompletedInc: 0,
          });
        }
      } else {
        tx.set(playerRef, {
          adHearts: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      tx.update(proofRef, {
        status: "consumed",
        hilalsAdded,
        consumedAt: FieldValue.serverTimestamp(),
      });
      return { purpose: proof.purpose, hilalsAdded, alreadyClaimed: false };
    });
    return { ok: true, ...outcome };
  },
);

const startQuizMatch = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "start", 20);
    const name = _validatedName(req.data?.name);
    const queueRef = db.collection("quiz_queue").doc(ownerHash);
    const playerRef = db.collection("quiz_players").doc(ownerHash);

    // Önce terk edilmiş waiting'i iade et (claim-on-reentry).
    await db.runTransaction(async (tx) => {
      const queueSnap = await tx.get(queueRef);
      const queue = queueSnap.data() || null;
      const fundingValid = queue?.status === "waiting"
        ? await _isQueueFundingValidInTransaction(tx, db, queue)
        : true;
      if (
        shouldRefundAbandonedQueue(queue, Date.now()) ||
        (queue?.status === "waiting" && !fundingValid)
      ) {
        await _refundQueueHeartInTransaction(tx, db, {
          queueRef,
          queue,
          playerRef,
        });
      }
    });

    const existing = await queueRef.get();
    const existingData = existing.data() || {};
    if (existingData.status === "matched" && existingData.matchId) {
      const priorMatch = await db.collection("quiz_matches")
        .doc(String(existingData.matchId))
        .get();
      if (priorMatch.exists && priorMatch.data()?.status === "playing") {
        return { ok: true, status: "matched", matchId: existingData.matchId };
      }
    }
    if (
      existingData.status === "waiting" &&
      !shouldRefundAbandonedQueue(existingData, Date.now())
    ) {
      return {
        ok: true,
        status: "waiting",
        queuedAtMs: existingData.queuedAt?.toMillis?.() || Date.now(),
      };
    }

    const playerSnap = await playerRef.get();
    const premium = await _isPremiumCaller(db, req);
    const profile = _publicProfile(ownerHash, {
      ...(playerSnap.data() || {}),
      name,
      premium,
    });
    const waitingSnap = await db.collection("quiz_queue")
      .where("status", "==", "waiting")
      .limit(20)
      .get();
    const nowMs = Date.now();
    const candidates = waitingSnap.docs
      .map((doc) => ({ ref: doc.ref, ...doc.data() }))
      .filter((item) => {
        if (item.ownerHash === ownerHash) return false;
        if (!isFundedQueue(item)) return false;
        if (shouldRefundAbandonedQueue(item, nowMs)) return false;
        const activeUntil = queueAbandonAtMs(item);
        return activeUntil === 0 || activeUntil > nowMs;
      })
      .sort((a, b) => {
        const exactA = a.level === profile.level ? 0 : 1;
        const exactB = b.level === profile.level ? 0 : 1;
        if (exactA !== exactB) return exactA - exactB;
        const gapA = Math.abs((a.level || 1) - profile.level);
        const gapB = Math.abs((b.level || 1) - profile.level);
        if (gapA !== gapB) return gapA - gapB;
        return (a.queuedAt?.toMillis?.() || 0) -
          (b.queuedAt?.toMillis?.() || 0);
      });
    const candidate = candidates[0] || null;

    return db.runTransaction(async (tx) => {
      const freshPlayer = await tx.get(playerRef);
      const freshQueue = await tx.get(queueRef);
      const freshCandidate = candidate ? await tx.get(candidate.ref) : null;
      const player = freshPlayer.data() || {};
      const currentQueue = freshQueue.data() || {};
      if (currentQueue.status === "matched" && currentQueue.matchId) {
        const activeMatch = await tx.get(
          db.collection("quiz_matches").doc(String(currentQueue.matchId)),
        );
        if (activeMatch.exists && activeMatch.data()?.status === "playing") {
          return {
            ok: true,
            status: "matched",
            matchId: currentQueue.matchId,
          };
        }
      }
      if (
        currentQueue.status === "waiting" &&
        !shouldRefundAbandonedQueue(currentQueue, Date.now())
      ) {
        return {
          ok: true,
          status: "waiting",
          queuedAtMs: currentQueue.queuedAt?.toMillis?.() || Date.now(),
        };
      }
      // Aynı tx içinde iade + yeni charge karışmasın; iade sonrası istemci tekrar dener.
      if (shouldRefundAbandonedQueue(currentQueue, Date.now())) {
        await _refundQueueHeartInTransaction(tx, db, {
          queueRef,
          queue: currentQueue,
          playerRef,
        });
        return { ok: true, status: "idle", refunded: true };
      }
      const adHearts = adHeartBalance(player);
      if (!premium && adHearts <= 0) {
        throw new HttpsError(
          "resource-exhausted",
          "Oynamak için reklam izleyerek can kazanmalısın.",
        );
      }
      const heartSource = premium ? "premium" : "ad";
      const heartChargeId = premium
        ? null
        : crypto.randomBytes(16).toString("hex");
      const chargeRef = heartChargeId
        ? db.collection("quiz_heart_charges").doc(heartChargeId)
        : null;
      // Tüm okumalar yazmadan önce tamamlanır (Firestore tx kuralı).
      if (chargeRef) await tx.get(chargeRef);
      // Adayla anında eşleşme yolunda _createMatchInTransaction çağrısından
      // önce adayın charge kaydını da oku. Firestore transaction'larında tüm
      // okumalar, aşağıdaki ilk yazmadan önce tamamlanmalıdır.
      const candidateChargeId = String(
        freshCandidate?.data()?.heartChargeId || "",
      ).trim();
      const candidateChargeSnap = candidateChargeId
        ? await tx.get(
          db.collection("quiz_heart_charges").doc(candidateChargeId),
        )
        : null;
      const chargeRecordsPreRead = new Map();
      if (heartChargeId) {
        chargeRecordsPreRead.set(heartChargeId, {
          ownerHash,
          heartSource: "ad",
          status: "charged",
        });
      }
      if (candidateChargeId && candidateChargeSnap?.exists) {
        chargeRecordsPreRead.set(candidateChargeId, candidateChargeSnap.data());
      }
      const candidateData = freshCandidate?.data() || null;
      const candidateFundingValid = candidateData?.status === "waiting" &&
        isValidQueueFunding(candidateData, candidateChargeSnap?.data());
      if (candidateData?.status === "waiting" && !candidateFundingValid) {
        await _refundQueueHeartInTransaction(tx, db, {
          queueRef: candidate.ref,
          queue: candidateData,
          playerRef: db.collection("quiz_players").doc(
            String(candidateData.ownerHash || candidate.ref.id),
          ),
        });
      }
      const queuedAt = Timestamp.now();
      const activeUntil = Timestamp.fromMillis(
        queuedAt.toMillis() + QUEUE_ABANDON_MS,
      );
      tx.set(playerRef, {
        name,
        ...(premium ? {} : { adHearts: FieldValue.increment(-1) }),
        updatedAt: FieldValue.serverTimestamp(),
        ...(player.createdAt ? {} : { createdAt: FieldValue.serverTimestamp() }),
      }, { merge: true });
      if (chargeRef) {
        tx.create(chargeRef, {
          ownerHash,
          heartSource,
          status: "charged",
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: Timestamp.fromMillis(Date.now() + 30 * 86400000),
        });
      }
      const queueData = {
        ownerHash,
        name,
        hilals: profile.hilals,
        level: profile.level,
        status: "waiting",
        heartSource,
        ...(heartChargeId ? { heartChargeId } : {}),
        refunded: false,
        queuedAt,
        activeUntil,
        updatedAt: Timestamp.now(),
        expiresAt: Timestamp.fromMillis(Date.now() + QUEUE_WAITING_TTL_MS),
      };
      if (
        candidate &&
        freshCandidate?.exists &&
        freshCandidate.data()?.status === "waiting" &&
        candidateFundingValid &&
        !shouldRefundAbandonedQueue(freshCandidate.data(), Date.now())
      ) {
        const result = await _createMatchInTransaction({
          tx,
          db,
          firstQueue: queueData,
          secondQueue: freshCandidate.data(),
          chargeRecordsPreRead,
        });
        return { ok: true, status: "matched", matchId: result.matchId };
      }
      // Yeni/replaced waiting dokümanında matchId alanına ihtiyaç yok.
      // FieldValue.delete(), mergesiz set() içinde geçersizdir ve callable'ı
      // INTERNAL ile düşürür.
      tx.set(queueRef, queueData);
      return {
        ok: true,
        status: "waiting",
        queuedAtMs: queueData.queuedAt.toMillis(),
      };
    });
  },
);

const cancelQuizMatchmaking = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "cancel", 30);
    const queueRef = db.collection("quiz_queue").doc(ownerHash);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const outcome = await db.runTransaction(async (tx) => {
      const queueSnap = await tx.get(queueRef);
      if (!queueSnap.exists) {
        return { ok: true, refunded: false, status: "idle" };
      }
      const queue = queueSnap.data() || {};
      if (queue.status === "matched" && queue.matchId) {
        // İptal yarışı: maç oluşmuşsa istemci maça girer.
        return {
          ok: true,
          refunded: false,
          status: "matched",
          matchId: String(queue.matchId),
        };
      }
      if (queue.status !== "waiting") {
        tx.set(queueRef, _idleQueuePatch(), { merge: true });
        return { ok: true, refunded: false, status: "idle" };
      }
      const refund = await _refundQueueHeartInTransaction(tx, db, {
        queueRef,
        queue,
        playerRef,
      });
      return {
        ok: true,
        refunded: refund.refunded,
        status: "idle",
      };
    });
    return outcome;
  },
);

const pollQuizMatch = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    // ~1s poll için geniş pencere (5 dk / ~900ms ≈ 333 → limit 450).
    await _assertQuizCallerRates(db, req, ownerHash, "poll", 450);
    const queueRef = db.collection("quiz_queue").doc(ownerHash);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const queueSnap = await queueRef.get();
    // Kuyruk yok / idle → throw etme; istemci lobide toparlansın.
    // (Eski davranış "Eşleşme isteği bulunamadı" ile 15sn ekranında takılıyordu.)
    if (!queueSnap.exists) {
      return { ok: true, status: "idle", reason: "missing_queue" };
    }
    const queue = queueSnap.data() || {};
    if (queue.status === "matched" && queue.matchId) {
      return { ok: true, status: "matched", matchId: String(queue.matchId) };
    }
    if (queue.status !== "waiting") {
      return { ok: true, status: "idle", reason: "not_waiting" };
    }
    if (!isFundedQueue(queue)) {
      await db.runTransaction(async (tx) => {
        const fresh = await tx.get(queueRef);
        const data = fresh.data() || {};
        if (data.status === "waiting" && !isFundedQueue(data)) {
          await _refundQueueHeartInTransaction(tx, db, {
            queueRef,
            queue: data,
            playerRef,
          });
        }
      });
      return { ok: true, status: "idle", reason: "invalid_funding_retired" };
    }
    if (shouldRefundAbandonedQueue(queue, Date.now())) {
      await db.runTransaction(async (tx) => {
        const fresh = await tx.get(queueRef);
        const data = fresh.data() || {};
        if (shouldRefundAbandonedQueue(data, Date.now())) {
          await _refundQueueHeartInTransaction(tx, db, {
            queueRef,
            queue: data,
            playerRef,
          });
        }
      });
      return { ok: true, status: "idle", refunded: true };
    }
    // queuedAt okunamazsa Date.now() fallback sonsuz "waiting" üretir — bot'a geç.
    const queuedAtMs = _timestampMs(queue.queuedAt);
    if (queuedAtMs > 0 && Date.now() - queuedAtMs < QUEUE_WAIT_MS) {
      return { ok: true, status: "waiting", queuedAtMs };
    }
    let result;
    try {
      result = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(queueRef);
        const data = fresh.data() || {};
        if (data.status === "matched" && data.matchId) return String(data.matchId);
        if (data.status !== "waiting") {
          throw new HttpsError("failed-precondition", "Eşleşme kapandı.");
        }
        const fundingValid = await _isQueueFundingValidInTransaction(
          tx,
          db,
          data,
        );
        if (!fundingValid) {
          await _refundQueueHeartInTransaction(tx, db, {
            queueRef,
            queue: data,
            playerRef,
          });
          return null;
        }
        const created = await _createMatchInTransaction({
          tx,
          db,
          firstQueue: { ...data, ownerHash: data.ownerHash || ownerHash },
          bot: true,
          ownerHashOverride: ownerHash,
        });
        return created.matchId;
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("[HilalDuel] bot match create failed:", error);
      throw new HttpsError(
        "internal",
        "Rakip atanamadı. Tekrar dene.",
      );
    }
    if (!result) {
      return { ok: true, status: "idle", reason: "invalid_funding_retired" };
    }
    return { ok: true, status: "matched", matchId: result };
  },
);

const getQuizMatch = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "get_match", 450);
    const matchId = _validatedDocumentId(req.data?.matchId, "karşılaşma");
    const matchRef = db.collection("quiz_matches").doc(matchId);
    const match = await db.runTransaction(async (tx) => {
      const snap = await tx.get(matchRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Karşılaşma bulunamadı.");
      }
      const data = snap.data();
      if (!data.players?.some((player) => player.id === ownerHash)) {
        throw new HttpsError("permission-denied", "Karşılaşmaya erişilemez.");
      }
      await _resolveRoundIfReady(tx, db, matchRef, data, Date.now());
      return data;
    });
    await _scheduleTop3RivalryFromMatch(db, matchRef, match);
    return {
      ok: true,
      match: _serializeMatch(matchId, match, ownerHash, _requestLocale(req)),
    };
  },
);

const submitQuizAnswer = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "submit", 60);
    const matchId = _validatedDocumentId(req.data?.matchId, "karşılaşma");
    const round = Number(req.data?.round);
    const choice = Number(req.data?.choice);
    if (!Number.isInteger(round) || round < 0 || round >= ROUND_COUNT) {
      throw new HttpsError("invalid-argument", "Geçersiz soru sırası.");
    }
    if (!Number.isInteger(choice) || choice < 0 || choice > 3) {
      throw new HttpsError("invalid-argument", "Geçersiz cevap.");
    }
    const matchRef = db.collection("quiz_matches").doc(matchId);
    const match = await db.runTransaction(async (tx) => {
      const snap = await tx.get(matchRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Karşılaşma bulunamadı.");
      }
      const data = snap.data();
      if (
        data.status !== "playing" ||
        data.currentRound !== round ||
        !data.players?.some(
          (player) => player.id === ownerHash && !player.isBot,
        )
      ) {
        throw new HttpsError("failed-precondition", "Bu soru artık aktif değil.");
      }
      const nowMs = Date.now();
      const existing = _answerFor(data, round, ownerHash);
      if (
        existing &&
        !canReplaceTimeoutAnswer(
          existing,
          nowMs,
          data.roundStartedAtMs,
          data.deadlineMs,
        )
      ) {
        await _resolveRoundIfReady(tx, db, matchRef, data, nowMs);
        return data;
      }
      const gate = canAcceptAnswer(nowMs, data.roundStartedAtMs, data.deadlineMs);
      if (!gate.ok && gate.reason === "not_started") {
        throw new HttpsError(
          "failed-precondition",
          "Soru henüz başlamadı.",
        );
      }
      if (!gate.ok && gate.reason === "expired") {
        await _resolveRoundIfReady(tx, db, matchRef, data, nowMs);
        return data;
      }
      const question = QUESTION_BY_ID.get(data.questionIds[round]);
      if (!question) {
        throw new HttpsError("failed-precondition", "Soru bulunamadı.");
      }
      const elapsedMs = Math.min(
        ROUND_DURATION_MS,
        Math.max(0, nowMs - data.roundStartedAtMs),
      );
      const graded = {
        choice,
        elapsedMs,
        correct: choice === question.correctIndex,
      };
      data.answers = {
        ...(data.answers || {}),
        [String(round)]: {
          ...(data.answers?.[String(round)] || {}),
          [ownerHash]: graded,
        },
      };
      await _resolveRoundIfReady(tx, db, matchRef, data, nowMs);
      if (!_answerFor(data, round, ownerHash)) {
        data.version = _nextVersion(data);
        tx.set(matchRef, {
          [`answers.${round}.${ownerHash}`]: graded,
          version: data.version,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      return data;
    });
    await _scheduleTop3RivalryFromMatch(db, matchRef, match);
    return {
      ok: true,
      match: _serializeMatch(matchId, match, ownerHash, _requestLocale(req)),
    };
  },
);

/**
 * Maçı yarıda terk: kalan oyuncu kazanır, çıkan kişiye hilal cezası.
 * Ödül yalnızca tamamlanan (veya forfeit ile kapanan) maçta yazılır.
 */
const forfeitQuizMatch = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "forfeit", 20);
    const matchId = _validatedDocumentId(req.data?.matchId, "karşılaşma");
    const matchRef = db.collection("quiz_matches").doc(matchId);
    const match = await db.runTransaction(async (tx) => {
      const snap = await tx.get(matchRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Karşılaşma bulunamadı.");
      }
      const data = snap.data() || {};
      if (data.status === "completed") {
        return data;
      }
      if (data.status !== "playing") {
        throw new HttpsError("failed-precondition", "Maç terk edilemez.");
      }
      if (!data.players?.some((player) => player.id === ownerHash && !player.isBot)) {
        throw new HttpsError("permission-denied", "Bu karşılaşmaya erişemezsiniz.");
      }
      await _completeMatch(tx, db, matchRef, data, { forfeitBy: ownerHash });
      return data;
    });
    await _scheduleTop3RivalryFromMatch(db, matchRef, match);
    return {
      ok: true,
      match: _serializeMatch(matchId, match, ownerHash, _requestLocale(req)),
    };
  },
);

/**
 * Admin: kendi kurulumuna hilal ekler (toplam + haftalık sıralama).
 * Sadece admin + kendi installId; başkasına yazmaz.
 */
const adminGrantSelfQuizHilals = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    if (!(await _quizCallerIsAdmin(db, req))) {
      throw new HttpsError("permission-denied", "Sadece admin hilal ekleyebilir.");
    }
    await _assertQuizCallerRates(db, req, ownerHash, "admin_self_hilals", 40);
    const amount = Math.floor(Number(req.data?.amount) || 0);
    if (!Number.isFinite(amount) || amount < 1 || amount > 500) {
      throw new HttpsError(
        "invalid-argument",
        "amount 1 ile 500 arasında olmalı.",
      );
    }
    const name = _validatedName(req.data?.name || "Arın Oyuncusu");
    const weekId = weekIdIstanbul();
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const weeklyRef = _weeklyEntryRef(db, weekId, ownerHash);
    const result = await db.runTransaction(async (tx) => {
      const playerSnap = await tx.get(playerRef);
      const weeklySnap = await tx.get(weeklyRef);
      return _writeHilalDelta(tx, {
        playerRef,
        weeklyRef,
        playerSnap,
        weeklySnap,
        delta: amount,
        name,
        weekId,
        matchesCompletedInc: 0,
      });
    });
    const weeklyRank = await _computeWeeklyRank(
      db,
      weekId,
      ownerHash,
      result.weeklyHilals,
    );
    const playerSnap = await playerRef.get();
    const rankPatch = _bestWeeklyRankPatch(
      playerSnap.data() || {},
      weekId,
      weeklyRank,
    );
    await playerRef.set({
      weeklyRank,
      ...(rankPatch || {}),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    const adminEmail = String(req.auth?.token?.email || "").toLowerCase();
    await db.collection("admin_audit").add({
      action: "quiz_hilals_grant_self",
      targetType: "quiz_player",
      targetId: ownerHash,
      uid: req.auth?.uid || null,
      email: adminEmail || null,
      details: {
        amount,
        hilals: result.nextHilals,
        weeklyHilals: result.weeklyHilals,
        weeklyRank,
      },
      createdAt: FieldValue.serverTimestamp(),
    });
    return {
      ok: true,
      amount,
      hilals: result.nextHilals,
      weeklyHilals: result.weeklyHilals,
      weeklyRank,
      level: result.level,
    };
  },
);

/**
 * Admin: kendi seviyesini ayarlar (toplam hilal = seviye tabanı).
 * Haftalık skor değişmez; weekly entry level/cosmetics güncellenir.
 */
const adminSetSelfQuizLevel = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    if (!(await _quizCallerIsAdmin(db, req))) {
      throw new HttpsError("permission-denied", "Sadece admin seviye ayarlayabilir.");
    }
    await _assertQuizCallerRates(db, req, ownerHash, "admin_self_level", 40);
    const level = Math.floor(Number(req.data?.level) || 0);
    if (!Number.isFinite(level) || level < 1 || level > MAX_LEVEL) {
      throw new HttpsError(
        "invalid-argument",
        `level 1 ile ${MAX_LEVEL} arasında olmalı.`,
      );
    }
    const name = _validatedName(req.data?.name || "Arın Oyuncusu");
    const targetHilals = hilalsFloorForLevel(level);
    const cosmetics = cosmeticsForLevel(level);
    const weekId = weekIdIstanbul();
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const weeklyRef = _weeklyEntryRef(db, weekId, ownerHash);
    const result = await db.runTransaction(async (tx) => {
      const playerSnap = await tx.get(playerRef);
      const weeklySnap = await tx.get(weeklyRef);
      const prev = playerSnap.data() || {};
      const excluded = prev.leaderboardExcluded === true;
      const displayName = excluded
        ? String(prev.name || "Oyuncu").slice(0, 32)
        : name;
      const weeklyHilals = weeklySnap.exists
        ? Math.floor(Number(weeklySnap.data()?.weeklyHilals) || 0)
        : (prev.weekId === weekId
          ? Math.floor(Number(prev.weeklyHilals) || 0)
          : 0);
      tx.set(playerRef, {
        name: displayName,
        hilals: targetHilals,
        weekId,
        weeklyHilals: excluded ? 0 : weeklyHilals,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      if (!excluded) {
        tx.set(weeklyRef, {
          ownerHash,
          name: displayName,
          weeklyHilals,
          level,
          isBot: false,
          ...cosmeticsDocFields(cosmetics),
          updatedAt: FieldValue.serverTimestamp(),
          expiresAt: Timestamp.fromMillis(Date.now() + WEEKLY_TTL_MS),
        }, { merge: true });
      }
      return { hilals: targetHilals, weeklyHilals: excluded ? 0 : weeklyHilals, level };
    });
    const adminEmail = String(req.auth?.token?.email || "").toLowerCase();
    await db.collection("admin_audit").add({
      action: "quiz_level_set_self",
      targetType: "quiz_player",
      targetId: ownerHash,
      uid: req.auth?.uid || null,
      email: adminEmail || null,
      details: {
        level: result.level,
        hilals: result.hilals,
        weeklyHilals: result.weeklyHilals,
      },
      createdAt: FieldValue.serverTimestamp(),
    });
    return {
      ok: true,
      level: result.level,
      hilals: result.hilals,
      weeklyHilals: result.weeklyHilals,
    };
  },
);

const getQuizWeeklyLeaderboard = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "weekly_board", 40);
    const weekId = weekIdIstanbul();
    const entriesRef = db.collection("quiz_weekly").doc(weekId).collection("entries");
    // İnsan skorları + botlar ayrı (botlar düşük skorla top60'dan düşmesin).
    const [topSnap, botSnap] = await Promise.all([
      entriesRef.orderBy("weeklyHilals", "desc").limit(60).get(),
      entriesRef.where("isBot", "==", true).limit(20).get(),
    ]);
    const byId = new Map();
    const mapDoc = (doc) => {
      const data = doc.data() || {};
      const level = Math.max(1, Math.floor(Number(data.level) || 1));
      const isBot = data.isBot === true || String(doc.id).startsWith("bot_");
      const cosmetics = isBot ? emptyCosmetics() : cosmeticsForLevel(level);
      const rawName = String(data.name || "Oyuncu").slice(0, 32);
      return {
        ownerHash: doc.id,
        name: isBot ? _botDisplayName(rawName) : rawName,
        weeklyHilals: Math.floor(Number(data.weeklyHilals) || 0),
        level: isBot ? Math.min(3, level) : level,
        ...cosmeticsDocFields(cosmetics),
        isBot,
        isSelf: doc.id === ownerHash,
      };
    };
    for (const doc of topSnap.docs) {
      // Admin moderasyonu entry üzerinde de işaretlenebilir.
      if (doc.data()?.leaderboardExcluded === true) continue;
      byId.set(doc.id, mapDoc(doc));
    }
    for (const doc of botSnap.docs) {
      if (doc.data()?.leaderboardExcluded === true) continue;
      if (!byId.has(doc.id)) byId.set(doc.id, mapDoc(doc));
    }
    const ordered = _orderWeeklyLeaderboard([...byId.values()]);
    const humans = ordered.filter((row) => !row.isBot);
    const bots = ordered.filter((row) => row.isBot);
    // Üstte insanlar, altta birkaç bot — inandırıcı doluluk.
    const top = [
      ...humans.slice(0, Math.max(12, WEEKLY_TOP_LIMIT - 6)),
      ...bots.slice(0, 6),
    ]
      .slice(0, WEEKLY_TOP_LIMIT)
      .map((row, index) => ({ ...row, rank: index + 1 }));
    // Premium işareti yalnız admin yanıtında — sıradan oyuncuya sızdırma.
    const callerIsAdmin = await _quizCallerIsAdmin(db, req);
    let topOut = top;
    if (callerIsAdmin) {
      const premiumFlags = await _premiumFlagsForOwnerHashes(
        db,
        top.filter((row) => !row.isBot).map((row) => row.ownerHash),
      );
      topOut = top.map((row) => ({
        ...row,
        premium: !row.isBot && premiumFlags.get(row.ownerHash) === true,
      }));
    }
    const humanTopHashes = topOut
      .filter((row) => !row.isBot)
      .map((row) => row.ownerHash);
    const championByHash = new Map();
    if (humanTopHashes.length > 0) {
      const champSnaps = await db.getAll(
        ...humanTopHashes.map((id) => db.collection("quiz_players").doc(id)),
      );
      for (const snap of champSnaps) {
        championByHash.set(
          snap.id,
          Math.max(0, Math.floor(Number(snap.data()?.hilalChampionWeeks) || 0)),
        );
      }
    }
    topOut = topOut.map((row) => ({
      ...row,
      championWeeks: row.isBot ? 0 : (championByHash.get(row.ownerHash) || 0),
    }));
    const selfSnap = await entriesRef.doc(ownerHash).get();
    const selfWeekly = selfSnap.exists
      ? Math.floor(Number(selfSnap.data()?.weeklyHilals) || 0)
      : 0;
    let selfRank = 0;
    if (selfSnap.exists) {
      const inTop = topOut.find((row) => row.ownerHash === ownerHash);
      if (inTop) {
        selfRank = inTop.rank;
      } else {
        selfRank = await _computeWeeklyRank(
          db,
          weekId,
          ownerHash,
          selfWeekly,
        );
      }
    }
    const playerSnap = await db.collection("quiz_players").doc(ownerHash).get();
    const progression = levelForHilals(
      Math.floor(Number(playerSnap.data()?.hilals) || 0),
    );
    const selfChampionWeeks = Math.max(
      0,
      Math.floor(Number(playerSnap.data()?.hilalChampionWeeks) || 0),
    );
    const lastWeekWinners = await _lastWeekWinnersPromo(db);
    return {
      ok: true,
      weekId,
      top: topOut,
      lastWeekWinners,
      self: {
        weeklyHilals: selfWeekly,
        rank: selfRank,
        level: progression.level,
        ...cosmeticsForLevel(progression.level),
        name: String(playerSnap.data()?.name || "Arın Oyuncusu").slice(0, 32),
        championWeeks: selfChampionWeeks,
      },
    };
  },
);

/**
 * Önceki haftanın yerleşimleri — lobide tüm hafta “kazananlar” reklamı.
 * Ledger yoksa / henüz settle olmadıysa null.
 */
async function _lastWeekWinnersPromo(db, now = new Date()) {
  const closedWeekId = previousWeekIdIstanbul(now);
  const snap = await db
    .collection(HILAL_WEEKLY_REWARDS_COLLECTION)
    .doc(closedWeekId)
    .get();
  if (!snap.exists) return null;
  const winners = lastWeekWinnersFromLedgerData(snap.data() || {});
  if (!winners || winners.length === 0) return null;
  return { weekId: closedWeekId, winners };
}

/**
 * Promo: Premium verilmediyse grantDays=0 (UI 14/7/3 yazmasın).
 * Ledger yok / henüz settle değil → null.
 */
function lastWeekWinnersFromLedgerData(data) {
  const status = String(data?.status || "");
  if (status !== "settled" && status !== "granted") return null;

  let placements = Array.isArray(data.placements) ? data.placements : [];
  if (placements.length === 0 && data.ownerHash) {
    placements = [{
      rank: 1,
      ownerHash: data.ownerHash,
      name: data.name || "Oyuncu",
      grantDays: Math.floor(Number(data.grantDays) || HILAL_WEEKLY_PREMIUM_DAYS),
      championIncremented: true,
      premiumStatus: status === "granted" ? "granted" : "skipped_no_auth",
    }];
  }

  const winners = placements
    .map((row) => {
      const rank = Math.max(1, Math.floor(Number(row?.rank) || 0));
      if (rank < 1 || rank > 3) return null;
      const name = String(row?.name || "Oyuncu").trim().slice(0, 32);
      if (!name) return null;
      const granted = String(row?.premiumStatus || "") === "granted";
      const grantDays = granted
        ? Math.max(
          0,
          Math.floor(Number(row?.grantDays) || hilalWeeklyPremiumDaysForRank(rank)),
        )
        : 0;
      return {
        rank,
        name,
        ownerHash: String(row?.ownerHash || "").trim().toLowerCase(),
        grantDays,
        champion: rank === 1 || row?.championIncremented === true,
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.rank - b.rank)
    .slice(0, 3);

  return winners.length === 0 ? null : winners;
}

/** Terk edilmiş waiting kuyruklarını iade eder; TTL silmeden önce çalışır. */
const cleanupAbandonedQuizQueues = onSchedule(
  {
    region: REGION,
    schedule: "every 5 minutes",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const db = getFirestore();
    const nowMs = Date.now();
    const snap = await db.collection("quiz_queue")
      .where("status", "==", "waiting")
      .limit(80)
      .get();
    let refunded = 0;
    for (const doc of snap.docs) {
      const queue = doc.data() || {};
      if (!shouldRefundAbandonedQueue(queue, nowMs)) continue;
      try {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          const data = fresh.data() || {};
          if (!shouldRefundAbandonedQueue(data, nowMs)) return;
          const playerRef = db.collection("quiz_players").doc(doc.id);
          await _refundQueueHeartInTransaction(tx, db, {
            queueRef: doc.ref,
            queue: data,
            playerRef,
            nowMs,
          });
        });
        refunded += 1;
      } catch (error) {
        console.error("[HilalDuel] queue refund failed", doc.id, error);
      }
    }
    if (refunded > 0) {
      console.log(`[HilalDuel] refunded abandoned queues: ${refunded}`);
    }
  },
);

const registerQuizDevice = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "register_device", 30);
    const token = String(req.data?.token || "").trim();
    if (token.length < 32 || token.length > 4096) {
      throw new HttpsError("invalid-argument", "Geçersiz bildirim kimliği.");
    }
    const platform = ["android", "ios"].includes(req.data?.platform)
      ? req.data.platform
      : "other";
    await db.collection("quiz_devices").doc(ownerHash).set({
      token,
      platform,
      locale: _validatedQuizLocale(req.data?.locale),
      expiresAt: Timestamp.fromMillis(Date.now() + QUIZ_DEVICE_TTL_MS),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true };
  },
);

async function _deliverQuizEngagementPush({
  db,
  ownerHash,
  token,
  locale,
  reason,
  currentRank,
}) {
  const copy = quizEngagementCopy(locale, reason);
  const messageId = await getMessaging().send({
    token,
    notification: copy,
    data: {
      type: "hilal_duel",
      reason: String(reason || "comeback"),
      rank: String(Math.max(0, Math.floor(Number(currentRank) || 0))),
    },
    android: {
      notification: {
        channelId: "arin_hilal_duel",
        priority: "default",
        defaultSound: true,
      },
    },
    apns: { payload: { aps: { sound: "default" } } },
  });
  await db.collection("quiz_players").doc(ownerHash).set({
    lastEngagementPushAt: FieldValue.serverTimestamp(),
    lastEngagementPushReason: String(reason || "comeback"),
    lastKnownWeeklyRank: Math.max(0, Math.floor(Number(currentRank) || 0)),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return messageId;
}

async function _deliverTop3RivalryPush({
  db,
  ownerHash,
  token,
  locale,
  reason,
  actorName,
}) {
  const copy = quizTop3RivalryCopy(locale, reason, { name: actorName });
  const messageId = await getMessaging().send({
    token,
    notification: copy,
    data: {
      type: "hilal_duel",
      reason: String(reason || "close_threat"),
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
  await db.collection("quiz_players").doc(ownerHash).set({
    lastTop3RivalryPushAt: FieldValue.serverTimestamp(),
    lastTop3RivalryPushReason: String(reason || "close_threat"),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return messageId;
}

/**
 * Maç / meydan okuma sonrası: top-3 rekabet push (idempotent claim).
 */
async function _claimAndNotifyTop3Rivalry(db, docRef, humanOwnerHashes) {
  const humans = [...new Set(
    (Array.isArray(humanOwnerHashes) ? humanOwnerHashes : [])
      .map((id) => String(id || "").trim().toLowerCase())
      .filter((id) => id && !id.startsWith("bot_")),
  )];
  if (humans.length === 0) return { sent: 0, skipped: true };

  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    if (!snap.exists || snap.data()?.top3RivalryPending !== true) {
      return false;
    }
    tx.set(docRef, {
      top3RivalryPending: false,
      top3RivalryNotifiedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  });
  if (!claimed) return { sent: 0, skipped: true };

  try {
  const weekId = weekIdIstanbul();
  const entriesRef = db.collection("quiz_weekly").doc(weekId).collection("entries");
  const topSnap = await entriesRef.orderBy("weeklyHilals", "desc").limit(12).get();
  const boardRows = [];
  for (const doc of topSnap.docs) {
    const data = doc.data() || {};
    const ownerHash = String(doc.id || "").trim().toLowerCase();
    if (!ownerHash || data.isBot === true || ownerHash.startsWith("bot_")) continue;
    if (data.leaderboardExcluded === true) continue;
    const weeklyHilals = Math.floor(Number(data.weeklyHilals) || 0);
    if (weeklyHilals <= 0) continue;
    boardRows.push({
      ownerHash,
      name: String(data.name || "Oyuncu").slice(0, 32),
      weeklyHilals,
      isBot: false,
    });
  }
  const ordered = _orderWeeklyLeaderboard(boardRows)
    .filter((row) => !row.isBot)
    .slice(0, 5)
    .map((row, index) => ({ ...row, rank: index + 1 }));

  const nowMs = Date.now();
  const playerSnaps = humans.length > 0
    ? await db.getAll(...humans.map((id) => db.collection("quiz_players").doc(id)))
    : [];
  const playerById = new Map(
    playerSnaps.map((snap) => [snap.id, snap.data() || {}]),
  );

  const targetIds = new Set();
  const plans = [];
  for (const actorId of humans) {
    const onBoard = ordered.find((row) => row.ownerHash === actorId);
    let actorHilals = onBoard?.weeklyHilals;
    let actorRank = onBoard?.rank || 0;
    let actorName = onBoard?.name;
    if (actorHilals == null) {
      const weeklySnap = await entriesRef.doc(actorId).get();
      actorHilals = Math.floor(Number(weeklySnap.data()?.weeklyHilals) || 0);
      actorName = String(
        weeklySnap.data()?.name || playerById.get(actorId)?.name || "Rakip",
      ).slice(0, 32);
      if (actorHilals > 0) {
        actorRank = await _computeWeeklyRank(db, weekId, actorId, actorHilals);
      }
    }
    const lastPushAtByOwner = {};
    for (const row of ordered) {
      lastPushAtByOwner[row.ownerHash] =
        playerById.get(row.ownerHash)?.lastTop3RivalryPushAt?.toMillis?.() || 0;
    }
    // Hedeflerin cooldown'u için gerekirse oku.
    const decided = decideTop3RivalryNotifications({
      actorOwnerHash: actorId,
      actorName: actorName || "Rakip",
      actorRank,
      actorHilals,
      board: ordered,
      lastPushAtByOwner,
      nowMs,
    });
    for (const item of decided) {
      if (targetIds.has(item.ownerHash)) continue;
      targetIds.add(item.ownerHash);
      plans.push(item);
    }
  }

  if (plans.length === 0) return { sent: 0, skipped: false };

  const missingCooldown = plans
    .map((p) => p.ownerHash)
    .filter((id) => !playerById.has(id));
  if (missingCooldown.length > 0) {
    const extra = await db.getAll(
      ...missingCooldown.map((id) => db.collection("quiz_players").doc(id)),
    );
    for (const snap of extra) {
      playerById.set(snap.id, snap.data() || {});
    }
  }

  let sent = 0;
  for (const plan of plans) {
    const last =
      playerById.get(plan.ownerHash)?.lastTop3RivalryPushAt?.toMillis?.() || 0;
    if (last > 0 && nowMs - last < TOP3_RIVALRY_COOLDOWN_MS) continue;
    const deviceSnap = await db.collection("quiz_devices").doc(plan.ownerHash).get();
    if (!deviceSnap.exists) continue;
    const device = deviceSnap.data() || {};
    const token = String(device.token || "").trim();
    if (token.length < 32) continue;
    if ((device.expiresAt?.toMillis?.() || 0) > 0 &&
      (device.expiresAt?.toMillis?.() || 0) <= nowMs) {
      continue;
    }
    try {
      await _deliverTop3RivalryPush({
        db,
        ownerHash: plan.ownerHash,
        token,
        locale: device.locale,
        reason: plan.reason,
        actorName: plan.actorName,
      });
      sent += 1;
    } catch (error) {
      const code = String(error?.code || "");
      if (
        code.includes("registration-token-not-registered") ||
        code.includes("invalid-registration-token")
      ) {
        await deviceSnap.ref.delete().catch(() => {});
      }
      console.error("[HilalDuel] top3 rivalry push failed", plan.ownerHash, error);
    }
  }
  return { sent, skipped: false };
  } catch (error) {
    // Claim sonrası çökme → bir sonraki get/submit tekrar denesin.
    await docRef.set({ top3RivalryPending: true }, { merge: true }).catch(() => {});
    throw error;
  }
}

function _humanIdsFromMatch(match) {
  return (Array.isArray(match?.players) ? match.players : [])
    .filter((player) => player && player.isBot !== true && !_isBotId(player.id))
    .map((player) => String(player.id || "").trim().toLowerCase())
    .filter(Boolean);
}

async function _scheduleTop3RivalryFromMatch(db, matchRef, match) {
  if (match?.top3RivalryPending !== true) return;
  const humans = _humanIdsFromMatch(match);
  if (humans.length === 0) return;
  try {
    await _claimAndNotifyTop3Rivalry(db, matchRef, humans);
  } catch (error) {
    console.error("[HilalDuel] top3 rivalry schedule failed", error);
  }
}

async function _scheduleTop3RivalryFromChallenge(db, challengeRef, challenge) {
  if (challenge?.top3RivalryPending !== true) return;
  if (String(challenge?.status || "") !== "completed") return;
  const humans = [
    String(challenge.challengerId || "").trim().toLowerCase(),
    String(challenge.challengedId || "").trim().toLowerCase(),
  ].filter((id) => id && !_isBotId(id));
  if (humans.length === 0) return;
  try {
    await _claimAndNotifyTop3Rivalry(db, challengeRef, humans);
  } catch (error) {
    console.error("[HilalDuel] top3 rivalry challenge schedule failed", error);
  }
}

/**
 * Günde 1 kez:
 * - hiç oynamamış (lobi açmış): 1g–30g teşvik
 * - oynamış: 36s–14g idle comeback / rank_drop
 * (Uygulamayı hiç açmamışlara `broadcast_all` admin kampanyası gider.)
 */
function _challengeAnswerFor(challenge, round, ownerHash) {
  return challenge.answers?.[String(round)]?.[ownerHash] || null;
}

function _challengePlayerStats(challenge, playerId) {
  let correct = 0;
  let elapsedMs = 0;
  for (let round = 0; round < ROUND_COUNT; round += 1) {
    const answer = _challengeAnswerFor(challenge, round, playerId);
    if (!answer) {
      elapsedMs += ROUND_DURATION_MS;
      continue;
    }
    if (isChoiceCorrect(answer.choice, challenge.questionIds?.[round])) {
      correct += 1;
    }
    elapsedMs += Number(answer.elapsedMs) || 0;
  }
  return { id: playerId, correct, elapsedMs };
}

/** Sonuç tahtası: correct | wrong | missed | pending */
function _challengeRoundMarkToken(challenge, round, playerId, missing) {
  const answer = _challengeAnswerFor(challenge, round, playerId);
  if (!answer) return missing;
  if (isTimeoutAnswer(answer)) return "missed";
  if (isChoiceCorrect(answer.choice, challenge.questionIds?.[round])) {
    return "correct";
  }
  return "wrong";
}

function _pendingRoundMarks() {
  return Array.from({ length: ROUND_COUNT }, () => "pending");
}

/**
 * Meydan okuma tur işaretleri. Bitmemiş maçta cevaplanmamış tur `pending`;
 * tamamlanmış / süresi dolmuşta boş tur `missed` (rakip tahtası için).
 */
function _challengeRoundMarks(challenge, playerId) {
  const status = String(challenge.status || "");
  const completed = status === "completed" || status === "expired";
  const activeId = String(challenge.activePlayerId || "");
  const playerFinished = completed ||
    (status === "opponent_playing" && String(playerId) !== activeId) ||
    (status === "awaiting_opponent" &&
      String(playerId) === String(challenge.challengerId || ""));
  const currentRound = Math.min(
    Math.max(0, Number(challenge.currentRound) || 0),
    ROUND_COUNT - 1,
  );
  const marks = [];
  for (let round = 0; round < ROUND_COUNT; round += 1) {
    const missing = playerFinished || round < currentRound ? "missed" : "pending";
    marks.push(_challengeRoundMarkToken(challenge, round, playerId, missing));
  }
  return marks;
}

/** Meydan okunan taraf oynarken rakip (meydan okuyan) tahtası açık. */
function _shouldRevealChallengeOpponentMarks(challenge, ownerHash, opponentId) {
  const status = String(challenge.status || "");
  if (status === "completed" || status === "expired") return true;
  if (status === "opponent_playing") {
    return String(ownerHash) === String(challenge.challengedId || "") &&
      String(opponentId) === String(challenge.challengerId || "");
  }
  return false;
}

function _serializeChallenge(challengeId, challenge, ownerHash, locale = "tr") {
  const challengerId = String(challenge.challengerId || "");
  const challengedId = String(challenge.challengedId || "");
  if (ownerHash !== challengerId && ownerHash !== challengedId) {
    throw new HttpsError("permission-denied", "Bu meydan okumaya erişemezsiniz.");
  }
  const selfIsChallenger = ownerHash === challengerId;
  const challengedIsBot = challenge.challengedIsBot === true ||
    _isBotId(challengedId);
  const self = {
    id: ownerHash,
    name: selfIsChallenger
      ? String(challenge.challengerName || "Oyuncu")
      : String(challenge.challengedName || "Oyuncu"),
    hilals: selfIsChallenger
      ? Math.floor(Number(challenge.challengerHilals) || 0)
      : Math.floor(Number(challenge.challengedHilals) || 0),
    level: selfIsChallenger
      ? Math.max(1, Math.floor(Number(challenge.challengerLevel) || 1))
      : Math.max(1, Math.floor(Number(challenge.challengedLevel) || 1)),
    isBot: !selfIsChallenger && challengedIsBot,
  };
  const opponent = {
    id: selfIsChallenger ? challengedId : challengerId,
    name: selfIsChallenger
      ? String(challenge.challengedName || "Oyuncu")
      : String(challenge.challengerName || "Oyuncu"),
    hilals: selfIsChallenger
      ? Math.floor(Number(challenge.challengedHilals) || 0)
      : Math.floor(Number(challenge.challengerHilals) || 0),
    level: selfIsChallenger
      ? Math.max(1, Math.floor(Number(challenge.challengedLevel) || 1))
      : Math.max(1, Math.floor(Number(challenge.challengerLevel) || 1)),
    isBot: selfIsChallenger && challengedIsBot,
  };
  const status = String(challenge.status || "");
  const currentRound = Math.min(
    Math.max(0, Number(challenge.currentRound) || 0),
    ROUND_COUNT - 1,
  );
  const playing = status === "challenger_playing" || status === "opponent_playing";
  const myTurn = playing && String(challenge.activePlayerId || "") === ownerHash;
  const selfAnswer = myTurn
    ? _challengeAnswerFor(challenge, currentRound, ownerHash)
    : null;
  const lastResolution = challenge.lastResolution || null;
  const revealOpponentMarks = _shouldRevealChallengeOpponentMarks(
    challenge,
    ownerHash,
    opponent.id,
  );
  const resolutionChoices = { ...(lastResolution?.choices || {}) };
  const resolutionElapsed = { ...(lastResolution?.elapsedMs || {}) };
  if (revealOpponentMarks && lastResolution) {
    const oppAnswer = _challengeAnswerFor(
      challenge,
      Number(lastResolution.round) || 0,
      opponent.id,
    );
    if (oppAnswer) {
      resolutionChoices[opponent.id] = Number(oppAnswer.choice);
      resolutionElapsed[opponent.id] = Number(oppAnswer.elapsedMs) || 0;
    }
  }
  const perspective = _perspectiveResolutionChoices(
    { ...(lastResolution || {}), choices: resolutionChoices },
    ownerHash,
    opponent.id,
  );
  return {
    id: challengeId,
    kind: "challenge",
    status,
    version: Math.max(0, Math.floor(Number(challenge.version) || 0)),
    currentRound,
    totalRounds: ROUND_COUNT,
    roundStartedAtMs: Number(challenge.roundStartedAtMs) || 0,
    deadlineMs: Number(challenge.deadlineMs) || 0,
    challengeDeadlineMs: challengeDeadlineMsOf(challenge),
    self: _decoratePlayer(self),
    opponent: _decoratePlayer(opponent),
    role: selfIsChallenger ? "challenger" : "challenged",
    myTurn,
    canAccept: status === "awaiting_opponent" &&
      ownerHash === challengedId &&
      !challengedIsBot,
    question: playing && myTurn
      ? _questionPayload(challenge.questionIds[currentRound], false, locale)
      : null,
    // Solo tur: rakip yok; istemci "rakip bekleniyor"a düşmesin.
    selfAnswered: Boolean(selfAnswer),
    opponentAnswered: myTurn ? Boolean(selfAnswer) : true,
    lastResolution: lastResolution
      ? {
          round: Number(lastResolution.round) || 0,
          choices: resolutionChoices,
          elapsedMs: resolutionElapsed,
          selfChoice: perspective.selfChoice,
          opponentChoice: perspective.opponentChoice,
          question: _questionPayload(
            challenge.questionIds[lastResolution.round],
            true,
            locale,
          ),
        }
      : null,
    result: _serializeChallengeResult(challenge, ownerHash, opponent.id),
    // Meydan okunan taraf oynarken rakip (bitirmiş meydan okuyan) tahtası
    // açık; ilk oyuncu sırasında rakip henüz cevaplamadı.
    selfRoundMarks: _challengeRoundMarks(challenge, ownerHash),
    opponentRoundMarks: revealOpponentMarks
      ? _challengeRoundMarks(challenge, opponent.id)
      : _pendingRoundMarks(),
  };
}

function _serializeChallengeResult(challenge, selfId, opponentId) {
  const raw = challenge.result && typeof challenge.result === "object"
    ? { ...challenge.result }
    : null;
  const completed = String(challenge.status || "") === "completed" ||
    String(challenge.status || "") === "expired";
  if (!completed) return raw;
  const stored = raw?.roundMarks && typeof raw.roundMarks === "object"
    ? raw.roundMarks
    : {};
  return {
    ...(raw || {
      winnerId: null,
      players: [],
      expired: String(challenge.status || "") === "expired",
    }),
    roundMarks: {
      ...stored,
      [selfId]: _challengeRoundMarks(challenge, selfId),
      [opponentId]: _challengeRoundMarks(challenge, opponentId),
    },
  };
}

async function _chargeHeartForChallenge(tx, db, {
  playerRef,
  playerData,
  ownerHash,
  premium,
  nowMs,
}) {
  const adHearts = adHeartBalance(playerData);
  if (!premium && adHearts <= 0) {
    throw new HttpsError(
      "resource-exhausted",
      "Oynamak için reklam izleyerek can kazanmalısın.",
    );
  }
  const heartSource = premium ? "premium" : "ad";
  const heartChargeId = premium
    ? null
    : crypto.randomBytes(16).toString("hex");
  if (!premium) {
    tx.set(playerRef, {
      adHearts: FieldValue.increment(-1),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.create(db.collection("quiz_heart_charges").doc(heartChargeId), {
      ownerHash,
      heartSource,
      status: "consumed_by_challenge",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(nowMs + 30 * 86400000),
    });
  }
  return { heartSource, heartChargeId };
}

async function _finalizeChallenge(tx, db, challengeRef, challenge, options = {}) {
  if (challenge.completedAwarded === true) {
    return;
  }
  const expired = options.expired === true;
  const challengerId = String(challenge.challengerId || "");
  const challengedId = String(challenge.challengedId || "");
  const challengedIsBot = challenge.challengedIsBot === true ||
    _isBotId(challengedId);
  const challengerStat = _challengePlayerStats(challenge, challengerId);
  const challengedStat = _challengePlayerStats(challenge, challengedId);
  let winnerId = null;
  let rankBonus = 0;
  const awards = {
    [challengerId]: 0,
    [challengedId]: 0,
  };
  if (!expired) {
    const outcome = determineWinner(challengerStat, challengedStat);
    winnerId = outcome === "a"
      ? challengerId
      : outcome === "b"
        ? challengedId
        : null;
    for (const stat of [challengerStat, challengedStat]) {
      const won = winnerId === stat.id;
      const draw = winnerId == null;
      awards[stat.id] = hilalAward(stat.correct, won, draw);
    }
    if (winnerId === challengerId) {
      rankBonus = challengeRankBonus(
        challenge.challengerRank,
        challenge.challengedRank,
      );
    } else if (winnerId === challengedId) {
      rankBonus = challengeRankBonus(
        challenge.challengedRank,
        challenge.challengerRank,
      );
    }
    if (winnerId && rankBonus > 0) {
      awards[winnerId] += rankBonus;
    }
  }

  const weekId = weekIdIstanbul();
  const playerIds = [challengerId, challengedId];
  const isBotSide = playerIds.map((id) => (
    id === challengedId ? challengedIsBot : _isBotId(id)
  ));
  const weeklyRefs = playerIds.map((id) => _weeklyEntryRef(db, weekId, id));
  const playerRefs = playerIds.map((id, i) => (
    isBotSide[i] ? null : db.collection("quiz_players").doc(id)
  ));
  // Firestore tx: tüm okumalar yazmalardan önce.
  const weeklySnaps = [];
  const playerSnaps = [];
  for (const ref of weeklyRefs) weeklySnaps.push(await tx.get(ref));
  for (const ref of playerRefs) {
    playerSnaps.push(ref ? await tx.get(ref) : null);
  }

  if (!expired) {
    for (let i = 0; i < playerIds.length; i += 1) {
      const id = playerIds[i];
      const delta = awards[id] || 0;
      const name = id === challengerId
        ? challenge.challengerName
        : challenge.challengedName;
      if (isBotSide[i]) {
        _writeBotWeeklyDelta(tx, {
          weeklyRef: weeklyRefs[i],
          weeklySnap: weeklySnaps[i],
          delta,
          name,
          level: id === challengedId
            ? challenge.challengedLevel
            : challenge.challengerLevel,
          botId: id,
        });
        continue;
      }
      _writeHilalDelta(tx, {
        playerRef: playerRefs[i],
        weeklyRef: weeklyRefs[i],
        playerSnap: playerSnaps[i],
        weeklySnap: weeklySnaps[i],
        delta,
        name,
        weekId,
        matchesCompletedInc: 1,
      });
    }
  }

  challenge.status = expired ? "expired" : "completed";
  challenge.completedAwarded = true;
  if (!expired) {
    challenge.top3RivalryPending = true;
  }
  challenge.version = _nextVersion(challenge);
  challenge.result = {
    winnerId,
    expired,
    rankBonus,
    players: [challengerStat, challengedStat].map((stat) => ({
      ...stat,
      hilalsAwarded: awards[stat.id] || 0,
    })),
    roundMarks: {
      [challengerId]: _challengeRoundMarks(challenge, challengerId),
      [challengedId]: _challengeRoundMarks(challenge, challengedId),
    },
  };
  challenge.updatedAt = Timestamp.now();
  tx.set(challengeRef, {
    status: challenge.status,
    result: challenge.result,
    completedAwarded: true,
    ...(expired ? {} : { top3RivalryPending: true }),
    version: challenge.version,
    activePlayerId: FieldValue.delete(),
    updatedAt: challenge.updatedAt,
  }, { merge: true });
  if (playerRefs[0] && !isBotSide[0]) {
    tx.set(playerRefs[0], {
      outgoingOpenChallengeIds: FieldValue.arrayRemove(challengeRef.id),
      [`openChallengePeers.${challengedId}`]: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (playerRefs[1] && !isBotSide[1]) {
    tx.set(playerRefs[1], {
      [`openChallengePeers.${challengerId}`]: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
}

async function _resolveChallengeRoundIfReady(tx, db, challengeRef, challenge, nowMs) {
  const status = String(challenge.status || "");
  if (status !== "challenger_playing" && status !== "opponent_playing") {
    return { finishedSide: false };
  }
  if (challengeIsExpired(challenge, nowMs)) {
    await _finalizeChallenge(tx, db, challengeRef, challenge, { expired: true });
    return { finishedSide: true, expired: true };
  }
  const activeId = String(challenge.activePlayerId || "");
  if (!activeId) return { finishedSide: false };
  const round = Math.max(0, Math.floor(Number(challenge.currentRound) || 0));
  const key = String(round);
  const answers = { ...(challenge.answers?.[key] || {}) };
  if (
    !answers[activeId] &&
    shouldAutoTimeoutAnswers(nowMs, challenge.deadlineMs)
  ) {
    answers[activeId] = {
      choice: -1,
      elapsedMs: ROUND_DURATION_MS,
      correct: false,
    };
  }
  if (!answers[activeId]) return { finishedSide: false };

  challenge.answers = { ...(challenge.answers || {}), [key]: answers };
  challenge.lastResolution = {
    round,
    choices: { [activeId]: answers[activeId].choice },
    elapsedMs: { [activeId]: answers[activeId].elapsedMs },
  };
  challenge.version = _nextVersion(challenge);

  if (round >= ROUND_COUNT - 1) {
    if (status === "challenger_playing") {
      challenge.status = "awaiting_opponent";
      challenge.activePlayerId = null;
      challenge.currentRound = 0;
      challenge.roundStartedAtMs = 0;
      challenge.deadlineMs = 0;
      const patch = {
        answers: challenge.answers,
        lastResolution: challenge.lastResolution,
        status: challenge.status,
        activePlayerId: FieldValue.delete(),
        currentRound: 0,
        roundStartedAtMs: 0,
        deadlineMs: 0,
        version: challenge.version,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (_isChallengeBotOpponent(challenge)) {
        const respondAfter = nowMs + CHALLENGE_BOT_DELAY_MS;
        challenge.botRespondAfterMs = respondAfter;
        patch.botRespondAfterMs = respondAfter;
        // 12 saatlik bot cevabı TTL'yi aşmasın.
        const nextDeadline = _challengeBotMinDeadlineMs(
          respondAfter,
          challenge.challengeDeadlineMs,
        );
        if (nextDeadline !== Number(challenge.challengeDeadlineMs)) {
          challenge.challengeDeadlineMs = nextDeadline;
          patch.challengeDeadlineMs = nextDeadline;
        }
      }
      tx.set(challengeRef, patch, { merge: true });
      return { finishedSide: true, awaitingOpponent: true };
    }
    await _finalizeChallenge(tx, db, challengeRef, challenge);
    tx.set(challengeRef, {
      answers: challenge.answers,
      lastResolution: challenge.lastResolution,
      version: challenge.version,
    }, { merge: true });
    return { finishedSide: true, completed: true };
  }

  challenge.currentRound = round + 1;
  challenge.roundStartedAtMs = nowMs + ROUND_REVEAL_MS;
  challenge.deadlineMs = challenge.roundStartedAtMs + ROUND_DURATION_MS;
  tx.set(challengeRef, {
    answers: challenge.answers,
    lastResolution: challenge.lastResolution,
    currentRound: challenge.currentRound,
    roundStartedAtMs: challenge.roundStartedAtMs,
    deadlineMs: challenge.deadlineMs,
    version: challenge.version,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { finishedSide: false };
}

/**
 * Bota meydan okuma: 12 saat sonra zayıf cevap yazıp maçı bitir.
 * Can / push yok; yalnızca haftalık bot satırı güncellenir.
 */
async function _maybeResolveBotChallenge(tx, db, challengeRef, challenge, nowMs) {
  if (!_isChallengeBotOpponent(challenge)) return { resolved: false };
  if (String(challenge.status || "") !== "awaiting_opponent") {
    return { resolved: false };
  }
  if (challenge.completedAwarded === true) return { resolved: false };
  if (challengeIsExpired(challenge, nowMs)) {
    await _finalizeChallenge(tx, db, challengeRef, challenge, { expired: true });
    return { resolved: true, expired: true };
  }
  const readyAt = Math.floor(Number(challenge.botRespondAfterMs) || 0);
  if (readyAt <= 0 || nowMs < readyAt) return { resolved: false };

  const botId = String(challenge.challengedId || "");
  const questionIds = Array.isArray(challenge.questionIds)
    ? challenge.questionIds
    : [];
  const plan = _challengeBotWeakPlan(questionIds);
  const answers = { ...(challenge.answers || {}) };
  for (let round = 0; round < ROUND_COUNT; round += 1) {
    const key = String(round);
    const roundAnswers = { ...(answers[key] || {}) };
    const step = plan[round] || {
      choice: -1,
      elapsedMs: ROUND_DURATION_MS,
      correct: false,
    };
    roundAnswers[botId] = {
      choice: step.choice,
      elapsedMs: step.elapsedMs,
      correct: step.correct === true,
    };
    answers[key] = roundAnswers;
  }
  challenge.answers = answers;
  challenge.botRespondedAtMs = nowMs;
  await _finalizeChallenge(tx, db, challengeRef, challenge);
  tx.set(challengeRef, {
    answers: challenge.answers,
    botRespondedAtMs: nowMs,
  }, { merge: true });
  return { resolved: true, completed: true };
}

/** Davet/hatırlatma yalnız rakibe; sonuçta oyundaki kişiye push yok. */
function challengePushRecipients({
  kind,
  challengerId,
  challengedId,
  exceptOwnerHash = "",
}) {
  const except = String(exceptOwnerHash || "").trim();
  const invitedLike = kind === "invited" || kind === "reminder";
  const raw = invitedLike
    ? [challengedId]
    : [challengerId, challengedId];
  return [...new Set(
    raw.map((id) => String(id || "").trim()).filter(Boolean),
  )].filter((id) => !_isBotId(id) && id !== except);
}

function claimChallengeNotify(challenge, field) {
  if (!challenge || challenge[field] === true) return false;
  challenge[field] = true;
  return true;
}

function _queueChallengeTransitionPushes(tx, challengeRef, challenge, resolved) {
  let notifyAwaiting = false;
  let notifyCompleted = false;
  if (
    resolved.awaitingOpponent &&
    !_isChallengeBotOpponent(challenge) &&
    claimChallengeNotify(challenge, "invitedPushSent")
  ) {
    notifyAwaiting = true;
    tx.set(challengeRef, {
      invitedPushSent: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (
    resolved.completed &&
    claimChallengeNotify(challenge, "completedPushSent")
  ) {
    notifyCompleted = true;
    tx.set(challengeRef, {
      completedPushSent: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  return { notifyAwaiting, notifyCompleted };
}

async function _deliverChallengeOutcomePushes(db, challenge, challengeId, {
  notifyAwaiting = false,
  notifyCompleted = false,
  exceptOwnerHash = "",
} = {}) {
  if (notifyAwaiting) {
    const targets = challengePushRecipients({
      kind: "invited",
      challengerId: challenge.challengerId,
      challengedId: challenge.challengedId,
      exceptOwnerHash,
    });
    await Promise.all(targets.map((id) => _deliverQuizChallengePush({
      db,
      ownerHash: id,
      kind: "invited",
      fromName: challenge.challengerName,
      challengeId,
    })));
  }
  if (notifyCompleted && challenge.result) {
    const winnerId = String(challenge.result.winnerId || "");
    const kindFor = (id) => {
      if (!winnerId) return "draw";
      return winnerId === id ? "won" : "lost";
    };
    const targets = challengePushRecipients({
      kind: "completed",
      challengerId: challenge.challengerId,
      challengedId: challenge.challengedId,
      exceptOwnerHash,
    });
    await Promise.all(targets.map((id) => _deliverQuizChallengePush({
      db,
      ownerHash: id,
      kind: kindFor(id),
      fromName: id === challenge.challengerId
        ? challenge.challengedName
        : challenge.challengerName,
      challengeId,
    })));
  }
}

async function _deliverQuizChallengePush({
  db,
  ownerHash,
  kind,
  fromName,
  challengeId,
}) {
  if (_isBotId(ownerHash)) return null;
  const deviceSnap = await db.collection("quiz_devices").doc(ownerHash).get();
  if (!deviceSnap.exists) return null;
  const device = deviceSnap.data() || {};
  const token = String(device.token || "").trim();
  if (token.length < 32) return null;
  const copy = quizChallengeCopy(device.locale, kind, { name: fromName });
  try {
    return await getMessaging().send({
      token,
      notification: copy,
      data: {
        type: "hilal_duel",
        reason: `challenge_${kind}`,
        challengeId: String(challengeId || ""),
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
  } catch (error) {
    const code = String(error?.code || "");
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-registration-token")
    ) {
      await deviceSnap.ref.delete().catch(() => {});
    }
    console.error("[HilalDuel] challenge push failed", ownerHash, error);
    return null;
  }
}

const createQuizChallenge = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    const autoPlay = req.data?.autoPlay === true;
    if (autoPlay && !(await _quizCallerIsAdmin(db, req))) {
      throw new HttpsError(
        "permission-denied",
        "Otomatik gönderim yalnız admin için.",
      );
    }
    await _assertQuizCallerRates(db, req, ownerHash, "challenge_create", 15);
    const name = _validatedName(req.data?.name);
    const opponentId = _validatedOpponentId(req.data?.opponentOwnerHash);
    if (opponentId === ownerHash) {
      throw new HttpsError("invalid-argument", "Kendine meydan okuyamazsın.");
    }
    const isBotOpponent = _isBotId(opponentId);
    const opponentRef = isBotOpponent
      ? null
      : db.collection("quiz_players").doc(opponentId);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const weekId = weekIdIstanbul();
    const [opponentSnap, playerSnap, botWeeklySnap] = await Promise.all([
      opponentRef ? opponentRef.get() : Promise.resolve(null),
      playerRef.get(),
      isBotOpponent
        ? _weeklyEntryRef(db, weekId, opponentId).get()
        : Promise.resolve(null),
    ]);
    if (isBotOpponent) {
      if (!botWeeklySnap?.exists) {
        throw new HttpsError("not-found", "Rakip bulunamadı.");
      }
      const botRow = botWeeklySnap.data() || {};
      if (botRow.isBot !== true) {
        throw new HttpsError("not-found", "Rakip bulunamadı.");
      }
    } else if (!opponentSnap?.exists) {
      throw new HttpsError("not-found", "Rakip bulunamadı.");
    }
    const [relatedSnap, outgoingSnap, incomingSnap] = await Promise.all([
      db.collection("quiz_challenges")
        .where("participantIds", "array-contains", ownerHash)
        .limit(30)
        .get(),
      db.collection("quiz_challenges")
        .where("challengerId", "==", ownerHash)
        .limit(20)
        .get(),
      db.collection("quiz_challenges")
        .where("challengedId", "==", ownerHash)
        .limit(20)
        .get(),
    ]);

    const premium = await _isPremiumCaller(db, req);
    const playerData = playerSnap.data() || {};
    const opponentData = isBotOpponent
      ? (botWeeklySnap.data() || {})
      : (opponentSnap.data() || {});
    const selfWeekly = playerData.weekId === weekId
      ? Math.floor(Number(playerData.weeklyHilals) || 0)
      : 0;
    const oppWeekly = isBotOpponent
      ? Math.floor(Number(opponentData.weeklyHilals) || 0)
      : (opponentData.weekId === weekId
        ? Math.floor(Number(opponentData.weeklyHilals) || 0)
        : 0);
    const challengedName = isBotOpponent
      ? _botDisplayName(opponentData.name)
      : String(opponentData.name || "Oyuncu").slice(0, 32);
    const challengedLevel = isBotOpponent
      ? Math.max(1, Math.min(3, Math.floor(Number(opponentData.level) || 1)))
      : levelForHilals(Math.floor(Number(opponentData.hilals) || 0)).level;
    const challengedHilals = isBotOpponent
      ? Math.floor(Number(opponentData.weeklyHilals) || 0)
      : Math.floor(Number(opponentData.hilals) || 0);
    const [selfRank, oppRank] = await Promise.all([
      _computeWeeklyRank(db, weekId, ownerHash, selfWeekly),
      _computeWeeklyRank(db, weekId, opponentId, oppWeekly),
    ]);
    const challengeId = crypto.randomBytes(16).toString("hex");
    const nowMs = Date.now();
    const challengeDeadlineMs = nowMs + CHALLENGE_TTL_MS;
    const challengeRef = db.collection("quiz_challenges").doc(challengeId);

    const challenge = await db.runTransaction(async (tx) => {
      const freshPlayer = await tx.get(playerRef);
      let freshOpponent = null;
      if (!isBotOpponent) {
        freshOpponent = await tx.get(opponentRef);
        if (!freshOpponent.exists) {
          throw new HttpsError("not-found", "Rakip bulunamadı.");
        }
      } else {
        const freshBotWeekly = await tx.get(
          _weeklyEntryRef(db, weekId, opponentId),
        );
        if (!freshBotWeekly.exists || freshBotWeekly.data()?.isBot !== true) {
          throw new HttpsError("not-found", "Rakip bulunamadı.");
        }
      }
      const storedIds = Array.isArray(freshPlayer.data()?.outgoingOpenChallengeIds)
        ? freshPlayer.data().outgoingOpenChallengeIds.map(String)
        : [];
      const peerIds = [
        openPeerChallengeId(freshPlayer.data(), opponentId),
        openPeerChallengeId(freshOpponent?.data(), ownerHash),
      ];
      const seenIds = new Set();
      const relatedFresh = [];
      const seedDocs = [
        ...relatedSnap.docs,
        ...outgoingSnap.docs,
        ...incomingSnap.docs,
      ];
      for (const doc of seedDocs) {
        if (seenIds.has(doc.id)) continue;
        seenIds.add(doc.id);
        relatedFresh.push(await tx.get(doc.ref));
      }
      for (const id of [...storedIds, ...peerIds]) {
        const clean = String(id || "").trim();
        if (!clean || seenIds.has(clean)) continue;
        seenIds.add(clean);
        relatedFresh.push(
          await tx.get(db.collection("quiz_challenges").doc(clean)),
        );
      }
      const tally = tallyCountableChallenges(
        relatedFresh.map((snap) => ({
          id: snap.id,
          data: snap.data() || {},
        })),
        ownerHash,
        opponentId,
        nowMs,
      );
      if (tally.outgoingOpen >= CHALLENGE_MAX_ACTIVE_OUTGOING) {
        throw new HttpsError(
          "resource-exhausted",
          "Aynı anda en fazla 3 açık meydan okuman olabilir.",
        );
      }
      if (tally.hasOpenPair) {
        throw new HttpsError(
          "already-exists",
          "Bu rakiple zaten açık bir meydan okumanız var.",
        );
      }
      const questionIds = _pickQuestions([
        ...normalizeQuestionIdList(freshPlayer.data()?.seenQuestionIds),
        ...normalizeQuestionIdList(freshOpponent?.data()?.seenQuestionIds),
      ]);
      await _chargeHeartForChallenge(tx, db, {
        playerRef,
        playerData: freshPlayer.data() || {},
        ownerHash,
        premium,
        nowMs,
      });
      const me = freshPlayer.data() || {};
      const doc = {
        challengerId: ownerHash,
        challengerName: name,
        challengerLevel: levelForHilals(Math.floor(Number(me.hilals) || 0)).level,
        challengerHilals: Math.floor(Number(me.hilals) || 0),
        challengerRank: selfRank,
        challengedId: opponentId,
        challengedName,
        challengedLevel,
        challengedHilals,
        challengedRank: oppRank,
        challengedIsBot: isBotOpponent,
        botRespondAfterMs: 0,
        participantIds: [ownerHash, opponentId],
        questionIds,
        status: "challenger_playing",
        activePlayerId: ownerHash,
        currentRound: 0,
        roundStartedAtMs: nowMs,
        deadlineMs: nowMs + ROUND_DURATION_MS,
        challengeDeadlineMs,
        answers: {},
        lastResolution: null,
        reminderSent: false,
        version: 1,
        createdAt: Timestamp.fromMillis(nowMs),
        updatedAt: Timestamp.fromMillis(nowMs),
        expiresAt: Timestamp.fromMillis(nowMs + CHALLENGE_DOC_TTL_MS),
      };
      tx.set(playerRef, {
        name,
        outgoingOpenChallengeIds: [...tally.openOutgoingIds, challengeId],
        [`openChallengePeers.${opponentId}`]: challengeId,
        seenQuestionIds: mergeSeenQuestionIds(me.seenQuestionIds, questionIds),
        updatedAt: FieldValue.serverTimestamp(),
        ...(me.createdAt ? {} : { createdAt: FieldValue.serverTimestamp() }),
      }, { merge: true });
      if (!isBotOpponent) {
        tx.set(opponentRef, {
          [`openChallengePeers.${ownerHash}`]: challengeId,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      tx.create(challengeRef, doc);
      if (autoPlay) {
        const patch = _applyAdminAutoChallengeToDoc(doc, ownerHash, nowMs);
        tx.set(challengeRef, patch, { merge: true });
      }
      return doc;
    });
    if (autoPlay && !_isChallengeBotOpponent(challenge)) {
      await _deliverChallengeOutcomePushes(db, challenge, challengeId, {
        notifyAwaiting: true,
        exceptOwnerHash: ownerHash,
      });
    }
    return {
      ok: true,
      challenge: _serializeChallenge(
        challengeId,
        challenge,
        ownerHash,
        _requestLocale(req),
      ),
    };
  },
);

const acceptQuizChallenge = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "challenge_accept", 20);
    const challengeId = _validatedDocumentId(req.data?.challengeId, "meydan okuma");
    const challengeRef = db.collection("quiz_challenges").doc(challengeId);
    const playerRef = db.collection("quiz_players").doc(ownerHash);
    const premium = await _isPremiumCaller(db, req);
    const nowMs = Date.now();
    const acceptOutcome = await db.runTransaction(async (tx) => {
      const snap = await tx.get(challengeRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Meydan okuma bulunamadı.");
      }
      const data = snap.data() || {};
      if (String(data.challengedId || "") !== ownerHash) {
        throw new HttpsError("permission-denied", "Bu davet sana ait değil.");
      }
      if (_isChallengeBotOpponent(data)) {
        throw new HttpsError(
          "failed-precondition",
          "Bu meydan okuma otomatik cevaplanır.",
        );
      }
      if (challengeIsExpired(data, nowMs)) {
        await _finalizeChallenge(tx, db, challengeRef, data, { expired: true });
        return { expired: true };
      }
      if (data.status === "opponent_playing" && data.activePlayerId === ownerHash) {
        return { challenge: data };
      }
      if (data.status !== "awaiting_opponent") {
        throw new HttpsError("failed-precondition", "Bu meydan okuma kabul edilemez.");
      }
      const playerSnap = await tx.get(playerRef);
      await _chargeHeartForChallenge(tx, db, {
        playerRef,
        playerData: playerSnap.data() || {},
        ownerHash,
        premium,
        nowMs,
      });
      tx.set(playerRef, {
        seenQuestionIds: mergeSeenQuestionIds(
          playerSnap.data()?.seenQuestionIds,
          data.questionIds,
        ),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      data.status = "opponent_playing";
      data.activePlayerId = ownerHash;
      data.currentRound = 0;
      data.roundStartedAtMs = nowMs;
      data.deadlineMs = nowMs + ROUND_DURATION_MS;
      data.lastResolution = null;
      data.version = _nextVersion(data);
      data.updatedAt = Timestamp.fromMillis(nowMs);
      tx.set(challengeRef, {
        status: data.status,
        activePlayerId: data.activePlayerId,
        currentRound: 0,
        roundStartedAtMs: data.roundStartedAtMs,
        deadlineMs: data.deadlineMs,
        lastResolution: null,
        version: data.version,
        updatedAt: data.updatedAt,
      }, { merge: true });
      return { challenge: data };
    });
    if (acceptOutcome.expired) {
      throw new HttpsError(
        "failed-precondition",
        "Bu meydan okumanın süresi doldu.",
      );
    }
    return {
      ok: true,
      challenge: _serializeChallenge(
        challengeId,
        acceptOutcome.challenge,
        ownerHash,
        _requestLocale(req),
      ),
    };
  },
);

const getQuizChallenge = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "challenge_get", 450);
    const challengeId = _validatedDocumentId(req.data?.challengeId, "meydan okuma");
    const challengeRef = db.collection("quiz_challenges").doc(challengeId);
    let notifyAwaiting = false;
    let notifyCompleted = false;
    const challenge = await db.runTransaction(async (tx) => {
      const snap = await tx.get(challengeRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Meydan okuma bulunamadı.");
      }
      const data = snap.data() || {};
      if (
        ownerHash !== data.challengerId &&
        ownerHash !== data.challengedId
      ) {
        throw new HttpsError("permission-denied", "Bu meydan okumaya erişemezsiniz.");
      }
      const nowMs = Date.now();
      if (
        challengeIsExpired(data, nowMs) &&
        data.status !== "completed" &&
        data.status !== "expired"
      ) {
        await _finalizeChallenge(tx, db, challengeRef, data, { expired: true });
        return data;
      }
      const botResolved = await _maybeResolveBotChallenge(
        tx,
        db,
        challengeRef,
        data,
        nowMs,
      );
      if (botResolved.completed) {
        const queued = _queueChallengeTransitionPushes(
          tx,
          challengeRef,
          data,
          { completed: true, awaitingOpponent: false },
        );
        notifyCompleted = queued.notifyCompleted;
        return data;
      }
      if (botResolved.expired) {
        return data;
      }
      const resolved = await _resolveChallengeRoundIfReady(
        tx,
        db,
        challengeRef,
        data,
        nowMs,
      );
      const queued = _queueChallengeTransitionPushes(
        tx,
        challengeRef,
        data,
        resolved,
      );
      notifyAwaiting = queued.notifyAwaiting;
      notifyCompleted = queued.notifyCompleted;
      return data;
    });
    await _deliverChallengeOutcomePushes(db, challenge, challengeId, {
      notifyAwaiting,
      notifyCompleted,
      exceptOwnerHash: ownerHash,
    });
    if (notifyCompleted) {
      await _scheduleTop3RivalryFromChallenge(db, challengeRef, challenge);
    }
    return {
      ok: true,
      challenge: _serializeChallenge(
        challengeId,
        challenge,
        ownerHash,
        _requestLocale(req),
      ),
    };
  },
);

const submitQuizChallengeAnswer = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "challenge_submit", 60);
    const challengeId = _validatedDocumentId(req.data?.challengeId, "meydan okuma");
    const round = Number(req.data?.round);
    const choice = Number(req.data?.choice);
    if (!Number.isInteger(round) || round < 0 || round >= ROUND_COUNT) {
      throw new HttpsError("invalid-argument", "Geçersiz soru sırası.");
    }
    if (!Number.isInteger(choice) || choice < 0 || choice > 3) {
      throw new HttpsError("invalid-argument", "Geçersiz cevap.");
    }
    const challengeRef = db.collection("quiz_challenges").doc(challengeId);
    let notifyAwaiting = false;
    let notifyCompleted = false;
    const challenge = await db.runTransaction(async (tx) => {
      const snap = await tx.get(challengeRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Meydan okuma bulunamadı.");
      }
      const data = snap.data() || {};
      const status = String(data.status || "");
      if (
        (status !== "challenger_playing" && status !== "opponent_playing") ||
        String(data.activePlayerId || "") !== ownerHash ||
        Number(data.currentRound) !== round
      ) {
        throw new HttpsError("failed-precondition", "Bu soru artık aktif değil.");
      }
      const nowMs = Date.now();
      if (challengeIsExpired(data, nowMs)) {
        await _finalizeChallenge(tx, db, challengeRef, data, { expired: true });
        return data;
      }
      const existing = _challengeAnswerFor(data, round, ownerHash);
      if (
        existing &&
        !canReplaceTimeoutAnswer(
          existing,
          nowMs,
          data.roundStartedAtMs,
          data.deadlineMs,
        )
      ) {
        const resolved = await _resolveChallengeRoundIfReady(
          tx,
          db,
          challengeRef,
          data,
          nowMs,
        );
        const queued = _queueChallengeTransitionPushes(
          tx,
          challengeRef,
          data,
          resolved,
        );
        notifyAwaiting = queued.notifyAwaiting;
        notifyCompleted = queued.notifyCompleted;
        return data;
      }
      const gate = canAcceptAnswer(nowMs, data.roundStartedAtMs, data.deadlineMs);
      if (!gate.ok && gate.reason === "not_started") {
        throw new HttpsError("failed-precondition", "Soru henüz başlamadı.");
      }
      if (!gate.ok && gate.reason === "expired") {
        const resolved = await _resolveChallengeRoundIfReady(
          tx,
          db,
          challengeRef,
          data,
          nowMs,
        );
        const queued = _queueChallengeTransitionPushes(
          tx,
          challengeRef,
          data,
          resolved,
        );
        notifyAwaiting = queued.notifyAwaiting;
        notifyCompleted = queued.notifyCompleted;
        return data;
      }
      const question = QUESTION_BY_ID.get(data.questionIds[round]);
      if (!question) {
        throw new HttpsError("failed-precondition", "Soru bulunamadı.");
      }
      const elapsedMs = Math.min(
        ROUND_DURATION_MS,
        Math.max(0, nowMs - data.roundStartedAtMs),
      );
      const graded = {
        choice,
        elapsedMs,
        correct: choice === question.correctIndex,
      };
      data.answers = {
        ...(data.answers || {}),
        [String(round)]: {
          ...(data.answers?.[String(round)] || {}),
          [ownerHash]: graded,
        },
      };
      const resolved = await _resolveChallengeRoundIfReady(
        tx,
        db,
        challengeRef,
        data,
        nowMs,
      );
      const queued = _queueChallengeTransitionPushes(
        tx,
        challengeRef,
        data,
        resolved,
      );
      notifyAwaiting = queued.notifyAwaiting;
      notifyCompleted = queued.notifyCompleted;
      if (!_challengeAnswerFor(data, round, ownerHash)) {
        data.version = _nextVersion(data);
        tx.set(challengeRef, {
          [`answers.${round}.${ownerHash}`]: graded,
          version: data.version,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      return data;
    });
    await _deliverChallengeOutcomePushes(db, challenge, challengeId, {
      notifyAwaiting,
      notifyCompleted,
      exceptOwnerHash: ownerHash,
    });
    if (notifyCompleted) {
      await _scheduleTop3RivalryFromChallenge(db, challengeRef, challenge);
    }
    return {
      ok: true,
      challenge: _serializeChallenge(
        challengeId,
        challenge,
        ownerHash,
        _requestLocale(req),
      ),
    };
  },
);

const listQuizChallenges = onCall(
  { region: REGION, memory: "256MiB", enforceAppCheck: ENFORCE_APP_CHECK },
  async (req) => {
    const db = getFirestore();
    const { ownerHash } = await _assertInstallation(db, req);
    await _assertQuizCallerRates(db, req, ownerHash, "challenge_list", 40);
    const snap = await db.collection("quiz_challenges")
      .where("participantIds", "array-contains", ownerHash)
      .limit(30)
      .get();
    const nowMs = Date.now();
    const items = [];
    for (const doc of snap.docs) {
      let fresh = doc.data() || {};
      if (
        challengeIsExpired(fresh, nowMs) &&
        fresh.status !== "completed" &&
        fresh.status !== "expired"
      ) {
        try {
          await db.runTransaction(async (tx) => {
            const currentSnap = await tx.get(doc.ref);
            const current = currentSnap.data() || {};
            if (
              challengeIsExpired(current, Date.now()) &&
              current.status !== "completed" &&
              current.status !== "expired"
            ) {
              await _finalizeChallenge(tx, db, doc.ref, current, {
                expired: true,
              });
            }
          });
          fresh = (await doc.ref.get()).data() || fresh;
        } catch (error) {
          console.error("[HilalDuel] challenge expire on list", doc.id, error);
        }
      } else if (
        fresh.status === "awaiting_opponent" &&
        _isChallengeBotOpponent(fresh)
      ) {
        try {
          let resolvedChallenge = null;
          await db.runTransaction(async (tx) => {
            const currentSnap = await tx.get(doc.ref);
            const current = currentSnap.data() || {};
            const result = await _maybeResolveBotChallenge(
              tx,
              db,
              doc.ref,
              current,
              Date.now(),
            );
            if (result.resolved && result.completed) {
              resolvedChallenge = current;
            }
          });
          fresh = (await doc.ref.get()).data() || fresh;
          if (resolvedChallenge) {
            await _scheduleTop3RivalryFromChallenge(
              db,
              doc.ref,
              resolvedChallenge,
            );
          }
        } catch (error) {
          console.error("[HilalDuel] bot challenge resolve on list", doc.id, error);
        }
      }
      const status = String(fresh.status || "");
      if (!shouldListChallengeInInbox(fresh, nowMs)) continue;
      const selfIsChallenger = ownerHash === fresh.challengerId;
      const winnerId = String(fresh.result?.winnerId || "");
      const outcome = challengeInboxOutcome(status, winnerId, ownerHash);
      items.push({
        id: doc.id,
        status,
        role: selfIsChallenger ? "challenger" : "challenged",
        canAccept: status === "awaiting_opponent" &&
          !selfIsChallenger &&
          !_isChallengeBotOpponent(fresh),
        myTurn: (
          (status === "challenger_playing" ||
            status === "opponent_playing") &&
          fresh.activePlayerId === ownerHash
        ),
        challengeDeadlineMs: challengeDeadlineMsOf(fresh),
        updatedAtMs: _timestampMs(fresh.updatedAt),
        opponentName: selfIsChallenger
          ? String(fresh.challengedName || "Oyuncu")
          : String(fresh.challengerName || "Oyuncu"),
        opponentLevel: selfIsChallenger
          ? Math.max(1, Math.floor(Number(fresh.challengedLevel) || 1))
          : Math.max(1, Math.floor(Number(fresh.challengerLevel) || 1)),
        result: fresh.result || null,
        outcome,
      });
    }
    items.sort((a, b) => (b.updatedAtMs || 0) - (a.updatedAtMs || 0));
    return { ok: true, challenges: items.slice(0, 20) };
  },
);

/** Süresi dolanları kapat + son 2 saat hatırlatması. */
const scanQuizChallenges = onSchedule(
  {
    region: REGION,
    schedule: "every 15 minutes",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const db = getFirestore();
    const nowMs = Date.now();
    const openStatuses = [
      "challenger_playing",
      "awaiting_opponent",
      "opponent_playing",
    ];
    let expired = 0;
    let reminded = 0;
    let botResolved = 0;
    for (const status of openStatuses) {
      const snap = await db.collection("quiz_challenges")
        .where("status", "==", status)
        .limit(40)
        .get();
      for (const doc of snap.docs) {
        const data = doc.data() || {};
        try {
          if (challengeIsExpired(data, nowMs)) {
            await db.runTransaction(async (tx) => {
              const fresh = await tx.get(doc.ref);
              const current = fresh.data() || {};
              if (
                challengeIsExpired(current, Date.now()) &&
                current.status !== "completed" &&
                current.status !== "expired"
              ) {
                await _finalizeChallenge(tx, db, doc.ref, current, {
                  expired: true,
                });
              }
            });
            expired += 1;
            continue;
          }
          if (
            status === "awaiting_opponent" &&
            _isChallengeBotOpponent(data)
          ) {
            let didResolve = false;
            let completedChallenge = null;
            await db.runTransaction(async (tx) => {
              const fresh = await tx.get(doc.ref);
              const current = fresh.data() || {};
              const result = await _maybeResolveBotChallenge(
                tx,
                db,
                doc.ref,
                current,
                Date.now(),
              );
              if (result.resolved) {
                didResolve = true;
                if (result.completed) {
                  const queued = _queueChallengeTransitionPushes(
                    tx,
                    doc.ref,
                    current,
                    { completed: true, awaitingOpponent: false },
                  );
                  if (queued.notifyCompleted) completedChallenge = current;
                }
              }
            });
            if (didResolve) {
              botResolved += 1;
              if (completedChallenge) {
                await _deliverChallengeOutcomePushes(
                  db,
                  completedChallenge,
                  doc.id,
                  { notifyCompleted: true },
                );
                await _scheduleTop3RivalryFromChallenge(
                  db,
                  doc.ref,
                  completedChallenge,
                );
              }
            }
            continue;
          }
          const deadline = challengeDeadlineMsOf(data);
          const inReminderWindow = deadline > 0 &&
            nowMs >= deadline - CHALLENGE_REMINDER_BEFORE_MS &&
            nowMs < deadline;
          if (
            inReminderWindow &&
            data.reminderSent !== true &&
            status === "awaiting_opponent" &&
            !_isChallengeBotOpponent(data)
          ) {
            let claimedReminder = false;
            await db.runTransaction(async (tx) => {
              const fresh = await tx.get(doc.ref);
              const current = fresh.data() || {};
              if (
                current.reminderSent === true ||
                String(current.status || "") !== "awaiting_opponent" ||
                _isChallengeBotOpponent(current)
              ) {
                return;
              }
              const freshDeadline = challengeDeadlineMsOf(current);
              const now = Date.now();
              if (
                !(freshDeadline > 0 &&
                  now >= freshDeadline - CHALLENGE_REMINDER_BEFORE_MS &&
                  now < freshDeadline)
              ) {
                return;
              }
              tx.set(doc.ref, {
                reminderSent: true,
                updatedAt: FieldValue.serverTimestamp(),
              }, { merge: true });
              claimedReminder = true;
            });
            if (claimedReminder) {
              const targets = challengePushRecipients({
                kind: "reminder",
                challengerId: data.challengerId,
                challengedId: data.challengedId,
              });
              await Promise.all(targets.map((id) => _deliverQuizChallengePush({
                db,
                ownerHash: id,
                kind: "reminder",
                fromName: data.challengerName,
                challengeId: doc.id,
              })));
              reminded += 1;
            }
          }
        } catch (error) {
          console.error("[HilalDuel] challenge scan failed", doc.id, error);
        }
      }
    }
    if (expired > 0 || reminded > 0 || botResolved > 0) {
      console.log(
        `[HilalDuel] challenge scan expired=${expired} reminded=${reminded} botResolved=${botResolved}`,
      );
    }
  },
);

/**
 * Kapalı haftanın insan adayları (bot / moderasyon dışı), lobi sırasıyla.
 */
async function _listClosedWeekHumanCandidates(db, weekId) {
  const entriesRef = db.collection("quiz_weekly").doc(weekId).collection("entries");
  const snap = await entriesRef.orderBy("weeklyHilals", "desc").limit(120).get();
  const rows = [];
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const ownerHash = String(doc.id || "").trim().toLowerCase();
    const isBot = data.isBot === true || ownerHash.startsWith("bot_");
    if (isBot) continue;
    if (data.leaderboardExcluded === true) continue;
    const weeklyHilals = Math.floor(Number(data.weeklyHilals) || 0);
    if (weeklyHilals <= 0) continue;
    rows.push({
      ownerHash,
      name: String(data.name || "Oyuncu").slice(0, 32),
      weeklyHilals,
      isBot: false,
      leaderboardExcluded: false,
    });
  }
  if (rows.length === 0) return [];

  const playerSnaps = await db.getAll(
    ...rows.map((row) => db.collection("quiz_players").doc(row.ownerHash)),
  );
  const excluded = new Set();
  for (const playerSnap of playerSnaps) {
    if (playerSnap.exists && playerSnap.data()?.leaderboardExcluded === true) {
      excluded.add(playerSnap.id);
    }
  }
  const eligible = rows.filter((row) => !excluded.has(row.ownerHash));
  return _orderWeeklyLeaderboard(eligible).filter((row) => !row.isBot);
}

const _WEEKLY_REWARD_TERMINAL = new Set([
  "settled",
  "granted",
  "skipped_no_winner",
  "skipped_no_auth",
  "skipped_lifetime",
]);

function _weeklyRewardLedgerWrite(tx, rewardRef, rewardSnap, payload) {
  const body = {
    ...payload,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (!rewardSnap.exists) {
    body.createdAt = FieldValue.serverTimestamp();
  }
  tx.set(rewardRef, body, { merge: true });
}

/**
 * Önceki İstanbul haftası insan top-3:
 * - #1: şampiyon sayacı (+1) herkese
 * - Premium yoksa: #1→14g, #2→7g, #3→3g (misafir / zaten Premium atlanır)
 * Idempotent: `quiz_weekly_rewards/{weekId}` ledger.
 */
async function settleHilalWeeklyPremiumReward(db, now = new Date()) {
  const closedWeekId = previousWeekIdIstanbul(now);
  const rewardRef = db.collection(HILAL_WEEKLY_REWARDS_COLLECTION).doc(closedWeekId);
  const prior = await rewardRef.get();
  if (prior.exists && _WEEKLY_REWARD_TERMINAL.has(String(prior.data()?.status || ""))) {
    return {
      ok: true,
      duplicate: true,
      weekId: closedWeekId,
      status: String(prior.data()?.status || ""),
      ownerHash: prior.data()?.ownerHash || null,
      uid: prior.data()?.uid || null,
      placements: prior.data()?.placements || null,
    };
  }

  const candidates = await _listClosedWeekHumanCandidates(db, closedWeekId);
  const nowMs = now.getTime();

  if (candidates.length === 0) {
    const result = await db.runTransaction(async (tx) => {
      const rewardSnap = await tx.get(rewardRef);
      if (
        rewardSnap.exists &&
        _WEEKLY_REWARD_TERMINAL.has(String(rewardSnap.data()?.status || ""))
      ) {
        return {
          duplicate: true,
          status: String(rewardSnap.data()?.status || ""),
          weekId: closedWeekId,
        };
      }
      _weeklyRewardLedgerWrite(tx, rewardRef, rewardSnap, {
        status: "skipped_no_winner",
        weekId: closedWeekId,
        placements: [],
      });
      return { status: "skipped_no_winner", weekId: closedWeekId, placements: [] };
    });
    return { ok: true, ...result };
  }

  const top = candidates.slice(0, 3);
  const installSnaps = await db.getAll(
    ...top.map((row) => db.collection("quiz_installations").doc(row.ownerHash)),
  );
  const uidByHash = new Map();
  for (const snap of installSnaps) {
    uidByHash.set(snap.id, String(snap.data()?.authUid || "").trim());
  }

  const plans = top.map((row, index) => {
    const rank = index + 1;
    return {
      rank,
      ownerHash: row.ownerHash,
      name: row.name,
      weeklyHilals: row.weeklyHilals,
      uid: uidByHash.get(row.ownerHash) || "",
      grantDays: hilalWeeklyPremiumDaysForRank(rank),
    };
  });

  // Entitlement + invite (lobideki premium kontrolüyle aynı kapsam).
  const alreadyPremiumUids = new Set();
  const uniqueGrantUids = [...new Set(
    plans.map((p) => p.uid).filter((uid) => isGrantablePremiumUid(uid)),
  )];
  for (const uid of uniqueGrantUids) {
    const entSnap = await db.collection("premium_entitlements").doc(uid).get();
    const entData = entSnap.data() || {};
    if (isLifetimePremium(entData) || premiumActiveAt(entData, nowMs)) {
      alreadyPremiumUids.add(uid);
      continue;
    }
    try {
      const user = await getAuth().getUser(uid);
      const email = String(user.email || "").trim().toLowerCase();
      if (!email) continue;
      const invite = await db.collection("premium_invites").doc(email).get();
      const inviteData = invite.data() || {};
      if (isLifetimePremium(inviteData) || premiumActiveAt(inviteData, nowMs)) {
        alreadyPremiumUids.add(uid);
      }
    } catch (_) {
      // Auth yoksa entitlement'a göre devam.
    }
  }

  const result = await db.runTransaction(async (tx) => {
    const rewardSnap = await tx.get(rewardRef);
    if (
      rewardSnap.exists &&
      _WEEKLY_REWARD_TERMINAL.has(String(rewardSnap.data()?.status || ""))
    ) {
      return {
        duplicate: true,
        status: String(rewardSnap.data()?.status || ""),
        weekId: closedWeekId,
        ownerHash: rewardSnap.data()?.ownerHash || plans[0]?.ownerHash || null,
        uid: rewardSnap.data()?.uid || null,
        placements: rewardSnap.data()?.placements || null,
      };
    }

    const entKeys = [];
    const entRefs = [];
    const seenEntUid = new Set();
    for (const plan of plans) {
      if (!isGrantablePremiumUid(plan.uid) || seenEntUid.has(plan.uid)) continue;
      seenEntUid.add(plan.uid);
      entKeys.push(plan.uid);
      entRefs.push(db.collection("premium_entitlements").doc(plan.uid));
    }
    const entSnaps = [];
    for (const ref of entRefs) entSnaps.push(await tx.get(ref));
    const entByUid = new Map();
    for (let i = 0; i < entKeys.length; i += 1) {
      entByUid.set(entKeys[i], entSnaps[i]);
    }

    const championRef = db.collection("quiz_players").doc(plans[0].ownerHash);
    await tx.get(championRef);

    const placements = [];
    let firstGranted = null;
    const grantedUids = new Set();

    for (const plan of plans) {
      const placement = {
        rank: plan.rank,
        ownerHash: plan.ownerHash,
        name: plan.name,
        weeklyHilals: plan.weeklyHilals,
        uid: isGrantablePremiumUid(plan.uid) ? plan.uid : null,
        grantDays: 0,
        championIncremented: plan.rank === 1,
        premiumStatus: "skipped_no_auth",
      };

      if (plan.rank === 1) {
        tx.set(championRef, {
          hilalChampionWeeks: FieldValue.increment(1),
          hilalChampionLastWeekId: closedWeekId,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      if (!isGrantablePremiumUid(plan.uid)) {
        placements.push(placement);
        continue;
      }

      if (grantedUids.has(plan.uid)) {
        placement.premiumStatus = "skipped_duplicate_uid";
        placements.push(placement);
        continue;
      }

      const entSnap = entByUid.get(plan.uid);
      const existing = entSnap?.data() || {};
      if (isLifetimePremium(existing)) {
        placement.premiumStatus = "skipped_lifetime";
        placements.push(placement);
        continue;
      }
      if (
        alreadyPremiumUids.has(plan.uid) ||
        premiumActiveAt(existing, nowMs)
      ) {
        placement.premiumStatus = "skipped_already_premium";
        placements.push(placement);
        continue;
      }

      const grantMs = hilalWeeklyPremiumMsForRank(plan.rank);
      if (grantMs <= 0) {
        placement.premiumStatus = "skipped_no_auth";
        placements.push(placement);
        continue;
      }
      const expiresAtMs = nowMs + grantMs;
      const entRef = db.collection("premium_entitlements").doc(plan.uid);
      tx.set(entRef, {
        uid: plan.uid,
        active: true,
        expiresAt: Timestamp.fromMillis(expiresAtMs),
        hilalWeeklyBonusExpiresAt: Timestamp.fromMillis(expiresAtMs),
        hilalWeeklyRewardWeekId: closedWeekId,
        hilalWeeklyRewardAt: FieldValue.serverTimestamp(),
        hilalWeeklyRewardRank: plan.rank,
        source: HILAL_WEEKLY_PREMIUM_SOURCE,
        productId: HILAL_WEEKLY_PREMIUM_PRODUCT_PREFIX + String(plan.rank),
        platform: "cloud_function",
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      grantedUids.add(plan.uid);
      placement.premiumStatus = "granted";
      placement.grantDays = plan.grantDays;
      placement.expiresAtMs = expiresAtMs;
      placements.push(placement);
      if (!firstGranted) firstGranted = placement;
    }

    const champion = placements[0] || null;
    _weeklyRewardLedgerWrite(tx, rewardRef, rewardSnap, {
      status: "settled",
      weekId: closedWeekId,
      placements,
      ownerHash: champion?.ownerHash || null,
      uid: champion?.uid || null,
      name: champion?.name || null,
      weeklyHilals: champion?.weeklyHilals || 0,
      grantDays: firstGranted?.grantDays || 0,
      expiresAtMs: firstGranted?.expiresAtMs || null,
      championOwnerHash: champion?.ownerHash || null,
    });

    return {
      status: "settled",
      weekId: closedWeekId,
      ownerHash: champion?.ownerHash || null,
      uid: champion?.uid || null,
      placements,
      granted: placements.filter((p) => p.premiumStatus === "granted").length,
    };
  });

  return { ok: true, ...result };
}

/** Pazartesi 00:05 Istanbul — kapanan haftanın top-3 ödülü + şampiyon rozeti. */
const settleHilalWeeklyPremiumRewards = onSchedule(
  {
    region: REGION,
    schedule: "5 0 * * 1",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const db = getFirestore();
    try {
      const result = await settleHilalWeeklyPremiumReward(db, new Date());
      const granted = Array.isArray(result.placements)
        ? result.placements.filter((p) => p.premiumStatus === "granted").length
        : (result.granted || 0);
      console.log(
        "[HilalDuel] weekly top rewards " +
          "week=" + (result.weekId || "?") + " status=" + (result.status || "?") + " " +
          "duplicate=" + (result.duplicate === true) + " " +
          "champion=" + (result.ownerHash || "-") + " granted=" + granted,
      );
    } catch (error) {
      console.error("[HilalDuel] weekly top rewards failed", error);
      throw error;
    }
  },
);

const scanQuizEngagementReminders = onSchedule(
  {
    region: REGION,
    schedule: "every day 18:00",
    timeZone: "Europe/Istanbul",
    memory: "512MiB",
    timeoutSeconds: 240,
  },
  async () => {
    const db = getFirestore();
    const nowMs = Date.now();
    const weekId = weekIdIstanbul();
    const devicesSnap = await db.collection("quiz_devices")
      .where("expiresAt", ">", Timestamp.fromMillis(nowMs))
      .orderBy("expiresAt", "desc")
      .limit(ENGAGEMENT_BATCH_LIMIT)
      .get();
    let sent = 0;
    let skipped = 0;
    for (const deviceDoc of devicesSnap.docs) {
      const ownerHash = deviceDoc.id;
      const device = deviceDoc.data() || {};
      const token = String(device.token || "").trim();
      if (token.length < 32) {
        skipped += 1;
        continue;
      }
      try {
        const playerSnap = await db.collection("quiz_players").doc(ownerHash).get();
        if (!playerSnap.exists) {
          skipped += 1;
          continue;
        }
        const player = playerSnap.data() || {};
        const weeklyHilals = player.weekId === weekId
          ? Math.floor(Number(player.weeklyHilals) || 0)
          : 0;
        let currentRank = Math.floor(Number(player.lastKnownWeeklyRank) || 0);
        if (weeklyHilals !== 0 || player.weekId === weekId) {
          currentRank = await _computeWeeklyRank(
            db,
            weekId,
            ownerHash,
            weeklyHilals,
          );
        }
        const bestWeek = String(player.bestWeeklyRankWeekId || "");
        const bestWeeklyRank = bestWeek === weekId
          ? Math.floor(Number(player.bestWeeklyRank) || 0)
          : 0;
        const decision = decideQuizEngagement({
          matchesCompleted: player.matchesCompleted,
          lastMatchAtMs: player.lastMatchAt?.toMillis?.() || 0,
          lastPushAtMs: player.lastEngagementPushAt?.toMillis?.() || 0,
          nowMs,
          currentRank,
          bestWeeklyRank,
          lastKnownWeeklyRank: player.lastKnownWeeklyRank,
          createdAtMs: player.createdAt?.toMillis?.() || 0,
        });
        if (!decision.send) {
          skipped += 1;
          continue;
        }
        await _deliverQuizEngagementPush({
          db,
          ownerHash,
          token,
          locale: device.locale,
          reason: decision.reason,
          currentRank,
        });
        sent += 1;
      } catch (error) {
        const code = String(error?.code || "");
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
          await deviceDoc.ref.delete().catch(() => {});
        }
        console.error("[HilalDuel] engagement push failed", ownerHash, error);
      }
    }
    if (sent > 0 || skipped > 0) {
      console.log(
        `[HilalDuel] engagement scan sent=${sent} skipped=${skipped}`,
      );
    }
  },
);

module.exports = {
  functions: {
    createQuizSession,
    getQuizProfile,
    beginQuizReward,
    claimQuizReward,
    startQuizMatch,
    cancelQuizMatchmaking,
    pollQuizMatch,
    getQuizMatch,
    submitQuizAnswer,
    forfeitQuizMatch,
    getQuizWeeklyLeaderboard,
    adminGrantSelfQuizHilals,
    adminSetSelfQuizLevel,
    registerQuizDevice,
    cleanupAbandonedQuizQueues,
    scanQuizEngagementReminders,
    settleHilalWeeklyPremiumRewards,
    createQuizChallenge,
    acceptQuizChallenge,
    getQuizChallenge,
    submitQuizChallengeAnswer,
    listQuizChallenges,
    scanQuizChallenges,
  },
  testables: {
    levelForHilals,
    hilalsFloorForLevel,
    determineWinner,
    hilalAward,
    istanbulDayKey: _istanbulDayKey,
    weekIdIstanbul,
    previousWeekIdIstanbul,
    isGrantablePremiumUid,
    computePremiumExtendExpiresAtMs,
    computeHilalWeeklyBonusExpiresAtMs,
    pickWeeklyHumanWinner,
    pickWeeklyHumanTop,
    hilalWeeklyPremiumDaysForRank,
    hilalWeeklyPremiumMsForRank,
    HILAL_WEEKLY_PREMIUM_DAYS_BY_RANK,
    premiumActiveAt,
    isLifetimePremium,
    decideTop3RivalryNotifications,
    quizTop3RivalryCopy,
    TOP3_RIVALRY_COOLDOWN_MS,
    TOP3_CLOSE_THREAT_HILAL_GAP,
    premiumRecordActive: _premiumRecordActive,
    HILAL_WEEKLY_PREMIUM_DAYS,
    HILAL_WEEKLY_PREMIUM_MS,
    cosmeticsForLevel,
    emptyCosmetics,
    cosmeticsDocFields,
    MAX_LEVEL,
    FORFEIT_PENALTY,
    BOT_WEEKLY_CAP,
    orderWeeklyLeaderboard: _orderWeeklyLeaderboard,
    stableBotId: _stableBotId,
    botDisplayName: _botDisplayName,
    BOT_NAMES,
    decideQuizEngagement,
    quizEngagementCopy,
    pendingPromoHeartsGain,
    ENGAGEMENT_COOLDOWN_MS,
    ENGAGEMENT_MIN_IDLE_MS,
    ENGAGEMENT_MAX_IDLE_MS,
    ENGAGEMENT_NEVER_PLAYED_MIN_AGE_MS,
    ENGAGEMENT_NEVER_PLAYED_MAX_AGE_MS,
    botPlan: _botPlan,
    botReadyAtMs: _botReadyAtMs,
    botAnswerElapsedMs: _botAnswerElapsedMs,
    canAcceptAnswer,
    shouldAutoTimeoutAnswers,
    isTimeoutAnswer,
    isChoiceCorrect,
    canReplaceTimeoutAnswer,
    perspectiveResolutionChoices: _perspectiveResolutionChoices,
    ANSWER_GRACE_MS,
    allPlayersAnswered,
    shouldRefundAbandonedQueue,
    queueAbandonAtMs,
    buildHeartRefundPlayerUpdates,
    describeHeartRefund,
    adHeartBalance,
    isAdFundedQueue,
    isPremiumFundedQueue,
    isFundedQueue,
    isValidChargedAdLedger,
    isValidQueueFunding,
    QUEUE_ABANDON_MS,
    QUEUE_WAIT_MS,
    ROUND_DURATION_MS,
    ROUND_REVEAL_MS,
    pickQuestions: _pickQuestions,
    questionPayload: _questionPayload,
    mergeSeenQuestionIds,
    normalizeQuestionIdList,
    SEEN_QUESTION_IDS_CAP,
    challengeRankBonus,
    challengeIsExpired,
    challengeDeadlineMsOf,
    isCountableOpenChallenge,
    tallyCountableChallenges,
    shouldListChallengeInInbox,
    challengeInboxOutcome,
    lastWeekWinnersFromLedgerData,
    openPeerChallengeId,
    decoratePlayer: _decoratePlayer,
    CHALLENGE_INBOX_COMPLETED_MS,
    quizChallengeCopy,
    CHALLENGE_TTL_MS,
    CHALLENGE_BOT_DELAY_MS,
    CHALLENGE_REMINDER_BEFORE_MS,
    isBotId: _isBotId,
    isChallengeBotOpponent: _isChallengeBotOpponent,
    validatedOpponentId: _validatedOpponentId,
    challengeBotWeakPlan: _challengeBotWeakPlan,
    adminChallengeAutoPlan: _adminChallengeAutoPlan,
    applyAdminAutoChallengeToDoc: _applyAdminAutoChallengeToDoc,
    challengeBotMinDeadlineMs: _challengeBotMinDeadlineMs,
    challengePushRecipients,
    claimChallengeNotify,
    challengeRoundMarks: _challengeRoundMarks,
    shouldRevealChallengeOpponentMarks: _shouldRevealChallengeOpponentMarks,
    serializeChallenge: _serializeChallenge,
  },
};
