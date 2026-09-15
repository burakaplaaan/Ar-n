"use strict";

const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getMessaging } = require("firebase-admin/messaging");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");

const REGION = "europe-west1";
// App Check store listing öncesi kapalı; Dua Halkası ile aynı politika.
const ENFORCE_APP_CHECK = false;
const FEED_PAGE = 10;
const COMMENT_PAGE = 30;
const POST_MIN = 12;
const POST_MAX = 280;
const COMMENT_MIN = 2;
const COMMENT_MAX = 200;
const BIO_MIN = 8;
const BIO_MAX = 80;
const AVATAR_MAX = 12;
const USERNAME_MIN = 3;
const USERNAME_MAX = 16;
const POSTS_PER_DAY = 3;
const COMMENTS_PER_DAY = 40;
const LIKES_PER_WINDOW = 40;
const REPORTS_TO_HIDE = 3;
const POPULAR_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
const POPULAR_CANDIDATE_LIMIT = 50;
const DIGEST_LATEST = "latest";
const DIGEST_POPULAR = "popular";

const RESERVED_USERNAMES = new Set([
  "arin",
  "admin",
  "support",
  "destek",
  "moderasyon",
  "moderator",
  "yardim",
  "help",
]);

function _turkishSafeWordListPattern(words) {
  const escaped = words.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  return new RegExp(
    `(?<![\\p{L}\\p{N}_])(?:${escaped.join("|")})(?![\\p{L}\\p{N}_])`,
    "iu",
  );
}

const SOCIAL_ADMIN_EMAILS = new Set([
  "burakmelihkuzi@gmail.com",
  "brkkpl5@gmail.com",
  "seyirteknikerr@gmail.com",
]);

const _forbiddenContactPatterns = [
  /https?:\/\/|www\./i,
  /\bTR\d{24}\b/i,
  /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i,
  /(?:^|\s)@[A-Za-z0-9_.-]{2,}/,
  /(?:(?:\+|00)\d[\d\s().-]{7,}\d|\b0\d[\d\s().-]{8,}\d)/,
  _turkishSafeWordListPattern([
    "iban", "whatsapp", "telegram", "instagram", "telefon", "phone",
    "ödeme", "payment",
  ]),
  _turkishSafeWordListPattern([
    "adresim", "address", "sokak", "mahallesi", "caddesi", "apartmanı",
  ]),
];

const _insultWords = [
  "orospu", "orospucocugu", "sikik", "sikeyim", "siktir", "hassiktir",
  "sikerim", "sikiyim", "aminakoyayim", "aminakoyim", "amcik", "amk", "amq",
  "pic", "ibne", "kahpe", "pezevenk", "gavat", "yavsak", "yarrak", "yarak",
  "gotveren", "serefsiz", "gerizekali", "pust", "sik", "aq", "oc",
  "ananisikeyim", "bacinisikeyim", "dangalak", "haysiyetsiz", "namussuz",
  "kevashe", "kevase", "gotlek", "fuck", "bitch", "nigger", "cunt", "whore",
  "faggot",
];

const _insultPhrases = [
  "orospu", "orospucocugu", "sikeyim", "siktir", "hassiktir", "sikerim",
  "sikiyim", "aminakoyayim", "aminakoyim", "amcik", "pezevenk", "yarrak",
  "gotveren", "serefsiz", "gerizekali", "ananisikeyim", "bacinisikeyim",
  "orospuevladi", "kahpe", "ibne", "yavsak",
];

const _insultExact = new Set(["sik", "amk", "amq", "aq", "oc", "pic"]);

function foldSocialInsultText(raw) {
  return String(raw || "")
    .replace(/İ/g, "i")
    .replace(/I/g, "i")
    .replace(/ı/g, "i")
    .toLocaleLowerCase("tr-TR")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .replace(/â/g, "a")
    .replace(/î/g, "i")
    .replace(/û/g, "u");
}

function leetSocialInsultText(folded) {
  return folded
    .replace(/[@4]/g, "a")
    .replace(/0/g, "o")
    .replace(/[1!|]/g, "i")
    .replace(/3/g, "e")
    .replace(/[$5]/g, "s")
    .replace(/7/g, "t");
}

function containsSocialInsult(raw) {
  const folded = leetSocialInsultText(foldSocialInsultText(raw));
  const spaced = folded.replace(/[^a-z0-9]+/g, " ").trim();
  const collapsed = folded.replace(/[^a-z0-9]+/g, "");
  if (_insultExact.has(collapsed)) return true;
  if (_turkishSafeWordListPattern(_insultWords).test(spaced)) return true;
  return _insultPhrases.some((stem) => collapsed.includes(stem));
}

function assertSocialAuth(req) {
  if (!req.auth?.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Sosyal için güvenli oturum oluşturulamadı.",
    );
  }
  return String(req.auth.uid);
}

function validatedInstallHash(rawInstallId) {
  const value = String(rawInstallId || "").trim();
  if (!/^[A-Za-z0-9_-]{16,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Geçersiz kurulum kimliği.");
  }
  return crypto.createHash("sha256").update(value).digest("hex");
}

function socialIpHash(req) {
  const forwarded = String(req.rawRequest?.headers?.["x-forwarded-for"] || "");
  const ip = forwarded.split(",")[0].trim() ||
    String(req.rawRequest?.ip || "unknown");
  return crypto.createHash("sha256").update(`social-ip:${ip}`).digest("hex");
}

function istanbulDayKey(ms = Date.now()) {
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

function socialWindowKey(nowMs = Date.now()) {
  return Math.floor(nowMs / (5 * 60 * 1000));
}

function usernameKey(raw) {
  return String(raw || "")
    .trim()
    .toLocaleLowerCase("tr-TR")
    .replace(/\s+/g, "");
}

function asciiUsernameKey(raw) {
  return String(raw || "")
    .trim()
    .replace(/İ/g, "i")
    .replace(/I/g, "i")
    .replace(/ı/g, "i")
    .toLowerCase()
    .replace(/\s+/g, "");
}

function validateUsername(raw) {
  const display = String(raw || "").trim();
  if (display.length < USERNAME_MIN || display.length > USERNAME_MAX) {
    throw new HttpsError(
      "invalid-argument",
      "Kullanıcı adı 3–16 karakter olmalı.",
    );
  }
  if (!/^[\p{L}\p{N}_]+$/u.test(display)) {
    throw new HttpsError(
      "invalid-argument",
      "Kullanıcı adı yalnızca harf, rakam veya _ olabilir.",
    );
  }
  const key = usernameKey(display);
  const asciiKey = asciiUsernameKey(display);
  if (
    !key ||
    RESERVED_USERNAMES.has(key) ||
    RESERVED_USERNAMES.has(asciiKey) ||
    containsSocialInsult(display)
  ) {
    throw new HttpsError("invalid-argument", "Bu kullanıcı adı kullanılamaz.");
  }
  return { display, key, asciiKey };
}

function validatedBindingSecretHash(raw) {
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

async function assertSocialBinding(db, req, installHash) {
  const uid = assertSocialAuth(req);
  const bindingSecretHash = validatedBindingSecretHash(req.data?.bindingSecret);
  if (uid.startsWith("prayer_")) {
    const claimedInstall = String(req.auth?.token?.prayerInstallation || "");
    if (
      uid !== `prayer_${installHash.substring(0, 48)}` ||
      claimedInstall !== installHash
    ) {
      throw new HttpsError(
        "permission-denied",
        "Oturum bu kuruluma ait değil.",
      );
    }
  }
  const ref = db.collection("prayer_installations").doc(`v2_${installHash}`);
  const snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      authHash: crypto.createHash("sha256").update(`auth:${uid}`).digest("hex"),
      bindingSecretHash,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + 180 * 86400000),
    });
    return uid;
  }
  if (String(snap.data()?.bindingSecretHash || "") !== bindingSecretHash) {
    throw new HttpsError(
      "permission-denied",
      "Bu kurulumun güvenlik anahtarı doğrulanamadı.",
    );
  }
  return uid;
}

