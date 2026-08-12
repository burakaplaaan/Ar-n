const test = require("node:test");
const assert = require("node:assert/strict");

process.env.NODE_ENV = "test";
const { _testables: t } = require("../index.js");
const questions = require("../data/islamic_quiz_questions.json");

test("question bank contains 1000 valid and unique questions", () => {
  assert.equal(questions.length, 1000);
  const ids = new Set();
  const normalizedQuestions = new Set();
  const byDifficulty = { 1: 0, 2: 0, 3: 0 };
  for (const item of questions) {
    assert.match(String(item.id), /^iq_\d{3,}$/);
    assert.equal(typeof item.question, "string");
    assert.ok(item.question.trim().length >= 12);
    assert.equal(item.options.length, 4);
    assert.equal(new Set(item.options.map((value) => value.trim())).size, 4);
    assert.ok(Number.isInteger(item.correctIndex));
    assert.ok(item.correctIndex >= 0 && item.correctIndex <= 3);
    assert.ok(item.options[item.correctIndex].trim().length > 0);
    assert.ok([1, 2, 3].includes(item.difficulty));
    byDifficulty[item.difficulty] += 1;
    assert.ok(item.explanation.trim().length >= 8);
    assert.ok(item.source.trim().length >= 4);
    assert.equal(ids.has(item.id), false);
    ids.add(item.id);
    const normalized = item.question.toLocaleLowerCase("tr-TR")
      .replace(/\s+/g, " ")
      .trim();
    assert.equal(normalizedQuestions.has(normalized), false);
    normalizedQuestions.add(normalized);
  }
  // Maçlar genel olarak zor: yeterli zor havuz şart.
  assert.ok(byDifficulty[3] >= 60, `hard pool too small: ${byDifficulty[3]}`);
});

test("match questions progress easy to hard without shuffle", () => {
  assert.equal(t.ROUND_REVEAL_MS, 2_600);
  for (let i = 0; i < 20; i += 1) {
    const ids = t.pickQuestions();
    assert.equal(ids.length, 7);
    assert.equal(new Set(ids).size, 7);
    const difficulties = ids.map((id) => {
      const item = questions.find((q) => q.id === id);
      assert.ok(item, `missing question ${id}`);
      return item.difficulty;
    });
    for (let j = 1; j < difficulties.length; j += 1) {
      assert.ok(
        difficulties[j] >= difficulties[j - 1],
        `not easy→hard: ${difficulties.join(",")}`,
      );
    }
  }
});

test("pickQuestions prefers unseen ids for the same player", () => {
  const easy = questions.filter((q) => q.difficulty === 1);
  assert.ok(easy.length >= 2);
  const keepEasy = easy[0].id;
  const excludeEasy = easy.slice(1).map((q) => q.id);
  const ids = t.pickQuestions(excludeEasy);
  const pickedEasy = ids.filter((id) => {
    const item = questions.find((q) => q.id === id);
    return item?.difficulty === 1;
  });
  assert.equal(pickedEasy.length, 1);
  assert.equal(pickedEasy[0], keepEasy);
  const merged = t.mergeSeenQuestionIds(["iq_001", "iq_002"], ["iq_002", "iq_003"], 7);
  assert.deepEqual(merged, ["iq_001", "iq_002", "iq_003"]);
  const capped = t.mergeSeenQuestionIds(
    ["a", "b", "c", "d", "e", "f", "g"],
    ["h"],
    7,
  );
  assert.deepEqual(capped, ["b", "c", "d", "e", "f", "g", "h"]);
  const allSeen = t.pickQuestions(questions.map((q) => q.id));
  assert.equal(allSeen.length, 7);
  assert.equal(new Set(allSeen).size, 7);
});

test("seen-question cap covers the full bank before repeats", () => {
  assert.ok(t.SEEN_QUESTION_IDS_CAP >= questions.length);
  const allIds = questions.map((q) => q.id);
  const kept = t.mergeSeenQuestionIds(allIds, []);
  assert.equal(kept.length, questions.length);
  assert.equal(kept[0], allIds[0]);
  assert.equal(kept[kept.length - 1], allIds[allIds.length - 1]);
});

test("question payload includes difficulty 1-3", () => {
  const payload = t.questionPayload("iq_001");
  assert.equal(payload.id, "iq_001");
  assert.ok([1, 2, 3].includes(payload.difficulty));
  assert.equal(payload.correctIndex, undefined);
});

test("iq_840 Nas ayah count is 6 in Hafs/Diyanet", () => {
  const item = questions.find((q) => q.id === "iq_840");
  assert.ok(item);
  assert.equal(item.options[item.correctIndex], "6");
  assert.match(item.explanation, /6 ayet/);
});

