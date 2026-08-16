"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

process.env.NODE_ENV = "test";
const { testables: t } = require("../assistant");

function assertHttpsError(fn, expectedCode) {
  assert.throws(
    fn,
    (err) => {
      assert.equal(err.code, expectedCode);
      return true;
    },
  );
}

test("assertUserMessage rejects empty, long, and wordy input", () => {
  assertHttpsError(() => t.assertUserMessage("   "), "invalid-argument");
  assertHttpsError(() => t.assertUserMessage("a".repeat(t.MAX_USER_CHARS + 1)), "invalid-argument");
  assert.equal(t.assertUserMessage("a".repeat(t.MAX_USER_CHARS)).length, t.MAX_USER_CHARS);
  assert.equal(t.assertUserMessage("  Öğleyi kıldım  "), "Öğleyi kıldım");
});

test("clipTurnText keeps long model replies within reply budget", () => {
  const long = Array.from({ length: 90 }, () => "kelime").join(" ");
  assert.ok(long.length > t.MAX_USER_CHARS);
  const kept = t.clipTurnText(long, "model");
  assert.equal(kept, long);
  assert.ok(kept.length <= t.MAX_REPLY_CHARS);
  assert.equal(t.clipTurnText("a".repeat(t.MAX_USER_CHARS + 20), "user").length, t.MAX_USER_CHARS);
});

test("sanitizeHistory keeps last 8 valid turns", () => {
  const raw = Array.from({ length: 12 }, (_, i) => ({
    role: i % 2 === 0 ? "user" : "model",
    text: `mesaj ${i}`,
  }));
  const cleaned = t.sanitizeHistory(raw);
  assert.equal(cleaned.length, t.MAX_HISTORY);
  assert.equal(cleaned[0].text, "mesaj 4");
  assert.equal(t.sanitizeHistory([{ role: "system", text: "x" }]).length, 0);
});

test("clipWords enforces reply cap", () => {
  const words = Array.from({ length: t.MAX_REPLY_WORDS + 40 }, () => "selam").join(" ");
  assert.equal(t.countWords(t.clipWords(words, t.MAX_REPLY_WORDS)), t.MAX_REPLY_WORDS);
});

test("applyQuotaTick blocks day, minute, and month caps", () => {
  const now = Date.parse("2026-08-16T12:00:00+03:00");
  const keys = t.istanbulParts(now);
  const dayBlock = t.applyQuotaTick(
    { dayKey: keys.dayKey, dayCount: t.MAX_DAY, monthKey: keys.monthKey, monthCount: 1 },
    now,
  );
  assert.equal(dayBlock.ok, false);
  assert.equal(dayBlock.reason, "day");

  const minuteBlock = t.applyQuotaTick(
    {
      dayKey: keys.dayKey,
      dayCount: 1,
      monthKey: keys.monthKey,
      monthCount: 1,
      minuteKey: keys.minuteKey,
      minuteCount: t.MAX_MINUTE,
    },
    now,
  );
  assert.equal(minuteBlock.ok, false);
  assert.equal(minuteBlock.reason, "minute");

  const monthBlock = t.applyQuotaTick(
    { dayKey: "2026-08-01", dayCount: 0, monthKey: keys.monthKey, monthCount: t.MAX_MONTH },
    now,
  );
  assert.equal(monthBlock.ok, false);
  assert.equal(monthBlock.reason, "month");

  const ok = t.applyQuotaTick({}, now);
  assert.equal(ok.ok, true);
  assert.equal(ok.next.dayCount, 1);
  assert.equal(ok.remainingToday, t.MAX_DAY - 1);
});

test("sanitizeActions drops unknown tools and clamps alarm", () => {
  const actions = t.sanitizeActions([
    { name: "open_page", args: { page: "qibla" } },
    { name: "open_page", args: { page: "widgets" } },
    { name: "open_page", args: { page: "bank_transfer" } },
    { name: "create_alarm", args: { hour: 7, minute: 0, title: "Sahur" } },
    { name: "create_alarm", args: { hour: 30, minute: 0 } },
    { name: "create_alarm", args: { hour: null, minute: 0 } },
    { name: "set_notifications", args: { channel: "prayer", enabled: false } },
    { name: "set_notifications", args: { channel: "zikir" } },
    { name: "delete_account", args: {} },
  ]);
  assert.deepEqual(
    actions.map((a) => a.name),
    ["open_page", "open_page", "create_alarm"],
  );
  assert.equal(actions[1].args.page, "widgets");
  assert.equal(actions[2].args.hour, 7);
  const stringBool = t.sanitizeActions([
    { name: "set_notifications", args: { channel: "zikir", enabled: "true" } },
  ]);
  assert.equal(stringBool[0].args.enabled, true);
});

test("premiumRecordActive requires active true unless bonus remains", () => {
  assert.equal(t.premiumRecordActive({}), false);
  assert.equal(t.premiumRecordActive({ active: "true" }), false);
  assert.equal(t.premiumRecordActive({ active: true, expiresAt: 0 }), false);
  assert.equal(t.premiumRecordActive({ active: true }), true);
  assert.equal(
    t.premiumRecordActive({
      active: false,
      hilalWeeklyBonusExpiresAt: { toMillis: () => Date.now() + 60_000 },
    }),
    true,
  );
});

test("parseGeminiPayload reads text and function calls", () => {
  const parsed = t.parseGeminiPayload({
    candidates: [
      {
        content: {
          parts: [
            { thought: true, text: "iç düşünce" },
            { text: "Yatsı bildirimini kapatıyorum." },
            { functionCall: { name: "set_notifications", args: { channel: "prayer_isha", enabled: false } } },
          ],
        },
      },
    ],
  });
  assert.match(parsed.reply, /Yatsı/);
  assert.doesNotMatch(parsed.reply, /düşünce/);
  assert.equal(parsed.actions[0].name, "set_notifications");
  assert.equal(parsed.actions[0].args.enabled, false);
});

test("gemini models use current lite endpoints", () => {
  assert.deepEqual(t.MODELS, ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite"]);
  assert.match(t.geminiUrl(t.MODELS[0]), /models\/gemini-3\.5-flash-lite:generateContent$/);
});

test("sanitizeContext stamps Istanbul clock and ignores client year", () => {
  const ctx = t.sanitizeContext(
    { name: "Asadad", locale: "tr", today: "2025-01-01" },
    Date.parse("2026-08-16T18:00:00+03:00"),
  );
  assert.equal(ctx.today, "2026-08-16");
  assert.equal(ctx.year, 2026);
  assert.match(ctx.now, /2026-08-16/);
  assert.match(ctx.now, /Europe\/Istanbul/);
});

test("sanitizeHistory drops leading model turns and merges same role", () => {
  const cleaned = t.sanitizeHistory([
    { role: "model", text: "eski" },
    { role: "user", text: "bir" },
    { role: "user", text: "iki" },
    { role: "model", text: "cevap" },
  ]);
  assert.equal(cleaned[0].role, "user");
  assert.match(cleaned[0].text, /bir/);
  assert.equal(cleaned[1].role, "model");
});