async function requireSocialSession(db, req) {
  const installHash = validatedInstallHash(req.data?.installId);
  const uid = await assertSocialBinding(db, req, installHash);
  return { uid, installHash };
}

function _assertCleanText(value) {
  if (_forbiddenContactPatterns.some((pattern) => pattern.test(value))) {
    throw new HttpsError(
      "invalid-argument",
      "İletişim, ödeme veya bağlantı bilgisi paylaşmayın.",
    );
  }
  if (containsSocialInsult(value)) {
    throw new HttpsError(
      "invalid-argument",
      "Küfür veya hakaret yazılamaz.",
    );
  }
  return value;
}

function callerEmail(req) {
  return String(req.auth?.token?.email || "").trim().toLowerCase();
}

async function callerIsSocialAdmin(db, req) {
  if (!req.auth?.uid) return false;
  const email = callerEmail(req);
  if (email && SOCIAL_ADMIN_EMAILS.has(email)) return true;
  try {
    const userSnap = await db.collection("admin_users").doc(req.auth.uid).get();
    if (userSnap.exists) {
      const role = String(userSnap.data()?.role || "content").trim();
      if (["content", "manager", "developer"].includes(role)) return true;
    }
  } catch (error) {
    console.warn("social admin_users skipped", error);
  }
  if (!email) return false;
  try {
    const inviteSnap = await db.collection("admin_invites").doc(email).get();
    if (inviteSnap.exists) {
      const role = String(inviteSnap.data()?.role || "").trim();
      if (["content", "manager", "developer"].includes(role)) return true;
    }
  } catch (error) {
    console.warn("social admin_invites skipped", error);
  }
  return false;
}

async function assertSocialAdmin(db, req) {
  if (await callerIsSocialAdmin(db, req)) return;
  throw new HttpsError("permission-denied", "Bu işlem yalnız admin için.");
}

function validatedBanHours(raw) {
  if (raw === "permanent" || raw === 0 || raw === "0") return 0;
  const hours = Number(raw);
  if (![1, 24, 168, 720].includes(hours)) {
    throw new HttpsError("invalid-argument", "Geçersiz ban süresi.");
  }
  return hours;
}

function readActiveBanData(data, nowMs = Date.now()) {
  if (!data) return null;
  if (data.permanent === true) {
    return { permanent: true, untilMs: null };
  }
  const untilMs = data.until?.toMillis?.() || Number(data.untilMs) || 0;
  if (untilMs > nowMs) return { permanent: false, untilMs };
  return null;
}

function socialBanMessage(ban) {
  if (!ban) return "Bu hesap sosyal tahtadan uzaklaştırıldı.";
  if (ban.permanent) {
    return "Bu hesap sosyal tahtadan kalıcı olarak uzaklaştırıldı.";
  }
  return "Bu hesap geçici olarak uzaklaştırıldı.";
}

async function readActiveBan(db, uid, installHash) {
  const refs = [db.collection("social_bans").doc(uid)];
  if (installHash) {
    refs.push(db.collection("social_bans").doc(`install_${installHash}`));
  }
  const snaps = await Promise.all(refs.map((ref) => ref.get()));
  for (const snap of snaps) {
    const ban = readActiveBanData(snap.data());
    if (ban) return ban;
  }
  return null;
}

async function assertNotBanned(db, uid, installHash) {
  const ban = await readActiveBan(db, uid, installHash);
  if (!ban) return;
  throw new HttpsError("failed-precondition", socialBanMessage(ban));
}

async function hideAuthorPosts(db, uid) {
  for (;;) {
    const snap = await db.collection("social_posts")
      .where("authorUid", "==", uid)
      .where("status", "==", "active")
      .limit(40)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        status: "hidden",
        hiddenReason: "ban",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    if (snap.size < 40) break;
  }
}

