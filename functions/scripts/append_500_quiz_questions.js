/**
 * Appends 500 Diyanet/Hafs-aligned questions to islamic_quiz_questions.json.
 * Run: node functions/scripts/append_500_quiz_questions.js
 */
"use strict";

const fs = require("fs");
const path = require("path");

/** Hafs / Diyanet Mushaf: sıra, Türkçe ad, ayet sayısı. */
const SURAHS = [
  [1, "Fatiha", 7], [2, "Bakara", 286], [3, "Âl-i İmrân", 200], [4, "Nisâ", 176],
  [5, "Mâide", 120], [6, "En'âm", 165], [7, "A'râf", 206], [8, "Enfâl", 75],
  [9, "Tevbe", 129], [10, "Yûnus", 109], [11, "Hûd", 123], [12, "Yûsuf", 111],
  [13, "Ra'd", 43], [14, "İbrâhîm", 52], [15, "Hicr", 99], [16, "Nahl", 128],
  [17, "İsrâ", 111], [18, "Kehf", 110], [19, "Meryem", 98], [20, "Tâhâ", 135],
  [21, "Enbiyâ", 112], [22, "Hac", 78], [23, "Mü'minûn", 118], [24, "Nûr", 64],
  [25, "Furkân", 77], [26, "Şuarâ", 227], [27, "Neml", 93], [28, "Kasas", 88],
  [29, "Ankebût", 69], [30, "Rûm", 60], [31, "Lokmân", 34], [32, "Secde", 30],
  [33, "Ahzâb", 73], [34, "Sebe'", 54], [35, "Fâtır", 45], [36, "Yâsîn", 83],
  [37, "Sâffât", 182], [38, "Sâd", 88], [39, "Zümer", 75], [40, "Mü'min", 85],
  [41, "Fussilet", 54], [42, "Şûrâ", 53], [43, "Zuhruf", 89], [44, "Duhân", 59],
  [45, "Câsiye", 37], [46, "Ahkâf", 35], [47, "Muhammed", 38], [48, "Fetih", 29],
  [49, "Hucurât", 18], [50, "Kâf", 45], [51, "Zâriyât", 60], [52, "Tûr", 49],
  [53, "Necm", 62], [54, "Kamer", 55], [55, "Rahmân", 78], [56, "Vâkıa", 96],
  [57, "Hadîd", 29], [58, "Mücâdele", 22], [59, "Haşr", 24], [60, "Mümtehine", 13],
  [61, "Saff", 14], [62, "Cuma", 11], [63, "Münâfikûn", 11], [64, "Tegâbün", 18],
  [65, "Talâk", 12], [66, "Tahrîm", 12], [67, "Mülk", 30], [68, "Kalem", 52],
  [69, "Hâkka", 52], [70, "Meâric", 44], [71, "Nûh", 28], [72, "Cin", 28],
  [73, "Müzzemmil", 20], [74, "Müddessir", 56], [75, "Kıyâme", 40], [76, "İnsan", 31],
  [77, "Mürselât", 50], [78, "Nebe", 40], [79, "Nâziât", 46], [80, "Abese", 42],
  [81, "Tekvîr", 29], [82, "İnfitâr", 19], [83, "Mutaffifîn", 36], [84, "İnşikâk", 25],
  [85, "Bürûc", 22], [86, "Târık", 17], [87, "A'lâ", 19], [88, "Gâşiye", 26],
  [89, "Fecr", 30], [90, "Beled", 20], [91, "Şems", 15], [92, "Leyl", 21],
  [93, "Duhâ", 11], [94, "İnşirâh", 8], [95, "Tîn", 8], [96, "Alak", 19],
  [97, "Kadr", 5], [98, "Beyyine", 8], [99, "Zilzâl", 8], [100, "Âdiyât", 11],
  [101, "Kâria", 11], [102, "Tekâsür", 8], [103, "Asr", 3], [104, "Hümeze", 9],
  [105, "Fîl", 5], [106, "Kureyş", 4], [107, "Mâûn", 7], [108, "Kevser", 3],
  [109, "Kâfirûn", 6], [110, "Nasr", 3], [111, "Tebbet", 5], [112, "İhlâs", 4],
  [113, "Felak", 5], [114, "Nâs", 6],
];

const PROPHETS = [
  "Âdem", "İdris", "Nûh", "Hûd", "Sâlih", "Lût", "İbrâhîm", "İsmâil",
  "İshak", "Ya'kûb", "Yûsuf", "Eyyûb", "Şuayb", "Mûsâ", "Hârûn", "Dâvûd",
  "Süleyman", "İlyas", "Elyesa", "Yûnus", "Zülkifl", "Zekeriyâ", "Yahyâ",
  "Îsâ", "Muhammed",
];

const FAKE_NAMES = [
  "Ardaşir", "Cengiz", "Firavun", "Nemrud", "Karun", "Hâmân",
  "Ebrehe", "Kisra", "Sezar", "Herakleios", "Buhtunnasr", "Belkıs veziri",
];

const MONTHS = [
  "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", "Cemaziyelevvel",
  "Cemaziyelahir", "Recep", "Şaban", "Ramazan", "Şevval", "Zilkade", "Zilhicce",
];

const SOURCE_QURAN = "Diyanet Mushaf (Hafs)";
const SOURCE_SIYER = "Diyanet Siyer-i Nebi / İslam Tarihi";
const SOURCE_IBADAT = "Diyanet Temel Dini Bilgiler";
const SOURCE_TDV = "TDV İslam Ansiklopedisi";

function shuffle(list, seed) {
  const out = [...list];
  let x = seed >>> 0;
  for (let i = out.length - 1; i > 0; i -= 1) {
    x = (Math.imul(1664525, x) + 1013904223) >>> 0;
    const j = x % (i + 1);
    const tmp = out[i];
    out[i] = out[j];
    out[j] = tmp;
  }
  return out;
}

function uniqueOptions(correct, wrongs) {
  const opts = [String(correct), ...wrongs.map(String)];
  if (new Set(opts.map((o) => o.trim())).size !== 4) {
    throw new Error(`Non-unique options around ${correct}: ${opts.join("|")}`);
  }
  const mixed = shuffle(opts, String(correct).length * 17 + opts.join("").length);
  return {
    options: mixed,
    correctIndex: mixed.indexOf(String(correct)),
  };
}

