"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const { testables } = require("../socialBoard");

test("usernameKey folds Turkish letters", () => {
  assert.equal(testables.usernameKey("Arın_1"), "arın_1");
});

test("validateUsername accepts letters and rejects reserved", () => {
  assert.deepEqual(testables.validateUsername("Kardeş_1"), {
    display: "Kardeş_1",
    key: "kardeş_1",
    asciiKey: "kardeş_1",
  });
  assert.throws(() => testables.validateUsername("admin"), /kullanılamaz/);
  assert.throws(() => testables.validateUsername("ADMIN"), /kullanılamaz/);
  assert.throws(() => testables.validateUsername("ARIN"), /kullanılamaz/);
  assert.throws(() => testables.validateUsername("arIn"), /kullanılamaz/);
  assert.throws(() => testables.validateUsername("ab"), /3–16/);
  assert.throws(() => testables.validateUsername("bad name"), /harf/);
  assert.equal(testables.asciiUsernameKey("ADMIN"), "admin");
});

test("post and comment length plus link filter", () => {
  assert.throws(() => testables.validatePostText("çok kısa"), /12–280/);
  const ok = "Sabaha kadar sabretmek güzeldir.";
  assert.equal(testables.validatePostText(ok), ok);
  assert.throws(() => testables.validatePostText("Bugün şükür:"), /12–280/);
  assert.throws(
    () => testables.validatePostText(`${ok} https://spam.com`),
    /bağlantı/,
  );
  assert.equal(testables.validateCommentText("amin"), "amin");
  assert.throws(() => testables.validateCommentText("a"), /2–200/);
});

test("popular sort prefers likes then recency", () => {
  const docs = [
    { id: "a", data: () => ({ likeCount: 2, createdAtMs: 10 }) },
    { id: "b", data: () => ({ likeCount: 5, createdAtMs: 1 }) },
    { id: "c", data: () => ({ likeCount: 5, createdAtMs: 8 }) },
  ];
  assert.deepEqual(
    testables.pickPopularItems(docs).map((row) => row.id),
    ["c", "b", "a"],
  );
});

test("digest stamps premium and vote ids stay scoped", () => {
  const item = testables.digestItemFromData("p1", {
    text: "Merhaba kardeşler",
    authorUid: "u1",
    authorUsername: "ali",
    authorPremium: true,
    likeCount: 3,
    commentCount: 2,
    createdAtMs: 9,
    lastComments: [
      { username: "ayse", text: "amin" },
      { username: "veli", text: "güzel" },
    ],
  });
  assert.equal(item.authorPremium, true);
  assert.equal(item.authorBio, "");
  assert.equal(item.authorAvatarId, 0);
  assert.equal(item.commentCount, 2);
  assert.deepEqual(item.lastComments, [
    { username: "ayse", text: "amin", avatarId: 0 },
    { username: "veli", text: "güzel", avatarId: 0 },
  ]);
  assert.equal(testables.voteDocId("post", "p1", "u1"), "post_p1_u1");
  assert.equal(testables.validatedSort("popular"), "popular");
  assert.equal(testables.validatedSort("new"), "latest");
});

test("last comments keep only the newest two", () => {
  const next = testables.appendLastComments(
    [
      { username: "a", text: "bir" },
      { username: "b", text: "iki" },
    ],
    { username: "c", text: "üç" },
  );
  assert.deepEqual(next, [
    { username: "b", text: "iki", avatarId: 0 },
    { username: "c", text: "üç", avatarId: 0 },
  ]);
  assert.equal(testables.validatedFcmToken("short"), null);
  assert.equal(
    testables.validatedFcmToken("a".repeat(24)),
    "a".repeat(24),
  );
});

test("Turkish insults are blocked without flagging normal words", () => {
  assert.equal(testables.containsSocialInsult("Sabaha kadar sabretmek güzeldir."), false);
  assert.equal(testables.containsSocialInsult("klasik bir dua"), false);
  assert.equal(testables.containsSocialInsult("siktir git"), true);
  assert.equal(testables.containsSocialInsult("o.r.o.s.p.u"), true);
  assert.equal(testables.containsSocialInsult("amk"), true);
  assert.throws(
    () => testables.validatePostText("Bu kadar siktir yeter kardeşim"),
    /Küfür veya hakaret/,
  );
  assert.throws(() => testables.validateUsername("orospu"), /kullanılamaz/);
});

