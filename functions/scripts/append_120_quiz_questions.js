/**
 * Appends 120 Diyanet/TDV-aligned questions to islamic_quiz_questions.json.
 * Run: node functions/scripts/append_120_quiz_questions.js
 */
"use strict";

const fs = require("fs");
const path = require("path");

const CATEGORIES = [
  "Kur'an bilgisi",
  "Siyer",
  "Peygamberler tarihi",
  "İslam tarihi",
  "İbadet ve temel dini bilgiler",
  "Dini kavramlar",
];

/** @type {Array<{category:string,difficulty:1|2|3,question:string,options:string[],correctIndex:number,explanation:string,source:string}>} */
const NEW_QUESTIONS = [
  // —— Kur'an bilgisi (20) ——
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "Kur'an-ı Kerim kaç cüze ayrılır?",
    options: ["20", "30", "40", "14"],
    correctIndex: 1,
    explanation: "Kur'an-ı Kerim okuma ve ezber kolaylığı için 30 cüze ayrılır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "Fatiha suresi kaç ayetten oluşur?",
    options: ["5", "6", "7", "8"],
    correctIndex: 2,
    explanation: "Fatiha suresi yedi ayetten oluşur.",
    source: "Diyanet Kur'an Yolu, Fatiha",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "İhlas suresi kaç ayetten oluşur?",
    options: ["3", "4", "5", "6"],
    correctIndex: 1,
    explanation: "İhlas suresi dört ayettir.",
    source: "Diyanet Kur'an Yolu, İhlas",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "Kur'an-ı Kerim'in bir cüzü yaklaşık kaç sayfadır (standart mushaf)?",
    options: ["10", "20", "30", "40"],
    correctIndex: 1,
    explanation: "Standart mushafta bir cüz yaklaşık 20 sayfadır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "Namazda okunması gereken ilk sure hangisidir?",
    options: ["İhlas", "Fatiha", "Nas", "Kevser"],
    correctIndex: 1,
    explanation: "Her rekâtta Fatiha okunur; namazın rükünlerindendir.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da 'ümmü'l-Kur'ân' diye anılan sure hangisidir?",
    options: ["Bakara", "Yasin", "Fatiha", "Rahmân"],
    correctIndex: 2,
    explanation: "Fatiha, Kur'an'ın özü anlamında ümmü'l-Kur'ân diye anılır.",
    source: "Diyanet Kur'an Yolu, Fatiha",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Mülk suresi mushafta kaçıncı sıradadır?",
    options: ["36", "55", "67", "78"],
    correctIndex: 2,
    explanation: "Mülk suresi mushafta 67. suredir.",
    source: "Diyanet Kur'an Yolu, Mülk",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da geçen 'kıssa' kavramı neyi ifade eder?",
    options: [
      "Hukuk hükmü",
      "Öğüt içeren geçmiş olay anlatımı",
      "Namaz kuralı",
      "Zekât hesabı",
    ],
    correctIndex: 1,
    explanation: "Kıssalar ibret ve öğüt için anlatılan geçmiş olaylardır.",
    source: "TDV İslam Ansiklopedisi, Kıssa",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da 'ehl-i beyt' ifadesi kimleri ifade eder?",
    options: [
      "Yalnızca komşuları",
      "Hz. Peygamber'in ev halkını",
      "Yalnızca tüccarları",
      "Yalnızca kâhinleri",
    ],
    correctIndex: 1,
    explanation: "Ehl-i beyt, Hz. Peygamber'in ev halkını ifade eder.",
    source: "TDV İslam Ansiklopedisi, Ehl-i Beyt",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da 'sabır' ile sık birlikte anılan erdem hangisidir?",
    options: ["İsraf", "Salât (namaz)", "Kibir", "Gıybet"],
    correctIndex: 1,
    explanation: "Birçok ayette sabır ile namaz birlikte emredilir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da 'zekât' emriyle sık vurgulanan amaç nedir?",
    options: [
      "Serveti gizleme",
      "Mülkiyeti yok sayma",
      "Yoksulu gözetme ve malı arındırma",
      "Ticareti yasaklama",
    ],
    correctIndex: 2,
    explanation: "Zekât malı arındırır ve ihtiyaç sahiplerini gözetir.",
    source: "Diyanet İlmihal, Zekât",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Kur'an'da 'ashâbü'l-yemîn' kimleri ifade eder?",
    options: [
      "Sağ ehli, kurtuluşa erenleri",
      "Yalnızca tüccarları",
      "Yalnızca kâfirleri",
      "Yalnızca melekleri",
    ],
    correctIndex: 0,
    explanation: "Ashâbü'l-yemîn, hesapta kurtuluşa erenleri ifade eder.",
    source: "Diyanet Kur'an Yolu, Vâkıa",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Kur'an'da 'ashâbü'ş-şimâl' kimleri ifade eder?",
    options: [
      "Peygamberleri",
      "Sol ehli, hüsrana uğrayanları",
      "Yalnızca çocukları",
      "Yalnızca melekleri",
    ],
    correctIndex: 1,
    explanation: "Ashâbü'ş-şimâl, ahirette hüsrana uğrayanları ifade eder.",
    source: "Diyanet Kur'an Yolu, Vâkıa",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Esbâb-ı nüzûl ilmi neyi inceler?",
    options: [
      "Ayetlerin iniş sebeplerini",
      "Namaz vakitlerini",
      "Zekât oranlarını",
      "Hac menasikini",
    ],
    correctIndex: 0,
    explanation: "Esbâb-ı nüzûl, ayetlerin iniş sebeplerini inceler.",
    source: "TDV İslam Ansiklopedisi, Esbâb-ı Nüzûl",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Kur'an'da 'hüccet' kavramı neyi ifade eder?",
    options: ["Şüphe", "Delil ve kanıt", "Yasak", "Ceza"],
    correctIndex: 1,
    explanation: "Hüccet, kesin delil ve kanıt anlamındadır.",
    source: "TDV İslam Ansiklopedisi, Hüccet",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Neml suresinde Hz. Süleyman ile ilgili öne çıkan mucize hangisidir?",
    options: [
      "Denizde yürümesi",
      "Kuşların ve cinlerin emrine verilmesi",
      "Asanın ejderha olması",
      "Beşikte konuşması",
    ],
    correctIndex: 1,
    explanation: "Neml suresinde Hz. Süleyman'a kuşlar ve cinler emrine verilmiştir.",
    source: "Diyanet Kur'an Yolu, Neml",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Kur'an'da 'beyyine' kavramı neyi ifade eder?",
    options: ["Belirsizlik", "Açık delil", "Gıybet", "İsraf"],
    correctIndex: 1,
    explanation: "Beyyine, apaçık delil demektir.",
    source: "TDV İslam Ansiklopedisi, Beyyine",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 1,
    question: "Kur'an okumaya genellikle hangi ifade ile başlanır?",
    options: [
      "Allahu ekber",
      "Eûzü-besmele",
      "Esselâmü aleyküm",
      "Amin",
    ],
    correctIndex: 1,
    explanation: "Kur'an okumaya eûzü ve besmele ile başlamak sünnettir.",
    source: "Diyanet İlmihal, Kur'an Okuma",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 2,
    question: "Kur'an'da 'rahmet' kavramı en çok hangi ilahi isimlerle birlikte anılır?",
    options: [
      "Rahmân ve Rahîm",
      "Müntakim ve Kahhâr",
      "Semî ve Basîr yalnız",
      "Melik ve Kuddûs yalnız",
    ],
    correctIndex: 0,
    explanation: "Rahmet, özellikle Rahmân ve Rahîm isimleriyle vurgulanır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Kur'an bilgisi",
    difficulty: 3,
    question: "Kur'an'da 'müzzemmil' hitabı hangi surede geçer?",
    options: ["Müddessir", "Müzzemmil", "Alak", "Duhâ"],
    correctIndex: 1,
    explanation: "Müzzemmil suresi Hz. Peygamber'e 'örtüsüne bürünen' hitabıyla başlar.",
    source: "Diyanet Kur'an Yolu, Müzzemmil",
  },

  // —— Siyer (20) ——
  {
    category: "Siyer",
    difficulty: 1,
    question: "İlk müezzin olarak bilinen sahabi kimdir?",
    options: ["Hz. Ömer", "Bilâl-i Habeşî", "Hz. Osman", "Hz. Ali"],
    correctIndex: 1,
    explanation: "İlk müezzin Bilâl-i Habeşî'dir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hz. Peygamber'in sütannesinin kabilesi hangisidir?",
    options: ["Kureyş", "Benî Sa'd", "Evs", "Hazrec"],
    correctIndex: 1,
    explanation: "Halîme, Benî Sa'd kabilesindendir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hz. Peygamber'e 'el-Emîn' lakabı neden verilmiştir?",
    options: [
      "Savaşçılığı nedeniyle",
      "Güvenilirliği nedeniyle",
      "Ticaret yasağı nedeniyle",
      "Şairliği nedeniyle",
    ],
    correctIndex: 1,
    explanation: "Güvenilir kişiliği nedeniyle el-Emîn diye anılmıştır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hicretten sonra Medine'de kardeşleştirme uygulamasına ne ad verilir?",
    options: ["Muhacirlik", "Muâhât", "İhram", "İtikâf"],
    correctIndex: 1,
    explanation: "Muhacir ile Ensar'ın kardeşleştirilmesine muâhât denir.",
    source: "TDV İslam Ansiklopedisi, Muâhât",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hz. Peygamber'in doğduğu yıl Fil Vak'ası ile nasıl ilişkilendirilir?",
    options: [
      "Aynı yıl doğduğu kabul edilir",
      "Yüz yıl sonradır",
      "İlişkisi yoktur",
      "Hicretten sonradır",
    ],
    correctIndex: 0,
    explanation: "Geleneksel rivayete göre doğum yılı Fil yılıdır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "Ashâb-ı Suffe kimlerdir?",
    options: [
      "Mescid-i Nebevî'de ilim ve ibadetle meşgul yoksul sahabiler",
      "Yalnızca tüccar sahabiler",
      "Mekke'nin müşrik ileri gelenleri",
      "Yalnızca Emevi yöneticileri",
    ],
    correctIndex: 0,
    explanation: "Suffe, Mescid-i Nebevî'de kalan ilim ehli sahabilerdir.",
    source: "TDV İslam Ansiklopedisi, Ashâb-ı Suffe",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "Hz. Peygamber'in amcası olup İslam'ı savunan sahabi kimdir?",
    options: ["Ebu Leheb", "Hz. Hamza", "Ebu Cehil", "Utbe"],
    correctIndex: 1,
    explanation: "Hz. Hamza, amcası olup İslam'ı savunan sahabedendir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "İlk Habeşistan hicretinde Müslümanları kabul eden hükümdar kimdir?",
    options: ["Kayser", "Necaşî", "Kisra", "Mukavkıs"],
    correctIndex: 1,
    explanation: "Habeşistan hükümdarı Necaşî Müslümanlara sığınma vermiştir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "Hicrette Medine'ye varışta ilk konaklanan ve mescit inşa edilen yer hangisidir?",
    options: ["Taif", "Kubâ", "Huneyn", "Hayber"],
    correctIndex: 1,
    explanation: "Kubâ'da konaklanmış ve Mescid-i Kubâ inşa edilmiştir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "Bedir Savaşı'nda Müslümanların sayısı geleneksel olarak yaklaşık kaçtır?",
    options: ["313", "1000", "10.000", "70"],
    correctIndex: 0,
    explanation: "Bedir'de Müslümanların sayısı yaklaşık 313'tür.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "Uhud Savaşı'nda okçuların bırakmaması gereken yer neresidir?",
    options: ["Dere yatağı", "Dağ geçidi / tepe", "Deniz kıyısı", "Çöl ortası"],
    correctIndex: 1,
    explanation: "Okçular tepeyi terk edince savaşın seyri değişmiştir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Hendek Savaşı'nda hendek kazma fikrini öneren sahabi kimdir?",
    options: ["Hz. Ömer", "Selmân-ı Fârisî", "Hz. Osman", "Ebû Zer"],
    correctIndex: 1,
    explanation: "Hendek fikri Selmân-ı Fârisî'ye nispet edilir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Hudeybiye Antlaşması'ndan sonra gerçekleşen önemli sonuç nedir?",
    options: [
      "İslam'ın tebliğinin hızlanması ve fethin yolu açılması",
      "Namazın kaldırılması",
      "Hicretin iptali",
      "Zekâtın yasaklanması",
    ],
    correctIndex: 0,
    explanation: "Hudeybiye, barış ortamıyla tebliğin yayılmasını sağlamıştır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Veda Hutbesi'nde vurgulanan temel ilkelerden biri nedir?",
    options: [
      "Irk üstünlüğü",
      "Can, mal ve namus dokunulmazlığı",
      "Faizin teşviki",
      "Kadın haklarının yok sayılması",
    ],
    correctIndex: 1,
    explanation: "Veda Hutbesi can, mal ve namusun korunmasını vurgular.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Hz. Peygamber'in annesi Âmine nerede vefat etmiştir?",
    options: ["Mekke", "Ebvâ", "Medine", "Taif"],
    correctIndex: 1,
    explanation: "Âmine, Ebvâ'da vefat etmiştir.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Mekke'nin fethinde Hz. Peygamber'in genel yaklaşımı ne olmuştur?",
    options: [
      "Genel af ve yumuşak davranış",
      "Toplu sürgün",
      "İbadetin yasaklanması",
      "Şehrin yakılması",
    ],
    correctIndex: 0,
    explanation: "Fetih günü genel af ilan edilerek yumuşak davranılmıştır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hz. Peygamber'in kızı olup Ehl-i Beyt'ten olan isim hangisidir?",
    options: ["Hz. Âişe", "Hz. Fâtıma", "Hz. Hatice'nin annesi", "Hz. Ümmü Seleme"],
    correctIndex: 1,
    explanation: "Hz. Fâtıma, Hz. Peygamber'in kızıdır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 2,
    question: "İlk Cuma namazı hangi şehir yolunda kılınmıştır?",
    options: ["Taif", "Ranûnâ vadisi (Kubâ-Medine arası)", "Hayber", "Huneyn"],
    correctIndex: 1,
    explanation: "İlk Cuma, Ranûnâ vadisinde kılınmıştır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 3,
    question: "Mute Seferi'nde sırayla komutanlık yapan üç sahabi kimlerdir?",
    options: [
      "Zeyd, Ca'fer, Abdullah b. Revâha",
      "Ebû Bekir, Ömer, Osman",
      "Hamza, Abbas, Talha",
      "Bilâl, Selmân, Ammâr",
    ],
    correctIndex: 0,
    explanation: "Mute'de bayrak sırasıyla Zeyd, Ca'fer ve Abdullah b. Revâha'dadır.",
    source: "Diyanet Siyer Bilgileri",
  },
  {
    category: "Siyer",
    difficulty: 1,
    question: "Hz. Peygamber'in vefat ettiği şehir hangisidir?",
    options: ["Mekke", "Medine", "Taif", "Kudüs"],
    correctIndex: 1,
    explanation: "Hz. Peygamber Medine'de vefat etmiştir.",
    source: "Diyanet Siyer Bilgileri",
  },

  // —— Peygamberler tarihi (20) ——
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hz. İbrahim'in oğullarından biri kimdir?",
    options: ["Hz. Yusuf", "Hz. İsmail", "Hz. Musa", "Hz. Yunus"],
    correctIndex: 1,
    explanation: "Hz. İsmail, Hz. İbrahim'in oğludur.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hz. İshak'ın babası kimdir?",
    options: ["Hz. Nuh", "Hz. İbrahim", "Hz. Yakub", "Hz. Yusuf"],
    correctIndex: 1,
    explanation: "Hz. İshak, Hz. İbrahim'in oğludur.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hz. Yakub'un oğlu olup Mısır'a yönetici olan peygamber kimdir?",
    options: ["Hz. Musa", "Hz. Yusuf", "Hz. Harun", "Hz. Şuayb"],
    correctIndex: 1,
    explanation: "Hz. Yusuf, Yakub'un oğlu olup Mısır'da yönetici olmuştur.",
    source: "Diyanet Kur'an Yolu, Yusuf",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hz. Musa hangi kavme gönderilmiştir?",
    options: ["Âd", "Semûd", "İsrailoğulları", "Medyen yalnız"],
    correctIndex: 2,
    explanation: "Hz. Musa İsrailoğullarına gönderilmiştir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hz. İsa'nın annesi kimdir?",
    options: ["Hz. Âsiye", "Hz. Meryem", "Hz. Hacer", "Hz. Sâre"],
    correctIndex: 1,
    explanation: "Hz. İsa'nın annesi Hz. Meryem'dir.",
    source: "Diyanet Kur'an Yolu, Meryem",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. Yahya'nın babası hangi peygamberdir?",
    options: ["Hz. Zekeriya", "Hz. İlyas", "Hz. Eyyûb", "Hz. Yunus"],
    correctIndex: 0,
    explanation: "Hz. Yahya, Hz. Zekeriya'nın oğludur.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. Lut hangi topluma gönderilmiştir?",
    options: [
      "Lut kavmine",
      "Âd kavmine",
      "Semûd kavmine",
      "Medyen halkına",
    ],
    correctIndex: 0,
    explanation: "Hz. Lut, kendi kavmine gönderilmiştir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. İbrahim'e verilen suhuf neyi ifade eder?",
    options: [
      "Kendisine indirilen sayfalar",
      "Yalnızca bir savaş bayrağı",
      "Yalnızca ticaret belgesi",
      "Yalnızca şehir haritası",
    ],
    correctIndex: 0,
    explanation: "Suhuf, bazı peygamberlere indirilen sayfalardır; Hz. İbrahim'e de suhuf verildiği bildirilir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. Eyyûb kıssasında öne çıkan erdem hangisidir?",
    options: ["Sabır", "İsraf", "Kibir", "Gıybet"],
    correctIndex: 0,
    explanation: "Hz. Eyyûb sabrıyla örnek gösterilir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. İbrahim'in eşi olup Hz. İsmail'in annesi kimdir?",
    options: ["Hz. Hacer", "Hz. Meryem", "Hz. Âsiye", "Hz. Havva"],
    correctIndex: 0,
    explanation: "Hz. İsmail'in annesi Hz. Hacer'dir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. Musa ile ilgili 'yed-i beyza' ifadesi neyi anlatır?",
    options: [
      "Elinin mucizevi biçimde bembeyaz görünmesi",
      "Asasının kırılması",
      "Denizin kuruması yalnız",
      "Putların yıkılması",
    ],
    correctIndex: 0,
    explanation: "Yed-i beyza, Hz. Musa'nın elinin bembeyaz görünmesi mucizesidir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. İdris Kur'an'da nasıl nitelendirilir?",
    options: [
      "Sıddîk ve nebî",
      "Yalnızca kral",
      "Yalnızca tüccar",
      "Yalnızca şair",
    ],
    correctIndex: 0,
    explanation: "Kur'an'da Hz. İdris sıddîk ve nebî diye anılır.",
    source: "Diyanet Kur'an Yolu, Meryem",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. İsmail ile ilgili Kâbe kıssasında öne çıkan olay nedir?",
    options: [
      "Kâbe'nin temellerinin yükseltilmesi",
      "Tufan gemisi",
      "Asanın ejderha olması",
      "Beşikte konuşma",
    ],
    correctIndex: 0,
    explanation: "Hz. İbrahim ve İsmail Kâbe'nin temellerini yükseltmiştir.",
    source: "Diyanet Kur'an Yolu, Bakara",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. Musa'ya Tur Dağı'nda verilen vahyin özü nedir?",
    options: [
      "Tevhid ve şeriat hükümleri",
      "Ticaret tarifesi",
      "Şiir öğretimi",
      "Savaş yasağı yalnız",
    ],
    correctIndex: 0,
    explanation: "Tur'da tevhid ve şeriat esasları vahyedilmiştir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. Yunus'un balık karnından kurtuluş duası hangi temayı işler?",
    options: [
      "Tevbe ve tevhid",
      "Mal biriktirme",
      "Irk üstünlüğü",
      "Savaş övgüsü",
    ],
    correctIndex: 0,
    explanation: "Yunus kıssası tevbe ve tevhidi öne çıkarır.",
    source: "Diyanet Kur'an Yolu, Enbiyâ",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. Şuayb'ın kavmine yönelttiği temel uyarı nedir?",
    options: [
      "Ölçü ve tartıda haksızlık yapmamaları",
      "Namazı bırakmaları",
      "Orucu terk etmeleri",
      "Hacca gitmemeleri",
    ],
    correctIndex: 0,
    explanation: "Hz. Şuayb ölçü ve tartıda adaleti emretmiştir.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Hâtemü'l-enbiyâ unvanı kime aittir?",
    options: ["Hz. İsa", "Hz. Musa", "Hz. Muhammed", "Hz. İbrahim"],
    correctIndex: 2,
    explanation: "Hâtemü'l-enbiyâ, son peygamber Hz. Muhammed'dir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 2,
    question: "Hz. Âdem'in eşi olarak anılan isim hangisidir?",
    options: ["Hz. Havva", "Hz. Meryem", "Hz. Hacer", "Hz. Âsiye"],
    correctIndex: 0,
    explanation: "Hz. Âdem'in eşi Hz. Havva'dır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 3,
    question: "Hz. Sâlih'in kavmine verilen deve mucizesi hangi temayı işler?",
    options: [
      "Allah'ın ayetine saygı ve imtihan",
      "Ticaret vergisi",
      "Savaş eğitimi",
      "Şiir yarışması",
    ],
    correctIndex: 0,
    explanation: "Deve mucizesi ilahi ayete saygı ve imtihanı vurgular.",
    source: "Diyanet Kur'an Yolu",
  },
  {
    category: "Peygamberler tarihi",
    difficulty: 1,
    question: "Dört büyük kitap hangileridir?",
    options: [
      "Tevrat, Zebur, İncil, Kur'an",
      "Yalnızca Kur'an ve İncil",
      "Yalnızca Tevrat ve Zebur",
      "Yalnızca suhuf",
    ],
    correctIndex: 0,
    explanation: "Dört büyük kitap: Tevrat, Zebur, İncil ve Kur'an'dır.",
    source: "Diyanet Temel Dini Bilgiler",
  },

  // —— İslam tarihi (20) ——
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Hulefâ-yi Râşidîn kimleri kapsar?",
    options: [
      "Ebû Bekir, Ömer, Osman ve Ali",
      "Yalnızca Emevi halifeleri",
      "Yalnızca Abbasi halifeleri",
      "Yalnızca Osmanlı padişahları",
    ],
    correctIndex: 0,
    explanation: "Hulefâ-yi Râşidîn dört halifedir: Ebû Bekir, Ömer, Osman ve Ali.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Yalancı peygamberlerle mücadele hangi dönemde yoğunlaşmıştır?",
    options: ["Hz. Ömer", "Hz. Ebû Bekir", "Hz. Osman", "Hz. Ali"],
    correctIndex: 1,
    explanation: "Ridde sürecinde yalancı peygamberlerle mücadele Hz. Ebû Bekir dönemindedir.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Hz. Ömer döneminde İslam topraklarına katılan kutsal şehir hangisidir?",
    options: ["Şam yalnız", "Kudüs", "Kurtuba", "Buhara"],
    correctIndex: 1,
    explanation: "Kudüs, Hz. Ömer döneminde İslam topraklarına katılmıştır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "İslam'da dört büyük fıkıh mezhebinden biri hangisidir?",
    options: ["Hanefî", "Sofist", "Stoacı", "Epikürcü"],
    correctIndex: 0,
    explanation: "Hanefî, dört büyük Sünnî fıkıh mezhebinden biridir.",
    source: "Diyanet İlmihal",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Ayasofya'yı camiye çeviren hükümdar kimdir?",
    options: ["Yavuz Sultan Selim", "Fatih Sultan Mehmet", "Kanuni Sultan Süleyman", "Orhan Gazi"],
    correctIndex: 1,
    explanation: "Fatih Sultan Mehmet İstanbul'un fethinden sonra Ayasofya'yı camiye çevirmiştir.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "Anadolu'nun Türkleşmesinde dönüm noktası sayılan zafer hangisidir?",
    options: ["Malazgirt", "Viyana kuşatması", "Preveze", "Çanakkale"],
    correctIndex: 0,
    explanation: "1071 Malazgirt Zaferi Anadolu'nun Türkleşmesinde dönüm noktasıdır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "Sahih-i Müslim'in derleyicisi kimdir?",
    options: ["İmam Buhârî", "İmam Müslim", "İmam Mâlik", "İmam Şâfiî"],
    correctIndex: 1,
    explanation: "Sahih-i Müslim, İmam Müslim tarafından derlenmiştir.",
    source: "TDV İslam Ansiklopedisi, Müslim",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "İmam Mâlik hangi şehirde yetişmiştir?",
    options: ["Bağdat", "Medine", "Şam", "Kahire"],
    correctIndex: 1,
    explanation: "İmam Mâlik Medine'de yetişmiştir.",
    source: "TDV İslam Ansiklopedisi, Mâlik b. Enes",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "İmam Şâfiî'nin fıkıh usulündeki temel eseri hangisidir?",
    options: ["el-Muvatta", "er-Risâle", "el-Müsned", "İhyâ"],
    correctIndex: 1,
    explanation: "İmam Şâfiî'nin usul eseri er-Risâle'dir.",
    source: "TDV İslam Ansiklopedisi, Şâfiî",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "Emevi döneminde İslam donanmasının güçlendiği deniz hangisidir?",
    options: ["Akdeniz", "Hazar Denizi yalnız", "Kızıldeniz yalnız", "Karadeniz yalnız"],
    correctIndex: 0,
    explanation: "Emeviler döneminde Akdeniz'de İslam donanması güçlenmiştir.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "Abbasi Devleti'nin ünlü başkenti hangisidir?",
    options: ["Şam", "Bağdat", "Kurtuba", "Bursa"],
    correctIndex: 1,
    explanation: "Abbasilerin ünlü başkenti Bağdat'tır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Yermük Savaşı hangi imparatorluk güçlerine karşı yapılmıştır?",
    options: ["Bizans", "Sasani yalnız", "Moğol", "Haçlı yalnız"],
    correctIndex: 0,
    explanation: "Yermük, Bizans'a karşı önemli bir zaferdir.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Kadisiye Savaşı hangi güce karşı yapılmıştır?",
    options: ["Bizans", "Sasaniler", "Haçlılar", "Moğollar"],
    correctIndex: 1,
    explanation: "Kadisiye, Sasanilere karşı kazanılmıştır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Endülüs'te İslam hâkimiyetinin sona erdiği yıl hangisidir?",
    options: ["1492", "1071", "1453", "1258"],
    correctIndex: 0,
    explanation: "Granada'nın düşüşüyle Endülüs 1492'de sona ermiştir.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Bağdat'ın Moğollar tarafından yıkıldığı yıl hangisidir?",
    options: ["1258", "1071", "1453", "636"],
    correctIndex: 0,
    explanation: "Bağdat 1258'de Moğollar tarafından yağmalanmıştır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Osmanlı'da ilk medreselerden birini kuran hükümdar kimdir?",
    options: ["Orhan Gazi", "Yavuz Sultan Selim", "Kanuni", "II. Abdülhamid"],
    correctIndex: 0,
    explanation: "Orhan Gazi döneminde İznik'te erken medrese kurulmuştur.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Hz. Ali'nin halifelik merkezi son dönemde hangi şehirdir?",
    options: ["Medine", "Kûfe", "Şam", "Mekke"],
    correctIndex: 1,
    explanation: "Hz. Ali halifelik merkezini Kûfe'ye taşımıştır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 2,
    question: "İmam Ahmed b. Hanbel hangi mezhebin imamıdır?",
    options: ["Hanefî", "Mâlikî", "Şâfiî", "Hanbelî"],
    correctIndex: 3,
    explanation: "Ahmed b. Hanbel, Hanbelî mezhebinin imamıdır.",
    source: "TDV İslam Ansiklopedisi, Ahmed b. Hanbel",
  },
  {
    category: "İslam tarihi",
    difficulty: 3,
    question: "Talas Savaşı'nın İslam tarihi açısından önemi nedir?",
    options: [
      "Orta Asya'da İslam etkisinin güçlenmesi",
      "Namazın farz kılınması",
      "Kur'an'ın inmesi",
      "Hicretin başlaması",
    ],
    correctIndex: 0,
    explanation: "Talas, Orta Asya'da İslam etkisinin artmasına yol açmıştır.",
    source: "Diyanet İslam Tarihi",
  },
  {
    category: "İslam tarihi",
    difficulty: 1,
    question: "Türkiye'de Diyanet İşleri Başkanlığı hangi alanda hizmet verir?",
    options: [
      "Dinî hizmetler ve din eğitimi",
      "Askerî savunma",
      "Merkez bankacılığı",
      "Spor federasyonu",
    ],
    correctIndex: 0,
    explanation: "Diyanet, dinî hizmet ve din eğitimi alanlarında görev yapar.",
    source: "Diyanet İşleri Başkanlığı",
  },

  // —— İbadet ve temel dini bilgiler (20) ——
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Sabah namazının farzı kaç rekâttır?",
    options: ["2", "3", "4", "1"],
    correctIndex: 0,
    explanation: "Sabah namazının farzı iki rekâttır.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Öğle namazının farzı kaç rekâttır?",
    options: ["2", "3", "4", "6"],
    correctIndex: 2,
    explanation: "Öğle namazının farzı dört rekâttır.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Akşam namazının farzı kaç rekâttır?",
    options: ["2", "3", "4", "1"],
    correctIndex: 1,
    explanation: "Akşam namazının farzı üç rekâttır.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Cuma namazının farzı kaç rekâttır?",
    options: ["2", "4", "3", "6"],
    correctIndex: 0,
    explanation: "Cuma namazının farzı iki rekâttır.",
    source: "Diyanet İlmihal, Cuma",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Namazda kıble hangi yöne doğrudur?",
    options: ["Kudüs", "Kâbe (Mescid-i Haram)", "Medine yalnız", "Şam"],
    correctIndex: 1,
    explanation: "Kıble, Mekke'deki Kâbe yönüdür.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Abdestin farzlarından biri hangisidir?",
    options: ["Yüzü yıkamak", "Misvak kullanmak", "Koku sürünmek", "Şapka takmak"],
    correctIndex: 0,
    explanation: "Yüzü yıkamak abdestin farzlarındandır.",
    source: "Diyanet İlmihal, Abdest",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Namazın rükünlerinden biri hangisidir?",
    options: ["Kıyam", "Tesbih çekmek sonra", "Selam vermek sokakta", "Sadaka vermek"],
    correctIndex: 0,
    explanation: "Kıyam, namazın rükünlerindendir.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Oruç ne zaman bozulur?",
    options: [
      "İmsaktan önce su içmekle",
      "Gündüz bilerek yemek-içmekle",
      "Gece yemekle",
      "Sahur yapmakla",
    ],
    correctIndex: 1,
    explanation: "Oruç, imsaktan iftara kadar bilerek yenilip içilince bozulur.",
    source: "Diyanet İlmihal, Oruç",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Hac'da Safa ile Merve arasında yapılan ibadete ne ad verilir?",
    options: ["Tavaf", "Sa'y", "Vakfe", "İhram"],
    correctIndex: 1,
    explanation: "Safa-Merve arası yürüyüşe sa'y denir.",
    source: "Diyanet İlmihal, Hac",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Kâbe'nin etrafında dönmeye ne ad verilir?",
    options: ["Sa'y", "Tavaf", "Vakfe", "Remy"],
    correctIndex: 1,
    explanation: "Kâbe etrafında dönmeye tavaf denir.",
    source: "Diyanet İlmihal, Hac",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Umre ile hac arasındaki temel fark nedir?",
    options: [
      "Umre belirli ayda farz değildir; hac belirli zamanda farzdır",
      "Umre farz, hac nafiledir",
      "İkisi tamamen aynıdır",
      "Umrede tavaf yoktur",
    ],
    correctIndex: 0,
    explanation: "Hac belirli zamanda farzdır; umre yıl içinde nafiledir.",
    source: "Diyanet İlmihal, Hac ve Umre",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "Hanefi uygulamasında teravih namazı genellikle kaç rekât kılınır?",
    options: ["8", "20", "2", "12"],
    correctIndex: 1,
    explanation: "Diyanet/Hanefi uygulamada teravih genellikle 20 rekâttır.",
    source: "Diyanet İlmihal, Teravih",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "Arefe günü hicri takvimde hangi gündür?",
    options: [
      "Zilhicce'nin 9. günü",
      "Muharrem'in 10. günü",
      "Ramazan'ın 1. günü",
      "Şaban'ın 15. günü",
    ],
    correctIndex: 0,
    explanation: "Arefe, Zilhicce'nin 9. günüdür.",
    source: "Diyanet İlmihal, Hac",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "Aşure günü hangi aydadır?",
    options: ["Ramazan", "Muharrem", "Şevval", "Zilhicce"],
    correctIndex: 1,
    explanation: "Aşure, Muharrem'in 10. günüdür.",
    source: "Diyanet İlmihal",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "İtikâf ibadeti geleneksel olarak nerede yapılır?",
    options: ["Evde yalnız", "Camide", "Çarşıda", "Yolda"],
    correctIndex: 1,
    explanation: "İtikâf camide yapılan bir ibadettir.",
    source: "Diyanet İlmihal, İtikâf",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "Zekâtın farz olabilmesi için malda aranan şartlardan biri nedir?",
    options: [
      "Nisaba ulaşması ve üzerinden yıl geçmesi",
      "Yalnızca borcun olması",
      "Malın haram olması",
      "Malın gizli tutulması",
    ],
    correctIndex: 0,
    explanation: "Zekât için nisap ve havl (yıl) şartı aranır.",
    source: "Diyanet İlmihal, Zekât",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Kelime-i şehadet neyi ifade eder?",
    options: [
      "Allah'tan başka ilah olmadığına ve Hz. Muhammed'in peygamberliğine şahitlik",
      "Yalnızca oruç niyeti",
      "Yalnızca hac duası",
      "Yalnızca zekât hesabı",
    ],
    correctIndex: 0,
    explanation: "Şehadet, tevhid ve peygamberlik inancını dil ile ikrar etmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 2,
    question: "Namazda rükûda omurga nasıl konumlanır?",
    options: [
      "Eğilerek eller dizlere konularak",
      "Oturarak",
      "Yan yatarak",
      "Koşarak",
    ],
    correctIndex: 0,
    explanation: "Rükûda eğilip eller dizlere konur.",
    source: "Diyanet İlmihal, Namaz",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 3,
    question: "Bayram namazı kaç rekât olarak kılınır?",
    options: ["2", "3", "4", "1"],
    correctIndex: 0,
    explanation: "Bayram namazı iki rekâttır.",
    source: "Diyanet İlmihal, Bayram Namazı",
  },
  {
    category: "İbadet ve temel dini bilgiler",
    difficulty: 1,
    question: "Fitre (fıtır sadakası) ne zaman verilir?",
    options: [
      "Ramazan Bayramı öncesinde",
      "Yalnızca Kurban Bayramı'nda",
      "Yalnızca Aşure'de",
      "Yalnızca Miraç'ta",
    ],
    correctIndex: 0,
    explanation: "Fitre, Ramazan Bayramı namazından önce verilir.",
    source: "Diyanet İlmihal, Fıtır Sadakası",
  },

  // —— Dini kavramlar (20) ——
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Kelime-i tevhid ne demektir?",
    options: [
      "Lâ ilâhe illallah",
      "Allahu ekber yalnız",
      "Sübhânallah yalnız",
      "Elhamdülillah yalnız",
    ],
    correctIndex: 0,
    explanation: "Kelime-i tevhid, Allah'tan başka ilah olmadığını bildirir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Sünnet ne demektir?",
    options: [
      "Hz. Peygamber'in söz, fiil ve takrirleri",
      "Yalnızca yerel âdet",
      "Yalnızca şiir",
      "Yalnızca ticaret kuralı",
    ],
    correctIndex: 0,
    explanation: "Sünnet, Hz. Peygamber'in söz, fiil ve onaylarıdır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Farz ile sünnet arasındaki temel fark nedir?",
    options: [
      "Farz kesin gerekli, sünnet Peygamber uygulamasıdır",
      "İkisi tamamen aynıdır",
      "Sünnet kesin yasaktır",
      "Farz nafiledir",
    ],
    correctIndex: 0,
    explanation: "Farz kesin bağlayıcıdır; sünnet Hz. Peygamber'in uygulamasıdır.",
    source: "Diyanet İlmihal",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Vâcip Hanefi fıkıhta neye yakındır?",
    options: [
      "Farz ile sünnet arasında, bağlayıcı hükme",
      "Haramın aynısı",
      "Mekruhun aynısı",
      "Mübahın aynısı",
    ],
    correctIndex: 0,
    explanation: "Hanefi usulde vâcip, farza yakın bağlayıcı hükümdür.",
    source: "Diyanet İlmihal",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Serbest bırakılan fiile fıkıhta ne denir?",
    options: ["Mübah", "Haram", "Farz", "Şirk"],
    correctIndex: 0,
    explanation: "Mübah, yapılması da yapılmaması da serbest olan fiildir.",
    source: "Diyanet İlmihal",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Günahtan pişman olup Allah'a yönelmeye ne denir?",
    options: ["Tövbe", "İsraf", "Riya", "Gıybet"],
    correctIndex: 0,
    explanation: "Tövbe, günahtan dönüp Allah'a yönelmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Allah'ı dil ve kalple anmaya ne ad verilir?",
    options: ["Zikir", "Gıybet", "İftira", "İsraf"],
    correctIndex: 0,
    explanation: "Zikir, Allah'ı anmaktır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Allah'tan istemek ve O'na niyaz etmeye ne denir?",
    options: ["Dua", "Gıybet", "Riya", "İsraf"],
    correctIndex: 0,
    explanation: "Dua, Allah'a niyaz ve istemektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Helal lokma neden önemsenir?",
    options: [
      "İbadet ve ahlakı beslediği için",
      "Yasaklandığı için",
      "Günah olduğu için",
      "Namazı bozduğu için",
    ],
    correctIndex: 0,
    explanation: "Helal kazanç, ibadet ve ahlak için temel sayılır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Hüsn-i zan ne demektir?",
    options: [
      "İnsanlar hakkında iyi düşünmek",
      "Sürekli kötü zan beslemek",
      "Gıybet etmek",
      "İftira atmak",
    ],
    correctIndex: 0,
    explanation: "Hüsn-i zan, mümin hakkında iyi düşünmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Sıla-i rahim ne demektir?",
    options: [
      "Akrabalık bağlarını gözetmek",
      "Akrabayı kesmek",
      "Komşuyu incitmek",
      "Sadakayı terk etmek",
    ],
    correctIndex: 0,
    explanation: "Sıla-i rahim, akraba ile ilişkiyi sürdürmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "Fıtrat kavramı neyi ifade eder?",
    options: [
      "İnsanın yaratılıştan gelen temiz eğilimi",
      "Yalnızca günah",
      "Yalnızca ceza",
      "Yalnızca savaş",
    ],
    correctIndex: 0,
    explanation: "Fıtrat, insanın yaratılışındaki aslî temiz yöneliştir.",
    source: "TDV İslam Ansiklopedisi, Fıtrat",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "İstiğfar ne demektir?",
    options: [
      "Allah'tan bağışlanma dilemek",
      "Şükür terk etmek",
      "Oruç bozmak",
      "Namazı kısaltmak",
    ],
    correctIndex: 0,
    explanation: "İstiğfar, bağışlanma istemektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "Taklîd fıkıhta ne demektir?",
    options: [
      "Bir müçtehidi delilsiz izlemek",
      "İctihad yapmak",
      "Ayet uydurmak",
      "Namazı iptal etmek",
    ],
    correctIndex: 0,
    explanation: "Taklîd, müçtehidin görüşünü delil araştırmadan izlemektir.",
    source: "TDV İslam Ansiklopedisi, Taklîd",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "İctihad ne demektir?",
    options: [
      "Şer'î hüküm çıkarmak için gayret göstermek",
      "Hadis uydurmak",
      "İbadeti terk etmek",
      "Şirk koşmak",
    ],
    correctIndex: 0,
    explanation: "İctihad, delillerden hüküm çıkarma çabasıdır.",
    source: "TDV İslam Ansiklopedisi, İctihad",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "Makâsıdü'ş-şerîa neyi ifade eder?",
    options: [
      "Şeriatın gözettiği temel amaçları",
      "Yalnızca dilbilgisi kurallarını",
      "Yalnızca savaş taktiklerini",
      "Yalnızca ticaret fiyatlarını",
    ],
    correctIndex: 0,
    explanation: "Makâsıd, şeriatın koruduğu temel amaçlardır.",
    source: "TDV İslam Ansiklopedisi, Makâsıdü'ş-şerîa",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Salavat getirmek ne demektir?",
    options: [
      "Hz. Peygamber'e salât ve selam okumak",
      "Oruç bozmak",
      "Zekât hesaplamak",
      "Hac menasikini iptal etmek",
    ],
    correctIndex: 0,
    explanation: "Salavat, Hz. Peygamber'e salât ü selam getirmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 2,
    question: "Emr-i bi'l-ma'rûf ne demektir?",
    options: [
      "İyiliği emretmek",
      "Kötülüğü övmek",
      "Gıybet etmek",
      "İsraf etmek",
    ],
    correctIndex: 0,
    explanation: "Emr-i bi'l-ma'rûf, iyiliği öğütlemek ve emretmektir.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 3,
    question: "Nehy-i ani'l-münker ne demektir?",
    options: [
      "Kötülükten sakındırmak",
      "Kötülüğü yaymak",
      "İyiliği yasaklamak",
      "Namazı kaldırmak",
    ],
    correctIndex: 0,
    explanation: "Nehy-i ani'l-münker, kötülükten alıkoymaktır.",
    source: "Diyanet Temel Dini Bilgiler",
  },
  {
    category: "Dini kavramlar",
    difficulty: 1,
    question: "Âmin demek namazda neyi ifade eder?",
    options: [
      "Duanın kabulünü dileme",
      "Namazı bozma",
      "Abdesti bozma",
      "Orucu açma",
    ],
    correctIndex: 0,
    explanation: "Âmin, 'kabul eyle' anlamında dua pekiştirmesidir.",
    source: "Diyanet İlmihal, Namaz",
  },
];

