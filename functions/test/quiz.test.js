const test = require("node:test");
const assert = require("node:assert/strict");

process.env.NODE_ENV = "test";
const { _testables: t } = require("../index.js");
const questions = require("../data/islamic_quiz_questions.json");

test("question bank contains 380 valid and unique questions", () => {
  assert.equal(questions.length, 380);
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
  assert.equal(t.cosmeticsForLevel(5).title, "Talebe");
  assert.equal(t.cosmeticsForLevel(10).title, "İlim Dostu");
  assert.equal(t.FORFEIT_PENALTY, 5);
  assert.match(
    t.weekIdIstanbul(new Date("2026-08-05T12:00:00+03:00")),
    /^\d{8}$/,
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
    { name: "Elif Aydın", weeklyHilals: 6, isBot: true },
    { name: "Arın Oyuncusu", weeklyHilals: 2, isBot: false },
    { name: "Ahmet", weeklyHilals: 1, isBot: false },
    { name: "Zeynep", weeklyHilals: 4, isBot: true },
  ]);
  assert.deepEqual(
    ordered.map((row) => row.name),
    ["Arın Oyuncusu", "Ahmet", "Elif Aydın", "Zeynep"],
  );
  assert.equal(ordered[0].rank, 1);
  assert.equal(ordered[2].isBot, true);
  assert.ok(ordered[0].weeklyHilals < ordered[2].weeklyHilals);
});

test("stableBotId is deterministic per display name", () => {
  const a = t.stableBotId("Elif Aydın");
  const b = t.stableBotId("Elif Aydın");
  const c = t.stableBotId("Ahmet Yılmaz");
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

test("botReadyAtMs delays after human answer without locking the round", () => {
  const start = 1_000_000;
  const planned = 12_000;
  // İnsan 3sn'de cevapladı; bot planı 12sn — en fazla ~4.2sn sonra gelsin.
  const ready = t.botReadyAtMs({
    roundStartedAtMs: start,
    plannedElapsedMs: planned,
    deadlineMs: start + 20_000,
    nowMs: start + 3_500,
    humanAnswered: true,
    humanElapsedMs: 3_000,
  });
  assert.ok(ready >= start + 3_000 + 1_400);
  assert.ok(ready <= start + 3_000 + 4_200);
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
});
