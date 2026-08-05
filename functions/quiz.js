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

const REGION = "europe-west1";
// TEMP (emülatör): Play Integrity emülatörde fail → Unauthenticated.
// Mağaza / prod öncesi mutlaka true yap.
const ENFORCE_APP_CHECK = false;
const ROUND_COUNT = 7;
const ROUND_DURATION_MS = 20_000;
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
/** Engajman push: en az 3 günde bir; bunaltmaz. */
const ENGAGEMENT_COOLDOWN_MS = 3 * 24 * 60 * 60_000;
/** Son maçtan sonra en az 36 saat sessizlik. */
const ENGAGEMENT_MIN_IDLE_MS = 36 * 60 * 60_000;
/** 14 günden eski oyuncuya tekrar yazma. */
const ENGAGEMENT_MAX_IDLE_MS = 14 * 24 * 60 * 60_000;
const ENGAGEMENT_BATCH_LIMIT = 60;
const QUIZ_DEVICE_TTL_MS = 45 * 24 * 60 * 60_000;
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
const BOT_NAMES = [
  "Ahmet Yılmaz",
  "Ayşe Demir",
  "Mehmet Kaya",
  "Zeynep Şahin",
  "Mustafa Çelik",
  "Elif Aydın",
  "Ömer Arslan",
  "Merve Koç",
  "Yusuf Kurt",
  "Fatma Yıldız",
  "Emine Aksoy",
  "İbrahim Kılıç",
];

function _assertQuestionBank() {
  if (!Array.isArray(questions) || questions.length !== 380) {
    throw new Error("Hilal Düellosu question bank must contain 380 questions.");
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
      item.correctIndex > 3
    ) {
      throw new Error(`Invalid Hilal Düellosu question: ${item?.id || "unknown"}`);
    }
    ids.add(item.id);
  }
}

_assertQuestionBank();
const QUESTION_BY_ID = new Map(questions.map((item) => [item.id, item]));

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