/**
 * Hedef: çoğunluk orta, biraz kolay, az zor.
 * 120 soru → ~45 kolay (1), ~60 orta (2), ~15 zor (3)
 * Kategori başına: 7 kolay + 10 orta + 3 zor
 */
function rebalanceDifficulties(items) {
  const perCategory = {
    1: 7,
    2: 10,
    3: 3,
  };
  const grouped = Object.fromEntries(CATEGORIES.map((c) => [c, []]));
  for (const item of items) grouped[item.category].push(item);

  const out = [];
  for (const category of CATEGORIES) {
    const list = grouped[category];
    if (list.length !== 20) {
      throw new Error(`Category ${category} has ${list.length}, expected 20`);
    }
    // Mevcut zorluk sırasına göre sırala; sonra hedef kotaya göre yeniden etiketle.
    list.sort((a, b) => a.difficulty - b.difficulty || a.question.localeCompare(b.question, "tr"));
    let cursor = 0;
    for (const difficulty of [1, 2, 3]) {
      const count = perCategory[difficulty];
      for (let i = 0; i < count; i += 1) {
        const item = { ...list[cursor], difficulty };
        out.push(item);
        cursor += 1;
      }
    }
  }
  return out;
}

function main() {
  if (NEW_QUESTIONS.length !== 120) {
    throw new Error(`Expected 120 questions, got ${NEW_QUESTIONS.length}`);
  }

  const balanced = rebalanceDifficulties(NEW_QUESTIONS);

  const outPath = path.join(__dirname, "..", "data", "islamic_quiz_questions.json");
  const existing = JSON.parse(fs.readFileSync(outPath, "utf8"));
  if (!Array.isArray(existing) || existing.length !== 380) {
    throw new Error(`Expected existing bank of 380, got ${existing.length}`);
  }

  const seen = new Set(
    existing.map((q) =>
      String(q.question).toLocaleLowerCase("tr-TR").replace(/\s+/g, " ").trim(),
    ),
  );

  const byCat = Object.fromEntries(CATEGORIES.map((c) => [c, 0]));
  const byDiff = { 1: 0, 2: 0, 3: 0 };
  const appended = [];

  for (let i = 0; i < balanced.length; i += 1) {
    const item = balanced[i];
    const normalized = item.question
      .toLocaleLowerCase("tr-TR")
      .replace(/\s+/g, " ")
      .trim();
    if (seen.has(normalized)) {
      throw new Error(`Duplicate question: ${item.question}`);
    }
    if (!CATEGORIES.includes(item.category)) {
      throw new Error(`Bad category: ${item.category}`);
    }
    if (![1, 2, 3].includes(item.difficulty)) {
      throw new Error(`Bad difficulty: ${item.question}`);
    }
    if (!Array.isArray(item.options) || item.options.length !== 4) {
      throw new Error(`Bad options: ${item.question}`);
    }
    if (new Set(item.options.map((o) => o.trim())).size !== 4) {
      throw new Error(`Non-unique options: ${item.question}`);
    }
    if (
      !Number.isInteger(item.correctIndex) ||
      item.correctIndex < 0 ||
      item.correctIndex > 3
    ) {
      throw new Error(`Bad correctIndex: ${item.question}`);
    }
    if (!item.explanation || item.explanation.trim().length < 8) {
      throw new Error(`Bad explanation: ${item.question}`);
    }
    if (!item.source || item.source.trim().length < 4) {
      throw new Error(`Bad source: ${item.question}`);
    }

    seen.add(normalized);
    byCat[item.category] += 1;
    byDiff[item.difficulty] += 1;
    appended.push({
      id: `iq_${String(381 + i).padStart(3, "0")}`,
      category: item.category,
      difficulty: item.difficulty,
      question: item.question,
      options: item.options,
      correctIndex: item.correctIndex,
      explanation: item.explanation,
      source: item.source,
    });
  }

  for (const c of CATEGORIES) {
    if (byCat[c] !== 20) {
      throw new Error(`Category ${c} has ${byCat[c]}, expected 20`);
    }
  }

  const merged = existing.concat(appended);
  if (merged.length !== 500) {
    throw new Error(`Merged length ${merged.length}, expected 500`);
  }

  fs.writeFileSync(outPath, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
  console.log("Appended 120 questions. Total:", merged.length);
  console.log("New by category:", byCat);
  console.log("New by difficulty:", byDiff);
}

main();
