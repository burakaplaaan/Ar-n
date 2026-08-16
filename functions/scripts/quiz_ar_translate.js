/**
 * Turkish → Arabic translator for Hilal Düellosu question bank.
 * Pattern-first for formulaic items; glossary + phrase composition for the rest.
 */
"use strict";

function norm(raw) {
  return String(raw || "")
    .toLocaleLowerCase("tr-TR")
    .replace(/[âáā]/g, "a")
    .replace(/[îíī]/g, "i")
    .replace(/[ûúū]/g, "u")
    .replace(/[êé]/g, "e")
    .replace(/[''′`ʼ]/g, "'")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .replace(/[.,;:!?؟]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const CATEGORY_AR = Object.freeze({
  "Kur'an bilgisi": "معرفة القرآن",
  Siyer: "السيرة النبوية",
  "Peygamberler tarihi": "تاريخ الأنبياء",
  "İslam tarihi": "التاريخ الإسلامي",
  "İbadet ve temel dini bilgiler": "العبادات والعلوم الشرعية",
  "Dini kavramlar": "المفاهيم الدينية",
});

/** Longest-first phrase / name / term map. Keys are normalized. */
const LEX = (() => {
  const rows = [
    // Sources / institutions
    ["diyanet isleri baskanligi", "رئاسة الشؤون الدينية"],
    ["diyanet temel dini bilgiler", "رئاسة الشؤون الدينية: المعلومات الدينية الأساسية"],
    ["diyanet kur'an yolu", "رئاسة الشؤون الدينية: طريق القرآن"],
    ["diyanet siyer-i nebi / islam tarihi", "رئاسة الشؤون الدينية: السيرة والتاريخ الإسلامي"],
    ["diyanet siyer bilgileri", "رئاسة الشؤون الدينية: السيرة النبوية"],
    ["diyanet islam tarihi", "رئاسة الشؤون الدينية: التاريخ الإسلامي"],
    ["diyanet mushaf (hafs)", "مصحف رئاسة الشؤون الدينية (حفص)"],
    ["diyanet ilmihal", "رئاسة الشؤون الدينية: الفقه العملي"],
    ["tdv islam ansiklopedisi", "موسوعة وقف الديانة التركي"],
    ["diyanet", "رئاسة الشؤون الدينية"],

    // Surahs (all 114 + common variants)
    ["fatiha", "الفاتحة"], ["bakara", "البقرة"], ["al-i imran", "آل عمران"],
    ["al-i imran", "آل عمران"], ["ali imran", "آل عمران"], ["nisa", "النساء"],
    ["maide", "المائدة"], ["en'am", "الأنعام"], ["enam", "الأنعام"],
    ["a'raf", "الأعراف"], ["araf", "الأعراف"], ["enfal", "الأنفال"],
    ["tevbe", "التوبة"], ["berae", "التوبة"], ["yunus", "يونس"],
    ["hud", "هود"], ["yusuf", "يوسف"], ["ra'd", "الرعد"], ["rad", "الرعد"],
    ["ibrahim", "إبراهيم"], ["hicr", "الحجر"], ["nahl", "النحل"],
    ["isra", "الإسراء"], ["kehf", "الكهف"], ["meryem", "مريم"],
    ["taha", "طه"], ["enbiya", "الأنبياء"], ["hac", "الحج"],
    ["mu'minun", "المؤمنون"], ["muminun", "المؤمنون"], ["nur", "النور"],
    ["furkan", "الفرقان"], ["suara", "الشعراء"], ["neml", "النمل"],
    ["kasas", "القصص"], ["ankebut", "العنكبوت"], ["rum", "الروم"],
    ["lokman", "لقمان"], ["secde", "السجدة"], ["ahzab", "الأحزاب"],
    ["sebe'", "سبأ"], ["sebe", "سبأ"], ["fatir", "فاطر"],
    ["yasin", "يس"], ["saffat", "الصافات"], ["sad", "ص"],
    ["zumer", "الزمر"], ["mu'min", "غافر"], ["mumin", "غافر"],
    ["fussilet", "فصلت"], ["sura", "الشورى"], ["zuhruf", "الزخرف"],
    ["duhan", "الدخان"], ["casiye", "الجاثية"], ["ahkaf", "الأحقاف"],
    ["muhammed", "محمد"], ["fetih", "الفتح"], ["feth", "الفتح"],
    ["hucurat", "الحجرات"], ["kaf", "ق"], ["zariyat", "الذاريات"],
    ["tur", "الطور"], ["necm", "النجم"], ["kamer", "القمر"],
    ["rahman", "الرحمن"], ["vakia", "الواقعة"], ["hadid", "الحديد"],
    ["mucadele", "المجادلة"], ["hasr", "الحشر"], ["mumtehine", "الممتحنة"],
    ["saff", "الصف"], ["cuma", "الجمعة"], ["munafikun", "المنافقون"],
    ["tegabun", "التغابن"], ["talak", "الطلاق"], ["tahrim", "التحريم"],
    ["mulk", "الملك"], ["kalem", "القلم"], ["hakka", "الحاقة"],
    ["mearic", "المعارج"], ["nuh", "نوح"], ["cin", "الجن"],
    ["muzzemmil", "المزمل"], ["muddessir", "المدثر"], ["kiyame", "القيامة"],
    ["insan", "الإنسان"], ["murselat", "المرسلات"], ["nebe", "النبأ"],
    ["naziat", "النازعات"], ["abese", "عبس"], ["tekvir", "التكوير"],
    ["infitar", "الانفطار"], ["mutaffifin", "المطففين"], ["insikak", "الانشقاق"],
    ["buruc", "البروج"], ["tarik", "الطارق"], ["a'la", "الأعلى"],
    ["ala", "الأعلى"], ["gasiye", "الغاشية"], ["fecr", "الفجر"],
    ["beled", "البلد"], ["sems", "الشمس"], ["leyl", "الليل"],
    ["duha", "الضحى"], ["insirah", "الشرح"], ["insirah", "الشرح"],
    ["tin", "التين"], ["alak", "العلق"], ["kadr", "القدر"],
    ["beyyine", "البينة"], ["zilzal", "الزلزلة"], ["adiyat", "العاديات"],
    ["karia", "القارعة"], ["tekasur", "التكاثر"], ["asr", "العصر"],
    ["humeze", "الهمزة"], ["fil", "الفيل"], ["kureys", "قريش"],
    ["maun", "الماعون"], ["kevser", "الكوثر"], ["kafirun", "الكافرون"],
    ["nasr", "النصر"], ["tebbet", "المسد"], ["ihlas", "الإخلاص"],
    ["felak", "الفلق"], ["nas", "الناس"], ["amme", "النبأ"],

    // Prophets / people
    ["hz peygamber", "النبي"], ["hz muhammed", "النبي محمد"],
    ["efendimiz", "نبينا"], ["peygamber", "النبي"],
    ["hz adem", "النبي آدم"], ["adem", "آدم"],
    ["hz nuh", "النبي نوح"], ["hz ibrahim", "النبي إبراهيم"],
    ["hz ismail", "النبي إسماعيل"], ["hz ishak", "النبي إسحاق"],
    ["hz yakub", "النبي يعقوب"], ["ya'kub", "يعقوب"], ["yakub", "يعقوب"],
    ["hz yusuf", "النبي يوسف"], ["hz musa", "النبي موسى"], ["musa", "موسى"],
    ["hz harun", "النبي هارون"], ["harun", "هارون"],
    ["hz davud", "النبي داود"], ["davud", "داود"],
    ["hz suleyman", "النبي سليمان"], ["suleyman", "سليمان"],
    ["hz eyyub", "النبي أيوب"], ["eyyub", "أيوب"],
    ["hz yunus", "النبي يونس"], ["hz isa", "النبي عيسى"], ["isa", "عيسى"],
    ["hz yahya", "النبي يحيى"], ["yahya", "يحيى"],
    ["hz zekeriya", "النبي زكريا"], ["zekeriya", "زكريا"],
    ["hz idris", "النبي إدريس"], ["idris", "إدريس"],
    ["hz ilyas", "النبي إلياس"], ["ilyas", "إلياس"],
    ["hz lut", "النبي لوط"], ["lut", "لوط"],
    ["hz salih", "النبي صالح"], ["salih", "صالح"],
    ["hz suayb", "النبي شعيب"], ["suayb", "شعيب"],
    ["hz hud", "النبي هود"], ["hz zulkifl", "النبي ذو الكفل"],
    ["hz meryem", "مريم"], ["hz asiye", "آسية"], ["asiye", "آسية"],
    ["hz havva", "حواء"], ["hz hacer", "هاجر"], ["hz sare", "سارة"],
    ["hz ebu bekir", "أبو بكر"], ["ebu bekir", "أبو بكر"], ["ebu bekir", "أبو بكر"],
    ["hz omer", "عمر بن الخطاب"], ["omer", "عمر"], ["omer b hattab", "عمر بن الخطاب"],
    ["hz osman", "عثمان بن عفان"], ["osman", "عثمان"],
    ["hz ali", "علي بن أبي طالب"], ["ali", "علي"],
    ["hz hatice", "خديجة"], ["hatice", "خديجة"],
    ["hz aise", "عائشة"], ["aise", "عائشة"],
    ["hz fatima", "فاطمة"], ["fatima", "فاطمة"],
    ["hz hamza", "حمزة"], ["hamza", "حمزة"],
    ["hz amine", "آمنة"], ["amine", "آمنة"],
    ["halime", "حليمة"], ["halime", "حليمة"],
    ["abdullah", "عبد الله"], ["abdulmuttalib", "عبد المطلب"],
    ["ebu talib", "أبو طالب"], ["ebu leheb", "أبو لهب"],
    ["ebu cehil", "أبو جهل"], ["bilal-i habesi", "بلال الحبشي"],
    ["bilal", "بلال"], ["selman-i farisi", "سلمان الفارسي"],
    ["selman", "سلمان"], ["zeyd b harise", "زيد بن حارثة"],
    ["zeyd", "زيد"], ["hafsa", "حفصة"], ["sevde", "سودة"],
    ["ummu seleme", "أم سلمة"], ["ummu cemil", "أم جميل"],
    ["sumeyye", "سمية"], ["hind", "هند"], ["reyhane", "ريحانة"],
    ["hasan", "الحسن"], ["huseyin", "الحسين"],
    ["ebu eyyub el-ensari", "أبو أيوب الأنصاري"],
    ["ebu hanife", "أبو حنيفة"], ["ebu yusuf", "أبو يوسف"],
    ["ebu zer", "أبو ذر"], ["imam malik", "الإمام مالك"],
    ["malik b enes", "مالك بن أنس"], ["malik", "مالك"],
    ["imam safii", "الإمام الشافعي"], ["safii", "الشافعي"],
    ["ahmed b hanbel", "أحمد بن حنبل"], ["hanbeli", "الحنبلي"],
    ["hanefi", "الحنفي"], ["maliki", "المالكي"],
    ["imam buhari", "الإمام البخاري"], ["buhari", "البخاري"],
    ["imam muslim", "الإمام مسلم"], ["muslim", "مسلم"],
    ["imam tirmizi", "الإمام الترمذي"], ["imam nesai", "الإمام النسائي"],
    ["gazali", "الغزالي"], ["ihya", "الإحياء"],
    ["ihyau ulumiddin", "إحياء علوم الدين"],
    ["ibn sina", "ابن سينا"], ["farabi", "الفارابي"], ["kindi", "الكندي"],
    ["taberi", "الطبري"], ["nizamulmulk", "نظام الملك"],
    ["alparslan", "ألب أرسلان"], ["fatih sultan mehmet", "السلطان محمد الفاتح"],
    ["fatih", "الفاتح"], ["yavuz sultan selim", "سليم الأول"],
    ["yavuz", "سليم الأول"], ["kanuni sultan suleyman", "سليمان القانوني"],
    ["kanuni", "القانوني"], ["osman gazi", "عثمان غازي"],
    ["osman bey", "عثمان بك"], ["orhan gazi", "أورخان غازي"],
    ["ii abdulhamid", "عبد الحميد الثاني"], ["i abdurrahman", "عبد الرحمن الداخل"],
    ["i murad", "مراد الأول"], ["ii hakem", "الحكم الثاني"],
    ["tarik b ziyad", "طارق بن زياد"], ["musa b nusayr", "موسى بن نصير"],
    ["muaviye", "معاوية"], ["yezid", "يزيد"], ["mervan", "مروان"],
    ["harun resid", "هارون الرشيد"], ["mansur", "المنصور"],
    ["me'mun", "المأمون"], ["memun", "المأمون"],
    ["mutevekkil", "المتوكل"], ["seffah", "السفاح"],
    ["ebu'l-abbas es-saffah", "أبو العباس السفاح"],
    ["timur", "تيمور"], ["selim i", "سليم الأول"],
    ["suleyman i", "سليمان القانوني"],
    ["cebrail", "جبريل"], ["mikail", "ميكائيل"], ["israfil", "إسرافيل"],
    ["azrail", "عزرائيل"], ["iblis", "إبليس"],
    ["necasi", "النجاشي"], ["kayser", "قيصر"], ["kisra", "كسرى"],
    ["mukavkis", "المقوقس"], ["seyma", "الشيماء"],
    ["utbe", "عتبة"], ["velid", "الوليد"], ["talha", "طلحة"],
    ["zubeyr", "الزبير"], ["sa'd", "سعد"], ["suheyb", "صهيب"],
    ["abbas", "العباس"], ["zeyneb", "زينب"], ["zeynep", "زينب"],
    ["evzai", "الأوزاعي"],

    // Places
    ["mekke", "مكة"], ["medine", "المدينة"], ["yesrib", "يثرب"],
    ["taif", "الطائف"], ["kudus", "القدس"], ["sam", "الشام"],
    ["bagdat", "بغداد"], ["kahire", "القاهرة"], ["kurtuba", "قرطبة"],
    ["endulus", "الأندلس"], ["iber yarimadasi", "شبه الجزيرة الإيبيرية"],
    ["hira magarasi", "غار حراء"], ["hira", "حراء"],
    ["sevr magarasi", "غار ثور"], ["sevr", "ثور"],
    ["kuba mescidi", "مسجد قباء"], ["kuba", "قباء"],
    ["mescid-i nebevi", "المسجد النبوي"], ["mescid-i aksa", "المسجد الأقصى"],
    ["mescid-i haram", "المسجد الحرام"], ["kabe", "الكعبة"],
    ["arafat", "عرفات"], ["mina", "منى"], ["muzdelife", "المزدلفة"],
    ["bedir", "بدر"], ["uhud", "أحد"], ["hendek", "الخندق"],
    ["hudeybiye", "الحديبية"], ["hayber", "خيبر"], ["huneyn", "حنين"],
    ["mute", "مؤتة"], ["tebuk", "تبوك"], ["ci'rane", "الجعرانة"],
    ["kerbela", "كربلاء"], ["siffin", "صفين"], ["cemel", "الجمل"],
    ["yemame", "اليمامة"], ["kadisiye", "القادسية"], ["nihavend", "نهاوند"],
    ["ayniclut", "عين جالوت"], ["malazgirt", "ملاذكرد"],
    ["istanbul", "إسطنبول"], ["bursa", "بورصة"], ["kufe", "الكوفة"],
    ["basra", "البصرة"], ["buhara", "بخارى"], ["granada", "غرناطة"],
    ["sevilla", "إشبيلية"], ["valensiya", "بلنسية"], ["sana", "صنعاء"],
    ["petra", "البتراء"], ["nineve", "نينوى"], ["sina", "سيناء"],
    ["cudi", "الجودي"], ["eyup sultan", "أبي أيوب"],
    ["sultanahmet", "السلطان أحمد"], ["canakkale", "جناق قلعة"],
    ["akdeniz", "البحر المتوسط"], ["karadeniz", "البحر الأسود"],
    ["kizildeniz", "البحر الأحمر"], ["hazar denizi", "بحر قزوين"],
    ["medyen", "مدين"], ["eyke", "الأيكة"], ["semud", "ثمود"],
    ["ad kavmi", "قوم عاد"], ["ad", "عاد"], ["nuh kavmi", "قوم نوح"],
    ["lut kavmi", "قوم لوط"], ["beni sa'd", "بنو سعد"],
    ["evs", "الأوس"], ["hazrec", "الخزرج"], ["sakif", "ثقيف"],
    ["habeşistan", "الحبشة"], ["iran", "إيران"], ["misir", "مصر"],
    ["bizans", "البيزنطيون"], ["sasaniler", "الساسانيون"],
    ["sasani", "الساساني"], ["mogol", "المغول"], ["mogollar", "المغول"],
    ["haclilar", "الصليبيون"], ["hacli", "الصليبي"],

    // Core Islamic terms
    ["kur'an-i kerim", "القرآن الكريم"], ["kur'an", "القرآن"],
    ["mushaf", "المصحف"], ["ayet", "آية"], ["ayetler", "آيات"],
    ["sure", "سورة"], ["sureler", "سور"], ["sureden", "سورة"],
    ["cuz", "جزء"], ["besmele", "البسملة"], ["euzu-besmele", "الاستعاذة والبسملة"],
    ["bismillahirrahmanirrahim", "بسم الله الرحمن الرحيم"],
    ["ayetul-kursi", "آية الكرسي"], ["muavvizeteyn", "المعوذتان"],
    ["sebu'l-mesani", "السبع المثاني"], ["sebu tival", "السبع الطوال"],
    ["tival", "الطوال"], ["mesani", "المثاني"], ["mufassal", "المفصل"],
    ["havamiim", "الحواميم"], ["kalbu'l-kur'an", "قلب القرآن"],
    ["arusu'l-kur'an", "عروس القرآن"], ["seyyidu'l-kur'an", "سيد القرآن"],
    ["ummu'l-kitab", "أم الكتاب"], ["furkan", "الفرقان"],
    ["levh-i mahfuz", "اللوح المحفوظ"], ["gayb", "الغيب"],
    ["mutesabih", "المتشابه"], ["muhkem", "المحكم"],
    ["esbab-i nuzul", "أسباب النزول"], ["nesh", "النسخ"], ["nesih", "النسخ"],
    ["kiraat", "القراءة"], ["tefsir", "التفسير"], ["hadis", "الحديث"],
    ["siyer", "السيرة"], ["fikih", "الفقه"], ["akaid", "العقيدة"],
    ["kelam", "علم الكلام"], ["tasavvuf", "التصوف"],
    ["suhuf", "الصحف"], ["tevrat", "التوراة"], ["zebur", "الزبور"],
    ["incil", "الإنجيل"], ["vahiy", "الوحي"],
    ["tevhid", "التوحيد"], ["sirk", "الشرك"], ["iman", "الإيمان"],
    ["islam", "الإسلام"], ["ihsan", "الإحسان"], ["takva", "التقوى"],
    ["tevekkul", "التوكل"], ["sabir", "الصبر"], ["zikir", "الذكر"],
    ["dua", "الدعاء"], ["tobe", "التوبة"], ["tevbe", "التوبة"],
    ["helal", "الحلال"], ["haram", "الحرام"], ["mekruh", "المكروه"],
    ["mubah", "المباح"], ["farz", "الفرض"], ["vacip", "الواجب"],
    ["nafile", "النافلة"], ["sunnet", "السنة"],
    ["farz-i ayn", "فرض العين"], ["farz-i kifaye", "فرض الكفاية"],
    ["sunnet-i muekkede", "السنة المؤكدة"],
    ["abdest", "الوضوء"], ["gusul", "الغسل"], ["teyemmum", "التيمم"],
    ["namaz", "الصلاة"], ["salat", "الصلاة"], ["oruc", "الصوم"],
    ["zekat", "الزكاة"], ["hac", "الحج"], ["umre", "العمرة"],
    ["ezan", "الأذان"], ["kible", "القبلة"], ["secde", "السجدة"],
    ["ruku", "الركوع"], ["kiyam", "القيام"], ["tahiyyat", "التحيات"],
    ["vitir", "الوتر"], ["teravih", "التراويح"], ["kusuf namazi", "صلاة الكسوف"],
    ["cenaze namazi", "صلاة الجنازة"], ["bayram namazi", "صلاة العيد"],
    ["cuma", "الجمعة"], ["fitir sadakasi", "صدقة الفطر"],
    ["itikaf", "الاعتكاف"], ["ihram", "الإحرام"], ["tavaf", "الطواف"],
    ["sa'y", "السعي"], ["vakfe", "الوقوف"], ["remy", "رمي الجمرات"],
    ["telbiye", "التلبية"], ["kurban", "الأضحية"],
    ["ramazan", "رمضان"], ["ramazan bayrami", "عيد الفطر"],
    ["kurban bayrami", "عيد الأضحى"], ["muharrem", "المحرم"],
    ["receb", "رجب"], ["saban", "شعبان"], ["sevval", "شوال"],
    ["zilhicce", "ذو الحجة"], ["asure", "عاشوراء"],
    ["regaib", "الرغائب"], ["mevlid", "المولد"], ["mevlit", "المولد"],
    ["imsak", "الإمساك"], ["sahur", "السحور"], ["iftar", "الإفطار"],
    ["nisap", "النصاب"], ["beytulmal", "بيت المال"],
    ["cihad", "الجهاد"], ["gaza", "الغزوة"], ["ganimet", "الغنيمة"],
    ["hicret", "الهجرة"], ["muhacir", "المهاجر"], ["ensar", "الأنصار"],
    ["muahat", "المؤاخاة"], ["sahabe", "الصحابة"], ["sahabi", "الصحابي"],
    ["tabiin", "التابعون"], ["tebeu't-tabiin", "تابعو التابعين"],
    ["ehl-i beyt", "أهل البيت"], ["ehl-i kitap", "أهل الكتاب"],
    ["munafik", "المنافق"], ["kafir", "الكافر"], ["musrik", "المشرك"],
    ["ummet", "الأمة"], ["halife", "الخليفة"],
    ["hulefa-i rasidin", "الخلفاء الراشدون"],
    ["hulefa-yi rasidin", "الخلفاء الراشدون"],
    ["emeviler", "الأمويون"], ["emevi", "الأموي"],
    ["abbasiler", "العباسيون"], ["abbasi", "العباسي"],
    ["osmanli", "العثمانيون"], ["osmanli devleti", "الدولة العثمانية"],
    ["selcuklular", "السلاجقة"], ["selcuklu", "السلجوقي"],
    ["memlukler", "المماليك"], ["safeviler", "الصفويون"],
    ["endulus emevileri", "أمويو الأندلس"],
    ["ridde", "الردة"], ["bid'at", "البدعة"], ["bidat", "البدعة"],
    ["icma", "الإجماع"], ["ictihad", "الاجتهاد"], ["kiyas", "القياس"],
    ["istihsan", "الاستحسان"], ["istidlal", "الاستدلال"],
    ["taklid", "التقليد"], ["sedd-i zeri", "سد الذريعة"],
    ["makasidu's-seria", "مقاصد الشريعة"],
    ["fitrat", "الفطرة"], ["hikmet", "الحكمة"], ["sefaat", "الشفاعة"],
    ["kissa", "القصة"], ["huccet", "الحجة"],
    ["uluhiyet", "الألوهية"], ["rububiyet", "الربوبية"],
    ["ubudiyet", "العبودية"], ["ma'siyet", "المعصية"],
    ["ulu'l-azm", "أولو العزم"], ["havari", "الحواري"],
    ["kiraat", "القراءة"], ["tilavet secdesi", "سجدة التلاوة"],
    ["ashab-i kehf", "أصحاب الكهف"], ["ashab-i suffe", "أهل الصفة"],
    ["darulerkam", "دار الأرقم"], ["darunnedve", "دار الندوة"],
    ["rıdvan biati", "بيعة الرضوان"], ["ridvan biati", "بيعة الرضوان"],
    ["akabe biatlari", "بيعتا العقبة"],
    ["medine sozlesmesi", "صحيفة المدينة"],
    ["veda hacci", "حجة الوداع"], ["veda hutbesi", "خطبة الوداع"],
    ["isra ve mirac", "الإسراء والمعراج"], ["mirac", "المعراج"],
    ["isra", "الإسراء"], ["fil vakasi", "حادثة الفيل"],
    ["boykot", "المقاطعة"], ["mekke'nin fethi", "فتح مكة"],
    ["kuba mescidi", "مسجد قباء"],
    ["ravza-i mutahhara", "الروضة المطهرة"],
    ["la ilahe illallah", "لا إله إلا الله"],
    ["allahu ekber", "الله أكبر"], ["elhamdulillah", "الحمد لله"],
    ["subhanallah", "سبحان الله"], ["esselamu aleykum", "السلام عليكم"],
    ["amin", "آمين"], ["ehad ve samed", "الأحد الصمد"],
    ["rahman ve rahim", "الرحمن الرحيم"],
    ["elif-lam-mim", "الم"], ["kiramen katibin", "الكرام الكاتبون"],
    ["sahih hadis", "الحديث الصحيح"], ["hasen hadis", "الحديث الحسن"],
    ["zayif rivayet", "الرواية الضعيفة"], ["mutevatir hadis", "الحديث المتواتر"],
    ["mursel", "المرسل"], ["mevzu", "الموضوع"],
    ["el-camiu's-sahih", "الجامع الصحيح"], ["el-muvatta", "الموطأ"],
    ["el-musned", "المسند"], ["er-risale", "الرسالة"],
    ["sunen-i ebu davud", "سنن أبي داود"],
    ["el-kanun", "القانون"], ["el-isarat", "الإشارات"],
    ["nizamiye medresesi", "المدرسة النظامية"],
    ["hicaz demiryolu", "سكة حديد الحجاز"],
    ["istanbul'un fethi", "فتح القسطنطينية"],
    ["malazgirt muharebesi", "معركة ملاذكرد"],
    ["preveze", "بريفزا"], ["viyana kusatmasi", "حصار فيينا"],

    // Frequent option / question phrases
    ["yalnizca", "فقط"], ["sadece", "فقط"], ["degil ifadesi yanlis", "وهذا القول غير صحيح"],
    ["zorunlu degil ifadesi yanlis", "والقول إنه غير واجب غير صحيح"],
    ["her yolculukta zorunlu degil ifadesi yanlis", "والقول إنه غير واجب في كل سفر غير صحيح"],
    ["allah'a ortak kosmak", "الإشراك بالله"],
    ["allah'in birligi inanci", "الإيمان بوحدانية الله"],
    ["allah'in birligi", "وحدانية الله"],
    ["kalben tasdik etmek", "التصديق بالقلب"],
    ["teslim olmak", "الاستسلام"], ["putperestlik", "الوثنية"],
    ["cok tanricilik", "تعدد الآلهة"], ["soy ustunlugu", "التفاخر بالنسب"],
    ["dinen izin verilen", "المأذون به شرعاً"],
    ["dinen yasak olan", "المحرّم شرعاً"],
    ["dinen yasaklanan", "ما حرّمه الدين"],
    ["yapilmasi hos gorulmeyen", "ما يُكره فعله"],
    ["yapilmasi kesin emredilen", "ما أُمر به قطعاً"],
    ["yapilmasi serbest olan", "ما أبيح فعله"],
    ["yapilmasi yasak olan", "ما نُهي عن فعله"],
    ["bes vakit namaz", "الصلوات الخمس"],
    ["gucu yeten muslumanlara", "على المسلمين المستطيعين"],
    ["nisap sahibi muslumanlara", "على المسلمين الذين بلغوا النصاب"],
    ["cunupluk ve benzeri hallerde", "عند الجنابة ونحوها"],
    ["su bulunamadiginda veya kullanilamadiginda", "عند فقد الماء أو تعذّر استعماله"],
    ["vaktinde kilinamayan namazin sonradan kilinmasi", "قضاء الصلاة التي فات وقتها"],
    ["birinin ardindan hoslanmayacagi soz soylemek", "ذكر المرء بما يكره في غيابه"],
    ["dinde sonradan uydurulan eklemeler bahsini", "ما أُحدث في الدين مما ليس منه"],
    ["allah'tan baska ilah olmadigina ve hz muhammed'in peygamberligine sahitlik",
      "الشهادة بأنه لا إله إلا الله وأن محمداً رسول الله"],
    ["allah'i goruyormus gibi kulluk", "أن تعبد الله كأنك تراه"],
    ["mescid-i nebevi'de ilim ve ibadetle mesgul yoksul sahabiler",
      "فقراء الصحابة المشتغلون بالعلم والعبادة في المسجد النبوي"],
    ["mescid-i nebevi'de ilimle mesgul sahabiler",
      "الصحابة المشتغلون بالعلم في المسجد النبوي"],
    ["islam'in tebliginin hizlanmasi ve fethin yolu acilmasi",
      "تسارع تبليغ الإسلام وفتح طريق الفتح"],
    ["elinin mucizevi bicimde bembeyaz gorunmesi", "بياض يده معجزة"],
    ["rabbinizin hangi nimetlerini yalanliyorsunuz", "فبأي آلاء ربكما تكذبان"],
    ["kadr degil alak", "العلق لا القدر"],
    ["ilk insan ve peygamber", "أول إنسان ونبي"],
    ["dosdogru yol", "الصراط المستقيم"],
    ["hamd allah'adir", "الحمد لله"],
    ["allah en buyuktur", "الله أكبر"],
    ["allah birdir", "الله واحد"],
    ["allah affedicidir", "الله غفور"],
    ["allah rizik verendir", "الله هو الرزاق"],
    ["alni yere koymak", "وضع الجبهة على الأرض"],
    ["abdest almak", "الوضوء"], ["abdest almayı", "الوضوء"],
    ["abdesti bozma", "نقض الوضوء"],
    ["namaz kilmak", "أداء الصلاة"], ["oruc tutmak", "الصيام"],
    ["zekat vermek", "إيتاء الزكاة"], ["hacca gitmek", "أداء الحج"],
    ["selam vermek", "إلقاء السلام"], ["sadaka vermek", "إعطاء الصدقة"],
    ["giybet etmek", "الغيبة"], ["iftira atmak", "الفرية"],
    ["inkar etmek", "الإنكار"], ["alay etmek", "الاستهزاء"],
    ["israf etmek", "الإسراف"], ["komsuyu incitmek", "إيذاء الجار"],
    ["akrabayi kesmek", "قطيعة الرحم"],
    ["akrabalik baglarini gozetmek", "صلة الرحم"],
    ["iyiligi emretmek", "الأمر بالمعروف"],
    ["kotulukten sakindirnak", "النهي عن المنكر"],
    ["can mal ve namus dokunulmazligi", "حرمة الدم والمال والعرض"],
    ["safa ile merve arasinda yuruyus", "السعي بين الصفا والمروة"],
    ["kabe'nin etrafinda donmek", "الطواف حول الكعبة"],
    ["arafat'ta durmak", "الوقوف بعرفة"],
    ["mina'da taslamak", "رمي الجمرات في منى"],
    ["gece yolculugu ve goge yukselis mucizesi", "معجزة الإسراء والمعراج"],
    ["gucukle birlikte kolaylik", "إن مع العسر يسرا"],
    ["her rekatta okunan temel suredir", "السورة الأساسية التي تُقرأ في كل ركعة"],
    ["hicri takvim", "التقويم الهجري"],
    ["devlet hazinesi", "خزانة الدولة"],
    ["dogru sahitlik", "الشهادة الصادقة"],
    ["adaletli sahitlik", "الشهادة العادلة"],
    ["ahiret bilinci", "الوعي بالآخرة"],
    ["putlara tapma", "عبادة الأصنام"],
    ["putlarin yikilmasi", "تحطيم الأصنام"],
    ["deniz in yarilmasi", "انفلاق البحر"],
    ["denizin yarilmasi", "انفلاق البحر"],
    ["besikte konusma", "الكلام في المهد"],
    ["kuyuya atilma", "الإلقاء في الجب"],
    ["baliga yutulma", "الالتقام من الحوت"],
    ["tufan gemisi", "سفينة الطوفان"],
    ["asanin ejderha olmasi", "تحول العصا إلى ثعبان"],
    ["ilk halife", "أول خليفة"], ["ikinci halife", "ثاني خليفة"],
    ["ucuncu halife", "ثالث خليفة"], ["dorduncu halife", "رابع خليفة"],
    ["islam'in sarti", "ركن الإسلام"], ["imanin sarti", "ركن الإيمان"],
    ["bes", "خمسة"], ["alti", "ستة"], ["dort", "أربعة"],
    ["uc", "ثلاثة"], ["iki", "اثنان"], ["yedi", "سبعة"],
    ["sekiz", "ثمانية"], ["on", "عشرة"], ["on iki", "اثنا عشر"],
    ["otuz", "ثلاثون"], ["kirk", "أربعون"], ["yuz", "مئة"],
    ["doksan dokuz", "تسعة وتسعون"], ["yuz on dort", "مئة وأربع عشرة"],
    ["evet", "نعم"], ["hayir", "لا"],
    ["evet temeldir", "نعم، هو أساس"],
    ["iliskisi yoktur", "لا علاقة له بذلك"],
    ["ikisi de farzdir", "كلاهما فرض"],
    ["hic kimseye", "على لا أحد"],
    ["hic okunmaz", "لا تُقرأ أصلاً"],
    ["belirsiz olan", "الأمر المبهم"],
    ["imkansiz olan", "المستحيل"],
    ["gunah", "الذنب"], ["sevap", "الثواب"], ["ceza", "العقاب"],
    ["azap", "العذاب"], ["kibir", "الكبر"], ["riya", "الرياء"],
    ["yalan", "الكذب"], ["emanet", "الأمانة"], ["hıyanet", "الخيانة"],
    ["hirsizlik", "السرقة"], ["gıybet", "الغيبة"], ["iftira", "الفرية"],
    ["israf", "الإسراف"], ["inkar", "الإنكار"], ["alay", "الاستهزاء"],
    ["suphe", "الشك"], ["gaflet", "الغفلة"],
    ["ibadet", "العبادة"], ["ticaret", "التجارة"],
    ["savas", "الحرب"], ["baris", "السلم"],
    ["yolculuk", "السفر"], ["cocuk", "الطفل"],
    ["erkek", "الرجل"], ["kadin", "المرأة"],
    ["gece", "الليل"], ["gunduz", "النهار"],
    ["yil", "سنة"], ["ay", "شهر"], ["gun", "يوم"],
    ["sehir", "مدينة"], ["dag", "جبل"], ["magara", "غار"],
    ["deniz", "بحر"], ["nehir", "نهر"],
    ["ilk", "أول"], ["son", "آخر"], ["en uzun", "أطول"],
    ["en kisa", "أقصر"], ["temel", "أساسي"],
    ["farzdir", "فرض"], ["vaciptir", "واجب"],
    ["haramdir", "حرام"], ["helaldir", "حلال"],
    ["mekke donemi", "العهد المكي"], ["medine donemi", "العهد المدني"],
    ["mekki sureler", "السور المكية"], ["medeni sureler", "السور المدنية"],
    ["hanefi", "الحنفي"], ["arabca", "العربية"], ["arapca", "العربية"],
    ["turkce", "التركية"], ["farsça", "الفارسية"], ["farsça", "الفارسية"],
    ["ibranice", "العبرية"], ["suryanice", "السريانية"], ["latince", "اللاتينية"],
    ["astronomi", "علم الفلك"], ["cografya", "الجغرافيا"],
    ["tip", "الطب"], ["felsefe", "الفلسفة"],
    ["siir", "الشعر"], ["muzik", "الموسيقى"],
    ["avcilik", "الصيد"], ["ciftcilik", "الزراعة"],
    ["denizcilik", "الملاحة"], ["madencilik", "التعدين"],
    ["gemicilik", "الملاحة"], ["tacir", "التاجر"],
    ["ciftci", "المزارع"], ["demirci", "الحدّاد"],
    ["denizci", "البحّار"], ["sair", "الشاعر"],
    ["kahin", "الكاهن"], ["kral", "الملك"],
    ["padişah", "السلطان"], ["padisah", "السلطان"],
    ["vezir", "الوزير"], ["imam", "الإمام"],
    ["alim", "العالم"], ["mufessir", "المفسّر"],
    ["sahih", "صحيح"], ["zayif", "ضعيف"],
    ["uzun", "طويل"], ["kisa", "قصير"],
    ["acilis", "افتتاح"],
  ];

  const map = new Map();
  for (const [tr, ar] of rows) {
    const key = norm(tr);
    if (key && !map.has(key)) map.set(key, ar);
  }
  return map;
})();

const GRAMMAR = new Map(Object.entries({
  kac: "كم",
  kacinci: "كم ترتيبها",
  kactir: "كم عدد",
  hangi: "أي",
  hangisidir: "ما هي",
  hangileridir: "ما هي",
  nedir: "ما هو",
  "ne demektir": "ماذا يعني",
  "ne demek": "ماذا يعني",
  kimdir: "من هو",
  kimlerdir: "من هم",
  nerededir: "أين",
  neresidir: "أين",
  "ne zaman": "متى",
  nasil: "كيف",
  neden: "لماذا",
  nicin: "لماذا",
  midir: "هل",
  mi: "هل",
  ve: "و",
  ile: "مع",
  icin: "لأجل",
  olarak: "بوصفه",
  sonra: "بعد",
  once: "قبل",
  doneminde: "في عهد",
  donemi: "عهد",
  yilinda: "في سنة",
  yilda: "في سنة",
  yilin: "سنة",
  ayidir: "في أي شهر",
  savasi: "معركة",
  gazvesi: "غزوة",
  antlasmasi: "صلح",
  sozlesmesi: "صحيفة",
  devleti: "دولة",
  tarihi: "تاريخ",
  bilgisi: "معرفة",
  kavrami: "مفهوم",
  ifadesi: "عبارة",
  kissasi: "قصة",
  mucizesi: "معجزة",
  suresi: "سورة",
  suresinin: "سورة",
  ayettir: "آية",
  suredir: "سورة",
  siradadir: "في الترتيب",
  siralamasinda: "في الترتيب",
  anilir: "يُذكر",
  anilan: "المذكور",
  gecen: "الوارد",
  yapilir: "يُفعل",
  yapilmistir: "تم",
  olmustur: "وقع",
  gerceklesmistir: "وقع",
  verilir: "يُعطى",
  edilir: "يُفعل",
  ifade: "يعبّر",
  eder: "يفعل",
  adi: "اسمه",
  ad: "اسم",
  biri: "أحد",
  one: "أبرز",
  cikar: "يبرز",
  geleneksel: "تقليدياً",
  olarak: "باعتباره",
  yer: "مكان",
  zaman: "وقت",
  temel: "أساسي",
  dini: "ديني",
  kavramlar: "مفاهيم",
  ibadet: "عبادة",
  namazi: "صلاة",
  farzi: "فرضه",
  sarti: "شرطه",
  halife: "خليفة",
  peygamberlerden: "من الأنبياء",
  peygamberler: "الأنبياء",
  tarihi: "تاريخ",
  islam: "الإسلام",
  ilk: "أول",
  son: "آخر",
  en: "أكثر",
  bir: "واحد",
  bu: "هذا",
  su: "ذلك",
  da: "",
  de: "",
  ki: "",
  ise: "أما",
  veya: "أو",
  ya: "أو",
  hem: "و",
  gibi: "مثل",
  kadar: "حتى",
  gore: "بحسب",
  ait: "خاص بـ",
  aittir: "ينتمي إلى",
  arasinda: "بين",
  icinde: "في",
  ustunde: "على",
  hakkinda: "عن",
  ilgili: "المتعلق بـ",
  yonelik: "باتجاه",
  karsi: "ضد",
  dolayi: "بسبب",
  yuzunden: "بسبب",
  basina: "في بداية",
  sonunda: "في نهايته",
  sirasinda: "أثناء",
  esnasinda: "أثناء",
  sonra: "بعد ذلك",
  once: "قبل ذلك",
  her: "كل",
  hic: "لا",
  daha: "أكثر",
  cok: "كثير",
  az: "قليل",
  buyuk: "كبير",
  kucuk: "صغير",
  yeni: "جديد",
  eski: "قديم",
  dogru: "صحيح",
  yanlis: "خطأ",
  evet: "نعم",
  hayir: "لا",
  kim: "من",
  ne: "ما",
  nerede: "أين",
  nereye: "إلى أين",
  nicin: "لماذا",
  kime: "لمن",
  kimin: "لمن",
  neyi: "ماذا",
  neye: "إلى ماذا",
  nasil: "كيف",
  kac: "كم",
  "hz": "",
}));

function lookup(text) {
  if (text == null) return null;
  const raw = String(text).trim();
  if (!raw) return "";
  if (/^\d+([.,]\d+)?$/.test(raw)) return raw;
  if (/^\d+\s*[-–]\s*\d+/.test(raw) && /yuzyil|yüzyıl|asir/i.test(raw) === false) {
    const simple = raw.match(/^(\d+)\s*[-–]\s*(\d+)\.?\s*(yuzyil|yüzyıl)?/i);
    if (simple && /yuzyil|yüzyıl/i.test(raw)) {
      return `القرن ${simple[1]}–${simple[2]}`;
    }
  }
  const key = norm(raw);
  if (LEX.has(key)) return LEX.get(key);
  const noHz = key.replace(/^hz\s+/, "");
  if (noHz !== key && LEX.has(noHz)) return LEX.get(noHz);
  return null;
}

function replaceLongest(text) {
  const tokens = String(text)
    .replace(/([?؟])/g, " $1")
    .split(/(\s+|\/|,|;|:|\(|\)|\[|\]|"|')/u)
    .filter((t) => t !== "");
  const used = new Array(tokens.length).fill(false);
  const out = [];
  for (let i = 0; i < tokens.length; ) {
    if (used[i] || /^\s+$/.test(tokens[i])) {
      if (!used[i] && /^\s+$/.test(tokens[i])) out.push(" ");
      i += 1;
      continue;
    }
    let matched = null;
    let consume = 1;
    const maxJoin = Math.min(8, tokens.length - i);
    for (let n = maxJoin; n >= 1; n -= 1) {
      const slice = tokens.slice(i, i + n).join("");
      if (/^\s+$/.test(slice) || /^[\/,;:()[\]"']+$/.test(slice)) continue;
      const found = lookup(slice.replace(/\s+/g, " ").trim());
      if (found != null) {
        matched = found;
        consume = n;
        break;
      }
    }
    if (matched != null) {
      out.push(matched);
      i += consume;
      continue;
    }
    const tok = tokens[i];
    const g = GRAMMAR.get(norm(tok));
    if (g != null) out.push(g);
    else if (/^\d+$/.test(tok)) out.push(tok);
    else if (/^[?؟.,!;:]+$/.test(tok)) out.push(tok === "?" ? "؟" : tok);
    else out.push(lookup(tok) || tok);
    i += 1;
  }
  return out.join("").replace(/\s+/g, " ").replace(/\s+؟/g, "؟").trim();
}

function hasArabic(s) {
  return /[\u0600-\u06FF]/.test(String(s || ""));
}

function hasTurkishLetters(s) {
  return /[ğüşıöçĞÜŞİÖÇ]/.test(String(s || ""));
}

function qMark(s) {
  const t = String(s || "").trim().replace(/[?؟]+$/g, "");
  return `${t}؟`;
}

function surahName(raw) {
  const cleaned = String(raw || "")
    .replace(/\s+suresi$/i, "")
    .replace(/^sure\s+/i, "")
    .trim();
  return lookup(cleaned) || replaceLongest(cleaned);
}

function term(raw) {
  const found = lookup(raw);
  if (found != null) return found;
  return replaceLongest(raw);
}

function translateQuestion(tr) {
  const text = String(tr || "").trim();
  const patterns = [
    [/^Mushaf sıralamasında ilk sure hangisidir\?$/i,
      () => "ما أول سورة في ترتيب المصحف؟"],
    [/^Mushaf sıralamasında son sure hangisidir\?$/i,
      () => "ما آخر سورة في ترتيب المصحف؟"],
    [/^Mushaf sıralamasında (\d+)\.\s*sure hangisidir\?$/i,
      (m) => `ما السورة رقم ${m[1]} في ترتيب المصحف؟`],
    [/^(.+?) suresi Mushaf sıralamasında kaçıncı suredir\?$/i,
      (m) => `ما ترتيب سورة ${surahName(m[1])} في المصحف؟`],
    [/^(.+?) suresi mushafta kaçıncı sıradadır\?$/i,
      (m) => `ما ترتيب سورة ${surahName(m[1])} في المصحف؟`],
    [/^(.+?) suresi Diyanet Mushaf'ında kaç ayettir\?$/i,
      (m) => `كم عدد آيات سورة ${surahName(m[1])} في مصحف رئاسة الشؤون الدينية؟`],
    [/^(.+?) suresi kaç ayettir\?$/i,
      (m) => `كم عدد آيات سورة ${surahName(m[1])}؟`],
    [/^Kur'an-ı Kerim kaç sureden oluşur\?$/i,
      () => "من كم سورة يتكون القرآن الكريم؟"],
    [/^Kur'an'ın en uzun suresi hangisidir\?$/i,
      () => "ما أطول سورة في القرآن؟"],
    [/^Kur'an'ın en kısa suresi hangisidir\?$/i,
      () => "ما أقصر سورة في القرآن؟"],
    [/^İslam'ın şartı kaçtır\?$/i, () => "كم عدد أركان الإسلام؟"],
    [/^İmanın şartı kaçtır\?$/i, () => "كم عدد أركان الإيمان؟"],
    [/^Günde farz namaz kaç vakittir\?$/i, () => "كم عدد الصلوات المفروضة في اليوم؟"],
    [/^Oruç hangi ayda farzdır\?$/i, () => "في أي شهر يُفرض الصيام؟"],
    [/^İlk halife kimdir\?$/i, () => "من أول خليفة؟"],
    [/^İkinci halife kimdir\?$/i, () => "من ثاني خليفة؟"],
    [/^Üçüncü halife kimdir\?$/i, () => "من ثالث خليفة؟"],
    [/^Dördüncü halife kimdir\?$/i, () => "من رابع خليفة؟"],
    [/^İlk insan ve peygamber kimdir\?$/i, () => "من أول إنسان ونبي؟"],
    [/^Hz\. Muhammed hangi şehirde doğmuştur\?$/i,
      () => "في أي مدينة وُلد النبي محمد؟"],
    [/^Hicret hangi şehre yapılmıştır\?$/i, () => "إلى أي مدينة كانت الهجرة؟"],
    [/^(.+?) ne demektir\?$/i, (m) => qMark(`ماذا يعني ${term(m[1])}`)],
    [/^(.+?) neye gelir\?$/i, (m) => qMark(`إلى أي معنى يرجع ${term(m[1])}`)],
    [/^(.+?) nedir\?$/i, (m) => qMark(`ما هو ${term(m[1])}`)],
    [/^(.+?) neydi\?$/i, (m) => qMark(`ماذا كان ${term(m[1])}`)],
    [/^(.+?) kimdir\?$/i, (m) => qMark(`من هو ${term(m[1])}`)],
    [/^(.+?) kimlerdir\?$/i, (m) => qMark(`من هم ${term(m[1])}`)],
    [/^(.+?) hangisidir\?$/i, (m) => qMark(`ما هي ${term(m[1])}`)],
    [/^(.+?) hangileridir\?$/i, (m) => qMark(`ما هي ${term(m[1])}`)],
    [/^(.+?) kaçtır\?$/i, (m) => qMark(`كم عدد ${term(m[1])}`)],
    [/^(.+?) nerededir\?$/i, (m) => qMark(`أين ${term(m[1])}`)],
    [/^(.+?) neresidir\?$/i, (m) => qMark(`ما مكان ${term(m[1])}`)],
    [/^(.+?) ne zaman (.+)\?$/i,
      (m) => qMark(`متى ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) hangi yılda (.+)\?$/i,
      (m) => qMark(`في أي عام ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) hangi ayda[dır]?\??$/i,
      (m) => qMark(`في أي شهر يقع ${term(m[1])}`)],
    [/^(.+?) hangi şehirde (.+)\?$/i,
      (m) => qMark(`في أي مدينة ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) hangi peygamberle (.+)\?$/i,
      (m) => qMark(`بأي نبي ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) hangi peygambere aittir\?$/i,
      (m) => qMark(`إلى أي نبي تنتمي ${term(m[1])}`)],
    [/^(.+?) hangi peygamberledir\?$/i,
      (m) => qMark(`بأي نبي تُذكر ${term(m[1])}`)],
    [/^(.+?) kimin döneminde (.+)\?$/i,
      (m) => qMark(`في عهد من ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) kimlere farzdır\?$/i, (m) => qMark(`على من يُفرض ${term(m[1])}`)],
    [/^(.+?) nasıl tarif edilir\?$/i, (m) => qMark(`كيف يُعرَّف ${term(m[1])}`)],
    [/^(.+?) nasıl (.+)\?$/i, (m) => qMark(`كيف ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) neden (.+)\?$/i, (m) => qMark(`لماذا ${term(m[2])} ${term(m[1])}`)],
    [/^(.+?) neyi ifade eder\?$/i, (m) => qMark(`ماذا يعني ${term(m[1])}`)],
    [/^(.+?) neyi vurgular\?$/i, (m) => qMark(`ماذا يؤكّد ${term(m[1])}`)],
    [/^(.+?) neyi bildirir\?$/i, (m) => qMark(`ماذا يبيّن ${term(m[1])}`)],
    [/^(.+?) neyi m[uü]jdele[rş].*$/i, (m) => qMark(`بماذا يبشّر ${term(m[1])}`)],
    [/^(.+?) neyi d[uü]zenlemiştir\?$/i, (m) => qMark(`ماذا نظّم ${term(m[1])}`)],
    [/^(.+?) ne i[cç]in kullan[ıi]lm[ıi]şt[ıi]r\?$/i,
      (m) => qMark(`فيمَ استُعمل ${term(m[1])}`)],
    [/^(.+?) hangi taraflar arasında olmuştur\?$/i,
      (m) => qMark(`بين من وقعت ${term(m[1])}`)],
    [/^(.+?) kimlerle yapılmıştır\?$/i,
      (m) => qMark(`مع من عُقد ${term(m[1])}`)],
    [/^(.+?) hangi olaydan sonra olmuştur\?$/i,
      (m) => qMark(`بعد أي حدث وقعت ${term(m[1])}`)],
    [/^(.+?) hangi d[oö]neme aittir\?$/i,
      (m) => qMark(`إلى أي عهد تنتمي ${term(m[1])}`)],
    [/^(.+?) hangi boydand[ıi]r\?$/i, (m) => qMark(`من أي قبيلة ${term(m[1])}`)],
    [/^(.+?) ad[ıi]n[ıi] hangi k[ıi]ssadan al[ıi]r\?$/i,
      (m) => qMark(`من أي قصة أخذت ${term(m[1])} اسمها؟`).replace(/؟؟$/, "؟")],
  ];

  for (const [re, fn] of patterns) {
    const m = text.match(re);
    if (m) return fn(m);
  }
  return qMark(replaceLongest(text.replace(/[?؟]+$/g, "")));
}

function translateExplanation(tr) {
  const text = String(tr || "").trim();
  const patterns = [
    [/^Kur'an-ı Kerim 114 sureden oluşur\.$/i,
      () => "يتكون القرآن الكريم من 114 سورة."],
    [/^Mushaf'ta ilk sure Fatiha'dır\.$/i,
      () => "أول سورة في المصحف هي الفاتحة."],
    [/^Mushaf'ta son sure Nas'tır\.$/i,
      () => "آخر سورة في المصحف هي الناس."],
    [/^En uzun sure Bakara'dır\.$/i, () => "أطول سورة هي البقرة."],
    [/^(.+?) suresi (\d+) ayettir\.$/i,
      (m) => `سورة ${surahName(m[1])} ${m[2]} آية.`],
    [/^Mushaf sıralamasında (\d+)\.\s*sure (.+?)['']d[ıi]r\.$/i,
      (m) => `السورة رقم ${m[1]} في ترتيب المصحف هي ${surahName(m[2])}.`],
    [/^(.+?) Mushaf sıralamasında (\d+)\.\s*suredir\.$/i,
      (m) => `سورة ${surahName(m[1])} هي السورة رقم ${m[2]} في المصحف.`],
    [/^(.+?) (dır|dir|dur|dür|tır|tir|tur|tür)\.$/i,
      (m) => `${term(m[1])}.`],
  ];
  for (const [re, fn] of patterns) {
    const m = text.match(re);
    if (m) {
      const out = fn(m);
      return /[.。]$/.test(out) ? out : `${out}.`;
    }
  }
  const body = replaceLongest(text.replace(/\.+$/g, ""));
  return /[.。]$/.test(body) ? body : `${body}.`;
}

function translateOption(tr) {
  const raw = String(tr || "").trim();
  if (!raw) return raw;
  if (/^\d+([.,]\d+)?$/.test(raw)) return raw;
  const hicri = raw.match(/^Hicri\s+(\d+)$/i);
  if (hicri) return `${hicri[1]} هـ`;
  const century = raw.match(/^(\d+)\.\s*yüzyıl(?:\s+başı)?$/i);
  if (century) return `القرن ${century[1]}`;
  const rangeCentury = raw.match(/^(\d+)-(\d+)\.\s*yüzyıl$/i);
  if (rangeCentury) return `القرن ${rangeCentury[1]}–${rangeCentury[2]}`;
  const only = raw.match(/^(Yalnızca|Sadece)\s+(.+)$/i);
  if (only) return `فقط ${term(only[2])}`;
  const found = lookup(raw);
  if (found != null) return found;
  return replaceLongest(raw);
}

function translateSource(tr) {
  const raw = String(tr || "").trim();
  if (!raw) return raw;
  const found = lookup(raw);
  if (found != null) return found;
  return replaceLongest(raw)
    .replace(/,\s*/g, "، ")
    .replace(/;\s*/g, "؛ ");
}

function translateItem(item) {
  const options = (item.options || []).map((opt) => translateOption(opt));
  return {
    category: CATEGORY_AR[item.category] || term(item.category),
    question: translateQuestion(item.question),
    options,
    explanation: translateExplanation(item.explanation || ""),
    source: translateSource(item.source || ""),
  };
}

module.exports = {
  CATEGORY_AR,
  lookup,
  term,
  surahName,
  translateQuestion,
  translateExplanation,
  translateOption,
  translateSource,
  translateItem,
  hasArabic,
  hasTurkishLetters,
  norm,
};