function nearbyInts(correct, extras = []) {
  const set = new Set([correct, ...extras]);
  const candidates = [
    correct + 1, correct - 1, correct + 2, correct - 2,
    correct + 5, correct - 5, correct + 10, correct - 10,
    correct + 3, correct + 7, Math.max(1, correct * 2),
  ].filter((n) => Number.isInteger(n) && n > 0 && !set.has(n));
  const wrongs = [];
  for (const n of candidates) {
    if (wrongs.length >= 3) break;
    if (!set.has(n)) {
      wrongs.push(n);
      set.add(n);
    }
  }
  if (wrongs.length < 3) {
    throw new Error(`Could not build distractors for ${correct}`);
  }
  return uniqueOptions(String(correct), wrongs.slice(0, 3).map(String));
}

function q(category, difficulty, question, correct, wrongs, explanation, source) {
  const packed = uniqueOptions(correct, wrongs);
  return {
    category,
    difficulty,
    question,
    options: packed.options,
    correctIndex: packed.correctIndex,
    explanation,
    source,
  };
}

function buildSurahQuestions() {
  const out = [];
  for (const [order, name, ayahs] of SURAHS) {
    const ayahPack = nearbyInts(ayahs);
    out.push({
      category: "Kur'an bilgisi",
      difficulty: 3,
      question: `${name} suresi Diyanet Mushaf'ında kaç ayettir?`,
      options: ayahPack.options,
      correctIndex: ayahPack.correctIndex,
      explanation: `${name} suresi Hafs rivayetine göre ${ayahs} ayettir.`,
      source: SOURCE_QURAN,
    });
    const orderPack = nearbyInts(order);
    out.push({
      category: "Kur'an bilgisi",
      difficulty: 2,
      question: `${name} suresi Mushaf sıralamasında kaçıncı suredir?`,
      options: orderPack.options,
      correctIndex: orderPack.correctIndex,
      explanation: `${name} suresi Mushaf'ta ${order}. sıradadır.`,
      source: SOURCE_QURAN,
    });
    const others = SURAHS.filter((row) => row[0] !== order)
      .map((row) => row[1]);
    const wrongNames = shuffle(others, order * 31).slice(0, 3);
    const namePack = uniqueOptions(name, wrongNames);
    out.push({
      category: "Kur'an bilgisi",
      difficulty: 3,
      question: `Mushaf sıralamasında ${order}. sure hangisidir?`,
      options: namePack.options,
      correctIndex: namePack.correctIndex,
      explanation: `${order}. sure ${name}'dir.`,
      source: SOURCE_QURAN,
    });
  }
  return out;
}

function buildProphetQuestions() {
  const out = [];
  for (let i = 0; i < PROPHETS.length; i += 1) {
    const name = PROPHETS[i];
    const wrongs = shuffle(FAKE_NAMES, i * 13).slice(0, 3);
    out.push(q(
      "Peygamberler tarihi",
      1,
      `Hangisi Kur'an-ı Kerim'de adı geçen peygamberlerdendir?`,
      name,
      wrongs,
      `${name}, Kur'an'da adı geçen peygamberlerdendir.`,
      SOURCE_QURAN,
    ));
  }
  // Deduped later — same stem 25 times is bad. Keep only 8 varied stems.
  return out.slice(0, 0);
}