test("levelForHilals keeps early levels attainable", () => {
  assert.deepEqual(t.levelForHilals(0), {
    level: 1,
    levelFloorHilals: 0,
    nextLevelHilals: 40,
    maxLevel: false,
  });
  assert.equal(t.levelForHilals(39).level, 1);
  assert.equal(t.levelForHilals(40).level, 2);
  assert.equal(t.levelForHilals(94).level, 2);
  assert.equal(t.levelForHilals(95).level, 3);
  assert.equal(t.levelForHilals(250).level, 5);
  assert.equal(t.MAX_LEVEL, 10);
  assert.equal(t.levelForHilals(900).level, 10);
  assert.equal(t.levelForHilals(900).maxLevel, true);
  assert.equal(t.hilalsFloorForLevel(1), 0);
  assert.equal(t.hilalsFloorForLevel(2), 40);
  assert.equal(t.hilalsFloorForLevel(3), 95);
  assert.equal(t.levelForHilals(t.hilalsFloorForLevel(10)).level, 10);
  assert.equal(t.cosmeticsForLevel(5).title, "Talebe");
  assert.equal(t.cosmeticsForLevel(9).title, "Müderris");
  assert.equal(t.cosmeticsForLevel(10).title, "İlim Dostu");
  assert.equal(t.cosmeticsForLevel(2).avatarFrame, false);
  assert.equal(t.cosmeticsForLevel(3).avatarFrame, true);
  assert.equal(t.cosmeticsForLevel(3).avatarFrameTier, 1);
  assert.equal(t.cosmeticsForLevel(4).avatarFrameTier, 2);
  assert.equal(t.cosmeticsForLevel(5).avatarGlow, false);
  assert.equal(t.cosmeticsForLevel(6).avatarGlow, true);
  assert.equal(t.cosmeticsForLevel(6).nameAccentFaint, true);
  assert.equal(t.cosmeticsForLevel(6).nameAccentSoft, false);
  assert.equal(t.cosmeticsForLevel(7).nameAccentSoft, true);
  assert.equal(t.cosmeticsForLevel(7).nameAccent, false);
  assert.equal(t.cosmeticsForLevel(9).specialHilalIcon, true);
  assert.equal(t.cosmeticsForLevel(10).nameAccent, true);
  const empty = t.emptyCosmetics();
  assert.equal(empty.avatarFrame, false);
  assert.equal(empty.avatarGlow, false);
  assert.equal(t.cosmeticsDocFields(t.cosmeticsForLevel(10)).nameAccent, true);
  assert.equal(t.FORFEIT_PENALTY, 5);
  assert.match(
    t.weekIdIstanbul(new Date("2026-08-05T12:00:00+03:00")),
    /^\d{8}$/,
  );
});

test("previousWeekIdIstanbul is seven calendar days before current weekId", () => {
  // 2026-08-12 Çarşamba Istanbul → week 20260810; previous 20260803.
  assert.equal(
    t.weekIdIstanbul(new Date("2026-08-12T00:05:00+03:00")),
    "20260810",
  );
  assert.equal(
    t.previousWeekIdIstanbul(new Date("2026-08-12T00:05:00+03:00")),
    "20260803",
  );
  // Pazartesi gece kapanışı: yeni hafta id'si, ödül önceki haftaya.
  assert.equal(
    t.previousWeekIdIstanbul(new Date("2026-08-10T00:05:00+03:00")),
    "20260803",
  );
});

test("pickWeeklyHumanWinner skips bots, excluded, and zero scores", () => {
  const winner = t.pickWeeklyHumanWinner([
    {
      ownerHash: "bot_aaaaaaaaaaaaaaaaaaaa",
      name: "Bot Ali",
      weeklyHilals: 99,
      isBot: true,
    },
    {
      ownerHash: "a".repeat(64),
      name: "Zeynep",
      weeklyHilals: 12,
      leaderboardExcluded: true,
    },
    {
      ownerHash: "b".repeat(64),
      name: "Ayşe",
      weeklyHilals: 10,
    },
    {
      ownerHash: "c".repeat(64),
      name: "Burak",
      weeklyHilals: 10,
    },
    {
      ownerHash: "d".repeat(64),
      name: "Boş",
      weeklyHilals: 0,
    },
  ]);
  // Aynı hilalde tr isim sırası: Ayşe < Burak.
  assert.equal(winner.ownerHash, "b".repeat(64));
  assert.equal(winner.name, "Ayşe");
  assert.equal(t.pickWeeklyHumanWinner([]), null);
  assert.equal(
    t.pickWeeklyHumanWinner([{ ownerHash: "x", weeklyHilals: 0 }]),
    null,
  );
});

test("isGrantablePremiumUid rejects guest quiz_ uids", () => {
  assert.equal(t.isGrantablePremiumUid("google-oauth2|abc"), true);
  assert.equal(t.isGrantablePremiumUid("quiz_" + "a".repeat(40)), false);
  assert.equal(t.isGrantablePremiumUid(""), false);
  assert.equal(t.isGrantablePremiumUid(null), false);
});

test("weekly premium days by rank are 14/7/3", () => {
  assert.equal(t.HILAL_WEEKLY_PREMIUM_DAYS, 14);
  assert.equal(t.hilalWeeklyPremiumDaysForRank(1), 14);
  assert.equal(t.hilalWeeklyPremiumDaysForRank(2), 7);
  assert.equal(t.hilalWeeklyPremiumDaysForRank(3), 3);
  assert.equal(t.hilalWeeklyPremiumDaysForRank(4), 0);
  assert.equal(t.hilalWeeklyPremiumMsForRank(2), 7 * 24 * 60 * 60_000);
});

test("pickWeeklyHumanTop returns ordered humans up to limit", () => {
  const top = t.pickWeeklyHumanTop([
    {
      ownerHash: "bot_aaaaaaaaaaaaaaaaaaaa",
      name: "Bot",
      weeklyHilals: 99,
      isBot: true,
    },
    { ownerHash: "a".repeat(64), name: "Zeynep", weeklyHilals: 12 },
    { ownerHash: "b".repeat(64), name: "Ayşe", weeklyHilals: 10 },
    { ownerHash: "c".repeat(64), name: "Burak", weeklyHilals: 9 },
    { ownerHash: "d".repeat(64), name: "Cem", weeklyHilals: 8 },
  ], 3);
  assert.equal(top.length, 3);
  assert.equal(top[0].name, "Zeynep");
  assert.equal(top[1].name, "Ayşe");
  assert.equal(top[2].name, "Burak");
});

