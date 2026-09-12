/**
 * Appends iq_1001–iq_1200 and rebalances A/B/C/D across the full bank.
 * Run: node functions/scripts/apply_quiz_batch_1001_1200.js
 */
"use strict";

const fs = require("fs");
const path = require("path");

const CATEGORY_AR = Object.freeze({
  "Kur'an bilgisi": "معرفة القرآن",
  Siyer: "السيرة النبوية",
  "Peygamberler tarihi": "تاريخ الأنبياء",
  "İslam tarihi": "التاريخ الإسلامي",
  "İbadet ve temel dini bilgiler": "العبادات والعلوم الشرعية",
  "Dini kavramlar": "المفاهيم الدينية",
});

const ROOT = path.join(__dirname, "..");
const TR_PATH = path.join(ROOT, "data", "islamic_quiz_questions.json");
const AR_PATH = path.join(ROOT, "data", "islamic_quiz_questions_ar.json");
const OVERRIDES_DIR = path.join(__dirname, "ar_overrides");
const BATCH_A = path.join(__dirname, "data", "quiz_batch_1001_1100.json");
const BATCH_B = path.join(__dirname, "data", "quiz_batch_1101_1200.json");
const TARGET_COUNT = 1200;
const SEED = 0xA11A1200;

function mulberry32(seed) {
  let a = seed >>> 0;
  return function rnd() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle(list, rnd) {
  const next = list.slice();
  for (let i = next.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rnd() * (i + 1));
    const tmp = next[i];
    next[i] = next[j];
    next[j] = tmp;
  }
  return next;
}

function moveIndex(arr, from, to) {
  if (from === to) return arr.slice();
  const next = arr.slice();
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item);
  return next;
}

function idNumber(id) {
  return Number(String(id).replace(/^iq_/, ""), 10);
}

function padId(n) {
  return `iq_${String(n).padStart(3, "0")}`;
}

function normalizeTr(text) {
  return String(text || "")
    .toLocaleLowerCase("tr-TR")
    .replace(/\s+/g, " ")
    .trim();
}

const existingTr = JSON.parse(fs.readFileSync(TR_PATH, "utf8"));
const existingAr = JSON.parse(fs.readFileSync(AR_PATH, "utf8"));
const batch = [
  ...JSON.parse(fs.readFileSync(BATCH_A, "utf8")),
  ...JSON.parse(fs.readFileSync(BATCH_B, "utf8")),
];

if (batch.length !== 200) {
  throw new Error(`Expected 200 new questions, got ${batch.length}`);
}

const keptTr = existingTr.filter((item) => idNumber(item.id) <= 1000);
if (keptTr.length !== 1000) {
  throw new Error(`Expected 1000 kept questions, got ${keptTr.length}`);
}

const seen = new Set(keptTr.map((item) => normalizeTr(item.question)));
const newTr = [];
const newAr = {};

batch.forEach((raw, index) => {
  const id = padId(1001 + index);
  const normalized = normalizeTr(raw.question);
  if (seen.has(normalized)) {
    throw new Error(`Duplicate question text at ${id}: ${raw.question}`);
  }
  seen.add(normalized);
  if (!raw.ar || !Array.isArray(raw.ar.options) || raw.ar.options.length !== 4) {
    throw new Error(`Missing Arabic options for batch item ${index}`);
  }
  newTr.push({
    id,
    category: raw.category,
    difficulty: raw.difficulty,
    question: raw.question,
    options: raw.options.slice(),
    correctIndex: 0,
    explanation: raw.explanation,
    source: raw.source,
  });
  newAr[id] = {
    category: CATEGORY_AR[raw.category] || raw.category,
    question: raw.ar.question,
    options: raw.ar.options.slice(),
    explanation: raw.ar.explanation,
    source: raw.ar.source,
  };
});

const questions = [...keptTr, ...newTr];
const questionsAr = { ...existingAr };
for (const item of keptTr) {
  if (!questionsAr[item.id]) {
    throw new Error(`Missing Arabic entry for ${item.id}`);
  }
}
Object.assign(questionsAr, newAr);

if (questions.length !== TARGET_COUNT) {
  throw new Error(`Expected ${TARGET_COUNT} questions, got ${questions.length}`);
}

const rnd = mulberry32(SEED);
const targets = shuffle(
  Array.from({ length: TARGET_COUNT }, (_, i) => i % 4),
  rnd,
);

for (let i = 0; i < questions.length; i += 1) {
  const item = questions[i];
  const ar = questionsAr[item.id];
  if (!ar || !Array.isArray(ar.options) || ar.options.length !== 4) {
    throw new Error(`Cannot rotate Arabic options for ${item.id}`);
  }
  const from = item.correctIndex;
  const to = targets[i];
  item.options = moveIndex(item.options, from, to);
  ar.options = moveIndex(ar.options, from, to);
  item.correctIndex = to;
}

const counts = [0, 0, 0, 0];
for (const item of questions) counts[item.correctIndex] += 1;
if (counts.some((n) => n !== 300)) {
  throw new Error(`Unbalanced correctIndex: ${counts.join(",")}`);
}

const arOut = {};
for (const item of questions) {
  arOut[item.id] = questionsAr[item.id];
}

fs.writeFileSync(TR_PATH, `${JSON.stringify(questions, null, 2)}\n`, "utf8");
fs.writeFileSync(AR_PATH, `${JSON.stringify(arOut, null, 2)}\n`, "utf8");

const overrideNames = fs.readdirSync(OVERRIDES_DIR).filter((name) => name.endsWith(".json"));
for (const name of overrideNames) {
  const filePath = path.join(OVERRIDES_DIR, name);
  const chunk = JSON.parse(fs.readFileSync(filePath, "utf8"));
  let changed = false;
  for (const [id, entry] of Object.entries(chunk)) {
    const ar = arOut[id];
    if (!ar || !entry || !Array.isArray(entry.options)) continue;
    entry.options = ar.options.slice();
    changed = true;
  }
  if (changed) {
    fs.writeFileSync(filePath, `${JSON.stringify(chunk, null, 2)}\n`, "utf8");
  }
}

const newOverride = {};
for (const item of newTr) {
  const ar = arOut[item.id];
  newOverride[item.id] = {
    question: ar.question,
    options: ar.options.slice(),
    explanation: ar.explanation,
    source: ar.source,
  };
}
fs.writeFileSync(
  path.join(OVERRIDES_DIR, "1000.json"),
  `${JSON.stringify(newOverride, null, 2)}\n`,
  "utf8",
);

console.log(`Wrote ${questions.length} TR + AR questions.`);
console.log(`correctIndex counts: A=${counts[0]} B=${counts[1]} C=${counts[2]} D=${counts[3]}`);