async function hideAuthorComments(db, uid) {
  const hiddenByPost = new Map();
  for (;;) {
    const snap = await db.collectionGroup("comments")
      .where("authorUid", "==", uid)
      .limit(40)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      const postId = doc.ref.parent.parent?.id;
      if (postId) {
        hiddenByPost.set(postId, (hiddenByPost.get(postId) || 0) + 1);
      }
      batch.delete(doc.ref);
    }
    await batch.commit();
    if (snap.size < 40) break;
  }
  for (const [postId, hiddenCount] of hiddenByPost) {
    const postRef = db.collection("social_posts").doc(postId);
    const snap = await postRef.get();
    if (!snap.exists || snap.data()?.status !== "active") continue;
    const lastComments = await loadLastCommentPreviews(postRef);
    const nextCount = Math.max(
      0,
      (Number(snap.data()?.commentCount) || 0) - hiddenCount,
    );
    await postRef.update({
      lastComments,
      commentCount: nextCount,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await patchDigestCounts(db, digestItemFromData(postId, {
      ...(snap.data() || {}),
      lastComments,
      commentCount: nextCount,
    }));
  }
}

async function hideBannedAuthorContent(db, uid) {
  await hideAuthorPosts(db, uid);
  await hideAuthorComments(db, uid);
  await rebuildSocialDigests(db);
}

function validatePostText(raw) {
  const value = String(raw || "").replace(/\s+/g, " ").trim();
  if (value.length < POST_MIN || value.length > POST_MAX) {
    throw new HttpsError(
      "invalid-argument",
      `Paylaşım ${POST_MIN}–${POST_MAX} karakter olmalı.`,
    );
  }
  if (/^(bugün şükür|bir ayet|dua iste|today's thanks|a verse|ask for dua|شكر اليوم|آية|اطلب دعاء)\s*:?\s*$/iu.test(value)) {
    throw new HttpsError(
      "invalid-argument",
      `Paylaşım ${POST_MIN}–${POST_MAX} karakter olmalı.`,
    );
  }
  return _assertCleanText(value);
}

function validateCommentText(raw) {
  const value = String(raw || "").replace(/\s+/g, " ").trim();
  if (value.length < COMMENT_MIN || value.length > COMMENT_MAX) {
    throw new HttpsError(
      "invalid-argument",
      `Yorum ${COMMENT_MIN}–${COMMENT_MAX} karakter olmalı.`,
    );
  }
  return _assertCleanText(value);
}

function validateBio(raw) {
  const value = String(raw || "").replace(/\s+/g, " ").trim();
  if (!value) return "";
  if (value.length < BIO_MIN || value.length > BIO_MAX) {
    throw new HttpsError(
      "invalid-argument",
      `Hakkında ${BIO_MIN}–${BIO_MAX} karakter olmalı.`,
    );
  }
  return _assertCleanText(value);
}

function normalizeAvatarId(raw) {
  const id = Math.trunc(Number(raw) || 0);
  if (!Number.isFinite(id) || id < 0 || id > AVATAR_MAX) return 0;
  return id;
}

function validateAvatarId(raw) {
  if (raw == null || raw === "") return 0;
  const n = Number(raw);
  if (!Number.isFinite(n)) {
    throw new HttpsError("invalid-argument", "Geçersiz avatar.");
  }
  const id = Math.trunc(n);
  if (id < 0 || id > AVATAR_MAX) {
    throw new HttpsError("invalid-argument", "Geçersiz avatar.");
  }
  return id;
}

function validatedDocumentId(raw, label = "kimlik") {
  const value = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{8,80}$/.test(value)) {
    throw new HttpsError("invalid-argument", `Geçersiz ${label}.`);
  }
  return value;
}

function validatedSort(raw) {
  return raw === DIGEST_POPULAR ? DIGEST_POPULAR : DIGEST_LATEST;
}

function voteDocId(targetType, targetId, uid) {
  return `${targetType}_${targetId}_${uid}`.slice(0, 700);
}

function premiumRecordActive(data) {
  if (!data) return false;
  const bonusMs = data.hilalWeeklyBonusExpiresAt?.toMillis?.() || 0;
  if (bonusMs > Date.now()) return true;
  if (data.active !== true) return false;
  const expiresAt = data.expiresAt;
  return expiresAt == null || (expiresAt?.toMillis?.() || 0) > Date.now();
}

async function callerIsPremium(db, req, uid) {
  const direct = await db.collection("premium_entitlements").doc(uid).get();
  if (premiumRecordActive(direct.data())) return true;
  const email = String(req.auth?.token?.email || "").trim().toLowerCase();
  if (!email) return false;
  const invite = await db.collection("premium_invites").doc(email).get();
  return premiumRecordActive(invite.data());
}

function previewCommentsFromData(data) {
  const raw = Array.isArray(data?.lastComments) ? data.lastComments : [];
  return raw
    .filter((row) => row && String(row.text || "").trim())
    .slice(-2)
    .map((row) => commentPreview(row));
}

function commentPreview(row) {
  return {
    username: String(row?.username || "").slice(0, USERNAME_MAX),
    text: String(row?.text || "").slice(0, 80),
    avatarId: normalizeAvatarId(row?.avatarId),
  };
}

function appendLastComments(existing, next) {
  const list = Array.isArray(existing)
    ? existing.filter((row) => row && String(row.text || "").trim())
        .map((row) => commentPreview(row))
    : [];
  list.push(commentPreview(next));
  return list.slice(-2);
}

function digestItemFromData(id, data) {
  return {
    id,
    text: String(data.text || ""),
    authorUid: String(data.authorUid || ""),
    authorUsername: String(data.authorUsername || ""),
    authorBio: String(data.authorBio || "").slice(0, BIO_MAX),
    authorAvatarId: normalizeAvatarId(data.authorAvatarId),
    authorPremium: data.authorPremium === true,
    likeCount: Math.max(0, Number(data.likeCount) || 0),
    commentCount: Math.max(0, Number(data.commentCount) || 0),
    createdAtMs: data.createdAt?.toMillis?.() || Number(data.createdAtMs) || 0,
    lastComments: previewCommentsFromData(data),
  };
}

function validatedFcmToken(raw) {
  const token = String(raw || "").trim();
  if (token.length < 20 || token.length > 4096) return null;
  return token;
}

async function readDailyPrompt(db) {
  try {
    const snap = await db.collection("social_config").doc("daily").get();
    const text = String(snap.data()?.text || "").replace(/\s+/g, " ").trim();
    return text ? text.slice(0, 80) : null;
  } catch (error) {
    console.warn("social daily prompt skipped", error);
    return null;
  }
}

async function loadLastCommentPreviews(postRef) {
  const snap = await postRef.collection("comments")
    .orderBy("createdAt", "desc")
    .limit(8)
    .get();
  return snap.docs
    .filter((doc) => doc.data()?.status !== "hidden")
    .reverse()
    .slice(-2)
    .map((doc) => {
      const data = doc.data() || {};
      return {
        username: String(data.authorUsername || "").slice(0, USERNAME_MAX),
        text: String(data.text || "").slice(0, 80),
      };
    });
}

function socialCommentAnonymousName(lang) {
  if (lang === "en") return "Someone";
  if (lang === "ar") return "أحدهم";
  return "Biri";
}

function socialCommentPushCopy(locale, name) {
  const lang = String(locale || "tr").toLowerCase().slice(0, 2);
  const who = String(name || "").trim() || socialCommentAnonymousName(lang);
  if (lang === "en") {
    return { title: "Social", body: `${who} commented on your post.` };
  }
  if (lang === "ar") {
    return { title: "اجتماعي", body: `${who} علّق على منشورك.` };
  }
  return { title: "Sosyal", body: `${who} senin gönderine yorum yaptı.` };
}

async function notifyPostAuthorOnComment({
  db,
  authorUid,
  commenterUid,
  commenterName,
  postId,
}) {
  if (!authorUid || authorUid === commenterUid) return;
  const ref = db.collection("social_profiles").doc(authorUid);
  const snap = await ref.get();
  const token = validatedFcmToken(snap.data()?.fcmToken);
  if (!token) return;
  const copy = socialCommentPushCopy(
    snap.data()?.locale,
    commenterName,
  );
  try {
    await getMessaging().send({
      token,
      notification: copy,
      data: {
        type: "social",
        postId: String(postId || ""),
      },
      android: {
        notification: {
          channelId: "arin_social",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: { payload: { aps: { sound: "default" } } },
    });
  } catch (error) {
    const code = String(error?.code || error?.errorInfo?.code || "");
    if (code.includes("registration-token-not-registered")) {
      await ref.set({
        fcmToken: FieldValue.delete(),
        fcmUpdatedAt: FieldValue.serverTimestamp(),
      }, { merge: true }).catch(() => {});
    }
    console.warn("social comment fcm skipped", code || error);
  }
}

function commentFromSnap(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    text: String(data.text || ""),
    authorUid: String(data.authorUid || ""),
    authorUsername: String(data.authorUsername || ""),
    authorBio: String(data.authorBio || "").slice(0, BIO_MAX),
    authorAvatarId: normalizeAvatarId(data.authorAvatarId),
    authorPremium: data.authorPremium === true,
    likeCount: Math.max(0, Number(data.likeCount) || 0),
    createdAtMs: data.createdAt?.toMillis?.() || 0,
  };
}

async function assertRate(db, owner, scope, limit, windowId, ttlMs, message) {
  const ref = db.collection("social_rate_limits")
    .doc(`${owner}_${scope}_${windowId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = Number(snap.data()?.count) || 0;
    if (count >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        message || "Çok hızlı işlem yapıldı. Biraz sonra tekrar dene.",
      );
    }
    tx.set(ref, {
      count: FieldValue.increment(1),
      expiresAt: Timestamp.fromMillis(Date.now() + ttlMs),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

async function assertSocialRates(
  db,
  req,
  installHash,
  scope,
  limit,
  daily,
  consume = true,
) {
  const uid = assertSocialAuth(req);
  const day = istanbulDayKey();
  const window = daily ? day : socialWindowKey();
  const ttlMs = daily ? 48 * 60 * 60 * 1000 : 24 * 60 * 60 * 1000;
  const message = daily
    ? "Günlük limit doldu. Yarın tekrar dene."
    : "Çok hızlı işlem yapıldı. Biraz sonra tekrar dene.";
  if (!consume) {
    const docs = await Promise.all([
      db.collection("social_rate_limits").doc(`${uid}_${scope}_uid_${window}`).get(),
      db.collection("social_rate_limits").doc(`${installHash}_${scope}_install_${window}`).get(),
      db.collection("social_rate_limits").doc(`${socialIpHash(req)}_${scope}_ip_${window}`).get(),
    ]);
    const over = docs.some((snap, index) =>
      (Number(snap.data()?.count) || 0) >= [limit, limit, limit * 3][index]);
    if (over) {
      throw new HttpsError("resource-exhausted", message);
    }
    return uid;
  }
  await Promise.all([
    assertRate(db, uid, `${scope}_uid`, limit, window, ttlMs, message),
    assertRate(db, installHash, `${scope}_install`, limit, window, ttlMs, message),
    assertRate(
      db,
      socialIpHash(req),
      `${scope}_ip`,
      limit * 3,
      window,
      ttlMs,
      message,
    ),
  ]);
  return uid;
}

async function assertSocialLikeRates(db, req, installHash) {
  const uid = assertSocialAuth(req);
  const window = socialWindowKey();
  const ttlMs = 24 * 60 * 60 * 1000;
  const ref = db.collection("social_rate_limits")
    .doc(`like_pack_${uid}_${installHash}_${window}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = Number(snap.data()?.count) || 0;
    if (count >= LIKES_PER_WINDOW) {
      throw new HttpsError(
        "resource-exhausted",
        "Çok hızlı işlem yapıldı. Biraz sonra tekrar dene.",
      );
    }
    tx.set(ref, {
      count: FieldValue.increment(1),
      expiresAt: Timestamp.fromMillis(Date.now() + ttlMs),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

function latestPostsQuery(db) {
  return db.collection("social_posts")
    .where("status", "==", "active")
    .orderBy("createdAt", "desc");
}

function pickPopularItems(docs) {
  return docs
    .map((doc) => digestItemFromData(doc.id, doc.data() || {}))
    .sort((a, b) =>
      b.likeCount - a.likeCount || b.createdAtMs - a.createdAtMs)
    .slice(0, FEED_PAGE);
}

async function rebuildSocialDigests(db) {
  const weekAgo = Timestamp.fromMillis(Date.now() - POPULAR_WINDOW_MS);
  const [latestSnap, recentSnap] = await Promise.all([
    latestPostsQuery(db).limit(FEED_PAGE).get(),
    db.collection("social_posts")
      .where("status", "==", "active")
      .where("createdAt", ">", weekAgo)
      .orderBy("createdAt", "desc")
      .limit(POPULAR_CANDIDATE_LIMIT)
      .get(),
  ]);
  const latest = latestSnap.docs.map((doc) =>
    digestItemFromData(doc.id, doc.data() || {}));
  const popular = pickPopularItems(recentSnap.docs);
  const now = FieldValue.serverTimestamp();
  await Promise.all([
    db.collection("social_feed").doc(DIGEST_LATEST).set({
      items: latest,
      builtAt: now,
    }),
    db.collection("social_feed").doc(DIGEST_POPULAR).set({
      items: popular,
      builtAt: now,
    }),
  ]);
  return { latest, popular };
}

function prependLatestItems(items, item) {
  const list = Array.isArray(items)
    ? items.filter((row) => row && row.id && row.id !== item.id)
    : [];
  return [item, ...list].slice(0, FEED_PAGE);
}

function dropDigestItem(items, postId) {
  return (Array.isArray(items) ? items : [])
    .filter((row) => row && row.id && row.id !== postId);
}

function popularRank(a, b) {
  return (Number(b.likeCount) || 0) - (Number(a.likeCount) || 0) ||
    (Number(b.createdAtMs) || 0) - (Number(a.createdAtMs) || 0);
}

function upsertPopularItems(items, item) {
  const others = (Array.isArray(items) ? items : [])
    .filter((row) => row && row.id && row.id !== item.id);
  const current = (Array.isArray(items) ? items : [])
    .find((row) => row && row.id === item.id);
  const nextItem = {
    ...(current || {}),
    ...item,
    id: item.id,
    likeCount: Math.max(0, Number(item.likeCount) || 0),
    commentCount: Math.max(
      0,
      Number.isFinite(Number(item.commentCount))
        ? Number(item.commentCount)
        : (Number(current?.commentCount) || 0),
    ),
  };
  if (!current && others.length >= FEED_PAGE) {
    const weakest = [...others].sort(popularRank).pop();
    const beats = popularRank(nextItem, weakest) < 0;
    if (!beats) return others;
  }
  return [...others, nextItem].sort(popularRank).slice(0, FEED_PAGE);
}

function patchDigestItem(items, item) {
  const list = Array.isArray(items) ? [...items] : [];
  const pos = list.findIndex((row) => row && row.id === item.id);
  if (pos < 0) return null;
  list[pos] = {
    ...list[pos],
    likeCount: item.likeCount,
    commentCount: item.commentCount,
    text: item.text,
    authorUsername: item.authorUsername,
    authorPremium: item.authorPremium === true,
    lastComments: previewCommentsFromData(item),
  };
  return list;
}

async function readFeedItems(db, sort) {
  const digestRef = db.collection("social_feed").doc(sort);
  const snap = await digestRef.get();
  if (!snap.exists || !Array.isArray(snap.data()?.items)) {
    const rebuilt = await rebuildSocialDigests(db);
    return sort === DIGEST_POPULAR ? rebuilt.popular : rebuilt.latest;
  }
  return (snap.data().items || []).filter((row) => row && row.id);
}

async function prependLatestDigest(db, item) {
  const latestRef = db.collection("social_feed").doc(DIGEST_LATEST);
  const popularRef = db.collection("social_feed").doc(DIGEST_POPULAR);
  const snap = await latestRef.get();
  if (!snap.exists || !Array.isArray(snap.data()?.items)) {
    await rebuildSocialDigests(db);
    return;
  }
  await db.runTransaction(async (tx) => {
    const [latestSnap, popularSnap] = await Promise.all([
      tx.get(latestRef),
      tx.get(popularRef),
    ]);
    const now = FieldValue.serverTimestamp();
    tx.set(latestRef, {
      items: prependLatestItems(latestSnap.data()?.items, item),
      builtAt: now,
    }, { merge: true });
    if (!popularSnap.exists || !Array.isArray(popularSnap.data()?.items)) {
      return;
    }
    const popular = upsertPopularItems(popularSnap.data()?.items, item);
    tx.set(popularRef, { items: popular, builtAt: now }, { merge: true });
  });
}

async function removeFromDigests(db, postId) {
  const refs = [
    db.collection("social_feed").doc(DIGEST_LATEST),
    db.collection("social_feed").doc(DIGEST_POPULAR),
  ];
  const snaps = await Promise.all(refs.map((ref) => ref.get()));
  if (snaps.every((snap) => !snap.exists)) {
    await rebuildSocialDigests(db);
    return;
  }
  await db.runTransaction(async (tx) => {
    const current = await Promise.all(refs.map((ref) => tx.get(ref)));
    current.forEach((snap, index) => {
      if (!snap.exists) return;
      const before = Array.isArray(snap.data()?.items) ? snap.data().items : [];
      const items = dropDigestItem(before, postId);
      if (items.length === before.length) return;
      tx.set(refs[index], { items, builtAt: FieldValue.serverTimestamp() }, {
        merge: true,
      });
    });
  });
}

async function patchDigestCounts(db, item) {
  const refs = [
    db.collection("social_feed").doc(DIGEST_LATEST),
    db.collection("social_feed").doc(DIGEST_POPULAR),
  ];
  await db.runTransaction(async (tx) => {
    const snaps = await Promise.all(refs.map((ref) => tx.get(ref)));
    snaps.forEach((snap, index) => {
      if (!snap.exists) return;
      const before = snap.data()?.items;
      const items = refs[index].id === DIGEST_POPULAR
        ? upsertPopularItems(before, item)
        : patchDigestItem(before, item);
      if (!items) return;
      tx.set(refs[index], { items, builtAt: FieldValue.serverTimestamp() }, {
        merge: true,
      });
    });
  });
}

async function readProfile(db, uid) {
  const snap = await db.collection("social_profiles").doc(uid).get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  const username = String(data.username || "").trim();
  if (!username) return null;
  return {
    username,
    usernameKey: String(data.usernameKey || usernameKey(username)),
    bio: String(data.bio || "").trim().slice(0, BIO_MAX),
    avatarId: normalizeAvatarId(data.avatarId),
    fcmToken: String(data.fcmToken || ""),
    locale: String(data.locale || ""),
  };
}

async function requireProfile(db, uid) {
  const profile = await readProfile(db, uid);
  if (!profile) {
    throw new HttpsError(
      "failed-precondition",
      "Önce bir kullanıcı adı seç.",
    );
  }
  return profile;
}

function callable(handler) {
  return onCall(
    {
      region: REGION,
      memory: "256MiB",
      enforceAppCheck: ENFORCE_APP_CHECK,
    },
    handler,
  );
}

function validatedLocale(raw) {
  const value = String(raw || "").trim().toLowerCase().slice(0, 2);
  return value === "en" || value === "ar" || value === "tr" ? value : null;
}

const getSocialProfile = callable(async (req) => {
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  const [profile, premium, admin, ban] = await Promise.all([
    readProfile(db, uid),
    callerIsPremium(db, req, uid),
    callerIsSocialAdmin(db, req),
    readActiveBan(db, uid, installHash),
  ]);
  const token = validatedFcmToken(req.data?.fcmToken);
  const locale = validatedLocale(req.data?.locale);
  const patch = {};
  if (profile && token && profile.fcmToken !== token) {
    patch.fcmToken = token;
    patch.fcmUpdatedAt = FieldValue.serverTimestamp();
  }
  if (profile && locale && profile.locale !== locale) {
    patch.locale = locale;
  }
  if (Object.keys(patch).length > 0) {
    await db.collection("social_profiles").doc(uid).set(patch, { merge: true });
  }
  return {
    ok: true,
    username: profile?.username || null,
    bio: profile?.bio || "",
    avatarId: profile?.avatarId || 0,
    premium,
    uid,
    admin,
    banned: !!ban,
    banPermanent: ban?.permanent === true,
    bannedUntilMs: ban?.untilMs || null,
  };
});

const claimSocialUsername = callable(async (req) => {
  const { display, key, asciiKey } = validateUsername(req.data?.username);
  const bio = validateBio(req.data?.bio);
  const avatarId = validateAvatarId(req.data?.avatarId);
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  await assertSocialRates(db, req, installHash, "username_attempt", 30, true);
  await assertSocialRates(db, req, installHash, "username", 3, true, false);
  const premium = await callerIsPremium(db, req, uid);
  const token = validatedFcmToken(req.data?.fcmToken);
  const locale = validatedLocale(req.data?.locale);
  const profileRef = db.collection("social_profiles").doc(uid);
  const nameRef = db.collection("social_usernames").doc(key);
  const asciiRef = asciiKey !== key
    ? db.collection("social_usernames").doc(asciiKey)
    : null;
  const installRef = db.collection("social_installs").doc(installHash);

  await db.runTransaction(async (tx) => {
    const reads = [tx.get(profileRef), tx.get(nameRef)];
    if (asciiRef) reads.push(tx.get(asciiRef));
    const [profileSnap, nameSnap, asciiSnap] = await Promise.all(reads);
    if (profileSnap.exists && String(profileSnap.data()?.username || "")) {
      throw new HttpsError(
        "already-exists",
        "Kullanıcı adın zaten seçildi.",
      );
    }
    if (nameSnap.exists || (asciiSnap && asciiSnap.exists)) {
      throw new HttpsError("already-exists", "Bu kullanıcı adı alınmış.");
    }
    const now = FieldValue.serverTimestamp();
    tx.create(nameRef, {
      uid,
      username: display,
      createdAt: now,
    });
    if (asciiRef) {
      tx.create(asciiRef, {
        uid,
        username: display,
        aliasOf: key,
        createdAt: now,
      });
    }
    const profile = {
      username: display,
      usernameKey: key,
      bio,
      avatarId,
      installHash,
      createdAt: now,
      updatedAt: now,
    };
    if (token) {
      profile.fcmToken = token;
      profile.fcmUpdatedAt = now;
    }
    if (locale) profile.locale = locale;
    tx.set(profileRef, profile, { merge: true });
    tx.set(installRef, {
      uid,
      usernameKey: key,
      createdAt: now,
    }, { merge: true });
  });

  try {
    await assertSocialRates(db, req, installHash, "username", 3, true);
  } catch (error) {
    console.warn("social username rate consume skipped", error);
  }
  const [adminFlag, ban] = await Promise.all([
    callerIsSocialAdmin(db, req),
    readActiveBan(db, uid, installHash),
  ]);
  return {
    ok: true,
    username: display,
    bio,
    avatarId,
    premium,
    uid,
    admin: adminFlag,
    banned: !!ban,
    banPermanent: ban?.permanent === true,
    bannedUntilMs: ban?.untilMs || null,
  };
});

const setSocialBio = callable(async (req) => {
  const payload = req.data && typeof req.data === "object" ? req.data : {};
  const bio = validateBio(payload.bio);
  const hasAvatar = Object.prototype.hasOwnProperty.call(payload, "avatarId");
  const nextAvatarId = hasAvatar ? validateAvatarId(payload.avatarId) : null;
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  const [profile, premium] = await Promise.all([
    requireProfile(db, uid),
    callerIsPremium(db, req, uid),
  ]);
  const avatarId = nextAvatarId == null ? profile.avatarId : nextAvatarId;
  const bioChanged = profile.bio !== bio;
  const avatarChanged = nextAvatarId != null && profile.avatarId !== nextAvatarId;
  if (bioChanged || avatarChanged) {
    await assertSocialRates(
      db,
      req,
      installHash,
      bioChanged ? "bio" : "avatar",
      8,
      true,
    );
    const patch = { updatedAt: FieldValue.serverTimestamp() };
    if (bioChanged) patch.bio = bio;
    if (avatarChanged) patch.avatarId = nextAvatarId;
    await db.collection("social_profiles").doc(uid).set(patch, { merge: true });
  }
  const [adminFlag, ban] = await Promise.all([
    callerIsSocialAdmin(db, req),
    readActiveBan(db, uid, installHash),
  ]);
  return {
    ok: true,
    username: profile.username,
    bio,
    avatarId,
    premium,
    uid,
    admin: adminFlag,
    banned: !!ban,
    banPermanent: ban?.permanent === true,
    bannedUntilMs: ban?.untilMs || null,
  };
});

const setSocialAvatar = callable(async (req) => {
  const avatarId = validateAvatarId(req.data?.avatarId);
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  const [profile, premium] = await Promise.all([
    requireProfile(db, uid),
    callerIsPremium(db, req, uid),
  ]);
  if (profile.avatarId !== avatarId) {
    await assertSocialRates(db, req, installHash, "avatar", 8, true);
    await db.collection("social_profiles").doc(uid).set({
      avatarId,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  const [adminFlag, ban] = await Promise.all([
    callerIsSocialAdmin(db, req),
    readActiveBan(db, uid, installHash),
  ]);
  return {
    ok: true,
    username: profile.username,
    bio: profile.bio || "",
    avatarId,
    premium,
    uid,
    admin: adminFlag,
    banned: !!ban,
    banPermanent: ban?.permanent === true,
    bannedUntilMs: ban?.untilMs || null,
  };
});

const listSocialFeed = callable(async (req) => {
  const db = getFirestore();
  await requireSocialSession(db, req);
  const sort = validatedSort(req.data?.sort);
  const digestRef = db.collection("social_feed").doc(sort);
  const snap = await digestRef.get();
  if (!snap.exists || !Array.isArray(snap.data()?.items)) {
    const rebuilt = await rebuildSocialDigests(db);
    return {
      ok: true,
      sort,
      items: sort === DIGEST_POPULAR ? rebuilt.popular : rebuilt.latest,
    };
  }
  return {
    ok: true,
    sort,
    items: (snap.data().items || []).filter((row) => row && row.id),
  };
});

const listSocialComments = callable(async (req) => {
  const postId = validatedDocumentId(req.data?.postId, "gönderi");
  const db = getFirestore();
  await requireSocialSession(db, req);
  const postSnap = await db.collection("social_posts").doc(postId).get();
  const post = postSnap.data() || {};
  if (!postSnap.exists || post.status !== "active") {
    throw new HttpsError("not-found", "Gönderi bulunamadı.");
  }
  let query = db.collection("social_posts").doc(postId)
    .collection("comments")
    .orderBy("createdAt", "asc")
    .limit(COMMENT_PAGE);
  const cursorMs = Number(req.data?.cursorCreatedAtMs);
  if (Number.isFinite(cursorMs) && cursorMs > 0) {
    query = query.startAfter(Timestamp.fromMillis(cursorMs));
  }
  const snap = await query.get();
  const last = snap.docs[snap.docs.length - 1];
  return {
    ok: true,
    post: digestItemFromData(postSnap.id, post),
    items: snap.docs
      .filter((doc) => doc.data()?.status !== "hidden")
      .map(commentFromSnap),
    nextCursorCreatedAtMs: snap.size === COMMENT_PAGE
      ? last?.data()?.createdAt?.toMillis?.() || null
      : null,
    nextCursorId: snap.size === COMMENT_PAGE ? last?.id || null : null,
  };
});

const createSocialPost = callable(async (req) => {
  const text = validatePostText(req.data?.text);
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  const [profile, premium] = await Promise.all([
    requireProfile(db, uid),
    callerIsPremium(db, req, uid),
  ]);
  await assertSocialRates(
    db,
    req,
    installHash,
    "post",
    POSTS_PER_DAY,
    true,
  );
  const postRef = db.collection("social_posts").doc();
  const createdAtMs = Date.now();
  const postItem = digestItemFromData(postRef.id, {
    text,
    authorUid: uid,
    authorUsername: profile.username,
    authorBio: profile.bio || "",
    authorAvatarId: profile.avatarId || 0,
    authorPremium: premium,
    likeCount: 0,
    commentCount: 0,
    lastComments: [],
    createdAtMs,
  });
  await postRef.set({
    text,
    authorUid: uid,
    authorUsername: profile.username,
    authorBio: profile.bio || "",
    authorAvatarId: profile.avatarId || 0,
    authorPremium: premium,
    likeCount: 0,
    commentCount: 0,
    lastComments: [],
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  try {
    await prependLatestDigest(db, postItem);
  } catch (error) {
    console.warn("social digest prepend after post skipped", error);
  }
  return {
    ok: true,
    post: postItem,
  };
});

const deleteSocialPost = callable(async (req) => {
  const postId = validatedDocumentId(req.data?.postId, "gönderi");
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  const admin = await callerIsSocialAdmin(db, req);
  if (!admin) {
    await assertSocialRates(db, req, installHash, "delete", 20, true);
  }
  const ref = db.collection("social_posts").doc(postId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Gönderi bulunamadı.");
    }
    const authorUid = String(snap.data()?.authorUid || "");
    if (authorUid !== uid && !admin) {
      throw new HttpsError("permission-denied", "Bu gönderiyi silemezsin.");
    }
    tx.update(ref, {
      status: "hidden",
      hiddenReason: authorUid === uid ? "author" : "admin",
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  try {
    await removeFromDigests(db, postId);
  } catch (error) {
    console.warn("social digest remove after delete skipped", error);
  }
  return { ok: true, hidden: true };
});

const addSocialComment = callable(async (req) => {
  const postId = validatedDocumentId(req.data?.postId, "gönderi");
  const text = validateCommentText(req.data?.text);
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  const [profile, premium] = await Promise.all([
    requireProfile(db, uid),
    callerIsPremium(db, req, uid),
  ]);
  await assertSocialRates(
    db,
    req,
    installHash,
    "comment",
    COMMENTS_PER_DAY,
    true,
  );
  const postRef = db.collection("social_posts").doc(postId);
  const commentRef = postRef.collection("comments").doc();
  let postItem = null;
  let authorUid = "";
  await db.runTransaction(async (tx) => {
    const postSnap = await tx.get(postRef);
    const post = postSnap.data() || {};
    if (!postSnap.exists || post.status !== "active") {
      throw new HttpsError("not-found", "Gönderi bulunamadı.");
    }
    authorUid = String(post.authorUid || "");
    const lastComments = appendLastComments(post.lastComments, {
      username: profile.username,
      text,
      avatarId: profile.avatarId || 0,
    });
    tx.create(commentRef, {
      text,
      authorUid: uid,
      authorUsername: profile.username,
      authorBio: profile.bio || "",
      authorAvatarId: profile.avatarId || 0,
      authorPremium: premium,
      likeCount: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    const nextCount = Math.max(0, Number(post.commentCount) || 0) + 1;
    tx.update(postRef, {
      commentCount: FieldValue.increment(1),
      lastComments,
      updatedAt: FieldValue.serverTimestamp(),
    });
    postItem = digestItemFromData(postSnap.id, {
      ...post,
      commentCount: nextCount,
      lastComments,
    });
  });
  if (postItem) {
    try {
      await patchDigestCounts(db, postItem);
    } catch (error) {
      console.warn("social comment digest skipped", error);
    }
  }
  try {
    await notifyPostAuthorOnComment({
      db,
      authorUid,
      commenterUid: uid,
      commenterName: profile.username,
      postId,
    });
  } catch (error) {
    console.warn("social comment notify skipped", error);
  }
  return {
    ok: true,
    comment: {
      id: commentRef.id,
      text,
      authorUid: uid,
      authorUsername: profile.username,
      authorBio: profile.bio || "",
      authorAvatarId: profile.avatarId || 0,
      authorPremium: premium,
      likeCount: 0,
      createdAtMs: Date.now(),
    },
    post: postItem,
  };
});

const deleteSocialComment = callable(async (req) => {
  const postId = validatedDocumentId(req.data?.postId, "gönderi");
  const commentId = validatedDocumentId(req.data?.commentId, "yorum");
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  const admin = await callerIsSocialAdmin(db, req);
  if (!admin) {
    await assertSocialRates(db, req, installHash, "delete", 20, true);
  }
  const postRef = db.collection("social_posts").doc(postId);
  const commentRef = postRef.collection("comments").doc(commentId);
  let postItem = null;
  await db.runTransaction(async (tx) => {
    const [postSnap, commentSnap] = await Promise.all([
      tx.get(postRef),
      tx.get(commentRef),
    ]);
    if (!commentSnap.exists) {
      throw new HttpsError("not-found", "Yorum bulunamadı.");
    }
    if (String(commentSnap.data()?.authorUid || "") !== uid && !admin) {
      throw new HttpsError("permission-denied", "Bu yorumu silemezsin.");
    }
    const post = postSnap.data() || {};
    tx.delete(commentRef);
    if (postSnap.exists && post.status === "active") {
      const current = Math.max(0, Number(post.commentCount) || 0);
      const nextCount = Math.max(0, current - 1);
      tx.update(postRef, {
        commentCount: nextCount,
        updatedAt: FieldValue.serverTimestamp(),
      });
      postItem = digestItemFromData(postSnap.id, {
        ...post,
        commentCount: nextCount,
      });
    }
  });
  if (postItem) {
    try {
      const lastComments = await loadLastCommentPreviews(postRef);
      await postRef.update({ lastComments });
      postItem = { ...postItem, lastComments };
    } catch (error) {
      console.warn("social lastComments rebuild skipped", error);
    }
    try {
      await patchDigestCounts(db, postItem);
    } catch (error) {
      console.warn("social comment delete digest skipped", error);
    }
  }
  return { ok: true, deleted: true, post: postItem };
});

const likeSocial = callable(async (req) => {
  const targetType = req.data?.targetType === "comment" ? "comment" : "post";
  const liked = req.data?.liked !== false;
  let targetRef;
  const db = getFirestore();
  if (targetType === "comment") {
    const postId = validatedDocumentId(req.data?.postId, "gönderi");
    const commentId = validatedDocumentId(req.data?.targetId, "yorum");
    targetRef = db.collection("social_posts").doc(postId)
      .collection("comments").doc(commentId);
  } else {
    const postId = validatedDocumentId(req.data?.targetId, "gönderi");
    targetRef = db.collection("social_posts").doc(postId);
  }
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  await assertSocialLikeRates(db, req, installHash);
  const voteRef = db.collection("social_votes")
    .doc(voteDocId(targetType, targetRef.id, uid));

  const result = await db.runTransaction(async (tx) => {
    const [targetSnap, voteSnap] = await Promise.all([
      tx.get(targetRef),
      tx.get(voteRef),
    ]);
    if (!targetSnap.exists) {
      throw new HttpsError("not-found", "Hedef bulunamadı.");
    }
    const data = targetSnap.data() || {};
    if (targetType === "post" && data.status !== "active") {
      throw new HttpsError("not-found", "Gönderi bulunamadı.");
    }
    const current = Math.max(0, Number(data.likeCount) || 0);
    if (liked) {
      if (voteSnap.exists) {
        return { liked: true, likeCount: current, data };
      }
      tx.set(voteRef, {
        targetType,
        targetId: targetRef.id,
        uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(targetRef, {
        likeCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { liked: true, likeCount: current + 1, data };
    }
    if (!voteSnap.exists) {
      return { liked: false, likeCount: current, data };
    }
    tx.delete(voteRef);
    tx.update(targetRef, {
      likeCount: current <= 0 ? 0 : FieldValue.increment(-1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { liked: false, likeCount: Math.max(0, current - 1), data };
  });

  if (targetType === "post") {
    try {
      await patchDigestCounts(db, digestItemFromData(targetRef.id, {
        ...(result.data || {}),
        likeCount: result.likeCount,
      }));
    } catch (error) {
      console.warn("social like digest skipped", error);
    }
  }

  return {
    ok: true,
    targetType,
    targetId: targetRef.id,
    liked: result.liked,
    likeCount: result.likeCount,
    post: null,
  };
});

const reportSocialPost = callable(async (req) => {
  const postId = validatedDocumentId(req.data?.postId, "gönderi");
  const db = getFirestore();
  const { uid, installHash } = await requireSocialSession(db, req);
  await assertNotBanned(db, uid, installHash);
  await assertSocialRates(db, req, installHash, "report", 10, true);
  const postRef = db.collection("social_posts").doc(postId);
  const reportRef = postRef.collection("reports").doc(uid);
  let hidden = false;
  await db.runTransaction(async (tx) => {
    const [postSnap, reportSnap] = await Promise.all([
      tx.get(postRef),
      tx.get(reportRef),
    ]);
    if (!postSnap.exists || postSnap.data()?.status !== "active") {
      throw new HttpsError("not-found", "Gönderi bulunamadı.");
    }
    if (reportSnap.exists) return;
    tx.set(reportRef, {
      uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    const nextReports = Math.max(0, Number(postSnap.data()?.reportCount) || 0) + 1;
    const patch = {
      reportCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (nextReports >= REPORTS_TO_HIDE) {
      hidden = true;
      patch.status = "hidden";
      patch.hiddenReason = "reports";
    }
    tx.update(postRef, patch);
  });
  if (hidden) {
    try {
      await removeFromDigests(db, postId);
    } catch (error) {
      console.warn("social digest remove after report skipped", error);
    }
  }
  return { ok: true, reported: true, hidden };
});

const banSocialUser = callable(async (req) => {
  const db = getFirestore();
  const { uid } = await requireSocialSession(db, req);
  await assertSocialAdmin(db, req);
  const targetUid = validatedDocumentId(req.data?.targetUid, "kullanıcı");
  if (targetUid === uid) {
    throw new HttpsError("invalid-argument", "Kendini banlayamazsın.");
  }
  if (req.data?.lift === true) {
    const profileSnap = await db.collection("social_profiles").doc(targetUid).get();
    const installHash = String(profileSnap.data()?.installHash || "");
    const deletes = [db.collection("social_bans").doc(targetUid).delete()];
    if (installHash) {
      deletes.push(
        db.collection("social_bans").doc(`install_${installHash}`).delete(),
      );
    }
    await Promise.all(deletes);
    return { ok: true, lifted: true, targetUid };
  }
  const hours = validatedBanHours(req.data?.durationHours);
  const now = Date.now();
  const permanent = hours === 0;
  const untilMs = permanent ? null : now + hours * 60 * 60 * 1000;
  const profileSnap = await db.collection("social_profiles").doc(targetUid).get();
  const installHash = String(profileSnap.data()?.installHash || "");
  const payload = {
    uid: targetUid,
    installHash: installHash || null,
    permanent,
    untilMs,
    until: permanent ? null : Timestamp.fromMillis(untilMs),
    expiresAt: permanent ? null : Timestamp.fromMillis(untilMs + 7 * 86400000),
    bannedBy: uid,
    createdAt: FieldValue.serverTimestamp(),
  };
  const writes = [db.collection("social_bans").doc(targetUid).set(payload)];
  if (installHash) {
    writes.push(
      db.collection("social_bans").doc(`install_${installHash}`).set(payload),
    );
  }
  await Promise.all(writes);
  await hideBannedAuthorContent(db, targetUid);
  return {
    ok: true,
    banned: true,
    targetUid,
    permanent,
    untilMs,
  };
});

async function purgeSocialIdentity(db, uid) {
  const profileRef = db.collection("social_profiles").doc(uid);
  const profileSnap = await profileRef.get();
  const key = String(profileSnap.data()?.usernameKey || "");
  if (key) {
    await db.collection("social_usernames").doc(key).delete().catch(() => {});
  }
  const asciiKey = asciiUsernameKey(profileSnap.data()?.username || "");
  if (asciiKey && asciiKey !== key) {
    await db.collection("social_usernames").doc(asciiKey).delete().catch(() => {});
  }
  const installHash = String(profileSnap.data()?.installHash || "");
  if (installHash) {
    await db.collection("social_installs").doc(installHash).delete().catch(() => {});
  }
  await profileRef.delete().catch(() => {});
}

module.exports = {
  functions: {
    getSocialProfile,
    claimSocialUsername,
    setSocialBio,
    setSocialAvatar,
    listSocialFeed,
    listSocialComments,
    createSocialPost,
    deleteSocialPost,
    addSocialComment,
    deleteSocialComment,
    likeSocial,
    reportSocialPost,
    banSocialUser,
  },
  testables: {
    usernameKey,
    validateUsername,
    validatePostText,
    validateCommentText,
    validateBio,
    validateAvatarId,
    normalizeAvatarId,
    prependLatestItems,
    dropDigestItem,
    upsertPopularItems,
    containsSocialInsult,
    validatedBanHours,
    readActiveBanData,
    socialBanMessage,
    voteDocId,
    digestItemFromData,
    pickPopularItems,
    validatedSort,
    premiumRecordActive,
    purgeSocialIdentity,
    previewCommentsFromData,
    appendLastComments,
    validatedFcmToken,
    socialCommentPushCopy,
    asciiUsernameKey,
    RESERVED_USERNAMES,
    POST_MIN,
    POST_MAX,
    COMMENT_MIN,
    COMMENT_MAX,
    BIO_MIN,
    BIO_MAX,
    AVATAR_MAX,
  },
};