test("decideTop3RivalryNotifications overtaken and close_threat", () => {
  const board = [
    { ownerHash: "a".repeat(64), name: "Ali", weeklyHilals: 20, rank: 1 },
    { ownerHash: "b".repeat(64), name: "Buse", weeklyHilals: 15, rank: 2 },
    { ownerHash: "c".repeat(64), name: "Cem", weeklyHilals: 14, rank: 3 },
  ];
  const overtaken = t.decideTop3RivalryNotifications({
    actorOwnerHash: "a".repeat(64),
    actorName: "Ali",
    actorRank: 1,
    actorHilals: 20,
    board,
    lastPushAtByOwner: {},
    nowMs: 1_000_000,
    cooldownMs: 0,
  });
  assert.equal(overtaken.length, 1);
  assert.equal(overtaken[0].reason, "overtaken");
  assert.equal(overtaken[0].ownerHash, "b".repeat(64));

  const threat = t.decideTop3RivalryNotifications({
    actorOwnerHash: "c".repeat(64),
    actorName: "Cem",
    actorRank: 3,
    actorHilals: 14,
    board,
    lastPushAtByOwner: {},
    nowMs: 1_000_000,
    cooldownMs: 0,
    closeGap: 3,
  });
  assert.ok(
    threat.some((n) => n.reason === "close_threat" && n.ownerHash === "b".repeat(64)),
  );
});

test("computePremiumExtendExpiresAtMs stacks and preserves lifetime", () => {
  const now = Date.parse("2026-08-12T00:05:00+03:00");
  const day = 24 * 60 * 60_000;
  // Yeni / süresi dolmuş → now + 14g (#1).
  assert.equal(
    t.computePremiumExtendExpiresAtMs({
      existingActive: false,
      existingExpiresAtMs: 0,
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
    }),
    now + 14 * day,
  );
  // Aktif kalan süre üzerine stack.
  assert.equal(
    t.computePremiumExtendExpiresAtMs({
      existingActive: true,
      existingExpiresAtMs: now + 3 * day,
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
    }),
    now + 17 * day,
  );
  // Süresiz aktif → dokunma.
  assert.equal(
    t.computePremiumExtendExpiresAtMs({
      existingActive: true,
      existingExpiresAtMs: null,
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
    }),
    null,
  );
});

test("computeHilalWeeklyBonusExpiresAtMs stacks over RC and prior bonus", () => {
  const now = Date.parse("2026-08-12T00:05:00+03:00");
  const day = 24 * 60 * 60_000;
  assert.equal(
    t.computeHilalWeeklyBonusExpiresAtMs({
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
      existingActive: true,
      existingExpiresAtMs: now + 30 * day,
      existingBonusExpiresAtMs: 0,
    }),
    now + 44 * day,
  );
  assert.equal(
    t.computeHilalWeeklyBonusExpiresAtMs({
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
      existingActive: false,
      existingExpiresAtMs: 0,
      existingBonusExpiresAtMs: now + 2 * day,
    }),
    now + 16 * day,
  );
  assert.equal(
    t.computeHilalWeeklyBonusExpiresAtMs({
      nowMs: now,
      grantMs: t.HILAL_WEEKLY_PREMIUM_MS,
      existingActive: true,
      existingExpiresAtMs: null,
      existingBonusExpiresAtMs: 0,
    }),
    null,
  );
});

test("quiz premiumRecordActive honors hilalWeeklyBonusExpiresAt after RC revoke", () => {
  const future = { toMillis: () => Date.now() + 60_000 };
  const past = { toMillis: () => Date.now() - 60_000 };
  assert.equal(
    t.premiumRecordActive({
      active: false,
      expiresAt: past,
      hilalWeeklyBonusExpiresAt: future,
    }),
    true,
  );
  assert.equal(
    t.premiumRecordActive({
      active: false,
      hilalWeeklyBonusExpiresAt: past,
    }),
    false,
  );
});

test("determineWinner prioritizes correctness, then speed", () => {
  assert.equal(
    t.determineWinner(
      { correct: 3, elapsedMs: 100_000 },
      { correct: 2, elapsedMs: 1_000 },
    ),
    "a",
  );
  assert.equal(
    t.determineWinner(
      { correct: 2, elapsedMs: 11_400 },
      { correct: 2, elapsedMs: 16_800 },
    ),
    "a",
  );
  assert.equal(
    t.determineWinner(
      { correct: 2, elapsedMs: 11_400 },
      { correct: 2, elapsedMs: 11_400 },
    ),
    "draw",
  );
});

test("hilalAward uses one progression currency", () => {
  assert.equal(t.hilalAward(2, false), 4);
  assert.equal(t.hilalAward(2, true), 9);
  assert.equal(t.hilalAward(7, true), 22);
  assert.equal(t.hilalAward(2, false, true), 6);
});

test("quiz reward custom data remains distinct from prayer SSV", () => {
  const proofId = "Q".repeat(24);
  const encoded = Buffer.from(JSON.stringify({
    version: 2,
    kind: "quiz",
    proofId,
  }), "utf8").toString("base64url");
  assert.deepEqual(t.decodeQuizRewardCustomData(encoded), { proofId });
  assert.equal(t.decodePrayerRewardCustomData(encoded), null);
});

