// 114 sure — yerel, anında açılır. Tanzil / mushaf sırası.
// Ayet sayıları toplamı 6236 (Kufî). Ses URL'si bu numaraya dayanır.

import 'quran_models.dart';

abstract final class QuranSurahCatalog {
  static const int ayahTotal = 6236;

  static const String bismillahArabic =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  static QuranSurahMeta byNumber(int number) {
    final i = number.clamp(1, all.length) - 1;
    return all[i];
  }

  static bool showsBismillah(int surah) => surah != 1 && surah != 9;

  /// 1-based sure + ayet → 1..6236.
  static int globalAyahNumber(int surah, int ayah) {
    if (surah < 1 || surah > 114) return 1;
    final meta = byNumber(surah);
    final clamped = ayah.clamp(1, meta.ayahCount);
    return _prefixSums[surah - 1] + clamped;
  }

  static (int surah, int ayah) fromGlobal(int global) {
    final g = global.clamp(1, ayahTotal);
    var lo = 0;
    var hi = 113;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_prefixSums[mid + 1] < g) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return (lo + 1, g - _prefixSums[lo]);
  }

  /// `_prefixSums[i]` = sure 1..i ayet toplamı (sure i+1'in ilk ayetinden önce).
  static List<int> get _prefixSums {
    final cached = _prefixCache;
    if (cached != null) return cached;
    final sums = List<int>.filled(all.length + 1, 0);
    for (var i = 0; i < all.length; i++) {
      sums[i + 1] = sums[i] + all[i].ayahCount;
    }
    _prefixCache = sums;
    return sums;
  }

  static List<int>? _prefixCache;

  static const List<QuranSurahMeta> all = <QuranSurahMeta>[
    QuranSurahMeta(number: 1, ayahCount: 7, arabic: 'الفاتحة', transliteration: 'Al-Fatiha', nameTr: 'Fâtiha', nameEn: 'The Opening', meccan: true),
    QuranSurahMeta(number: 2, ayahCount: 286, arabic: 'البقرة', transliteration: 'Al-Baqara', nameTr: 'Bakara', nameEn: 'The Cow', meccan: false),
    QuranSurahMeta(number: 3, ayahCount: 200, arabic: 'آل عمران', transliteration: 'Aal-i-Imran', nameTr: 'Âl-i İmrân', nameEn: 'Family of Imran', meccan: false),
    QuranSurahMeta(number: 4, ayahCount: 176, arabic: 'النساء', transliteration: 'An-Nisa', nameTr: 'Nisâ', nameEn: 'The Women', meccan: false),
    QuranSurahMeta(number: 5, ayahCount: 120, arabic: 'المائدة', transliteration: 'Al-Maida', nameTr: 'Mâide', nameEn: 'The Table', meccan: false),
    QuranSurahMeta(number: 6, ayahCount: 165, arabic: 'الأنعام', transliteration: 'Al-Anam', nameTr: 'En\'âm', nameEn: 'The Cattle', meccan: true),
    QuranSurahMeta(number: 7, ayahCount: 206, arabic: 'الأعراف', transliteration: 'Al-Araf', nameTr: 'A\'râf', nameEn: 'The Heights', meccan: true),
    QuranSurahMeta(number: 8, ayahCount: 75, arabic: 'الأنفال', transliteration: 'Al-Anfal', nameTr: 'Enfâl', nameEn: 'The Spoils', meccan: false),
    QuranSurahMeta(number: 9, ayahCount: 129, arabic: 'التوبة', transliteration: 'At-Tawba', nameTr: 'Tevbe', nameEn: 'The Repentance', meccan: false),
    QuranSurahMeta(number: 10, ayahCount: 109, arabic: 'يونس', transliteration: 'Yunus', nameTr: 'Yûnus', nameEn: 'Jonah', meccan: true),
    QuranSurahMeta(number: 11, ayahCount: 123, arabic: 'هود', transliteration: 'Hud', nameTr: 'Hûd', nameEn: 'Hud', meccan: true),
    QuranSurahMeta(number: 12, ayahCount: 111, arabic: 'يوسف', transliteration: 'Yusuf', nameTr: 'Yûsuf', nameEn: 'Joseph', meccan: true),
    QuranSurahMeta(number: 13, ayahCount: 43, arabic: 'الرعد', transliteration: 'Ar-Rad', nameTr: 'Ra\'d', nameEn: 'The Thunder', meccan: false),
    QuranSurahMeta(number: 14, ayahCount: 52, arabic: 'إبراهيم', transliteration: 'Ibrahim', nameTr: 'İbrâhim', nameEn: 'Abraham', meccan: true),
    QuranSurahMeta(number: 15, ayahCount: 99, arabic: 'الحجر', transliteration: 'Al-Hijr', nameTr: 'Hicr', nameEn: 'The Rock', meccan: true),
    QuranSurahMeta(number: 16, ayahCount: 128, arabic: 'النحل', transliteration: 'An-Nahl', nameTr: 'Nahl', nameEn: 'The Bee', meccan: true),
    QuranSurahMeta(number: 17, ayahCount: 111, arabic: 'الإسراء', transliteration: 'Al-Isra', nameTr: 'İsrâ', nameEn: 'The Night Journey', meccan: true),
    QuranSurahMeta(number: 18, ayahCount: 110, arabic: 'الكهف', transliteration: 'Al-Kahf', nameTr: 'Kehf', nameEn: 'The Cave', meccan: true),
    QuranSurahMeta(number: 19, ayahCount: 98, arabic: 'مريم', transliteration: 'Maryam', nameTr: 'Meryem', nameEn: 'Mary', meccan: true),
    QuranSurahMeta(number: 20, ayahCount: 135, arabic: 'طه', transliteration: 'Taha', nameTr: 'Tâhâ', nameEn: 'Ta-Ha', meccan: true),
    QuranSurahMeta(number: 21, ayahCount: 112, arabic: 'الأنبياء', transliteration: 'Al-Anbiya', nameTr: 'Enbiyâ', nameEn: 'The Prophets', meccan: true),
    QuranSurahMeta(number: 22, ayahCount: 78, arabic: 'الحج', transliteration: 'Al-Hajj', nameTr: 'Hac', nameEn: 'The Pilgrimage', meccan: false),
    QuranSurahMeta(number: 23, ayahCount: 118, arabic: 'المؤمنون', transliteration: 'Al-Muminun', nameTr: 'Mü\'minûn', nameEn: 'The Believers', meccan: true),
    QuranSurahMeta(number: 24, ayahCount: 64, arabic: 'النور', transliteration: 'An-Nur', nameTr: 'Nûr', nameEn: 'The Light', meccan: false),
    QuranSurahMeta(number: 25, ayahCount: 77, arabic: 'الفرقان', transliteration: 'Al-Furqan', nameTr: 'Furkân', nameEn: 'The Criterion', meccan: true),
    QuranSurahMeta(number: 26, ayahCount: 227, arabic: 'الشعراء', transliteration: 'Ash-Shuara', nameTr: 'Şuarâ', nameEn: 'The Poets', meccan: true),
    QuranSurahMeta(number: 27, ayahCount: 93, arabic: 'النمل', transliteration: 'An-Naml', nameTr: 'Neml', nameEn: 'The Ant', meccan: true),
    QuranSurahMeta(number: 28, ayahCount: 88, arabic: 'القصص', transliteration: 'Al-Qasas', nameTr: 'Kasas', nameEn: 'The Stories', meccan: true),
    QuranSurahMeta(number: 29, ayahCount: 69, arabic: 'العنكبوت', transliteration: 'Al-Ankabut', nameTr: 'Ankebût', nameEn: 'The Spider', meccan: true),
    QuranSurahMeta(number: 30, ayahCount: 60, arabic: 'الروم', transliteration: 'Ar-Rum', nameTr: 'Rûm', nameEn: 'The Romans', meccan: true),
    QuranSurahMeta(number: 31, ayahCount: 34, arabic: 'لقمان', transliteration: 'Luqman', nameTr: 'Lokmân', nameEn: 'Luqman', meccan: true),
    QuranSurahMeta(number: 32, ayahCount: 30, arabic: 'السجدة', transliteration: 'As-Sajda', nameTr: 'Secde', nameEn: 'The Prostration', meccan: true),
    QuranSurahMeta(number: 33, ayahCount: 73, arabic: 'الأحزاب', transliteration: 'Al-Ahzab', nameTr: 'Ahzâb', nameEn: 'The Clans', meccan: false),
    QuranSurahMeta(number: 34, ayahCount: 54, arabic: 'سبأ', transliteration: 'Saba', nameTr: 'Sebe\'', nameEn: 'Sheba', meccan: true),
    QuranSurahMeta(number: 35, ayahCount: 45, arabic: 'فاطر', transliteration: 'Fatir', nameTr: 'Fâtır', nameEn: 'The Originator', meccan: true),
    QuranSurahMeta(number: 36, ayahCount: 83, arabic: 'يس', transliteration: 'Ya-Sin', nameTr: 'Yâsîn', nameEn: 'Ya-Sin', meccan: true),
    QuranSurahMeta(number: 37, ayahCount: 182, arabic: 'الصافات', transliteration: 'As-Saffat', nameTr: 'Sâffât', nameEn: 'Those Drawn Up', meccan: true),
    QuranSurahMeta(number: 38, ayahCount: 88, arabic: 'ص', transliteration: 'Sad', nameTr: 'Sâd', nameEn: 'Sad', meccan: true),
    QuranSurahMeta(number: 39, ayahCount: 75, arabic: 'الزمر', transliteration: 'Az-Zumar', nameTr: 'Zümer', nameEn: 'The Troops', meccan: true),
    QuranSurahMeta(number: 40, ayahCount: 85, arabic: 'غافر', transliteration: 'Ghafir', nameTr: 'Mü\'min', nameEn: 'The Forgiver', meccan: true),
    QuranSurahMeta(number: 41, ayahCount: 54, arabic: 'فصلت', transliteration: 'Fussilat', nameTr: 'Fussilet', nameEn: 'Explained in Detail', meccan: true),
    QuranSurahMeta(number: 42, ayahCount: 53, arabic: 'الشورى', transliteration: 'Ash-Shura', nameTr: 'Şûrâ', nameEn: 'The Consultation', meccan: true),
    QuranSurahMeta(number: 43, ayahCount: 89, arabic: 'الزخرف', transliteration: 'Az-Zukhruf', nameTr: 'Zuhruf', nameEn: 'The Ornaments', meccan: true),
    QuranSurahMeta(number: 44, ayahCount: 59, arabic: 'الدخان', transliteration: 'Ad-Dukhan', nameTr: 'Duhân', nameEn: 'The Smoke', meccan: true),
    QuranSurahMeta(number: 45, ayahCount: 37, arabic: 'الجاثية', transliteration: 'Al-Jathiya', nameTr: 'Câsiye', nameEn: 'The Kneeling', meccan: true),
    QuranSurahMeta(number: 46, ayahCount: 35, arabic: 'الأحقاف', transliteration: 'Al-Ahqaf', nameTr: 'Ahkâf', nameEn: 'The Dunes', meccan: true),
    QuranSurahMeta(number: 47, ayahCount: 38, arabic: 'محمد', transliteration: 'Muhammad', nameTr: 'Muhammed', nameEn: 'Muhammad', meccan: false),
    QuranSurahMeta(number: 48, ayahCount: 29, arabic: 'الفتح', transliteration: 'Al-Fath', nameTr: 'Feth', nameEn: 'The Victory', meccan: false),
    QuranSurahMeta(number: 49, ayahCount: 18, arabic: 'الحجرات', transliteration: 'Al-Hujurat', nameTr: 'Hucurât', nameEn: 'The Rooms', meccan: false),
    QuranSurahMeta(number: 50, ayahCount: 45, arabic: 'ق', transliteration: 'Qaf', nameTr: 'Kâf', nameEn: 'Qaf', meccan: true),
    QuranSurahMeta(number: 51, ayahCount: 60, arabic: 'الذاريات', transliteration: 'Adh-Dhariyat', nameTr: 'Zâriyât', nameEn: 'The Winnowing Winds', meccan: true),
    QuranSurahMeta(number: 52, ayahCount: 49, arabic: 'الطور', transliteration: 'At-Tur', nameTr: 'Tûr', nameEn: 'The Mount', meccan: true),
    QuranSurahMeta(number: 53, ayahCount: 62, arabic: 'النجم', transliteration: 'An-Najm', nameTr: 'Necm', nameEn: 'The Star', meccan: true),
    QuranSurahMeta(number: 54, ayahCount: 55, arabic: 'القمر', transliteration: 'Al-Qamar', nameTr: 'Kamer', nameEn: 'The Moon', meccan: true),
    QuranSurahMeta(number: 55, ayahCount: 78, arabic: 'الرحمن', transliteration: 'Ar-Rahman', nameTr: 'Rahmân', nameEn: 'The Beneficent', meccan: true),
    QuranSurahMeta(number: 56, ayahCount: 96, arabic: 'الواقعة', transliteration: 'Al-Waqia', nameTr: 'Vâkıa', nameEn: 'The Inevitable', meccan: true),
    QuranSurahMeta(number: 57, ayahCount: 29, arabic: 'الحديد', transliteration: 'Al-Hadid', nameTr: 'Hadîd', nameEn: 'The Iron', meccan: false),
    QuranSurahMeta(number: 58, ayahCount: 22, arabic: 'المجادلة', transliteration: 'Al-Mujadila', nameTr: 'Mücâdele', nameEn: 'The Pleading', meccan: false),
    QuranSurahMeta(number: 59, ayahCount: 24, arabic: 'الحشر', transliteration: 'Al-Hashr', nameTr: 'Haşr', nameEn: 'The Exile', meccan: false),
    QuranSurahMeta(number: 60, ayahCount: 13, arabic: 'الممتحنة', transliteration: 'Al-Mumtahina', nameTr: 'Mümtehine', nameEn: 'She That Is To Be Examined', meccan: false),
    QuranSurahMeta(number: 61, ayahCount: 14, arabic: 'الصف', transliteration: 'As-Saff', nameTr: 'Saff', nameEn: 'The Ranks', meccan: false),
    QuranSurahMeta(number: 62, ayahCount: 11, arabic: 'الجمعة', transliteration: 'Al-Jumu\'a', nameTr: 'Cum\'a', nameEn: 'Friday', meccan: false),
    QuranSurahMeta(number: 63, ayahCount: 11, arabic: 'المنافقون', transliteration: 'Al-Munafiqun', nameTr: 'Münâfikûn', nameEn: 'The Hypocrites', meccan: false),
    QuranSurahMeta(number: 64, ayahCount: 18, arabic: 'التغابن', transliteration: 'At-Taghabun', nameTr: 'Tegâbün', nameEn: 'The Mutual Disillusion', meccan: false),
    QuranSurahMeta(number: 65, ayahCount: 12, arabic: 'الطلاق', transliteration: 'At-Talaq', nameTr: 'Talâk', nameEn: 'The Divorce', meccan: false),
    QuranSurahMeta(number: 66, ayahCount: 12, arabic: 'التحريم', transliteration: 'At-Tahrim', nameTr: 'Tahrim', nameEn: 'The Prohibition', meccan: false),
    QuranSurahMeta(number: 67, ayahCount: 30, arabic: 'الملك', transliteration: 'Al-Mulk', nameTr: 'Mülk', nameEn: 'The Sovereignty', meccan: true),
    QuranSurahMeta(number: 68, ayahCount: 52, arabic: 'القلم', transliteration: 'Al-Qalam', nameTr: 'Kalem', nameEn: 'The Pen', meccan: true),
    QuranSurahMeta(number: 69, ayahCount: 52, arabic: 'الحاقة', transliteration: 'Al-Haqqa', nameTr: 'Hâkka', nameEn: 'The Reality', meccan: true),
    QuranSurahMeta(number: 70, ayahCount: 44, arabic: 'المعارج', transliteration: 'Al-Maarij', nameTr: 'Meâric', nameEn: 'The Ascending Stairways', meccan: true),
    QuranSurahMeta(number: 71, ayahCount: 28, arabic: 'نوح', transliteration: 'Nuh', nameTr: 'Nûh', nameEn: 'Noah', meccan: true),
    QuranSurahMeta(number: 72, ayahCount: 28, arabic: 'الجن', transliteration: 'Al-Jinn', nameTr: 'Cin', nameEn: 'The Jinn', meccan: true),
    QuranSurahMeta(number: 73, ayahCount: 20, arabic: 'المزمل', transliteration: 'Al-Muzzammil', nameTr: 'Müzzemmil', nameEn: 'The Enshrouded One', meccan: true),
    QuranSurahMeta(number: 74, ayahCount: 56, arabic: 'المدثر', transliteration: 'Al-Muddaththir', nameTr: 'Müddessir', nameEn: 'The Cloaked One', meccan: true),
    QuranSurahMeta(number: 75, ayahCount: 40, arabic: 'القيامة', transliteration: 'Al-Qiyama', nameTr: 'Kıyamet', nameEn: 'The Resurrection', meccan: true),
    QuranSurahMeta(number: 76, ayahCount: 31, arabic: 'الإنسان', transliteration: 'Al-Insan', nameTr: 'İnsan', nameEn: 'The Human', meccan: false),
    QuranSurahMeta(number: 77, ayahCount: 50, arabic: 'المرسلات', transliteration: 'Al-Mursalat', nameTr: 'Mürselât', nameEn: 'The Emissaries', meccan: true),
    QuranSurahMeta(number: 78, ayahCount: 40, arabic: 'النبأ', transliteration: 'An-Naba', nameTr: 'Nebe\'', nameEn: 'The Tidings', meccan: true),
    QuranSurahMeta(number: 79, ayahCount: 46, arabic: 'النازعات', transliteration: 'An-Naziat', nameTr: 'Nâziât', nameEn: 'Those Who Drag Forth', meccan: true),
    QuranSurahMeta(number: 80, ayahCount: 42, arabic: 'عبس', transliteration: 'Abasa', nameTr: 'Abese', nameEn: 'He Frowned', meccan: true),
    QuranSurahMeta(number: 81, ayahCount: 29, arabic: 'التكوير', transliteration: 'At-Takwir', nameTr: 'Tekvir', nameEn: 'The Overthrowing', meccan: true),
    QuranSurahMeta(number: 82, ayahCount: 19, arabic: 'الإنفطار', transliteration: 'Al-Infitar', nameTr: 'İnfitâr', nameEn: 'The Cleaving', meccan: true),
    QuranSurahMeta(number: 83, ayahCount: 36, arabic: 'المطففين', transliteration: 'Al-Mutaffifin', nameTr: 'Mutaffifîn', nameEn: 'The Defrauding', meccan: true),
    QuranSurahMeta(number: 84, ayahCount: 25, arabic: 'الإنشقاق', transliteration: 'Al-Inshiqaq', nameTr: 'İnşikâk', nameEn: 'The Splitting Open', meccan: true),
    QuranSurahMeta(number: 85, ayahCount: 22, arabic: 'البروج', transliteration: 'Al-Burooj', nameTr: 'Burûc', nameEn: 'The Mansions of the Stars', meccan: true),
    QuranSurahMeta(number: 86, ayahCount: 17, arabic: 'الطارق', transliteration: 'At-Tariq', nameTr: 'Târık', nameEn: 'The Morning Star', meccan: true),
    QuranSurahMeta(number: 87, ayahCount: 19, arabic: 'الأعلى', transliteration: 'Al-Ala', nameTr: 'A\'lâ', nameEn: 'The Most High', meccan: true),
    QuranSurahMeta(number: 88, ayahCount: 26, arabic: 'الغاشية', transliteration: 'Al-Ghashiya', nameTr: 'Gâşiye', nameEn: 'The Overwhelming', meccan: true),
    QuranSurahMeta(number: 89, ayahCount: 30, arabic: 'الفجر', transliteration: 'Al-Fajr', nameTr: 'Fecr', nameEn: 'The Dawn', meccan: true),
    QuranSurahMeta(number: 90, ayahCount: 20, arabic: 'البلد', transliteration: 'Al-Balad', nameTr: 'Beled', nameEn: 'The City', meccan: true),
    QuranSurahMeta(number: 91, ayahCount: 15, arabic: 'الشمس', transliteration: 'Ash-Shams', nameTr: 'Şems', nameEn: 'The Sun', meccan: true),
    QuranSurahMeta(number: 92, ayahCount: 21, arabic: 'الليل', transliteration: 'Al-Lail', nameTr: 'Leyl', nameEn: 'The Night', meccan: true),
    QuranSurahMeta(number: 93, ayahCount: 11, arabic: 'الضحى', transliteration: 'Ad-Dhuha', nameTr: 'Duhâ', nameEn: 'The Morning Hours', meccan: true),
    QuranSurahMeta(number: 94, ayahCount: 8, arabic: 'الشرح', transliteration: 'Ash-Sharh', nameTr: 'İnşirâh', nameEn: 'The Relief', meccan: true),
    QuranSurahMeta(number: 95, ayahCount: 8, arabic: 'التين', transliteration: 'At-Tin', nameTr: 'Tin', nameEn: 'The Fig', meccan: true),
    QuranSurahMeta(number: 96, ayahCount: 19, arabic: 'العلق', transliteration: 'Al-Alaq', nameTr: 'Alak', nameEn: 'The Clot', meccan: true),
    QuranSurahMeta(number: 97, ayahCount: 5, arabic: 'القدر', transliteration: 'Al-Qadr', nameTr: 'Kadr', nameEn: 'The Power', meccan: true),
    QuranSurahMeta(number: 98, ayahCount: 8, arabic: 'البينة', transliteration: 'Al-Bayyina', nameTr: 'Beyyine', nameEn: 'The Evidence', meccan: false),
    QuranSurahMeta(number: 99, ayahCount: 8, arabic: 'الزلزلة', transliteration: 'Az-Zalzala', nameTr: 'Zilzâl', nameEn: 'The Earthquake', meccan: false),
    QuranSurahMeta(number: 100, ayahCount: 11, arabic: 'العاديات', transliteration: 'Al-Adiyat', nameTr: 'Âdiyât', nameEn: 'The Courser', meccan: true),
    QuranSurahMeta(number: 101, ayahCount: 11, arabic: 'القارعة', transliteration: 'Al-Qaria', nameTr: 'Kâria', nameEn: 'The Calamity', meccan: true),
    QuranSurahMeta(number: 102, ayahCount: 8, arabic: 'التكاثر', transliteration: 'At-Takathur', nameTr: 'Tekâsür', nameEn: 'The Rivalry', meccan: true),
    QuranSurahMeta(number: 103, ayahCount: 3, arabic: 'العصر', transliteration: 'Al-Asr', nameTr: 'Asr', nameEn: 'The Declining Day', meccan: true),
    QuranSurahMeta(number: 104, ayahCount: 9, arabic: 'الهمزة', transliteration: 'Al-Humaza', nameTr: 'Hümeze', nameEn: 'The Traducer', meccan: true),
    QuranSurahMeta(number: 105, ayahCount: 5, arabic: 'الفيل', transliteration: 'Al-Fil', nameTr: 'Fîl', nameEn: 'The Elephant', meccan: true),
    QuranSurahMeta(number: 106, ayahCount: 4, arabic: 'قريش', transliteration: 'Quraysh', nameTr: 'Kureyş', nameEn: 'Quraysh', meccan: true),
    QuranSurahMeta(number: 107, ayahCount: 7, arabic: 'الماعون', transliteration: 'Al-Maun', nameTr: 'Mâ\'ûn', nameEn: 'The Small Kindnesses', meccan: true),
    QuranSurahMeta(number: 108, ayahCount: 3, arabic: 'الكوثر', transliteration: 'Al-Kawthar', nameTr: 'Kevser', nameEn: 'The Abundance', meccan: true),
    QuranSurahMeta(number: 109, ayahCount: 6, arabic: 'الكافرون', transliteration: 'Al-Kafirun', nameTr: 'Kâfirûn', nameEn: 'The Disbelievers', meccan: true),
    QuranSurahMeta(number: 110, ayahCount: 3, arabic: 'النصر', transliteration: 'An-Nasr', nameTr: 'Nasr', nameEn: 'The Help', meccan: false),
    QuranSurahMeta(number: 111, ayahCount: 5, arabic: 'المسد', transliteration: 'Al-Masad', nameTr: 'Tebbet', nameEn: 'The Palm Fiber', meccan: true),
    QuranSurahMeta(number: 112, ayahCount: 4, arabic: 'الإخلاص', transliteration: 'Al-Ikhlas', nameTr: 'İhlâs', nameEn: 'The Sincerity', meccan: true),
    QuranSurahMeta(number: 113, ayahCount: 5, arabic: 'الفلق', transliteration: 'Al-Falaq', nameTr: 'Felak', nameEn: 'The Daybreak', meccan: true),
    QuranSurahMeta(number: 114, ayahCount: 6, arabic: 'الناس', transliteration: 'An-Nas', nameTr: 'Nâs', nameEn: 'Mankind', meccan: true),
  ];
}