function cosmeticsForLevel(rawLevel) {
  const level = Math.max(1, Math.min(MAX_LEVEL, Math.floor(Number(rawLevel) || 1)));
  return {
    avatarFrame: level >= 3,
    title: level >= 10 ? "İlim Dostu" : level >= 5 ? "Talebe" : null,
    specialHilalIcon: level >= 8,
    nameAccent: level >= 10,
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
    badge: player?.badge ? String(player.badge) : null,
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
  const prevMatches = Math.max(
    0,
    Math.floor(Number(playerSnap.data()?.matchesCompleted) || 0),
  );
  const playerPatch = {
    name: displayName,
    hilals: nextHilals,
    weekId,
    weeklyHilals,
    matchesCompleted: prevMatches + Math.max(0, matchesCompletedInc),
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (matchesCompletedInc > 0) {
    playerPatch.lastMatchAt = FieldValue.serverTimestamp();
  }
  tx.set(playerRef, playerPatch, { merge: true });
  tx.set(weeklyRef, {
    ownerHash: playerRef.id,
    name: displayName,
    weeklyHilals,
    level: progression.level,
    isBot: false,
    title: cosmetics.title,
    avatarFrame: cosmetics.avatarFrame,
    specialHilalIcon: cosmetics.specialHilalIcon,
    nameAccent: cosmetics.nameAccent,
    updatedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + WEEKLY_TTL_MS),
  }, { merge: true });
  return { nextHilals, weeklyHilals, level: progression.level };
}

/** Bot id'si isme sabit — aynı "Elif Aydın" haftalıkta tek satır. */
function _stableBotId(name) {
  return `bot_${_sha256(`hilal_bot:${String(name || "").trim()}`).slice(0, 20)}`;
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
  if (gain <= 0 && weeklySnap.exists) {
    // Yine de isim/level tazele.
    tx.set(weeklyRef, {
      name: String(name || "Oyuncu").slice(0, 32),
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
    name: String(name || "Oyuncu").slice(0, 32),
    weeklyHilals,
    level: safeLevel,
    isBot: true,
    title: null,
    avatarFrame: false,
    specialHilalIcon: false,
    nameAccent: false,
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

/**
 * Engajman push adayı mı? (en az 1 maç, 36s–14g boşluk, 3g cooldown)
 * reason: "rank_drop" | "comeback" | null
 */
function decideQuizEngagement({
  matchesCompleted,
  lastMatchAtMs,
  lastPushAtMs,
  nowMs,
  currentRank,
  bestWeeklyRank,
  lastKnownWeeklyRank = 0,
}) {
  const matches = Math.floor(Number(matchesCompleted) || 0);
  if (matches < 1) return { send: false, reason: null };
  const now = Math.floor(Number(nowMs) || 0);
  const lastMatch = Math.floor(Number(lastMatchAtMs) || 0);
  if (!lastMatch) return { send: false, reason: null };
  const idle = now - lastMatch;
  if (idle < ENGAGEMENT_MIN_IDLE_MS || idle > ENGAGEMENT_MAX_IDLE_MS) {
    return { send: false, reason: null };
  }
  const lastPush = Math.floor(Number(lastPushAtMs) || 0);
  if (lastPush > 0 && now - lastPush < ENGAGEMENT_COOLDOWN_MS) {
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

async function _computeWeeklyRank(db, weekId, ownerHash, weeklyHilals) {
  const hilals = Math.floor(Number(weeklyHilals) || 0);
  try {
    const higher = await _weeklyEntryRef(db, weekId, ownerHash).parent
      .where("weeklyHilals", ">", hilals)
      .count()
      .get();
    return (higher.data().count || 0) + 1;
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

/** Erken gönderim istismarı: tur başlamadan cevap kabul edilmez. */
function canAcceptAnswer(nowMs, roundStartedAtMs, deadlineMs) {
  const start = Number(roundStartedAtMs) || 0;
  const deadline = Number(deadlineMs) || 0;
  const now = Number(nowMs) || 0;
  if (now < start) return { ok: false, reason: "not_started" };
  if (now > deadline + 1_500) return { ok: false, reason: "expired" };
  return { ok: true, reason: "ok" };
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
  if (data?.active !== true) return false;
  const expiresAt = data?.expiresAt;
  return expiresAt == null || (expiresAt?.toMillis?.() || 0) > Date.now();
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

/** Maç içi sıra: kolay → zor. Genel olarak daha zor (1 kolay, 2 orta, 4 zor). */
function _pickQuestions() {
  const buckets = new Map([[1, []], [2, []], [3, []]]);
  for (const item of questions) {
    const difficulty = [1, 2, 3].includes(item.difficulty)
      ? item.difficulty
      : 2;
    buckets.get(difficulty).push(item);
  }
  const selected = [];
  const selectedIds = new Set();
  const takeRandom = (difficulty, count) => {
    const pool = [...buckets.get(difficulty)];
    for (let i = 0; i < count && pool.length > 0; i += 1) {
      const index = crypto.randomInt(pool.length);
      const item = pool.splice(index, 1)[0];
      if (selectedIds.has(item.id)) continue;
      selected.push(item);
      selectedIds.add(item.id);
    }
  };
  takeRandom(1, 1);
  takeRandom(2, 2);
  takeRandom(3, 4);
  // Eksik kalırsa en zor havuzdan doldur.
  for (const difficulty of [3, 2, 1]) {
    while (selected.length < ROUND_COUNT) {
      const before = selected.length;
      takeRandom(difficulty, ROUND_COUNT - selected.length);
      if (selected.length === before) break;
    }
  }
  // Kolaydan zora sabit sıra (shuffle yok).
  selected.sort((a, b) => {
    const da = [1, 2, 3].includes(a.difficulty) ? a.difficulty : 2;
    const db = [1, 2, 3].includes(b.difficulty) ? b.difficulty : 2;
    if (da !== db) return da - db;
    return String(a.id).localeCompare(String(b.id));
  });
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

/** İnsan cevapladıktan sonra botun anında basmasını engeller; turu da kilitlemez. */
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
  if (!humanAnswered) {
    return Math.min(planned, deadline - 200);
  }
  const humanAt = start + Math.max(0, Math.floor(Number(humanElapsedMs) || 0));
  // Planlanan süre + insanın ardından kısa düşünme; en fazla ~4.2sn beklet.
  const minAfterHuman = humanAt + 1_400;
  const maxAfterHuman = humanAt + 4_200;
  const ready = Math.min(maxAfterHuman, Math.max(planned, minAfterHuman));
  return Math.min(ready, deadline - 200);
}

function _questionPayload(questionId, includeAnswer = false) {
  const question = QUESTION_BY_ID.get(questionId);
  if (!question) throw new Error(`Question not found: ${questionId}`);
  return {
    id: question.id,
    category: question.category,
    question: question.question,
    options: question.options,
    ...(includeAnswer
      ? {
          correctIndex: question.correctIndex,
          explanation: question.explanation,
          source: question.source,
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

function _serializeMatch(matchId, match, ownerHash) {
  const selfIndex = match.players.findIndex((player) => player.id === ownerHash);
  if (selfIndex < 0) {
    throw new HttpsError("permission-denied", "Bu karşılaşmaya erişemezsiniz.");
  }
  const opponentIndex = selfIndex === 0 ? 1 : 0;
  const currentRound = Math.min(
    Math.max(0, Number(match.currentRound) || 0),
    ROUND_COUNT - 1,
  );
  const selfAnswer = _answerFor(match, currentRound, ownerHash);
  const opponentAnswer = _answerFor(
    match,
    currentRound,
    match.players[opponentIndex].id,
  );
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
      : _questionPayload(match.questionIds[currentRound]),
    selfAnswered: Boolean(selfAnswer),
    opponentAnswered: Boolean(opponentAnswer),
    doubled: match.doubledBy?.[ownerHash] === true,
    lastResolution: lastResolution
      ? {
          ...lastResolution,
          question: _questionPayload(
            match.questionIds[lastResolution.round],
            true,
          ),
        }
      : null,
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
  const questionIds = _pickQuestions();
  const matchId = crypto.randomBytes(16).toString("hex");
  const matchRef = db.collection("quiz_matches").doc(matchId);
  const nowMs = Date.now();
  const queuesForCharges = bot ? [firstQueue] : [firstQueue, secondQueue];
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
  const firstPlayer = {
    id: firstOwner,
    name: String(firstQueue.name || "Arın Oyuncusu").slice(0, 32),
    hilals: firstHilals,
    level: firstLevel,
    isBot: false,
  };
  const secondPlayer = bot
    ? (() => {
      const botName = BOT_NAMES[crypto.randomInt(BOT_NAMES.length)];
      return {
        id: _stableBotId(botName),
        name: botName,
        hilals: Math.max(0, firstHilals + crypto.randomInt(-20, 21)),
        level: Math.max(1, Math.min(3, firstLevel + crypto.randomInt(-1, 2))),
        isBot: true,
        badge: "Hızlı Rakip",
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
  return { matchId, match };
}

function _matchPlayerStats(match) {
  return match.players.map((player) => {
    let correct = 0;
    let elapsedMs = 0;
    for (let round = 0; round < ROUND_COUNT; round += 1) {
      const answer = _answerFor(match, round, player.id);
      if (answer?.correct === true) correct += 1;
      elapsedMs += answer ? Number(answer.elapsedMs) || 0 : ROUND_DURATION_MS;
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
        const roundStart = Number(match.roundStartedAtMs) || nowMs;
        const elapsedMs = Math.min(
          ROUND_DURATION_MS,
          Math.max(
            800,
            Math.min(Number(plan.elapsedMs) || ROUND_DURATION_MS, nowMs - roundStart),
          ),
        );
        answers[bot.id] = {
          choice: plan.choice,
          elapsedMs,
          correct: plan.choice === question.correctIndex,
        };
      }
    }
  }
  if (nowMs >= match.deadlineMs) {
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

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(playerRef);
      if (!snap.exists) {
        tx.create(playerRef, {
          name,
          hilals: 0,
          adHearts: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }
      tx.update(playerRef, {
        name,
        updatedAt: FieldValue.serverTimestamp(),
      });
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
    return { ok: true, match: _serializeMatch(matchId, match, ownerHash) };
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
      if (_answerFor(data, round, ownerHash)) {
        await _resolveRoundIfReady(tx, db, matchRef, data, Date.now());
        return data;
      }
      const nowMs = Date.now();
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
      const elapsedMs = Math.min(
        ROUND_DURATION_MS,
        Math.max(0, nowMs - data.roundStartedAtMs),
      );
      data.answers = {
        ...(data.answers || {}),
        [String(round)]: {
          ...(data.answers?.[String(round)] || {}),
          [ownerHash]: {
            choice,
            elapsedMs,
            correct: choice === question.correctIndex,
          },
        },
      };
      await _resolveRoundIfReady(tx, db, matchRef, data, nowMs);
      if (!_answerFor(data, round, ownerHash)) {
        data.version = _nextVersion(data);
        tx.set(matchRef, {
          [`answers.${round}.${ownerHash}`]: {
            choice,
            elapsedMs,
            correct: choice === question.correctIndex,
          },
          version: data.version,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      return data;
    });
    return { ok: true, match: _serializeMatch(matchId, match, ownerHash) };
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
    return { ok: true, match: _serializeMatch(matchId, match, ownerHash) };
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
      const cosmetics = isBot
        ? {
          title: null,
          avatarFrame: false,
          specialHilalIcon: false,
          nameAccent: false,
        }
        : cosmeticsForLevel(level);
      return {
        ownerHash: doc.id,
        name: String(data.name || "Oyuncu").slice(0, 32),
        weeklyHilals: Math.floor(Number(data.weeklyHilals) || 0),
        level: isBot ? Math.min(3, level) : level,
        title: isBot ? null : (data.title || cosmetics.title),
        avatarFrame: isBot
          ? false
          : data.avatarFrame === true || cosmetics.avatarFrame,
        specialHilalIcon: isBot
          ? false
          : data.specialHilalIcon === true || cosmetics.specialHilalIcon,
        nameAccent: isBot
          ? false
          : data.nameAccent === true || cosmetics.nameAccent,
        isBot,
        isSelf: doc.id === ownerHash,
      };
    };
    for (const doc of topSnap.docs) byId.set(doc.id, mapDoc(doc));
    for (const doc of botSnap.docs) {
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
    const selfSnap = await entriesRef.doc(ownerHash).get();
    const selfWeekly = selfSnap.exists
      ? Math.floor(Number(selfSnap.data()?.weeklyHilals) || 0)
      : 0;
    let selfRank = 0;
    if (selfSnap.exists) {
      const inTop = top.find((row) => row.ownerHash === ownerHash);
      if (inTop) {
        selfRank = inTop.rank;
      } else {
        // Sıra: yalnız gerçek oyuncular arasında (botlar şişirmez).
        selfRank = humans.filter((row) => row.weeklyHilals > selfWeekly).length +
          1;
      }
    }
    const playerSnap = await db.collection("quiz_players").doc(ownerHash).get();
    const progression = levelForHilals(
      Math.floor(Number(playerSnap.data()?.hilals) || 0),
    );
    return {
      ok: true,
      weekId,
      top,
      self: {
        weeklyHilals: selfWeekly,
        rank: selfRank,
        level: progression.level,
        ...cosmeticsForLevel(progression.level),
        name: String(playerSnap.data()?.name || "Arın Oyuncusu").slice(0, 32),
      },
    };
  },
);

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

/**
 * Günde 1 kez: en az 1 maç oynamış, 36s–14g idle, 3g cooldown.
 * Sıra düştüyse ona göre metin; değilse nazik comeback.
 */
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
    registerQuizDevice,
    cleanupAbandonedQuizQueues,
    scanQuizEngagementReminders,
  },
  testables: {
    levelForHilals,
    determineWinner,
    hilalAward,
    istanbulDayKey: _istanbulDayKey,
    weekIdIstanbul,
    cosmeticsForLevel,
    MAX_LEVEL,
    FORFEIT_PENALTY,
    BOT_WEEKLY_CAP,
    orderWeeklyLeaderboard: _orderWeeklyLeaderboard,
    stableBotId: _stableBotId,
    decideQuizEngagement,
    quizEngagementCopy,
    ENGAGEMENT_COOLDOWN_MS,
    ENGAGEMENT_MIN_IDLE_MS,
    ENGAGEMENT_MAX_IDLE_MS,
    botPlan: _botPlan,
    botReadyAtMs: _botReadyAtMs,
    canAcceptAnswer,
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
  },
};
