// Dua Halkası (Prayer Circle) — pure backend validation & security-invariant
// tests. Uses only Node's built-in test runner/assert (no extra runtime
// dependencies). Exercises the pure helpers exposed via
// `exports._testables` in ../index.js, which are the exact functions the
// deployed `onCall`/`onSchedule`/`onRequest` handlers call — nothing here is
// duplicated/reimplemented logic that could silently drift from production.

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");

process.env.NODE_ENV = "test";
const { _testables: t } = require("../index.js");

function assertHttpsError(fn, expectedCode) {
  assert.throws(
    fn,
    (err) => {
      assert.equal(err.code, expectedCode);
      return true;
    },
  );
}

test("prayerSessionMatchesInstall: binds custom prayer uid and claim", () => {
  const installHash = "a".repeat(64);
  const uid = `prayer_${installHash.substring(0, 48)}`;
  assert.equal(t.prayerSessionMatchesInstall(uid, installHash, installHash), true);
  assert.equal(
    t.prayerSessionMatchesInstall(uid, "b".repeat(64), installHash),
    false,
  );
  assert.equal(
    t.prayerSessionMatchesInstall(`prayer_${"b".repeat(48)}`, installHash, installHash),
    false,
  );
});

test("prayerSessionMatchesInstall: allows real Firebase account binding", () => {
  assert.equal(
    t.prayerSessionMatchesInstall("google-firebase-uid", "", "a".repeat(64)),
    true,
  );
});