test("canAcceptAnswer rejects submits before roundStartedAtMs", () => {
  const start = 1_000_000;
  const deadline = start + 20_000;
  assert.deepEqual(
    t.canAcceptAnswer(start - 1, start, deadline),
    { ok: false, reason: "not_started" },
  );
  assert.deepEqual(
    t.canAcceptAnswer(start, start, deadline),
    { ok: true, reason: "ok" },
  );
  assert.deepEqual(
    t.canAcceptAnswer(start + 100, start, deadline),
    { ok: true, reason: "ok" },
  );
  assert.deepEqual(
    t.canAcceptAnswer(deadline + 2_000, start, deadline),
    { ok: false, reason: "expired" },
  );
});

test("perspective resolution choices survive map-key lookup", () => {
  const lastResolution = {
    round: 2,
    choices: {
      aaa111: 1,
      bbb222: 3,
    },
  };
  assert.deepEqual(
    t.perspectiveResolutionChoices(lastResolution, "aaa111", "bbb222"),
    { selfChoice: 1, opponentChoice: 3 },
  );
  assert.deepEqual(
    t.perspectiveResolutionChoices(lastResolution, "bbb222", "aaa111"),
    { selfChoice: 3, opponentChoice: 1 },
  );
  // Eksik oyuncu: null (challenge solo); timeout ile karıştırma.
  assert.deepEqual(
    t.perspectiveResolutionChoices(lastResolution, "missing", "bbb222"),
    { selfChoice: null, opponentChoice: 3 },
  );
  assert.deepEqual(
    t.perspectiveResolutionChoices({ round: 0 }, "aaa111", "bbb222"),
    { selfChoice: null, opponentChoice: null },
  );
  assert.deepEqual(
    t.perspectiveResolutionChoices(
      { round: 1, choices: { aaa111: -1 } },
      "aaa111",
      "bbb222",
    ),
    { selfChoice: -1, opponentChoice: null },
  );
});

test("answer grace keeps poll timeout and submit window aligned", () => {
  const start = 1_000_000;
  const deadline = start + 20_000;
  assert.equal(t.ANSWER_GRACE_MS, 1_500);
  // Deadline anında cevap hâlâ kabul; otomatik timeout YOK.
  assert.deepEqual(
    t.canAcceptAnswer(deadline, start, deadline),
    { ok: true, reason: "ok" },
  );
  assert.equal(t.shouldAutoTimeoutAnswers(deadline, deadline), false);
  assert.deepEqual(
    t.canAcceptAnswer(deadline + 1_000, start, deadline),
    { ok: true, reason: "ok" },
  );
  assert.equal(t.shouldAutoTimeoutAnswers(deadline + 1_000, deadline), false);
  // Grace sınırında submit ok; hemen sonra timeout dolar.
  assert.deepEqual(
    t.canAcceptAnswer(deadline + t.ANSWER_GRACE_MS, start, deadline),
    { ok: true, reason: "ok" },
  );
  assert.equal(
    t.shouldAutoTimeoutAnswers(deadline + t.ANSWER_GRACE_MS, deadline),
    false,
  );
  assert.deepEqual(
    t.canAcceptAnswer(deadline + t.ANSWER_GRACE_MS + 1, start, deadline),
    { ok: false, reason: "expired" },
  );
  assert.equal(
    t.shouldAutoTimeoutAnswers(deadline + t.ANSWER_GRACE_MS + 1, deadline),
    true,
  );
  assert.equal(t.isTimeoutAnswer({ choice: -1, correct: false }), true);
  assert.equal(t.isTimeoutAnswer({ choice: 2, correct: true }), false);
  assert.equal(
    t.canReplaceTimeoutAnswer(
      { choice: -1, correct: false },
      deadline + 500,
      start,
      deadline,
    ),
    true,
  );
  assert.equal(
    t.canReplaceTimeoutAnswer(
      { choice: 1, correct: false },
      deadline + 500,
      start,
      deadline,
    ),
    false,
  );
  const sampleId = questions[0].id;
  assert.equal(
    t.isChoiceCorrect(questions[0].correctIndex, sampleId),
    true,
  );
  assert.equal(
    t.isChoiceCorrect((questions[0].correctIndex + 1) % 4, sampleId),
    false,
  );
  assert.equal(t.isChoiceCorrect(-1, sampleId), false);
});

test("round advances as soon as both players answer", () => {
  const players = [{ id: "a" }, { id: "b" }];
  assert.equal(t.ROUND_DURATION_MS, 20_000);
  assert.equal(t.allPlayersAnswered(players, {}), false);
  assert.equal(t.allPlayersAnswered(players, { a: { choice: 0 } }), false);
  assert.equal(
    t.allPlayersAnswered(players, {
      a: { choice: 0 },
      b: { choice: 1 },
    }),
    true,
  );
});

test("shouldRefundAbandonedQueue is heart-source aware", () => {
  const now = Date.now();
  const waiting = {
    status: "waiting",
    heartSource: "ad",
    refunded: false,
    queuedAtMs: now - t.QUEUE_ABANDON_MS - 1,
  };
  assert.equal(t.shouldRefundAbandonedQueue(waiting, now), true);
  assert.equal(
    t.shouldRefundAbandonedQueue({ ...waiting, heartSource: "premium" }, now),
    false,
  );
  assert.equal(
    t.shouldRefundAbandonedQueue({ ...waiting, refunded: true }, now),
    false,
  );
  assert.equal(
    t.shouldRefundAbandonedQueue({
      ...waiting,
      queuedAtMs: now - 1_000,
      activeUntilMs: now + 60_000,
    }, now),
    false,
  );
  assert.equal(
    t.shouldRefundAbandonedQueue({ status: "matched", heartSource: "ad" }, now),
    false,
  );
});