test("ban hours and active window", () => {
  assert.equal(testables.validatedBanHours(1), 1);
  assert.equal(testables.validatedBanHours(0), 0);
  assert.equal(testables.validatedBanHours("permanent"), 0);
  assert.throws(() => testables.validatedBanHours(3), /süre/);
  assert.equal(testables.readActiveBanData({ permanent: true }).permanent, true);
  assert.equal(
    testables.readActiveBanData({
      untilMs: Date.now() - 1000,
    }),
    null,
  );
  assert.match(testables.socialBanMessage({ permanent: true }), /kalıcı/);
});

test("bio length and clean text", () => {
  assert.equal(
    testables.validateBio("Namazı kaçırmamaya çalışan biriyim."),
    "Namazı kaçırmamaya çalışan biriyim.",
  );
  assert.throws(() => testables.validateBio("kısa"), /8–80/);
  assert.throws(
    () => testables.validateBio(`${"a".repeat(81)}`),
    /8–80/,
  );
  assert.throws(
    () => testables.validateBio("Kendimi anlatayım https://spam.com"),
    /bağlantı/,
  );
});

test("digest prepend and drop stay local", () => {
  const first = { id: "p1", text: "a" };
  const next = testables.prependLatestItems([first, { id: "p2" }], {
    id: "p3",
    text: "yeni",
  });
  assert.deepEqual(next.map((row) => row.id), ["p3", "p1", "p2"]);
  assert.deepEqual(
    testables.dropDigestItem(next, "p1").map((row) => row.id),
    ["p3", "p2"],
  );
  const popular = testables.upsertPopularItems(
    [{ id: "p1", likeCount: 2, createdAtMs: 1 }],
    { id: "p9", likeCount: 0, createdAtMs: 9 },
  );
  assert.deepEqual(popular.map((row) => row.id), ["p1", "p9"]);
  const full = Array.from({ length: 10 }, (_, i) => ({
    id: `f${i}`,
    likeCount: 4,
    createdAtMs: i,
  }));
  assert.deepEqual(
    testables.upsertPopularItems(full, {
      id: "new",
      likeCount: 0,
      createdAtMs: 99,
    }).map((row) => row.id),
    full.map((row) => row.id),
  );
  const promoted = testables.upsertPopularItems(full, {
    id: "hot",
    likeCount: 9,
    createdAtMs: 99,
  });
  assert.equal(promoted[0].id, "hot");
  assert.equal(promoted.length, 10);
  assert.equal(promoted.some((row) => row.id === "f0"), false);
  const resorted = testables.upsertPopularItems(
    [
      { id: "a", likeCount: 1, createdAtMs: 1 },
      { id: "b", likeCount: 5, createdAtMs: 2 },
    ],
    { id: "a", likeCount: 8, createdAtMs: 1 },
  );
  assert.deepEqual(resorted.map((row) => row.id), ["a", "b"]);
});

test("digest stamps author bio", () => {
  const item = testables.digestItemFromData("p2", {
    text: "Merhaba",
    authorUid: "u1",
    authorUsername: "ali",
    authorBio: "Sabırlı bir kardeş.",
    authorAvatarId: 3,
    createdAtMs: 1,
    lastComments: [
      { username: "ayse", text: "amin", avatarId: 1 },
    ],
  });
  assert.equal(item.authorBio, "Sabırlı bir kardeş.");
  assert.equal(item.authorAvatarId, 3);
  assert.equal(item.lastComments[0].avatarId, 1);
});

test("avatar ids stay in the local emoji set", () => {
  assert.equal(testables.AVATAR_MAX, 12);
  assert.equal(testables.validateAvatarId(undefined), 0);
  assert.equal(testables.validateAvatarId(7), 7);
  assert.equal(testables.validateAvatarId("12"), 12);
  assert.equal(testables.normalizeAvatarId(99), 0);
  assert.throws(() => testables.validateAvatarId(13), /avatar/);
  assert.throws(() => testables.validateAvatarId(-1), /avatar/);
});

test("premiumRecordActive honors expiry", () => {
  assert.equal(testables.premiumRecordActive(null), false);
  assert.equal(testables.premiumRecordActive({ active: true }), true);
  assert.equal(
    testables.premiumRecordActive({
      active: true,
      expiresAt: { toMillis: () => Date.now() - 1000 },
    }),
    false,
  );
});