test("validatedPrayerBindingSecretHash: validates and hashes secrets", () => {
  const secret = "binding_secret_1234567890_abcdef";
  const hash = t.validatedPrayerBindingSecretHash(secret);
  assert.match(hash, /^[a-f0-9]{64}$/);
  assert.equal(hash, t.validatedPrayerBindingSecretHash(secret));
  assertHttpsError(
    () => t.validatedPrayerBindingSecretHash("too-short"),
    "invalid-argument",
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// _validatedPrayerText — normalization, length bounds, and PII/spam rejection
// ─────────────────────────────────────────────────────────────────────────────
test("validatedPrayerText: collapses internal whitespace and trims", () => {
  const out = t.validatedPrayerText("  Annem   için\n\tdua   edin lütfen  ");
  assert.equal(out, "Annem için dua edin lütfen");
  assert.ok(!/\s{2,}/.test(out), "no run of 2+ whitespace chars should remain");
  assert.equal(out, out.trim());
});

test("validatedPrayerText: rejects text shorter than 8 chars", () => {
  assertHttpsError(() => t.validatedPrayerText("kısa"), "invalid-argument");
});

test("validatedPrayerText: accepts text at the 8-char lower bound", () => {
  const out = t.validatedPrayerText("A".repeat(8));
  assert.equal(out.length, 8);
});

test("validatedPrayerText: rejects text longer than 420 chars", () => {
  assertHttpsError(
    () => t.validatedPrayerText("a ".repeat(300)),
    "invalid-argument",
  );
});

test("validatedPrayerText: accepts text at the 420-char upper bound", () => {
  const exact = "b".repeat(420);
  assert.equal(t.validatedPrayerText(exact).length, 420);
});

test("validatedPrayerText: rejects http/https/www URLs", () => {
  for (const bad of [
    "Lütfen bu duayı oku http://example.com şimdi hemen",
    "Lütfen bu duayı oku https://example.com şimdi hemen",
    "Lütfen www.example.com adresine bak şimdi hemen olur",
  ]) {
    assertHttpsError(() => t.validatedPrayerText(bad), "invalid-argument");
  }
});

test("validatedPrayerText: rejects embedded email addresses", () => {
  assertHttpsError(
    () => t.validatedPrayerText("Bana yaz: someone@example.com lütfen olur mu"),
    "invalid-argument",
  );
});

test("validatedPrayerText: rejects Turkish IBAN patterns", () => {
  assertHttpsError(
    () => t.validatedPrayerText("Bağış için TR330006100519786457841326 gönderin"),
    "invalid-argument",
  );
});

test("validatedPrayerText: rejects phone-number-like sequences", () => {
  assertHttpsError(
    () => t.validatedPrayerText("Beni ara: +90 555 123 45 67 hemen şimdi lütfen"),
    "invalid-argument",
  );
});

test("validatedPrayerText: rejects payment/contact keyword mentions", () => {
  for (const keyword of ["iban", "whatsapp", "telegram", "ödeme", "payment"]) {
    assertHttpsError(
      () => t.validatedPrayerText(`Lütfen ${keyword} üzerinden ulaşın bana olur mu`),
      "invalid-argument",
    );
  }
});

test("validatedPrayerText: rejects @mention-style handles", () => {
  assertHttpsError(
    () => t.validatedPrayerText("Beni takip et @kullaniciadi lütfen hemen olur"),
    "invalid-argument",
  );
});

test("validatedPrayerText: rejects profanity", () => {
  assertHttpsError(
    () => t.validatedPrayerText("Bu adam tam bir piç, ona da dua edin lütfen"),
    "invalid-argument",
  );
});

test("validatedPrayerText: accepts a clean, well-formed prayer request", () => {
  const out = t.validatedPrayerText(
    "Annemin sağlığı için dua eder misiniz, ameliyatı yaklaşıyor.",
  );
  assert.equal(
    out,
    "Annemin sağlığı için dua eder misiniz, ameliyatı yaklaşıyor.",
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// _validatedPrayerCategory / _validatedPrayerLocale
// ─────────────────────────────────────────────────────────────────────────────
test("validatedPrayerCategory: accepts each known category (case/whitespace insensitive)", () => {
  for (const c of ["health", "family", "peace", "education", "work", "general"]) {
    assert.equal(t.validatedPrayerCategory(` ${c.toUpperCase()} `), c);
  }
});

test("validatedPrayerCategory: rejects unknown categories", () => {
  for (const bad of ["", "money", "politics", "<script>", null, undefined]) {
    assertHttpsError(() => t.validatedPrayerCategory(bad), "invalid-argument");
  }
});

test("validatedPrayerLocale: accepts tr/en/ar and defaults invalid/missing to tr", () => {
  assert.equal(t.validatedPrayerLocale("TR"), "tr");
  assert.equal(t.validatedPrayerLocale(" en "), "en");
  assert.equal(t.validatedPrayerLocale("AR"), "ar");
  assert.equal(t.validatedPrayerLocale("de"), "tr");
  assert.equal(t.validatedPrayerLocale(""), "tr");
  assert.equal(t.validatedPrayerLocale(undefined), "tr");
  assert.equal(t.validatedPrayerLocale(null), "tr");
  // Locale is a soft fallback, never throws — a malicious/garbage locale must
  // not be able to abort a call that otherwise validated correctly.
  assert.equal(t.validatedPrayerLocale({ toString: () => "en" }), "en");
});

// ─────────────────────────────────────────────────────────────────────────────
// ID validation — request/document/proof IDs (injection & shape hardening)
// ─────────────────────────────────────────────────────────────────────────────
test("validatedPrayerRequestId: accepts 16-128 char alnum/dash/underscore", () => {
  assert.equal(t.validatedPrayerRequestId("A".repeat(16)), "A".repeat(16));
  assert.equal(t.validatedPrayerRequestId("a-b_c-" + "1".repeat(20)), "a-b_c-" + "1".repeat(20));
  assert.equal(t.validatedPrayerRequestId("X".repeat(128)), "X".repeat(128));
});

test("validatedPrayerRequestId: rejects too-short, too-long, and bad-char ids", () => {
  assertHttpsError(() => t.validatedPrayerRequestId("short"), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerRequestId("A".repeat(129)), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerRequestId("a".repeat(16) + "/"), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerRequestId("a".repeat(15) + " "), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerRequestId(""), "invalid-argument");
});

test("validatedPrayerDocumentId: requires exactly 32 lowercase-hex chars (Firestore doc-path safety)", () => {
  const good = "a".repeat(32).replace(/a/g, (c, i) => "0123456789abcdef"[i % 16]);
  assert.equal(t.validatedPrayerDocumentId(good), good);
  assertHttpsError(() => t.validatedPrayerDocumentId(good.slice(0, 31)), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerDocumentId(good + "0"), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerDocumentId(good.toUpperCase()), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerDocumentId("g".repeat(32)), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerDocumentId("../../etc/passwd"), "invalid-argument");
});

test("validatedPrayerProofId: accepts 20-64 alphanumeric chars only", () => {
  assert.equal(t.validatedPrayerProofId("A".repeat(20)), "A".repeat(20));
  assert.equal(t.validatedPrayerProofId("z".repeat(64)), "z".repeat(64));
});

test("validatedPrayerProofId: rejects out-of-range length and non-alphanumeric chars", () => {
  assertHttpsError(() => t.validatedPrayerProofId("a".repeat(19)), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerProofId("a".repeat(65)), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerProofId("a".repeat(19) + "-"), "invalid-argument");
  assertHttpsError(() => t.validatedPrayerProofId(""), "invalid-argument");
});

// ─────────────────────────────────────────────────────────────────────────────
// _decodePrayerRewardCustomData — AdMod SSV custom_data decoding must fail
// closed (return null) on any malformed or mismatched payload; it never
// throws to the caller since a bad third-party payload should be ignored,
// not crash the SSV endpoint.
// ─────────────────────────────────────────────────────────────────────────────
function encodeCustomData(obj) {
  return Buffer.from(JSON.stringify(obj), "utf8").toString("base64url");
}

const VALID_PROOF_ID = "P".repeat(24);

test("decodePrayerRewardCustomData: decodes a well-formed payload", () => {
  const payload = { version: 1, proofId: VALID_PROOF_ID };
  const decoded = t.decodePrayerRewardCustomData(encodeCustomData(payload));
  assert.deepEqual(decoded, { proofId: VALID_PROOF_ID });
  assert.ok(encodeCustomData(payload).length < 100);
});

test("decodePrayerRewardCustomData: rejects malformed base64", () => {
  assert.equal(t.decodePrayerRewardCustomData("%%%not-base64%%%"), null);
});

test("decodePrayerRewardCustomData: rejects non-JSON payload", () => {
  const notJson = Buffer.from("this is not json", "utf8").toString("base64url");
  assert.equal(t.decodePrayerRewardCustomData(notJson), null);
});

test("decodePrayerRewardCustomData: rejects missing fields", () => {
  assert.equal(t.decodePrayerRewardCustomData(encodeCustomData({})), null);
  assert.equal(
    t.decodePrayerRewardCustomData(
      encodeCustomData({ version: 1 }),
    ),
    null,
  );
});

test("decodePrayerRewardCustomData: rejects mismatched/invalid shapes", () => {
  const base = { version: 1, proofId: VALID_PROOF_ID };
  // Unknown/missing protocol version fails closed.
  assert.equal(
    t.decodePrayerRewardCustomData(encodeCustomData({ ...base, version: 2 })),
    null,
  );
  assert.equal(
    t.decodePrayerRewardCustomData(encodeCustomData({ proofId: VALID_PROOF_ID })),
    null,
  );
  // proofId fails its own validator (too short) -> internal throw caught, null
  assert.equal(
    t.decodePrayerRewardCustomData(encodeCustomData({ ...base, proofId: "short" })),
    null,
  );
});

test("decodePrayerRewardCustomData: rejects extra-nested/prototype-polluting shapes gracefully", () => {
  const weird = encodeCustomData({
    version: 1,
    proofId: VALID_PROOF_ID,
    __proto__: { polluted: true },
    extra: { nested: "ignored" },
  });
  const decoded = t.decodePrayerRewardCustomData(weird);
  assert.ok(decoded);
  assert.equal(decoded.polluted, undefined);
  assert.deepEqual(decoded, { proofId: VALID_PROOF_ID });
});

test("verifyAdMobSsvSignature: accepts exact signed query and rejects tampering", () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  const signedContent =
    "ad_network=1&ad_unit=test-unit&custom_data=abc&transaction_id=tx-1";
  const signature = crypto.sign(
    "sha256",
    Buffer.from(signedContent, "utf8"),
    privateKey,
  ).toString("base64url");
  const rawQuery = `${signedContent}&signature=${signature}&key_id=123`;
  const pem = publicKey.export({ type: "spki", format: "pem" });
  assert.equal(t.verifyAdMobSsvSignature(rawQuery, pem), true);
  assert.equal(
    t.verifyAdMobSsvSignature(rawQuery.replace("tx-1", "tx-2"), pem),
    false,
  );
  assert.equal(t.verifyAdMobSsvSignature("missing=signature", pem), false);
});

// ─────────────────────────────────────────────────────────────────────────────
// _dedupeId — deterministic hashing used to derive Firestore document IDs
// ─────────────────────────────────────────────────────────────────────────────
test("dedupeId: is deterministic and produces a 64-char lowercase hex sha256", () => {
  const a = t.dedupeId(["ownerHashValue", "requestIdValue"]);
  const b = t.dedupeId(["ownerHashValue", "requestIdValue"]);
  assert.equal(a, b);
  assert.match(a, /^[a-f0-9]{64}$/);
});

test("dedupeId: different inputs produce different hashes (no trivial collisions)", () => {
  const a = t.dedupeId(["owner1", "req1"]);
  const b = t.dedupeId(["owner2", "req1"]);
  const c = t.dedupeId(["owner1", "req2"]);
  assert.notEqual(a, b);
  assert.notEqual(a, c);
  assert.notEqual(b, c);
});

test("dedupeId: joins parts with '|' (documented, non-exploitable property)", () => {
  // dedupeId hashes parts.join("|") without escaping, so ["a","b|c"] and
  // ["a|b","c"] collide (both join to "a|b|c"). Every current caller only
  // passes regex-validated ids (hex hashes / [A-Za-z0-9_-]) that can never
  // contain "|", so this is not exploitable today — but it means dedupeId
  // must not be fed unsanitized/free-text input in the future.
  const a = t.dedupeId(["a", "b|c"]);
  const b = t.dedupeId(["a|b", "c"]);
  assert.equal(a, b, "expected documented separator-collision behavior");
});

// ─────────────────────────────────────────────────────────────────────────────
// Notification milestone logic & job id derivation
// ─────────────────────────────────────────────────────────────────────────────
test("isPrayerMilestone: fires only on positive multiples of 5", () => {
  assert.equal(t.isPrayerMilestone(5), true);
  assert.equal(t.isPrayerMilestone(10), true);
  assert.equal(t.isPrayerMilestone(100), true);
  assert.equal(t.isPrayerMilestone(0), false);
  assert.equal(t.isPrayerMilestone(-5), false);
  assert.equal(t.isPrayerMilestone(4), false);
  assert.equal(t.isPrayerMilestone(6), false);
  assert.equal(t.isPrayerMilestone(5.5), false);
});

test("prayerNotificationJobId: deterministic and idempotent per (documentId, count)", () => {
  const id1 = t.prayerNotificationJobId("doc123", 5);
  const id2 = t.prayerNotificationJobId("doc123", 5);
  const id3 = t.prayerNotificationJobId("doc123", 10);
  const id4 = t.prayerNotificationJobId("docXYZ", 5);
  assert.equal(id1, "doc123_5");
  assert.equal(id1, id2, "same (documentId, count) must map to the same job id (idempotency)");
  assert.notEqual(id1, id3);
  assert.notEqual(id1, id4);
});

test("prayerNotificationCopy: renders per-locale copy with count interpolated, falls back to tr", () => {
  const tr = t.prayerNotificationCopy("tr", 5);
  const en = t.prayerNotificationCopy("en", 5);
  const ar = t.prayerNotificationCopy("ar", 5);
  const fallback = t.prayerNotificationCopy("xx", 5);
  assert.ok(tr.title && tr.body.includes("5"));
  assert.ok(en.title && en.body.includes("5"));
  assert.ok(ar.title && ar.body.includes("5"));
  assert.deepEqual(fallback, tr);
});

// ─────────────────────────────────────────────────────────────────────────────
// Pagination cursor sanitization (listPrayerRequests)
// ─────────────────────────────────────────────────────────────────────────────
test("validatedPrayerCursorMs: accepts positive safe integers", () => {
  assert.equal(t.validatedPrayerCursorMs(1700000000000), 1700000000000);
  assert.equal(t.validatedPrayerCursorMs("1700000000000"), 1700000000000);
  assert.equal(t.validatedPrayerCursorMs(1), 1);
});

test("validatedPrayerCursorMs: rejects zero, negative, non-numeric, non-integer, and unsafe values", () => {
  assert.equal(t.validatedPrayerCursorMs(0), null);
  assert.equal(t.validatedPrayerCursorMs(-1), null);
  assert.equal(t.validatedPrayerCursorMs("not-a-number"), null);
  assert.equal(t.validatedPrayerCursorMs(1.5), null);
  assert.equal(t.validatedPrayerCursorMs(undefined), null);
  assert.equal(t.validatedPrayerCursorMs(null), null);
  assert.equal(t.validatedPrayerCursorMs(Number.MAX_SAFE_INTEGER + 10), null);
  assert.equal(t.validatedPrayerCursorMs(NaN), null);
  assert.equal(t.validatedPrayerCursorMs(Infinity), null);
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth invariant & premium-record activity check (security invariants)
// ─────────────────────────────────────────────────────────────────────────────
test("assertPrayerAuth: throws unauthenticated when req.auth is missing/empty", () => {
  assertHttpsError(() => t.assertPrayerAuth({}), "unauthenticated");
  assertHttpsError(() => t.assertPrayerAuth({ auth: null }), "unauthenticated");
  assertHttpsError(() => t.assertPrayerAuth({ auth: {} }), "unauthenticated");
});

test("assertPrayerAuth: returns the caller's uid as a string when present", () => {
  assert.equal(t.assertPrayerAuth({ auth: { uid: "user-123" } }), "user-123");
});

test("assertPrayerPolicyAccepted: accepts only the current policy version", () => {
  assert.equal(t.assertPrayerPolicyAccepted(1), 1);
  assert.equal(t.assertPrayerPolicyAccepted("1"), 1);
  assertHttpsError(() => t.assertPrayerPolicyAccepted(0), "failed-precondition");
  assertHttpsError(
    () => t.assertPrayerPolicyAccepted(undefined),
    "failed-precondition",
  );
});

test("premiumRecordActive: requires active === true (strict boolean)", () => {
  assert.equal(t.premiumRecordActive({ active: true }), true);
  assert.equal(t.premiumRecordActive({ active: "true" }), false);
  assert.equal(t.premiumRecordActive({ active: 1 }), false);
  assert.equal(t.premiumRecordActive(null), false);
  assert.equal(t.premiumRecordActive(undefined), false);
  assert.equal(t.premiumRecordActive({}), false);
});

test("premiumRecordActive: treats missing expiresAt as active-forever, but rejects expired entitlements", () => {
  assert.equal(t.premiumRecordActive({ active: true, expiresAt: null }), true);
  assert.equal(t.premiumRecordActive({ active: true }), true);
  const future = { toMillis: () => Date.now() + 60_000 };
  const past = { toMillis: () => Date.now() - 60_000 };
  assert.equal(t.premiumRecordActive({ active: true, expiresAt: future }), true);
  assert.equal(t.premiumRecordActive({ active: true, expiresAt: past }), false);
});
