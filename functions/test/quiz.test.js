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

test("pickQuestions draws a mixed 7 from the full bank", () => {
  assert.equal(t.ROUND_REVEAL_MS, 2_600);
  for (let i = 0; i < 20; i += 1) {
    const ids = t.pickQuestions();
    assert.equal(ids.length, 7);
    assert.equal(new Set(ids).size, 7);
    for (const id of ids) {
      assert.ok(questions.some((item) => item.id === id), `missing ${id}`);
    }
  }
});

test("pickQuestions prefers unseen ids without a difficulty quota", () => {
  const keep = questions.slice(0, 7).map((item) => item.id);
  const exclude = questions.slice(7).map((item) => item.id);
  const ids = t.pickQuestions(exclude);
  assert.deepEqual(new Set(ids), new Set(keep));

  const hard = questions.filter((item) => item.difficulty === 3).slice(0, 7);
  assert.equal(hard.length, 7);
  const hardIds = hard.map((item) => item.id);
  const excludeAllButHard = questions
    .map((item) => item.id)
    .filter((id) => !hardIds.includes(id));
  const allHard = t.pickQuestions(excludeAllButHard);
  assert.deepEqual(new Set(allHard), new Set(hardIds));
  assert.ok(allHard.every((id) => {
    const item = questions.find((row) => row.id === id);
    return item?.difficulty === 3;
  }));

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

test("pickQuestions shuffles difficulty order in the match list", () => {
  const easy = questions.filter((item) => item.difficulty === 1).slice(0, 2);
  const medium = questions.filter((item) => item.difficulty === 2).slice(0, 2);
  const hard = questions.filter((item) => item.difficulty === 3).slice(0, 3);
  const keep = [...easy, ...medium, ...hard].map((item) => item.id);
  const exclude = questions
    .map((item) => item.id)
    .filter((id) => !keep.includes(id));
  const isSorted = (ids) => {
    const difficulties = ids.map((id) => {
      const item = questions.find((row) => row.id === id);
      return item.difficulty;
    });
    for (let i = 1; i < difficulties.length; i += 1) {
      if (difficulties[i] < difficulties[i - 1]) return false;
    }
    return true;
  };
  let mixed = 0;
  const signatures = new Set();
  for (let i = 0; i < 40; i += 1) {
    const ids = t.pickQuestions(exclude);
    assert.deepEqual(new Set(ids), new Set(keep));
    signatures.add(ids.join(","));
    if (!isSorted(ids)) mixed += 1;
  }
  assert.ok(mixed >= 8, `difficulty order stayed sorted: mixed=${mixed}`);
  assert.ok(signatures.size >= 3, `match order not shuffled: ${signatures.size}`);
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

test("arabic locale localizes question text and keeps answer index", () => {
  const questionsAr = require("../data/islamic_quiz_questions_ar.json");
  assert.equal(Object.keys(questionsAr).length, questions.length);
  const tr = t.questionPayload("iq_001", true, "tr");
  const ar = t.questionPayload("iq_001", true, "ar");
  const fallback = t.questionPayload("iq_001", true, "de");
  assert.equal(tr.question, "Kur'an-ı Kerim kaç sureden oluşur?");
  assert.match(ar.question, /القرآن/);
  assert.notEqual(ar.question, tr.question);
  assert.equal(ar.category, "معرفة القرآن");
  assert.equal(ar.correctIndex, tr.correctIndex);
  assert.equal(ar.options[ar.correctIndex], "114");
  assert.equal(fallback.question, tr.question);
  const kadir = t.questionPayload("iq_955", false, "ar");
  assert.match(kadir.question, /ليلة القدر/);
  assert.equal(kadir.options[0], "القدر");
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

test("challenge round marks reveal opponent sheet only when finished", () => {
  const q = questions[0];
  const wrong = (q.correctIndex + 1) % 4;
  const questionIds = Array.from({ length: 7 }, () => q.id);
  const completed = {
    status: "completed",
    currentRound: 6,
    questionIds,
    answers: {
      0: {
        me: { choice: q.correctIndex, elapsedMs: 900 },
        opp: { choice: wrong, elapsedMs: 1100 },
      },
      1: {
        me: { choice: -1, elapsedMs: 20000 },
        opp: { choice: q.correctIndex, elapsedMs: 800 },
      },
    },
  };
  assert.deepEqual(t.challengeRoundMarks(completed, "me"), [
    "correct", "missed", "missed", "missed", "missed", "missed", "missed",
  ]);
  assert.deepEqual(t.challengeRoundMarks(completed, "opp"), [
    "wrong", "correct", "missed", "missed", "missed", "missed", "missed",
  ]);

  const playing = {
    ...completed,
    status: "challenger_playing",
    currentRound: 2,
  };
  assert.deepEqual(t.challengeRoundMarks(playing, "me"), [
    "correct", "missed", "pending", "pending", "pending", "pending", "pending",
  ]);

  const serialized = t.serializeChallenge("c1", {
    challengerId: "aaa",
    challengedId: "bbb",
    challengerName: "A",
    challengedName: "B",
    status: "completed",
    currentRound: 6,
    questionIds,
    answers: {
      0: {
        aaa: { choice: q.correctIndex, elapsedMs: 1 },
        bbb: { choice: wrong, elapsedMs: 2 },
      },
    },
    result: { winnerId: "aaa", players: [] },
  }, "aaa");
  assert.equal(serialized.selfRoundMarks[0], "correct");
  assert.equal(serialized.opponentRoundMarks[0], "wrong");
  assert.equal(serialized.opponentRoundMarks[1], "missed");
  assert.equal(serialized.result.roundMarks.aaa[0], "correct");
  assert.equal(serialized.result.roundMarks.bbb[0], "wrong");

  const liveSource = {
    challengerId: "aaa",
    challengedId: "bbb",
    challengerName: "A",
    challengedName: "B",
    status: "challenger_playing",
    activePlayerId: "aaa",
    currentRound: 1,
    questionIds,
    answers: {
      0: { aaa: { choice: q.correctIndex, elapsedMs: 1 } },
    },
    lastResolution: {
      round: 0,
      choices: { aaa: q.correctIndex },
      elapsedMs: { aaa: 1 },
    },
  };
  const live = t.serializeChallenge("c2", liveSource, "aaa");
  assert.equal(live.selfRoundMarks[0], "correct");
  assert.deepEqual(live.opponentRoundMarks, [
    "pending", "pending", "pending", "pending", "pending", "pending", "pending",
  ]);
  assert.equal(live.opponentAnswered, false);
  assert.equal(t.challengePlayerSideState(liveSource, "bbb"), "not_started");

  const asChallenged = t.serializeChallenge("c2", liveSource, "bbb");
  assert.deepEqual(asChallenged.selfRoundMarks, [
    "pending", "pending", "pending", "pending", "pending", "pending", "pending",
  ]);
  assert.equal(asChallenged.selfAnswered, false);
  assert.equal(asChallenged.opponentAnswered, false);
  assert.equal(asChallenged.lastResolution, null);

  const awaiting = {
    ...liveSource,
    status: "awaiting_opponent",
    activePlayerId: null,
    currentRound: 0,
    lastResolution: {
      round: 6,
      choices: { aaa: q.correctIndex },
      elapsedMs: { aaa: 1 },
    },
  };
  assert.deepEqual(t.challengeRoundMarks(awaiting, "bbb"), [
    "pending", "pending", "pending", "pending", "pending", "pending", "pending",
  ]);
  assert.equal(t.serializeChallenge("c2b", awaiting, "bbb").lastResolution, null);

  const challengedTurn = t.serializeChallenge("c3", {
    challengerId: "aaa",
    challengedId: "bbb",
    challengerName: "A",
    challengedName: "B",
    status: "opponent_playing",
    activePlayerId: "bbb",
    currentRound: 2,
    lastResolution: {
      round: 1,
      choices: { bbb: wrong },
      elapsedMs: { bbb: 900 },
    },
    questionIds,
    answers: {
      0: {
        aaa: { choice: q.correctIndex, elapsedMs: 1 },
        bbb: { choice: wrong, elapsedMs: 2 },
      },
      1: {
        aaa: { choice: wrong, elapsedMs: 3 },
        bbb: { choice: wrong, elapsedMs: 900 },
      },
      2: { aaa: { choice: q.correctIndex, elapsedMs: 4 } },
    },
  }, "bbb");
  assert.equal(challengedTurn.opponentRoundMarks[0], "correct");
  assert.equal(challengedTurn.opponentRoundMarks[1], "wrong");
  assert.equal(challengedTurn.opponentRoundMarks[2], "correct");
  assert.equal(challengedTurn.lastResolution.opponentChoice, wrong);
  assert.equal(
    t.shouldRevealChallengeOpponentMarks(
      { status: "opponent_playing", challengedId: "bbb", challengerId: "aaa" },
      "bbb",
      "aaa",
    ),
    true,
  );
  assert.equal(
    t.shouldRevealChallengeOpponentMarks(
      { status: "challenger_playing", challengedId: "bbb", challengerId: "aaa" },
      "aaa",
      "bbb",
    ),
    false,
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

test("rankLiveQueueCandidates prefers recent joiners over older waiters", () => {
  const now = Date.now();
  const self = "self_owner";
  const items = [
    {
      ownerHash: "lvl5",
      status: "waiting",
      heartSource: "premium",
      level: 5,
      queuedAtMs: now - 9_000,
    },
    {
      ownerHash: "lvl2-new",
      status: "waiting",
      heartSource: "premium",
      level: 2,
      queuedAtMs: now - 2_000,
    },
    {
      ownerHash: "lvl2-old",
      status: "waiting",
      heartSource: "premium",
      level: 2,
      queuedAtMs: now - 8_000,
    },
    {
      ownerHash: self,
      status: "waiting",
      heartSource: "premium",
      level: 2,
      queuedAtMs: now - 20_000,
    },
    {
      ownerHash: "unfunded",
      status: "waiting",
      heartSource: "ad",
      level: 2,
      queuedAtMs: now - 12_000,
    },
    {
      ownerHash: "stale",
      status: "waiting",
      heartSource: "ad",
      heartChargeId: "charge_stale",
      level: 2,
      queuedAtMs: now - t.QUEUE_ABANDON_MS - 50,
      activeUntilMs: now - 1,
    },
    {
      ownerHash: "ancient",
      status: "waiting",
      heartSource: "premium",
      level: 2,
      queuedAtMs: now - t.QUEUE_RECENT_MS - 5_000,
    },
  ];
  const ranked = t.rankLiveQueueCandidates(items, {
    excludeOwnerHash: self,
    nowMs: now,
    level: 2,
    limit: 5,
  });
  assert.deepEqual(ranked.map((item) => item.ownerHash), [
    "lvl2-new",
    "lvl2-old",
    "lvl5",
    "ancient",
  ]);
});

test("pickPairableCandidate requires a live funded ledger", () => {
  const now = Date.now();
  const adQueue = {
    ownerHash: "owner_a",
    status: "waiting",
    heartSource: "ad",
    heartChargeId: "charge_a",
    level: 1,
    queuedAtMs: now - 1_000,
  };
  const premiumQueue = {
    ownerHash: "owner_b",
    status: "waiting",
    heartSource: "premium",
    level: 1,
    queuedAtMs: now - 500,
  };
  assert.equal(
    t.pickPairableCandidate([adQueue], new Map(), {
      nowMs: now,
      excludeOwnerHash: "self",
    }),
    null,
  );
  assert.equal(
    t.pickPairableCandidate([adQueue], new Map([
      ["charge_a", {
        ownerHash: "owner_a",
        heartSource: "ad",
        status: "charged",
      }],
    ]), {
      nowMs: now,
      excludeOwnerHash: "self",
    })?.ownerHash,
    "owner_a",
  );
  assert.equal(
    t.pickPairableCandidate([premiumQueue], new Map(), {
      nowMs: now,
      excludeOwnerHash: "self",
    })?.ownerHash,
    "owner_b",
  );
});

test("decideLiveQueuePollAction pairs humans before the bot timeout", () => {
  const now = Date.now();
  assert.equal(
    t.decideLiveQueuePollAction({
      selfStatus: "waiting",
      hasPairableHuman: true,
      queuedAtMs: now,
      nowMs: now + 1_000,
    }),
    "pair_human",
  );
  assert.equal(
    t.decideLiveQueuePollAction({
      selfStatus: "waiting",
      hasPairableHuman: false,
      queuedAtMs: now,
      nowMs: now + 1_000,
    }),
    "keep_waiting",
  );
  assert.equal(
    t.decideLiveQueuePollAction({
      selfStatus: "waiting",
      hasPairableHuman: true,
      queuedAtMs: now - t.QUEUE_WAIT_MS - 10,
      nowMs: now,
    }),
    "pair_human",
  );
  assert.equal(
    t.decideLiveQueuePollAction({
      selfStatus: "waiting",
      hasPairableHuman: false,
      queuedAtMs: now - t.QUEUE_WAIT_MS - 10,
      nowMs: now,
    }),
    "pair_bot",
  );
  assert.equal(
    t.decideLiveQueuePollAction({
      selfStatus: "waiting",
      hasPairableHuman: false,
      queuedAtMs: 0,
      nowMs: now,
    }),
    "pair_bot",
  );
});

test("stale premium waiting retires without an ad refund", () => {
  const now = Date.now();
  const premium = {
    ownerHash: "premium_owner",
    status: "waiting",
    heartSource: "premium",
    queuedAtMs: now - t.QUEUE_ABANDON_MS - 1,
  };
  assert.equal(t.shouldRefundAbandonedQueue(premium, now), false);
  assert.equal(t.shouldRetireStaleWaitingQueue(premium, now), true);
  assert.equal(t.isPairableWaitingQueue(premium, { nowMs: now }), false);
  assert.equal(
    t.isPairableWaitingQueue({
      ...premium,
      queuedAtMs: now - 1_000,
      activeUntilMs: now + 60_000,
    }, { nowMs: now }),
    true,
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

test("bot plan caps live matches at 1-3 correct and delays after human", () => {
  const ids = t.pickQuestions();
  assert.equal(ids.length, 7);
  const histogram = { 1: 0, 2: 0, 3: 0 };
  for (let sample = 0; sample < 80; sample += 1) {
    const plan = t.botPlan(ids, 10);
    assert.equal(plan.length, 7);
    const correctCount = plan.filter((step) => step.correct === true).length;
    assert.ok(correctCount >= 1 && correctCount <= 3, `out of range: ${correctCount}`);
    histogram[correctCount] += 1;
    for (let i = 0; i < plan.length; i += 1) {
      const step = plan[i];
      assert.ok(Number.isInteger(step.choice));
      assert.ok(step.choice >= 0 && step.choice <= 3);
      assert.ok(step.elapsedMs >= 2_200);
      assert.ok(step.elapsedMs <= 19_500);
      assert.equal(t.isChoiceCorrect(step.choice, ids[i]), step.correct);
      assert.ok(step.afterHumanDelayMs >= 2_500);
      assert.ok(step.afterHumanDelayMs <= 5_200);
      assert.ok(
        step.afterHumanDelayMs <= 3_500 || step.afterHumanDelayMs >= 4_800,
        `delay bucket: ${step.afterHumanDelayMs}`,
      );
    }
  }
  assert.ok(histogram[2] > histogram[1], `expected 2 most common: ${JSON.stringify(histogram)}`);
  assert.ok(histogram[2] > histogram[3], `expected 2 most common: ${JSON.stringify(histogram)}`);
  assert.ok(histogram[1] > 0);
  assert.ok(histogram[3] > 0);
  assert.equal(t.pickBotCorrectCount(0), 0);
  assert.equal(t.pickBotCorrectCount(1), 1);
});

test("botReadyAtMs waits after human and does not write before them", () => {
  const start = 1_000_000;
  // İnsan 3 sn'de cevapladıysa 2.5 sn daha bekle.
  assert.equal(
    t.botReadyAtMs({
      roundStartedAtMs: start,
      plannedElapsedMs: 12_000,
      deadlineMs: start + 20_000,
      nowMs: start + 3_500,
      humanAnswered: true,
      humanElapsedMs: 3_000,
      afterHumanDelayMs: 2_500,
    }),
    start + 5_500,
  );
  // Plan insandan önce dolmuş olsa bile submit anında yazma.
  assert.equal(
    t.botReadyAtMs({
      roundStartedAtMs: start,
      plannedElapsedMs: 4_000,
      deadlineMs: start + 20_000,
      nowMs: start + 15_000,
      humanAnswered: true,
      humanElapsedMs: 15_000,
      afterHumanDelayMs: 2_500,
    }),
    start + 17_500,
  );
  // İnsan yokken deadline'a kadar bekle — erken "Cevapladı" yok.
  assert.equal(
    t.botReadyAtMs({
      roundStartedAtMs: start,
      plannedElapsedMs: 7_000,
      deadlineMs: start + 20_000,
      nowMs: start,
      humanAnswered: false,
      humanElapsedMs: 0,
    }),
    start + 19_800,
  );
  // Gecikme deadline'ı ezmesin.
  assert.equal(
    t.botReadyAtMs({
      roundStartedAtMs: start,
      plannedElapsedMs: 19_500,
      deadlineMs: start + 20_000,
      nowMs: start + 18_500,
      humanAnswered: true,
      humanElapsedMs: 18_000,
      afterHumanDelayMs: 5_000,
    }),
    start + 19_800,
  );
});

test("roundAnswersChanged ignores identical poll snapshots", () => {
  const human = { choice: 1, elapsedMs: 3_000, correct: true };
  assert.equal(
    t.roundAnswersChanged({ p1: human }, { p1: { ...human } }),
    false,
  );
  assert.equal(
    t.roundAnswersChanged({ p1: human }, { p1: human, bot: { choice: 2, elapsedMs: 5_500, correct: false } }),
    true,
  );
  assert.equal(t.roundAnswersChanged({}, { p1: human }), true);
});

test("botAnswerElapsedMs follows human delay instead of instant write", () => {
  const start = 1_000_000;
  const planElapsed = 12_000;
  // 15 sn insan → bot ~10 sn (2/3 bandı).
  const fifteen = t.botAnswerElapsedMs({
    planElapsedMs: planElapsed,
    nowMs: start + 17_500,
    roundStartedAtMs: start,
    humanAnswered: true,
    humanElapsedMs: 15_000,
    afterHumanDelayMs: 2_500,
  });
  assert.ok(fifteen >= 8_500 && fifteen <= 11_000, `15s human → ${fifteen}`);
  assert.equal(
    t.botElapsedAfterHuman({
      humanElapsedMs: 15_000,
      planElapsedMs: planElapsed,
      afterHumanDelayMs: 2_500,
    }),
    fifteen,
  );
  const lateHuman = t.botAnswerElapsedMs({
    planElapsedMs: 4_000,
    nowMs: start + 17_500,
    roundStartedAtMs: start,
    humanAnswered: true,
    humanElapsedMs: 15_000,
    afterHumanDelayMs: 2_500,
  });
  assert.ok(lateHuman < 15_000, `bot must look faster than 15s: ${lateHuman}`);
  assert.ok(lateHuman >= 2_200);
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
  assert.equal(t.CHALLENGE_REMINDER_BEFORE_MS, 2 * 60 * 60_000);
});

test("admin auto challenge plan scores 3-5 correct", () => {
  const ids = t.pickQuestions([]);
  const plan = t.adminChallengeAutoPlan(ids);
  assert.equal(plan.length, 7);
  const marked = plan.filter((step) => step.correct === true).length;
  assert.ok(marked >= 3 && marked <= 5, `correct=${marked}`);
  const graded = plan.filter((step, index) =>
    t.isChoiceCorrect(step.choice, ids[index]),
  ).length;
  assert.equal(graded, marked);
  for (const step of plan) {
    assert.ok(Number.isInteger(step.choice));
    assert.ok(step.choice >= 0 && step.choice <= 3);
    assert.ok(step.elapsedMs >= 2_200);
    assert.ok(step.elapsedMs < t.ROUND_DURATION_MS);
  }
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
  assert.equal(t.CHALLENGE_REMINDER_BEFORE_MS, 2 * 60 * 60_000);
  assert.deepEqual(
    t.challengePushRecipients({
      kind: "completed",
      challengerId: "aaa",
      challengedId: "bbb",
      exceptOwnerHash: "bbb",
    }),
    ["aaa"],
  );
  assert.deepEqual(
    t.challengePushRecipients({
      kind: "invited",
      challengerId: "aaa",
      challengedId: "bbb",
      exceptOwnerHash: "aaa",
    }),
    ["bbb"],
  );
  assert.deepEqual(
    t.challengePushRecipients({
      kind: "completed",
      challengerId: "aaa",
      challengedId: "bot_aaaaaaaaaaaaaaaaaaaa",
    }),
    ["aaa"],
  );
  const flags = {};
  assert.equal(t.claimChallengeNotify(flags, "completedPushSent"), true);
  assert.equal(t.claimChallengeNotify(flags, "completedPushSent"), false);
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
  assert.equal(tally.outgoingPlaying, 1);
  assert.equal(tally.hasOpenPair, false);
  assert.deepEqual(tally.openOutgoingIds, ["c1", "c3"]);
  assert.equal(
    t.openPeerChallengeId({ openChallengePeers: { bb: "c9" } }, "bb"),
    "c9",
  );
  assert.equal(t.openPeerChallengeId({}, "bb"), "");
});

test("open outgoing challenges are counted without an active cap", () => {
  const now = 2_000_000;
  const me = "aa";
  const awaiting = (id, other) => ({
    id,
    data: {
      status: "awaiting_opponent",
      challengerId: me,
      challengedId: other,
      challengeDeadlineMs: now + 1,
    },
  });
  const tally = t.tallyCountableChallenges(
    [awaiting("c1", "b1"), awaiting("c2", "b2"), awaiting("c3", "b3")],
    me,
    "zz",
    now,
  );
  assert.equal(tally.outgoingOpen, 3);
  assert.equal(tally.outgoingPlaying, 0);
  assert.equal(t.CHALLENGE_MAX_ACTIVE_PLAYING, undefined);
  assert.equal(t.CHALLENGE_MAX_ACTIVE_OUTGOING, undefined);
});

test("quizClientIp skips unknown and loopback so they do not share a bucket", () => {
  assert.equal(t.quizClientIp({ rawRequest: {} }), "");
  assert.equal(
    t.quizClientIp({ rawRequest: { ip: "unknown" } }),
    "",
  );
  assert.equal(
    t.quizClientIp({ rawRequest: { ip: "127.0.0.1" } }),
    "",
  );
  assert.equal(
    t.quizClientIp({
      rawRequest: { headers: { "x-forwarded-for": "203.0.113.9, 10.0.0.1" } },
    }),
    "203.0.113.9",
  );
  assert.equal(
    t.quizClientIp({
      rawRequest: {
        ip: "198.51.100.4",
        headers: { "x-forwarded-for": "unknown" },
      },
    }),
    "198.51.100.4",
  );
});

test("challenge inbox keeps completed 24h and hides expired", () => {
  const now = 1_700_000_000_000;
  assert.equal(t.CHALLENGE_INBOX_COMPLETED_MS, 24 * 60 * 60_000);
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
      updatedAt: { toMillis: () => now - t.CHALLENGE_INBOX_COMPLETED_MS + 1 },
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

test("last-week promo always advertises 14/7/3 by rank", () => {
  const skipped = t.lastWeekWinnersFromLedgerData({
    status: "settled",
    placements: [
      { rank: 1, name: "Ali", ownerHash: "aa", grantDays: 0, premiumStatus: "skipped_already_premium" },
      { rank: 2, name: "Ece", ownerHash: "bb", grantDays: 7, premiumStatus: "granted" },
      { rank: 3, name: "Can", ownerHash: "cc", grantDays: 0, premiumStatus: "skipped_no_auth" },
    ],
  });
  assert.equal(skipped.length, 3);
  assert.equal(skipped[0].grantDays, 14);
  assert.equal(skipped[1].grantDays, 7);
  assert.equal(skipped[2].grantDays, 3);
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

test("createMatchInTransaction applies afterReads only after reads", async () => {
  const events = [];
  const fakeDb = {
    collection(col) {
      return {
        doc(id) {
          return { path: `${col}/${id}`, id };
        },
      };
    },
  };
  const tx = {
    async get(ref) {
      events.push(`get:${ref.path}`);
      return { exists: true, data: () => ({ seenQuestionIds: [] }) };
    },
    create(ref) {
      events.push(`create:${ref.path}`);
    },
    set(ref) {
      events.push(`set:${ref.path}`);
    },
  };
  const firstOwner = "a".repeat(64);
  const secondOwner = "b".repeat(64);
  const firstCharge = "c".repeat(32);
  const secondCharge = "d".repeat(32);
  const firstQueue = {
    ownerHash: firstOwner,
    name: "Ali",
    hilals: 10,
    level: 2,
    status: "waiting",
    heartSource: "ad",
    heartChargeId: firstCharge,
  };
  const secondQueue = {
    ownerHash: secondOwner,
    name: "Ece",
    hilals: 8,
    level: 2,
    status: "waiting",
    heartSource: "ad",
    heartChargeId: secondCharge,
  };
  const chargeRecordsPreRead = new Map([
    [firstCharge, {
      ownerHash: firstOwner,
      heartSource: "ad",
      status: "charged",
    }],
    [secondCharge, {
      ownerHash: secondOwner,
      heartSource: "ad",
      status: "charged",
    }],
  ]);
  const created = await t.createMatchInTransaction({
    tx,
    db: fakeDb,
    firstQueue,
    secondQueue,
    chargeRecordsPreRead,
    afterReads: () => {
      events.push("afterReads");
    },
  });
  assert.equal(typeof created.matchId, "string");
  assert.equal(created.matchId.length, 32);
  const afterReadsAt = events.indexOf("afterReads");
  assert.ok(afterReadsAt >= 0, "afterReads must run");
  const firstWrite = events.findIndex((item) =>
    item.startsWith("create:") || item.startsWith("set:")
  );
  assert.ok(firstWrite > afterReadsAt, "writes must start after afterReads");
  assert.ok(
    events.slice(0, afterReadsAt).every((item) => item.startsWith("get:")),
    "only reads may happen before afterReads",
  );
  assert.deepEqual(
    events.filter((item) => item.startsWith("get:")).sort(),
    [`get:quiz_players/${firstOwner}`, `get:quiz_players/${secondOwner}`].sort(),
  );
});

test("engagement gift copy uses heart not life in en/ar", () => {
  assert.match(t.quizEngagementCopy("en", "never_played").body, /heart/i);
  assert.equal(/life/i.test(t.quizEngagementCopy("en", "never_played").body), false);
  assert.match(t.quizEngagementCopy("ar", "never_played").body, /قلب/);
  assert.equal(/حياة/.test(t.quizEngagementCopy("ar", "never_played").body), false);
});
