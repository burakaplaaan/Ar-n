/**
 * Builds functions/data/islamic_quiz_questions_ar.json
 * Formulaic mushaf/ayah items use the pattern translator; the rest use
 * hand-reviewed overrides in functions/scripts/ar_overrides/.
 *
 * Run: node functions/scripts/build_quiz_questions_ar.js
 */
"use strict";

const fs = require("fs");
const path = require("path");
const questions = require("../data/islamic_quiz_questions.json");
const {
  CATEGORY_AR,
  translateItem,
  hasArabic,
  hasTurkishLetters,
} = require("./quiz_ar_translate");

if (!Array.isArray(questions) || questions.length !== 1000) {
  throw new Error("Expected 1000 Turkish questions.");
}

function isFormulaic(question) {
  const s = String(question || "");
  return /Mushaf sıralamasında \d+\. sure hangisidir/.test(s)
    || /suresi Mushaf sıralamasında kaçıncı suredir/.test(s)
    || /suresi Diyanet Mushaf'ında kaç ayettir/.test(s)
    || /suresi mushafta kaçıncı sıradadır/.test(s)
    || /Mushaf sıralamasında (ilk|son) sure hangisidir/.test(s);
}

function loadOverrides() {
  const dir = path.join(__dirname, "ar_overrides");
  const merged = Object.create(null);
  for (const name of fs.readdirSync(dir).sort()) {
    if (!name.endsWith(".json")) continue;
    const chunk = JSON.parse(fs.readFileSync(path.join(dir, name), "utf8"));
    Object.assign(merged, chunk);
  }
  return merged;
}

function assertArabicEntry(id, ar) {
  const errors = [];
  if (!ar || typeof ar !== "object") {
    return [`${id} missing Arabic entry`];
  }
  if (typeof ar.question !== "string" || ar.question.trim().length < 8) {
    errors.push(`${id} bad question`);
  }
  if (!hasArabic(ar.question)) errors.push(`${id} question has no Arabic`);
  if (hasTurkishLetters(ar.question)) {
    errors.push(`${id} question still Turkish: ${ar.question}`);
  }
  if (!Array.isArray(ar.options) || ar.options.length !== 4) {
    errors.push(`${id} options must be 4`);
  } else {
    const unique = new Set(ar.options.map((v) => String(v).trim()));
    if (unique.size !== 4) {
      errors.push(`${id} duplicate options: ${ar.options.join(" | ")}`);
    }
    ar.options.forEach((opt, i) => {
      const raw = String(opt || "").trim();
      if (!raw) errors.push(`${id} empty option ${i}`);
      if (
        !/^\d+([.,]\d+)?$/.test(raw) &&
        !/^\d+\s*هـ$/.test(raw) &&
        !hasArabic(raw) &&
        /[A-Za-zğüşıöçĞÜŞİÖÇ]/.test(raw)
      ) {
        errors.push(`${id} option ${i} not Arabic: ${raw}`);
      }
    });
  }
  if (typeof ar.explanation !== "string" || ar.explanation.trim().length < 4) {
    errors.push(`${id} bad explanation`);
  }
  if (hasTurkishLetters(ar.explanation || "")) {
    errors.push(`${id} explanation still Turkish: ${ar.explanation}`);
  }
  if (typeof ar.category !== "string" || !hasArabic(ar.category)) {
    errors.push(`${id} bad category`);
  }
  return errors;
}

const overrides = loadOverrides();
const overlay = {};
const errors = [];

for (const item of questions) {
  let ar;
  if (overrides[item.id]) {
    const ovr = overrides[item.id];
    ar = {
      category: CATEGORY_AR[item.category] || item.category,
      question: ovr.question,
      options: ovr.options,
      explanation: ovr.explanation,
      source: ovr.source || "",
    };
  } else if (isFormulaic(item.question)) {
    ar = translateItem(item);
  } else {
    errors.push(`${item.id} has neither override nor formulaic pattern`);
    continue;
  }
  overlay[item.id] = ar;
  errors.push(...assertArabicEntry(item.id, ar));
}

if (errors.length) {
  console.error(`Arabic bank build failed (${errors.length} issues):`);
  console.error(errors.slice(0, 100).join("\n"));
  if (errors.length > 100) console.error(`... +${errors.length - 100} more`);
  process.exit(1);
}

const outPath = path.join(__dirname, "..", "data", "islamic_quiz_questions_ar.json");
fs.writeFileSync(outPath, `${JSON.stringify(overlay, null, 2)}\n`, "utf8");
console.log(`Wrote ${Object.keys(overlay).length} Arabic questions → ${outPath}`);