test("describeHeartRefund maps free vs ad without duplicates conceptually", () => {
  assert.deepEqual(t.describeHeartRefund("ad"), {
    type: "ad",
    incrementAdHearts: 1,
  });
  assert.deepEqual(t.describeHeartRefund("free"), {
    type: "free",
    clearFreeHeartUsedDay: true,
  });
  assert.deepEqual(t.describeHeartRefund("premium"), { type: "none" });
  assert.deepEqual(t.describeHeartRefund(""), { type: "none" });
});

test("free-player hearts come only from rewarded-ad balance", () => {
  assert.equal(t.adHeartBalance({ adHearts: 3 }), 3);
  assert.equal(t.adHeartBalance({ adHearts: -2 }), 0);
  assert.equal(
    t.adHeartBalance({
      adHearts: 0,
      premium: true,
      freeHeartUsedDay: null,
    }),
    0,
  );
  assert.equal(
    t.isAdFundedQueue({
      status: "waiting",
      heartSource: "ad",
      heartChargeId: "charge_1",
    }),
    true,
  );
  assert.equal(
    t.isAdFundedQueue({
      status: "waiting",
      heartSource: "free",
      heartChargeId: "charge_2",
    }),
    false,
  );
  assert.equal(
    t.isAdFundedQueue({ status: "waiting", heartSource: "premium" }),
    false,
  );
  const premiumQueue = {
    status: "waiting",
    heartSource: "premium",
  };
  assert.equal(t.isPremiumFundedQueue(premiumQueue), true);
  assert.equal(t.isFundedQueue(premiumQueue), true);
  assert.equal(t.isValidQueueFunding(premiumQueue), true);
  assert.equal(
    t.isPremiumFundedQueue({
      ...premiumQueue,
      heartChargeId: "unexpected_charge",
    }),
    false,
  );
  assert.equal(
    t.isValidQueueFunding({
      status: "waiting",
      ownerHash: "owner_1",
      heartSource: "ad",
      heartChargeId: "missing_ledger",
    }),
    false,
  );
});

test("ad-funded queue requires matching charged ledger", () => {
  const queue = {
    status: "waiting",
    ownerHash: "owner_1",
    heartSource: "ad",
    heartChargeId: "charge_1",
  };
  assert.equal(
    t.isValidChargedAdLedger(queue, {
      ownerHash: "owner_1",
      heartSource: "ad",
      status: "charged",
    }),
    true,
  );
  for (const charge of [
    null,
    { ownerHash: "other", heartSource: "ad", status: "charged" },
    { ownerHash: "owner_1", heartSource: "free", status: "charged" },
    { ownerHash: "owner_1", heartSource: "ad", status: "refunded" },
    { ownerHash: "owner_1", heartSource: "ad", status: "consumed_by_match" },
  ]) {
    assert.equal(t.isValidChargedAdLedger(queue, charge), false);
  }
});

test("queueAbandonAtMs prefers activeUntil over queuedAt+window", () => {
  const queuedAtMs = 1_000;
  assert.equal(
    t.queueAbandonAtMs({ queuedAtMs, activeUntilMs: 5_000 }),
    5_000,
  );
  assert.equal(
    t.queueAbandonAtMs({ queuedAtMs }),
    queuedAtMs + t.QUEUE_ABANDON_MS,
  );
});

test("weekly leaderboard keeps bots below humans without score inflation", () => {
  assert.equal(t.BOT_WEEKLY_CAP, 6);
  const ordered = t.orderWeeklyLeaderboard([
    { name: "Elif", weeklyHilals: 6, isBot: true },
    { name: "Arın Oyuncusu", weeklyHilals: 2, isBot: false },
    { name: "Ahmet", weeklyHilals: 1, isBot: false },
    { name: "Zeynep", weeklyHilals: 4, isBot: true },
  ]);
  assert.deepEqual(
    ordered.map((row) => row.name),
    ["Arın Oyuncusu", "Ahmet", "Elif", "Zeynep"],
  );
  assert.equal(ordered[0].rank, 1);
  assert.equal(ordered[2].isBot, true);
  assert.ok(ordered[0].weeklyHilals < ordered[2].weeklyHilals);
});

test("bot display names drop surnames", () => {
  assert.equal(t.botDisplayName("Elif Aydın"), "Elif");
  assert.equal(t.botDisplayName("  Mehmet   Kaya "), "Mehmet");
  assert.equal(t.botDisplayName("Ayşe"), "Ayşe");
  assert.ok(t.BOT_NAMES.every((name) => !/\s/u.test(name)));
});

test("stableBotId is deterministic per display name", () => {
  const a = t.stableBotId("Elif");
  const b = t.stableBotId("Elif Aydın"); // soyad düşülür → aynı id
  const c = t.stableBotId("Ahmet");
  assert.match(a, /^bot_[a-f0-9]{20}$/);
  assert.equal(a, b);
  assert.notEqual(a, c);
});