const HAND = [
  q("İbadet ve temel dini bilgiler", 1, "İslam'ın şartı kaçtır?", "5", ["4", "6", "7"], "İslam'ın beş şartı vardır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "İmanın şartı kaçtır?", "6", ["5", "4", "7"], "İmanın altı şartı vardır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Günde farz namaz kaç vakittir?", "5", ["3", "4", "6"], "Beş vakit namaz farzdır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Oruç hangi ayda farzdır?", "Ramazan", ["Şaban", "Recep", "Muharrem"], "Ramazan orucu farzdır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Haccın yapıldığı belde hangisidir?", "Mekke", ["Medine", "Kudüs", "Taif"], "Hac Mekke'de eda edilir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Sabah namazının farzı kaç rekâttır?", "2", ["4", "3", "1"], "Sabah farzı 2 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Öğle namazının farzı kaç rekâttır?", "4", ["2", "3", "6"], "Öğle farzı 4 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "İkindi namazının farzı kaç rekâttır?", "4", ["2", "3", "6"], "İkindi farzı 4 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Akşam namazının farzı kaç rekâttır?", "3", ["2", "4", "1"], "Akşam farzı 3 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Yatsı namazının farzı kaç rekâttır?", "4", ["2", "3", "6"], "Yatsı farzı 4 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Cuma namazının farzı kaç rekâttır?", "2", ["4", "3", "1"], "Cuma farzı 2 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Bayram namazı kaç rekâttır?", "2", ["4", "3", "1"], "Bayram namazı 2 rekâttır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Namazın yönü (kıble) neresidir?", "Kâbe", ["Mescid-i Nebevî", "Mescid-i Aksâ", "Uhud"], "Kıble Kâbe'dir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Hicretten önce ilk kıble neresiydi?", "Mescid-i Aksâ", ["Kâbe", "Uhud", "Bedir"], "İlk kıble Mescid-i Aksâ idi.", SOURCE_SIYER),
  q("İbadet ve temel dini bilgiler", 1, "Abdestin farzlarından biri hangisidir?", "Yüzü yıkamak", ["Misvak kullanmak", "Koku sürünmek", "Tıraş olmak"], "Yüzü yıkamak abdestin farzlarındandır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Hanefi mezhebine göre abdestin farzı kaçtır?", "4", ["3", "6", "7"], "Hanefi'de abdestin 4 farzı vardır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Hanefi mezhebine göre vitir namazı hükmü nedir?", "Vacip", ["Sünnet-i müekkede", "Nafile", "Farz-ı ayn"], "Hanefi'de vitir vaciptir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Zekât İslam'ın şartlarından midir?", "Evet", ["Hayır", "Yalnızca sünnettir", "Yalnızca nafiledir"], "Zekât İslam'ın beş şartındandır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Fitre (fıtır sadakası) ne zaman verilir?", "Ramazan bayramından önce", ["Kurban bayramında", "Muharrem'de", "Recep'te"], "Fitre Ramazan Bayramı namazından önce verilir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Kelime-i tevhid neyi ifade eder?", "Allah'ın birliği", ["Namaz vakitlerini", "Zekât nisabını", "Hac menâsikini"], "Tevhid, Allah'ın birliğidir.", SOURCE_IBADAT),
  q("Kur'an bilgisi", 1, "Kur'an-ı Kerim hangi dilde inmiştir?", "Arapça", ["Farsça", "Türkçe", "İbranice"], "Kur'an Arapça inmiştir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "İlk vahyin geldiği dağ hangisidir?", "Nur Dağı", ["Uhud", "Sevr", "Arafat"], "İlk vahiy Nur Dağı'ndaki Hira'da geldi.", SOURCE_SIYER),
  q("Kur'an bilgisi", 1, "Hira mağarası hangi dağdadır?", "Nur Dağı", ["Sevr", "Uhud", "Merve"], "Hira, Nur Dağı'ndadır.", SOURCE_SIYER),
  q("Kur'an bilgisi", 2, "İlk inen ayetler hangi surede yer alır?", "Alak", ["Fatiha", "Müddessir", "Kalem"], "İlk vahiy Alak suresinin ilk ayetleridir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "Fatiha suresi başka hangi adla anılır?", "Ümmü'l-Kitab", ["Seyyidü'l-Kur'an", "Kalbu'l-Kur'an", "Arûsü'l-Kur'an"], "Fatiha, Ümmü'l-Kitab olarak da anılır.", SOURCE_TDV),
  q("Kur'an bilgisi", 2, "Yâsîn suresi geleneksel olarak nasıl anılır?", "Kalbu'l-Kur'an", ["Ümmü'l-Kitab", "Seb'u'l-mesânî", "Levh-i mahfuz"], "Yâsîn, Kalbu'l-Kur'an diye anılır.", SOURCE_TDV),
  q("Kur'an bilgisi", 1, "Kevser suresi kaç ayettir?", "3", ["4", "5", "7"], "Kevser 3 ayettir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "Asr suresi kaç ayettir?", "3", ["4", "5", "8"], "Asr 3 ayettir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "İhlâs suresi kaç ayettir?", "4", ["3", "5", "6"], "İhlâs 4 ayettir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 2, "Tevbe suresinin başında ne yoktur?", "Besmele", ["Elif-Lâm-Mîm", "Secde ayeti", "Nesih kaydı"], "Tevbe suresinin başında besmele yoktur.", SOURCE_QURAN),
  q("Kur'an bilgisi", 2, "Kur'an'da secde ayeti bulunan surelerden biri hangisidir?", "Secde", ["Kevser", "Asr", "Kureyş"], "Secde suresinde tilavet secdesi vardır.", SOURCE_QURAN),
  q("Kur'an bilgisi", 3, "Tilavet secdesi gereken ayetlerden biri hangi surededir?", "Alak", ["Kevser", "Nasr", "Kureyş"], "Alak suresinin sonunda tilavet secdesi vardır.", SOURCE_IBADAT),
  q("Siyer", 1, "Peygamber Efendimiz hangi şehirde doğmuştur?", "Mekke", ["Medine", "Taif", "Kudüs"], "Hz. Muhammed Mekke'de doğmuştur.", SOURCE_SIYER),
  q("Siyer", 1, "Peygamber Efendimiz hangi şehirde vefat etmiştir?", "Medine", ["Mekke", "Taif", "Kudüs"], "Vefatı Medine'dedir.", SOURCE_SIYER),
  q("Siyer", 1, "Hicret hangi şehre yapılmıştır?", "Medine", ["Taif", "Yemen", "Şam"], "Hicret Medine'yedir.", SOURCE_SIYER),
  q("Siyer", 2, "Hicrî takvimin başlangıcı hangi olaydır?", "Hicret", ["Bedir", "Fetih", "Veda Haccı"], "Hicrî takvim Hicret'le başlar.", SOURCE_SIYER),
  q("Siyer", 2, "Hicret miladi olarak hangi yıldır?", "622", ["610", "630", "632"], "Hicret 622 miladîdir.", SOURCE_SIYER),
  q("Siyer", 2, "İlk vahiy miladi olarak hangi yılda gelmiştir?", "610", ["622", "632", "571"], "İlk vahiy 610 civarındadır.", SOURCE_SIYER),
  q("Siyer", 1, "Peygamber Efendimiz'in babasının adı nedir?", "Abdullah", ["Abdülmuttalib", "Ebû Talib", "Hamza"], "Babası Abdullah'tır.", SOURCE_SIYER),
  q("Siyer", 1, "Peygamber Efendimiz'in annesinin adı nedir?", "Âmine", ["Hatice", "Fatıma", "Hâlime"], "Annesi Âmine'dir.", SOURCE_SIYER),
  q("Siyer", 1, "Peygamber Efendimiz'in sütannesinin adı nedir?", "Hâlime", ["Âmine", "Sümeyye", "Ümmü Seleme"], "Sütannesi Hâlime'dir.", SOURCE_SIYER),
  q("Siyer", 1, "İlk Müslüman kadın kimdir?", "Hatice", ["Fatıma", "Âişe", "Zeyneb"], "İlk iman eden kadın Hz. Hatice'dir.", SOURCE_SIYER),
  q("Siyer", 2, "İlk Müslüman çocuk kimdir?", "Ali", ["Hasan", "Hüseyin", "Zeyd"], "İlk iman eden çocuk Hz. Ali'dir.", SOURCE_SIYER),
  q("Siyer", 2, "İlk Müslüman köle kimdir?", "Zeyd b. Hârise", ["Bilal", "Selman", "Suheyb"], "Zeyd b. Hârise ilk Müslüman kölelerdendir.", SOURCE_SIYER),
  q("Siyer", 1, "İlk müezzin kimdir?", "Bilal-i Habeşî", ["Ebû Bekir", "Ömer", "Osman"], "İlk müezzin Bilal-i Habeşî'dir.", SOURCE_SIYER),
  q("Siyer", 2, "Habeşistan'a hicreti öneren peygamber hangisidir?", "Hz. Muhammed", ["Hz. Mûsâ", "Hz. Îsâ", "Hz. Nûh"], "İlk Habeşistan hicreti Hz. Muhammed zamanındadır.", SOURCE_SIYER),
  q("Siyer", 1, "Bedir Savaşı kiminle yapılmıştır?", "Mekkeli müşrikler", ["Rumlar", "Sâsânîler", "Habeşliler"], "Bedir, Mekkeli müşriklerle yapılmıştır.", SOURCE_SIYER),
  q("Siyer", 2, "Bedir Savaşı hicrî kaçıncı yıldadır?", "2", ["1", "5", "8"], "Bedir hicrî 2. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Uhud Savaşı hicrî kaçıncı yıldadır?", "3", ["2", "5", "8"], "Uhud hicrî 3. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Hendek (Ahzâb) Savaşı hicrî kaçıncı yıldadır?", "5", ["2", "3", "8"], "Hendek hicrî 5. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Mekke'nin fethi hicrî kaçıncı yıldadır?", "8", ["6", "7", "10"], "Fetih hicrî 8. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Veda Haccı hicrî kaçıncı yıldadır?", "10", ["8", "9", "11"], "Veda Haccı hicrî 10. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Hudeybiye Antlaşması hicrî kaçıncı yıldadır?", "6", ["5", "8", "10"], "Hudeybiye hicrî 6. yıldadır.", SOURCE_SIYER),
  q("Siyer", 1, "Uhud'da şehit düşen amca kimdir?", "Hamza", ["Abbas", "Ebû Talib", "Zübeyr"], "Hz. Hamza Uhud'da şehit olmuştur.", SOURCE_SIYER),
  q("Siyer", 2, "Peygamber Efendimiz kaç yaşında vefat etmiştir?", "63", ["40", "53", "73"], "63 yaşında vefat etmiştir.", SOURCE_SIYER),
  q("Siyer", 2, "Peygamber Efendimiz kaç yaşında peygamber olmuştur?", "40", ["25", "33", "63"], "40 yaşında vahiy gelmiştir.", SOURCE_SIYER),
  q("Siyer", 2, "Mekke dönemi peygamberlik kaç yıl sürmüştür?", "13", ["10", "23", "7"], "Mekke dönemi 13 yıldır.", SOURCE_SIYER),
  q("Siyer", 2, "Medine dönemi peygamberlik kaç yıl sürmüştür?", "10", ["13", "23", "7"], "Medine dönemi 10 yıldır.", SOURCE_SIYER),
  q("Siyer", 1, "İlk halife kimdir?", "Ebû Bekir", ["Ömer", "Osman", "Ali"], "İlk halife Hz. Ebû Bekir'dir.", SOURCE_SIYER),
  q("Siyer", 1, "İkinci halife kimdir?", "Ömer", ["Osman", "Ali", "Ebû Bekir"], "İkinci halife Hz. Ömer'dir.", SOURCE_SIYER),
  q("Siyer", 1, "Üçüncü halife kimdir?", "Osman", ["Ali", "Ömer", "Hasan"], "Üçüncü halife Hz. Osman'dır.", SOURCE_SIYER),
  q("Siyer", 1, "Dördüncü halife kimdir?", "Ali", ["Hasan", "Hüseyin", "Muaviye"], "Dördüncü halife Hz. Ali'dir.", SOURCE_SIYER),
  q("Siyer", 2, "Kur'an'ın mushaf hâlinde cem'ini emreden halife kimdir?", "Ebû Bekir", ["Ömer", "Osman", "Ali"], "Cem'i Hz. Ebû Bekir döneminde başlamıştır.", SOURCE_TDV),
  q("Siyer", 2, "Mushaf'ın çoğaltılıp vilayetlere gönderilmesini sağlayan halife kimdir?", "Osman", ["Ebû Bekir", "Ömer", "Ali"], "İstinsah Hz. Osman dönemindedir.", SOURCE_TDV),
  q("İslam tarihi", 2, "Emevî Devleti'nin ilk halifesi kimdir?", "Muaviye", ["Yezid", "Mervan", "Abdülmelik"], "Muaviye b. Ebû Süfyan'dır.", SOURCE_TDV),
  q("İslam tarihi", 2, "Abbasî Devleti'nin ilk halifesi kimdir?", "Seffah", ["Mansur", "Me'mun", "Harun Reşid"], "Ebü'l-Abbas es-Seffah'tır.", SOURCE_TDV),
  q("İslam tarihi", 3, "Endülüs Emevî Devleti'nin kurucusu kimdir?", "I. Abdurrahman", ["Tarık b. Ziyad", "Musa b. Nusayr", "II. Hakem"], "I. Abdurrahman (Dâhil) kurmuştur.", SOURCE_TDV),
  q("İslam tarihi", 2, "İstanbul'u fetheden Osmanlı padişahı kimdir?", "II. Mehmed", ["I. Murad", "Yavuz Selim", "Kanuni"], "İstanbul'u Fatih Sultan Mehmed fethetmiştir.", SOURCE_TDV),
  q("İslam tarihi", 2, "İstanbul'un fethi miladi hangi yıldır?", "1453", ["1071", "1299", "1517"], "Feth 1453'tedir.", SOURCE_TDV),
  q("İslam tarihi", 2, "Malazgirt Zaferi miladi hangi yıldır?", "1071", ["1453", "1299", "1517"], "Malazgirt 1071'dedir.", SOURCE_TDV),
  q("Peygamberler tarihi", 1, "İlk insan ve ilk peygamber kimdir?", "Âdem", ["Nûh", "İbrâhîm", "Mûsâ"], "Hz. Âdem ilk insan ve peygamberdir.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Tufan peygamberi kimdir?", "Nûh", ["Hûd", "Sâlih", "Lût"], "Tufan Hz. Nûh ile anılır.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Kâbe'yi oğluyla birlikte yükselten peygamber kimdir?", "İbrâhîm", ["Nûh", "Mûsâ", "Dâvûd"], "Hz. İbrâhîm ve İsmâil Kâbe'yi yükseltmiştir.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Asâsıyla denizi yaran peygamber kimdir?", "Mûsâ", ["Hârûn", "Yûsuf", "Yûnus"], "Hz. Mûsâ'dır.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Balık tarafından yutulan peygamber kimdir?", "Yûnus", ["Eyyûb", "İlyas", "Şuayb"], "Hz. Yûnus'tur.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Kuyuya atılan peygamber kimdir?", "Yûsuf", ["Yûnus", "Yahyâ", "Zekeriyâ"], "Hz. Yûsuf kuyuya atılmıştır.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Sabır timsali olarak anılan peygamber kimdir?", "Eyyûb", ["Yûnus", "Hûd", "Sâlih"], "Hz. Eyyûb sabrıyla anılır.", SOURCE_QURAN),
  q("Peygamberler tarihi", 2, "Âd kavminin peygamberi kimdir?", "Hûd", ["Sâlih", "Şuayb", "Lût"], "Âd kavmine Hz. Hûd gönderilmiştir.", SOURCE_QURAN),
  q("Peygamberler tarihi", 2, "Semûd kavminin peygamberi kimdir?", "Sâlih", ["Hûd", "Şuayb", "Lût"], "Semûd kavmine Hz. Sâlih gönderilmiştir.", SOURCE_QURAN),
  q("Peygamberler tarihi", 2, "Medyen halkının peygamberi kimdir?", "Şuayb", ["Hûd", "Sâlih", "Lût"], "Medyen'e Hz. Şuayb gönderilmiştir.", SOURCE_QURAN),
  q("Peygamberler tarihi", 1, "Zebur hangi peygambere verilmiştir?", "Dâvûd", ["Mûsâ", "Îsâ", "Süleyman"], "Zebur Hz. Dâvûd'a verilmiştir.", SOURCE_IBADAT),
  q("Peygamberler tarihi", 1, "Tevrat hangi peygambere verilmiştir?", "Mûsâ", ["Dâvûd", "Îsâ", "İbrâhîm"], "Tevrat Hz. Mûsâ'ya verilmiştir.", SOURCE_IBADAT),
  q("Peygamberler tarihi", 1, "İncil hangi peygambere verilmiştir?", "Îsâ", ["Mûsâ", "Dâvûd", "Yahyâ"], "İncil Hz. Îsâ'ya verilmiştir.", SOURCE_IBADAT),
  q("Peygamberler tarihi", 2, "Süleyman peygamberin babası kimdir?", "Dâvûd", ["Yakub", "İshak", "Hârûn"], "Hz. Süleyman, Hz. Dâvûd'un oğludur.", SOURCE_QURAN),
  q("Peygamberler tarihi", 2, "Yûsuf peygamberin babası kimdir?", "Ya'kûb", ["İshak", "İbrâhîm", "İsmâil"], "Hz. Yûsuf, Hz. Ya'kûb'un oğludur.", SOURCE_QURAN),
  q("Dini kavramlar", 1, "Meleklerin görevi nedir?", "Allah'ın emirlerini yerine getirmek", ["Kendi iradeleriyle günah işlemek", "İnsanlara şefaat satmak", "Rızkı kendileri yaratmak"], "Melekler Allah'ın emrine âmâdedir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Vahiy getiren melek kimdir?", "Cebrâil", ["Mikâil", "İsrâfil", "Azrâil"], "Vahiy Cebrâil ile gelmiştir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Rızıkla ilişkilendirilen melek kimdir?", "Mikâil", ["Cebrâil", "İsrâfil", "Azrâil"], "Mikâil rızık ve yağmurla anılır.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Sûr'u üfleyecek melek kimdir?", "İsrâfil", ["Cebrâil", "Mikâil", "Azrâil"], "Sûr İsrâfil'e aittir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Ölüm meleği olarak anılan kimdir?", "Azrâil", ["Cebrâil", "Mikâil", "İsrâfil"], "Azrâil ölüm meleği olarak anılır.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Şeytanın diğer adı nedir?", "İblis", ["Hârût", "Mârût", "Kırâmen kâtibîn"], "İblis, şeytanın adıdır.", SOURCE_QURAN),
  q("Dini kavramlar", 2, "Kırâmen kâtibîn melekleri neyi yazar?", "Amelleri", ["Rızkı", "Yağmuru", "Eceli"], "Sağ ve sol melekler amelleri yazar.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Ahiret gününe iman imanın şartlarından midir?", "Evet", ["Hayır", "Yalnızca sünnettir", "Yalnızca âlimlere vaciptir"], "Ahirete iman imanın şartlarındandır.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Kadere iman imanın şartlarından midir?", "Evet", ["Hayır", "Yalnızca Mutezile'ye göredir", "Kur'an'da yoktur"], "Kadere iman imanın altı şartındandır.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Helal ne demektir?", "Dinen izin verilen", ["Kesinlikle yasak olan", "Şüpheli olan", "Mekruh olan"], "Helal, dinen caiz olandır.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Haram ne demektir?", "Dinen yasak olan", ["Tavsiye edilen", "Mübah olan", "Sünnet olan"], "Haram, dinen yasaktır.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Farż ne demektir?", "Yapılması kesin emredilen", ["Yapılması yasak olan", "Serbest bırakılan", "Sadece tavsiye edilen"], "Farz, kesin emirdir.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Sünnet ne demektir?", "Peygamberin yolu ve uygulaması", ["Kur'an'ın nesh ettiği hüküm", "Yalnızca âdet", "Haramın karşılığı"], "Sünnet, peygamberin yoludur.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Cihad kelimesinin kök anlamı nedir?", "Çaba göstermek", ["Yalnızca savaşmak", "Ticaret yapmak", "Göç etmek"], "Cihad, çaba ve gayrettir.", SOURCE_TDV),
  q("Dini kavramlar", 1, "Selamın anlamı nedir?", "Esenlik dilemek", ["Vedalaşmak", "Savaş ilan etmek", "Borç istemek"], "Selam esenliktir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Âmin ne demektir?", "Kabul eyle", ["Başla", "Bitir", "Sus"], "Âmin, 'kabul eyle' anlamındadır.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "İstiğfar ne demektir?", "Bağışlanma dilemek", ["Şükretmek", "Yemin etmek", "Adak adamak"], "İstiğfar, mağfiret dilemektir.", SOURCE_IBADAT),
  q("Dini kavramlar", 2, "Tevbe ne demektir?", "Günahı bırakıp Allah'a dönmek", ["Sadaka vermek", "Hacca gitmek", "Oruç tutmak"], "Tevbe, dönüş ve pişmanlıktır.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Şükür ne demektir?", "Nimeti görüp teşekkür etmek", ["Nimeti gizlemek", "Nimeti inkâr etmek", "Nimeti israf etmek"], "Şükür, nimeti itiraf etmektir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Sabrın zıddı hangisidir?", "Sabırsızlık / sızlanma", ["Şükür", "Tevbe", "Zikir"], "Sabır, sızlanmamaktır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Hicrî yılın ilk ayı hangisidir?", "Muharrem", ["Ramazan", "Şevval", "Zilhicce"], "Muharrem ilk aydır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Kurban Bayramı hangi aydadır?", "Zilhicce", ["Ramazan", "Şevval", "Muharrem"], "Kurban Zilhicce'dedir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Ramazan Bayramı hangi ayın başındadır?", "Şevval", ["Zilhicce", "Recep", "Şaban"], "Ramazan Bayramı Şevval'in biridir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Aşure günü hangi aydadır?", "Muharrem", ["Recep", "Şaban", "Ramazan"], "Aşure Muharrem'in 10'udur.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Kandil gecelerinden biri hangisidir?", "Mevlid", ["Bedir", "Hendek", "Fetih"], "Mevlid kandillerdendir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Regaib kandili hangi aydadır?", "Recep", ["Ramazan", "Şaban", "Muharrem"], "Regaib Recep'tedir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Berat kandili hangi aydadır?", "Şaban", ["Recep", "Ramazan", "Muharrem"], "Berat Şaban'dadır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Miraç kandili hangi aydadır?", "Recep", ["Şaban", "Ramazan", "Zilhicce"], "Miraç Recep'tedir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Kadir Gecesi hangi aydadır?", "Ramazan", ["Şaban", "Recep", "Muharrem"], "Kadir Gecesi Ramazan'dadır.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "Kadir Gecesi hangi surede anlatılır?", "Kadr", ["Alak", "Kevser", "İhlâs"], "Kadr suresi Kadir Gecesi'ni anlatır.", SOURCE_QURAN),
  q("Kur'an bilgisi", 2, "Kadir Gecesi bin aydan hayırlıdır ifadesi hangi surededir?", "Kadr", ["Kadr değil Alak", "Duhâ", "İnşirâh"], "Kadr, 3. ayet.", SOURCE_QURAN),
  q("Kur'an bilgisi", 1, "Namazda okunan açılış suresi hangisidir?", "Fatiha", ["İhlâs", "Kevser", "Nas"], "Her rekâtta Fatiha okunur.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Namazda Fatiha'dan sonra kısa sure okumak Hanefi'de nedir?", "Vacip", ["Farz", "Haram", "Mekruh tahrimen değil farz"], "Hanefi'de zamm-ı sure vaciptir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Ezandan sonra okunan dua kime salât içerir?", "Peygamber Efendimiz", ["Yalnızca sahabeye", "Yalnızca meleklere", "Yalnızca halifelere"], "Ezân duasında peygambere salât vardır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Kamet ne zaman getirilir?", "Farz namaza durmadan önce", ["Oruca niyetlenirken", "Hacca ihrama girerken", "Zekât verirken"], "Kamet farz namaz öncesidir.", SOURCE_IBADAT),
  q("Siyer", 2, "Mescid-i Nebevî hangi şehirdedir?", "Medine", ["Mekke", "Kudüs", "Taif"], "Mescid-i Nebevî Medine'dedir.", SOURCE_SIYER),
  q("Siyer", 1, "Mescid-i Haram hangi şehirdedir?", "Mekke", ["Medine", "Kudüs", "Taif"], "Mescid-i Haram Mekke'dedir.", SOURCE_IBADAT),
  q("Siyer", 1, "Mescid-i Aksâ hangi şehirdedir?", "Kudüs", ["Mekke", "Medine", "Şam"], "Mescid-i Aksâ Kudüs'tedir.", SOURCE_TDV),
  q("Siyer", 2, "Sevr mağarası hicrette kiminle paylaşılmıştır?", "Ebû Bekir", ["Ömer", "Ali", "Osman"], "Sevr'de Hz. Ebû Bekir vardı.", SOURCE_SIYER),
  q("Siyer", 2, "Medine'nin eski adı nedir?", "Yesrib", ["Hayber", "Fadak", "Tebük"], "Medine, Yesrib idi.", SOURCE_SIYER),
  q("Siyer", 2, "Hayber gazvesi kime karşıdır?", "Hayber Yahudileri", ["Mekkeli müşrikler", "Rumlar", "Sâsânîler"], "Hayber, Hayber Yahudilerine karşıdır.", SOURCE_SIYER),
  q("Siyer", 3, "Tebük Seferi hicrî kaçıncı yıldadır?", "9", ["6", "8", "10"], "Tebük hicrî 9. yıldadır.", SOURCE_SIYER),
  q("Siyer", 2, "Ashâb-ı Suffe nerede kalırdı?", "Mescid-i Nebevî'nin suffesinde", ["Kâbe'de", "Uhud'da", "Hira'da"], "Suffe, Mescid-i Nebevî'dedir.", SOURCE_SIYER),
  q("Siyer", 1, "Peygamber Efendimiz'in kızı Fatıma'nın eşi kimdir?", "Ali", ["Zübeyr", "Talha", "Sa'd"], "Hz. Fatıma, Hz. Ali ile evlidir.", SOURCE_SIYER),
  q("Siyer", 1, "Hasan ve Hüseyin'in babası kimdir?", "Ali", ["Ömer", "Osman", "Ebû Bekir"], "Babaları Hz. Ali'dir.", SOURCE_SIYER),
  q("Siyer", 2, "Aşere-i mübeşşere kaç kişidir?", "10", ["7", "12", "40"], "On kişi cennetle müjdelenmiştir.", SOURCE_TDV),
  q("Kur'an bilgisi", 2, "Elif-Lâm-Mîm ile başlayan surelerden biri hangisidir?", "Bakara", ["İhlâs", "Kevser", "Nas"], "Bakara Elif-Lâm-Mîm ile başlar.", SOURCE_QURAN),
  q("Kur'an bilgisi", 3, "Hurûf-ı mukattaa nedir?", "Bazı sure başlarındaki kesik harfler", ["Neshedilmiş ayetler", "Kıraat farkları", "Vakıf işaretleri"], "Mukattaa, sure başı harfleridir.", SOURCE_TDV),
  q("Kur'an bilgisi", 2, "Kur'an'ın indirilişi kaç yılda tamamlanmıştır?", "23", ["13", "10", "40"], "Vahiy yaklaşık 23 yıldır.", SOURCE_SIYER),
  q("Kur'an bilgisi", 1, "Amenerrasulü hangi surenin sonundadır?", "Bakara", ["Âl-i İmrân", "Nisâ", "Mâide"], "Amenerrasulü Bakara'nın sonudur.", SOURCE_QURAN),
  q("Kur'an bilgisi", 2, "Âyetü'l-kürsî hangi surededir?", "Bakara", ["Âl-i İmrân", "İhlâs", "Yâsîn"], "Âyetü'l-kürsî Bakara 255'tir.", SOURCE_QURAN),
  q("Kur'an bilgisi", 3, "Âyetü'l-kürsî Bakara suresinin kaçıncı ayetidir?", "255", ["286", "1", "114"], "Bakara 255'tir.", SOURCE_QURAN),
  q("Dini kavramlar", 2, "Tecvid nedir?", "Kur'an'ı usulüne göre okuma ilmi", ["Fıkıh usulü", "Hadis tenkidi", "Siyer yazımı"], "Tecvid, kıraat usulüdür.", SOURCE_TDV),
  q("Dini kavramlar", 2, "Tefsir nedir?", "Kur'an'ı açıklama ilmi", ["Hadis ezberleme", "Fıkıh ferâizi", "Kelam polemiği"], "Tefsir, açıklamadır.", SOURCE_TDV),
  q("Dini kavramlar", 2, "Hadis nedir?", "Peygamber sözü, fiili ve takriri", ["Yalnızca sahabe sözü", "Yalnızca Kur'an ayeti", "Yalnızca rüya"], "Hadis, sünnetin rivayetidir.", SOURCE_TDV),
  q("Dini kavramlar", 3, "Mütevâtir haber nedir?", "Yalan üzere birleşmesi mümkün olmayan kalabalıkça nakledilen", ["Tek kişinin nakli", "Zayıf rivayet", "Uydurma haber"], "Mütevâtir, kesin bilgi ifade eder.", SOURCE_TDV),
  q("Dini kavramlar", 2, "Sıhhat açısından en sağlam hadis türü hangisidir?", "Sahih", ["Zayıf", "Mevzu", "Mürsel her zaman"], "Sahih hadis makbuldür.", SOURCE_TDV),
  q("Dini kavramlar", 3, "Mevzu hadis ne demektir?", "Uydurma hadis", ["Sahih hadis", "Hasen hadis", "Mütevâtir hadis"], "Mevzu, uydurmadır.", SOURCE_TDV),
  q("İslam tarihi", 2, "Dört büyük mezhep imamından biri hangisidir?", "Ebû Hanîfe", ["İbn Sina", "Farabi", "Kindî"], "Ebû Hanîfe fıkıh imamıdır.", SOURCE_TDV),
  q("İslam tarihi", 2, "Mâlikî mezhebinin imamı kimdir?", "Mâlik b. Enes", ["Şâfiî", "Ahmed b. Hanbel", "Evzâî"], "İmam Mâlik'tir.", SOURCE_TDV),
  q("İslam tarihi", 2, "Şâfiî mezhebinin imamı kimdir?", "Muhammed b. İdris eş-Şâfiî", ["Mâlik", "Ebû Hanîfe", "Ahmed b. Hanbel"], "İmam Şâfiî'dir.", SOURCE_TDV),
  q("İslam tarihi", 2, "Hanbelî mezhebinin imamı kimdir?", "Ahmed b. Hanbel", ["Şâfiî", "Mâlik", "Ebû Yûsuf"], "İmam Ahmed'dir.", SOURCE_TDV),
  q("İslam tarihi", 3, "Buhârî'nin hadis kitabının adı nedir?", "el-Câmiu's-sahîh", ["el-Muvatta", "el-Müsned", "Sünen-i Ebû Dâvûd"], "Sahîh-i Buhârî diye anılır.", SOURCE_TDV),
  q("İslam tarihi", 3, "Kütüb-i Sitte kaç kitaptır?", "6", ["4", "5", "9"], "Altı temel hadis kitabıdır.", SOURCE_TDV),
  q("Peygamberler tarihi", 2, "Kur'an'da adı geçen peygamber sayısı geleneksel tespite göre kaçtır?", "25", ["12", "40", "124000"], "Kur'an'da 25 peygamber adı geçer.", SOURCE_IBADAT),
  q("Peygamberler tarihi", 3, "Ulü'l-azm peygamberler kaçtır?", "5", ["3", "7", "10"], "Nûh, İbrâhîm, Mûsâ, Îsâ, Muhammed.", SOURCE_TDV),
  q("Peygamberler tarihi", 2, "Ulü'l-azm peygamberlerden biri hangisidir?", "Nûh", ["Yûsuf", "Yûnus", "Hârûn"], "Nûh ulü'l-azmdandır.", SOURCE_TDV),
  q("Dini kavramlar", 1, "Besmele hangi ifadeyle başlar?", "Bismillahirrahmanirrahim", ["Elhamdülillah", "Allahu ekber", "Lâ ilâhe illallah"], "Besmele Rahman ve Rahim adıyla başlar.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Allahu ekber ne demektir?", "Allah en büyüktür", ["Allah birdir", "Allah affedicidir", "Allah rızık verendir"], "Tekbir, Allahu ekber'dir.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Elhamdülillah ne demektir?", "Hamd Allah'adır", ["Allah en büyüktür", "Bağışla yâ Rabbi", "İşittik itaat ettik"], "Hamd Allah'adır.", SOURCE_IBADAT),
  q("Dini kavramlar", 1, "Sübhânallah ne demektir?", "Allah'ı noksanlıklardan tenzih ederim", ["Allah en büyüktür", "Hamd Allah'adır", "Allah birdir"], "Tesbih tenzihtir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Tesbih namazı nafile midir?", "Evet", ["Farz-ı ayn", "Farz-ı kifaye", "Vacip"], "Tesbih namazı nafiledir.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 1, "Teravih hangi ayda kılınır?", "Ramazan", ["Şaban", "Recep", "Muharrem"], "Teravih Ramazan'dadır.", SOURCE_IBADAT),
  q("İbadet ve temel dini bilgiler", 2, "Teravih namazı hükmü nedir?", "Sünnet-i müekkede", ["Farz", "Vacip", "Haram"], "Teravih müekked sünnettir.", SOURCE_IBADAT),
  q("Kur'an bilgisi", 2, "Fatiha'dan sonra en çok okunan kısa surelerden biri hangisidir?", "İhlâs", ["Bakara", "Nisâ", "A'râf"], "İhlâs kısa tevhid suresidir.", SOURCE_IBADAT),
  q("Kur'an bilgisi", 1, "Felak ve Nâs sureleri birlikte nasıl anılır?", "Muavvizeteyn", ["Seb'u'l-mesânî", "Tıvâl", "Mufassal"], "Felak ve Nâs, Muavvizeteyn'dir.", SOURCE_TDV),
  q("Kur'an bilgisi", 2, "Kâfirûn suresinin temel konusu nedir?", "Küfürden berâet / tevhid netliği", ["Namaz vakitleri", "Zekât nisabı", "Hac menâsiki"], "Kâfirûn, inanç ayrılığını bildirir.", SOURCE_QURAN),
  q("İbadet ve temel dini bilgiler", 1, "Niyet ibadetin geçerliliği için gerekli midir?", "Evet", ["Hayır", "Yalnızca hacda", "Yalnızca zekâtta"], "Niyet ibadetin temelidir.", SOURCE_IBADAT),
];

function monthQuestions() {
  const out = [];
  for (let i = 0; i < MONTHS.length; i += 1) {
    const name = MONTHS[i];
    const order = i + 1;
    const pack = nearbyInts(order);
    out.push({
      category: "İbadet ve temel dini bilgiler",
      difficulty: 2,
      question: `${name} hicrî yılın kaçıncı ayıdır?`,
      options: pack.options,
      correctIndex: pack.correctIndex,
      explanation: `${name} ${order}. aydır.`,
      source: SOURCE_IBADAT,
    });
  }
  return out;
}

function prophetPickQuestions() {
  const out = [];
  for (let i = 0; i < PROPHETS.length; i += 1) {
    const name = PROPHETS[i];
    const wrongs = shuffle(FAKE_NAMES, 100 + i).slice(0, 3);
    out.push(q(
      "Peygamberler tarihi",
      1,
      `Kur'an'da adı geçen peygamberlerden biri: hangisi doğrudur? (${i + 1})`,
      name,
      wrongs,
      `${name} Kur'an'da geçen peygamberlerdendir.`,
      SOURCE_QURAN,
    ));
  }
  // Numbered stems are ugly and may fail uniqueness style. Skip numbered.
  return [];
}

function extraProphet() {
  return PROPHETS.filter((_, i) => i % 3 === 0).map((name) => q(
    "Peygamberler tarihi",
    2,
    `${name} peygamber Kur'an-ı Kerim'de adı geçen peygamberlerden midir?`,
    "Evet",
    ["Hayır", "Yalnızca hadislerde geçer", "Yalnızca İsrailiyat'ta geçer"],
    `${name} Kur'an'da anılır.`,
    SOURCE_QURAN,
  ));
}

function normalize(text) {
  return String(text).toLocaleLowerCase("tr-TR").replace(/\s+/g, " ").trim();
}

function validateItem(item) {
  if (typeof item.question !== "string" || item.question.trim().length < 12) {
    throw new Error(`Short question: ${item.question}`);
  }
  if (!Array.isArray(item.options) || item.options.length !== 4) {
    throw new Error(`Options: ${item.question}`);
  }
  if (new Set(item.options.map((o) => String(o).trim())).size !== 4) {
    throw new Error(`Dup options: ${item.question}`);
  }
  if (![1, 2, 3].includes(item.difficulty)) {
    throw new Error(`Diff: ${item.question}`);
  }
  if (!Number.isInteger(item.correctIndex) || item.correctIndex < 0 || item.correctIndex > 3) {
    throw new Error(`Index: ${item.question}`);
  }
  if (!item.options[item.correctIndex] || !String(item.options[item.correctIndex]).trim()) {
    throw new Error(`Empty correct: ${item.question}`);
  }
  if (String(item.explanation || "").trim().length < 8) {
    throw new Error(`Expl: ${item.question}`);
  }
  if (String(item.source || "").trim().length < 4) {
    throw new Error(`Source: ${item.question}`);
  }
}

function main() {
  const outPath = path.join(__dirname, "..", "data", "islamic_quiz_questions.json");
  const existing = JSON.parse(fs.readFileSync(outPath, "utf8"));
  if (!Array.isArray(existing) || existing.length !== 500) {
    throw new Error(`Expected existing bank of 500, got ${existing.length}`);
  }

  const candidates = [
    ...buildSurahQuestions(),
    ...monthQuestions(),
    ...extraProphet(),
    ...HAND,
  ];

  const seen = new Set(existing.map((row) => normalize(row.question)));
  const picked = [];
  for (const item of candidates) {
    validateItem(item);
    const key = normalize(item.question);
    if (seen.has(key)) continue;
    seen.add(key);
    picked.push(item);
    if (picked.length === 500) break;
  }
  if (picked.length !== 500) {
    throw new Error(`Needed 500 unique new questions, got ${picked.length}`);
  }

  const startId = 501;
  const appended = picked.map((item, i) => ({
    id: `iq_${String(startId + i).padStart(3, "0")}`,
    category: item.category,
    difficulty: item.difficulty,
    question: item.question,
    options: item.options,
    correctIndex: item.correctIndex,
    explanation: item.explanation,
    source: item.source,
  }));

  const next = existing.concat(appended);
  fs.writeFileSync(outPath, `${JSON.stringify(next, null, 2)}\n`);
  const byDiff = { 1: 0, 2: 0, 3: 0 };
  for (const row of next) byDiff[row.difficulty] += 1;
  console.log(`Wrote ${next.length} questions`, byDiff);
}

main();