test("bot plan knows easy questions and hesitates on hard misses", () => {
  const easyIds = questions.filter((q) => q.difficulty === 1).slice(0, 40).map((q) => q.id);
  const hardIds = questions.filter((q) => q.difficulty === 3).slice(0, 40).map((q) => q.id);
  const easyPlan = t.botPlan(easyIds, 1);
  const hardPlan = t.botPlan(hardIds, 1);
  const easyCorrect = easyPlan.filter((row, i) => {
    const q = questions.find((item) => item.id === easyIds[i]);
    return row.choice === q.correctIndex;
  }).length;
  const hardCorrect = hardPlan.filter((row, i) => {
    const q = questions.find((item) => item.id === hardIds[i]);
    return row.choice === q.correctIndex;
  }).length;
  assert.ok(easyCorrect >= 30, `easy accuracy too low: ${easyCorrect}/40`);
  assert.ok(hardCorrect <= 22, `hard accuracy too high: ${hardCorrect}/40`);
  const hardWrong = hardPlan.filter((row, i) => {
    const q = questions.find((item) => item.id === hardIds[i]);
    return row.choice !== q.correctIndex;
  });
  assert.ok(hardWrong.length > 0);
  const avgWrongMs = hardWrong.reduce((sum, row) => sum + row.elapsedMs, 0) /
    hardWrong.length;
  assert.ok(avgWrongMs >= 8_000, `hard wrong too fast: ${avgWrongMs}`);
});

test("botReadyAtMs resolves with human submit; waits plan if human silent", () => {
  const start = 1_000_000;
  const planned = 12_000;
  // İnsan cevapladıysa bot aynı nowMs ile hazır — submit'te reveal gelsin.
  const ready = t.botReadyAtMs({
    roundStartedAtMs: start,
    plannedElapsedMs: planned,
    deadlineMs: start + 20_000,
    nowMs: start + 3_500,
    humanAnswered: true,
    humanElapsedMs: 3_000,
  });
  assert.equal(ready, start + 3_500);
  // İnsan yoksa planlanan süre.
  assert.equal(
    t.botReadyAtMs({
      roundStartedAtMs: start,
      plannedElapsedMs: 7_000,
      deadlineMs: start + 20_000,
      nowMs: start,
      humanAnswered: false,
      humanElapsedMs: 0,
    }),
    start + 7_000,
  );
});

test("botAnswerElapsedMs keeps plan when human forces early bot write", () => {
  const start = 1_000_000;
  const planElapsed = 12_000;
  assert.equal(
    t.botAnswerElapsedMs({
      planElapsedMs: planElapsed,
      nowMs: start + 3_500,
      roundStartedAtMs: start,
      humanAnswered: true,
    }),
    planElapsed,
  );
  // İnsan yokken duvar saati planı aşmasın.
  assert.equal(
    t.botAnswerElapsedMs({
      planElapsedMs: planElapsed,
      nowMs: start + 5_000,
      roundStartedAtMs: start,
      humanAnswered: false,
    }),
    5_000,
  );
});

test("quiz engagement stays non-spammy and prefers rank-drop copy", () => {
  const now = 1_000_000_000_000;
  const idleOk = now - t.ENGAGEMENT_MIN_IDLE_MS - 1_000;
  assert.equal(
    t.decideQuizEngagement({
      matchesCompleted: 0,
      lastMatchAtMs: idleOk,
      lastPushAtMs: 0,
      nowMs: now,
      currentRank: 5,
      bestWeeklyRank: 1,
    }).send,
    false,
  );
  const neverPlayed = t.decideQuizEngagement({
    matchesCompleted: 0,
    createdAtMs: now - t.ENGAGEMENT_NEVER_PLAYED_MIN_AGE_MS - 1_000,
    lastMatchAtMs: 0,
    lastPushAtMs: 0,
    nowMs: now,
    currentRank: 0,
    bestWeeklyRank: 0,
  });
  assert.equal(neverPlayed.send, true);
  assert.equal(neverPlayed.reason, "never_played");
  assert.equal(
    t.decideQuizEngagement({
      matchesCompleted: 1,
      lastMatchAtMs: now - 60_000,
      lastPushAtMs: 0,
      nowMs: now,
      currentRank: 5,
      bestWeeklyRank: 1,
    }).send,
    false,
  );
  assert.equal(
    t.decideQuizEngagement({
      matchesCompleted: 1,
      lastMatchAtMs: idleOk,
      lastPushAtMs: now - 60_000,
      nowMs: now,
      currentRank: 5,
      bestWeeklyRank: 1,
    }).send,
    false,
  );
  const drop = t.decideQuizEngagement({
    matchesCompleted: 2,
    lastMatchAtMs: idleOk,
    lastPushAtMs: now - t.ENGAGEMENT_COOLDOWN_MS - 1,
    nowMs: now,
    currentRank: 4,
    bestWeeklyRank: 1,
  });
  assert.equal(drop.send, true);
  assert.equal(drop.reason, "rank_drop");
  const comeback = t.decideQuizEngagement({
    matchesCompleted: 2,
    lastMatchAtMs: idleOk,
    lastPushAtMs: 0,
    nowMs: now,
    currentRank: 1,
    bestWeeklyRank: 1,
  });
  assert.equal(comeback.send, true);
  assert.equal(comeback.reason, "comeback");
  assert.match(t.quizEngagementCopy("tr", "rank_drop").title, /Sıralaman/);
  assert.match(t.quizEngagementCopy("tr", "comeback").body, /oyna/i);
  assert.match(t.quizEngagementCopy("tr", "never_played").body, /hediye|ilk/i);
});

test("pending promo hearts grant once per seq", () => {
  assert.equal(
    t.pendingPromoHeartsGain({ claimedSeq: 0, promoSeq: 3, amount: 1 }),
    1,
  );
  assert.equal(
    t.pendingPromoHeartsGain({ claimedSeq: 3, promoSeq: 3, amount: 1 }),
    0,
  );
  assert.equal(
    t.pendingPromoHeartsGain({ claimedSeq: 2, promoSeq: 5, amount: 1 }),
    1,
  );
  assert.equal(
    t.pendingPromoHeartsGain({ claimedSeq: 0, promoSeq: 0, amount: 1 }),
    0,
  );
});

test("challenge rank bonus rewards beating higher ranks", () => {
  assert.equal(t.challengeRankBonus(10, 2), 5);
  assert.equal(t.challengeRankBonus(0, 2), 5);
  assert.equal(t.challengeRankBonus(12, 8), 3);
  assert.equal(t.challengeRankBonus(20, 15), 2);
  assert.equal(t.challengeRankBonus(3, 10), 0);
  assert.equal(t.challengeRankBonus(5, 0), 0);
  assert.equal(t.CHALLENGE_TTL_MS, 24 * 60 * 60_000);
  assert.equal(t.CHALLENGE_BOT_DELAY_MS, 12 * 60 * 60_000);
  assert.equal(t.CHALLENGE_REMINDER_BEFORE_MS, 4 * 60 * 60_000);
});

test("bot challenge ids and weak plan (exactly one correct)", () => {
  assert.equal(t.isBotId("bot_0123456789abcdef0123"), true);
  assert.equal(t.isBotId("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"), false);
  assert.equal(t.isBotId("bot_short"), false);
  // createQuizChallenge must accept bot weekly ids (not only 64-hex humans).
  assert.equal(
    t.validatedOpponentId("bot_0123456789abcdef0123"),
    "bot_0123456789abcdef0123",
  );
  assert.equal(
    t.validatedOpponentId("BOT_0123456789ABCDEF0123"),
    "bot_0123456789abcdef0123",
  );
  const human = "a".repeat(64);
  assert.equal(t.validatedOpponentId(human), human);
  assert.throws(
    () => t.validatedOpponentId("not-a-player"),
    (err) => String(err?.message || "").includes("Geçersiz oyuncu kimliği"),
  );
  assert.equal(
    t.isChallengeBotOpponent({
      challengedIsBot: true,
      challengedId: "bot_0123456789abcdef0123",
    }),
    true,
  );
  assert.equal(
    t.isChallengeBotOpponent({
      challengedIsBot: false,
      challengedId: "a".repeat(64),
    }),
    false,
  );
  // Accept path: bot opponent must be treated as non-acceptable invite target.
  assert.equal(
    t.isChallengeBotOpponent({ challengedId: "bot_0123456789abcdef0123" }),
    true,
  );
  const respondAfter = 1_000_000;
  const originalDeadline = respondAfter - 60_000; // shorter than 12h window
  assert.equal(
    t.challengeBotMinDeadlineMs(respondAfter, originalDeadline),
    respondAfter + 5 * 60_000,
  );
  assert.equal(
    t.challengeBotMinDeadlineMs(respondAfter, respondAfter + 10 * 60_000),
    respondAfter + 10 * 60_000,
  );
  const ids = t.pickQuestions();
  assert.equal(ids.length, 7);
  const plan = t.challengeBotWeakPlan(ids);
  assert.equal(plan.length, 7);
  const correctCount = plan.filter((step) => step.correct === true).length;
  assert.equal(correctCount, 1);
  // Weak plan ⇒ bot rarely beats a human who scores ≥2; award stays soft.
  assert.ok(correctCount < 2);
  for (let i = 0; i < plan.length; i += 1) {
    const step = plan[i];
    assert.ok(Number.isInteger(step.choice));
    assert.ok(step.choice >= 0 && step.choice <= 3);
    assert.ok(step.elapsedMs > 0);
    assert.equal(t.isChoiceCorrect(step.choice, ids[i]), step.correct);
  }
});

test("challenge expiry and copy", () => {
  const now = 1_000_000;
  assert.equal(
    t.challengeIsExpired({
      status: "awaiting_opponent",
      challengeDeadlineMs: now - 1,
    }, now),
    true,
  );
  assert.equal(
    t.challengeIsExpired({
      status: "completed",
      challengeDeadlineMs: now - 1,
    }, now),
    false,
  );
  assert.equal(
    t.challengeIsExpired({
      status: "awaiting_opponent",
      challengeDeadlineMs: now + 10_000,
    }, now),
    false,
  );
  // Eski kayıt: deadline yok → createdAt + 24s.
  const late = 2_000_000_000_000;
  assert.equal(
    t.challengeDeadlineMsOf({
      createdAt: { toMillis: () => late - t.CHALLENGE_TTL_MS - 5_000 },
    }),
    late - 5_000,
  );
  assert.equal(
    t.challengeIsExpired({
      status: "awaiting_opponent",
      createdAt: { toMillis: () => late - t.CHALLENGE_TTL_MS - 5_000 },
    }, late),
    true,
  );
  assert.match(t.quizChallengeCopy("tr", "invited", { name: "Ayşe" }).body, /Ayşe/);
  assert.match(t.quizChallengeCopy("tr", "reminder").body, /puan/i);
  for (const lang of ["tr", "en", "ar"]) {
    for (const kind of ["invited", "reminder", "won", "lost", "draw"]) {
      const copy = t.quizChallengeCopy(lang, kind, { name: "Ayşe" });
      assert.equal(/bot/i.test(copy.title + " " + copy.body), false);
    }
  }
});

test("createQuizChallenge skips expired-unfinalized as still open", () => {
  const now = 2_000_000;
  assert.equal(
    t.isCountableOpenChallenge({
      status: "awaiting_opponent",
      challengeDeadlineMs: now + 10_000,
    }, now),
    true,
  );
  assert.equal(
    t.isCountableOpenChallenge({
      status: "awaiting_opponent",
      challengeDeadlineMs: now - 1,
    }, now),
    false,
  );
  assert.equal(
    t.isCountableOpenChallenge({
      status: "completed",
      challengeDeadlineMs: now + 10_000,
    }, now),
    false,
  );
  const me = "aa";
  const other = "bb";
  const tally = t.tallyCountableChallenges([
    {
      id: "c1",
      data: {
        status: "awaiting_opponent",
        challengerId: me,
        challengedId: "x",
        challengeDeadlineMs: now + 1,
      },
    },
    {
      id: "c2",
      data: {
        status: "awaiting_opponent",
        challengerId: me,
        challengedId: other,
        challengeDeadlineMs: now - 1,
      },
    },
    {
      id: "c3",
      data: {
        status: "challenger_playing",
        challengerId: me,
        challengedId: "y",
        challengeDeadlineMs: now + 1,
      },
    },
  ], me, other, now);
  assert.equal(tally.outgoingOpen, 2);
  assert.equal(tally.hasOpenPair, false);
  assert.deepEqual(tally.openOutgoingIds, ["c1", "c3"]);
  assert.equal(
    t.openPeerChallengeId({ openChallengePeers: { bb: "c9" } }, "bb"),
    "c9",
  );
  assert.equal(t.openPeerChallengeId({}, "bb"), "");
});

test("challenge inbox keeps completed 48h and hides expired", () => {
  const now = 1_700_000_000_000;
  assert.equal(t.CHALLENGE_INBOX_COMPLETED_MS, 48 * 60 * 60_000);
  assert.equal(
    t.shouldListChallengeInInbox({
      status: "expired",
      challengeDeadlineMs: now - 1,
    }, now),
    false,
  );
  assert.equal(
    t.shouldListChallengeInInbox({
      status: "awaiting_opponent",
      challengeDeadlineMs: now - 1,
    }, now),
    false,
  );
  assert.equal(
    t.shouldListChallengeInInbox({
      status: "opponent_playing",
      challengeDeadlineMs: now + 5_000,
    }, now),
    true,
  );
  assert.equal(
    t.shouldListChallengeInInbox({
      status: "completed",
      updatedAt: { toMillis: () => now - 60_000 },
    }, now),
    true,
  );
  assert.equal(
    t.shouldListChallengeInInbox({
      status: "completed",
      updatedAt: { toMillis: () => now - t.CHALLENGE_INBOX_COMPLETED_MS - 1 },
    }, now),
    false,
  );
  assert.equal(t.challengeInboxOutcome("completed", "me", "me"), "won");
  assert.equal(t.challengeInboxOutcome("completed", "them", "me"), "lost");
  assert.equal(t.challengeInboxOutcome("completed", "", "me"), "draw");
  assert.equal(t.challengeInboxOutcome("awaiting_opponent", "me", "me"), null);
});

test("last-week promo grantDays is 0 unless premium was granted", () => {
  const skipped = t.lastWeekWinnersFromLedgerData({
    status: "settled",
    placements: [
      { rank: 1, name: "Ali", ownerHash: "aa", grantDays: 14, premiumStatus: "skipped_already_premium" },
      { rank: 2, name: "Ece", ownerHash: "bb", grantDays: 7, premiumStatus: "granted" },
      { rank: 3, name: "Can", ownerHash: "cc", grantDays: 3, premiumStatus: "skipped_no_auth" },
    ],
  });
  assert.equal(skipped.length, 3);
  assert.equal(skipped[0].grantDays, 0);
  assert.equal(skipped[1].grantDays, 7);
  assert.equal(skipped[2].grantDays, 0);
  const granted = t.lastWeekWinnersFromLedgerData({
    status: "granted",
    ownerHash: "aa",
    name: "Ali",
    grantDays: 14,
  });
  assert.equal(granted.length, 1);
  assert.equal(granted[0].grantDays, 14);
  assert.equal(t.lastWeekWinnersFromLedgerData({ status: "pending" }), null);
});

test("match player payload never exposes a bot tell badge", () => {
  const decorated = t.decoratePlayer({
    id: "bot_0123456789abcdef0123",
    name: "Elif",
    hilals: 10,
    level: 2,
    isBot: true,
    badge: "Hızlı Rakip",
  });
  assert.equal(decorated.badge, null);
  assert.equal(decorated.isBot, true);
});

test("engagement gift copy uses heart not life in en/ar", () => {
  assert.match(t.quizEngagementCopy("en", "never_played").body, /heart/i);
  assert.equal(/life/i.test(t.quizEngagementCopy("en", "never_played").body), false);
  assert.match(t.quizEngagementCopy("ar", "never_played").body, /قلب/);
  assert.equal(/حياة/.test(t.quizEngagementCopy("ar", "never_played").body), false);
});
