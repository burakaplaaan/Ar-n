/**
 * Builds functions/data/islamic_quiz_questions.json with exactly 300 items.
 * Run: node functions/scripts/generate_islamic_quiz_questions.js
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
  "Dini kavramlar"
];

/** Compact rows: [category, difficulty, question, correct, wrongs[], explanation, source] */
const ROWS = [
  [
    "Kur'an bilgisi",
    1,
    "Kur'an-ı Kerim kaç sureden oluşur?",
    "114",
    [
      "120",
      "99",
      "110"
    ],
    "Kur'an-ı Kerim 114 sureden oluşur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Mushaf sıralamasında ilk sure hangisidir?",
    "Fatiha",
    [
      "Bakara",
      "İhlas",
      "Nas"
    ],
    "Mushaf'ta ilk sure Fatiha'dır.",
    "Diyanet Kur'an Yolu"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Mushaf sıralamasında son sure hangisidir?",
    "Nas",
    [
      "Fatiha",
      "İhlas",
      "Felak"
    ],
    "Mushaf'ta son sure Nas'tır.",
    "Diyanet Kur'an Yolu"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kur'an'ın en uzun suresi hangisidir?",
    "Bakara",
    [
      "Âl-i İmran",
      "Nisâ",
      "Mâide"
    ],
    "En uzun sure Bakara'dır.",
    "Diyanet Kur'an Yolu"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Tevhid vurgusuyla bilinen kısa sure hangisidir?",
    "İhlas",
    [
      "Kevser",
      "Nasr",
      "Asr"
    ],
    "İhlas suresi tevhid esasını özlü anlatır.",
    "Diyanet Kur'an Yolu, İhlas"
  ],
  [
    "Kur'an bilgisi",
    2,
    "İlk vahyin geldiği yer geleneksel olarak neresidir?",
    "Hira Mağarası",
    [
      "Sevr Mağarası",
      "Kuba Mescidi",
      "Uhud dağı"
    ],
    "İlk vahyin Hira'da geldiği kabul edilir.",
    "TDV İslam Ansiklopedisi, Vahiy"
  ],
  [
    "Kur'an bilgisi",
    1,
    "İlk inen ayetler hangi sureye aittir?",
    "Alak",
    [
      "Müddessir",
      "Müzzemmil",
      "Fatiha"
    ],
    "İlk inen ayetler Alak suresindendir.",
    "Diyanet Kur'an Yolu, Alak"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da özel adıyla anılan tek kadın kimdir?",
    "Meryem",
    [
      "Âsiye",
      "Hatice",
      "Fâtıma"
    ],
    "Kur'an'da adı geçen kadın Meryem'dir.",
    "TDV İslam Ansiklopedisi, Meryem"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Fatiha suresinin diğer adlarından biri nedir?",
    "Seb'u'l-Mesânî",
    [
      "Âyetü'l-Kürsî",
      "Amme",
      "Tıvâl"
    ],
    "Fatiha, Seb'u'l-Mesânî diye de anılır.",
    "TDV İslam Ansiklopedisi, Fâtiha"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Âyetü'l-Kürsî hangi surededir?",
    "Bakara",
    [
      "Âl-i İmran",
      "Nisâ",
      "İhlas"
    ],
    "Âyetü'l-Kürsî Bakara 2/255'tedir.",
    "Diyanet Kur'an Yolu, Bakara 2/255"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kevser suresi kaç ayetten oluşur?",
    "3",
    [
      "5",
      "7",
      "10"
    ],
    "Kevser suresi üç ayettir.",
    "Diyanet Kur'an Yolu, Kevser"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Secde ayeti okunduğunda yapılan secdeye ne ad verilir?",
    "Tilavet secdesi",
    [
      "Şükür namazı",
      "Cenaze namazı",
      "Küsuf namazı"
    ],
    "Secde ayetinde tilavet secdesi yapılır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Yasin suresinde öne çıkan temel hatırlatmalardan biri nedir?",
    "Ahiret bilinci",
    [
      "Sadece miras hesabı",
      "Sadece faiz hükmü",
      "Sadece savaş ganimeti"
    ],
    "Yasin'de ahiret ve risalet vurgusu vardır.",
    "Diyanet Kur'an Yolu, Yasin"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Vahyin tamamlanması yaklaşık kaç yıl sürmüştür?",
    "23 yıl",
    [
      "10 yıl",
      "40 yıl",
      "7 yıl"
    ],
    "Kur'an vahyi yaklaşık 23 yılda tamamlanmıştır.",
    "TDV İslam Ansiklopedisi, Kur'an"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Mekkî sureler hangi döneme aittir?",
    "Mekke dönemi",
    [
      "Yalnızca fetih sonrası",
      "Yalnızca Veda Hutbesi günü",
      "Yalnızca Taif yılı"
    ],
    "Mekkî sureler Mekke döneminde inmiştir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Medenî sureler hangi döneme aittir?",
    "Medine dönemi",
    [
      "Yalnızca Hira yılları",
      "Yalnızca Sevr gecesi",
      "Yalnızca Fil Vakası"
    ],
    "Medenî sureler Medine döneminde inmiştir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kıssası bir sure boyunca genişçe anlatılan peygamber kimdir?",
    "Hz. Yusuf",
    [
      "Hz. Şuayb",
      "Hz. İdris",
      "Hz. Zülkifl"
    ],
    "Yusuf suresi kıssayı genişçe anlatır.",
    "Diyanet Kur'an Yolu, Yusuf"
  ],
  [
    "Kur'an bilgisi",
    3,
    "Tevbe suresinin başında besmele bulunmamasının sebebi nedir?",
    "Nüzul ve üslup özelliği",
    [
      "Surenin eksik oluşu",
      "Çok kısa oluşu",
      "Yalnızca şiir oluşu"
    ],
    "Tevbe, besmelesiz başlayan tek suredir.",
    "Diyanet Kur'an Yolu, Tevbe"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Felak ve Nas sureleri birlikte nasıl adlandırılır?",
    "Muavvizeteyn",
    [
      "Mufassal",
      "Tıvâl",
      "Mesânî"
    ],
    "Felak ve Nas Muavvizeteyn diye anılır.",
    "TDV İslam Ansiklopedisi, Muavvizeteyn"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da Levh-i Mahfuz neyi ifade eder?",
    "Korunan ilahi yazgı gerçeğini",
    [
      "Kabile nüfus defterini",
      "Ticaret sicilini",
      "Savaş ganimet listesini"
    ],
    "Levh-i Mahfuz ilahi ilim ve korunan yazgıyla anılır.",
    "TDV İslam Ansiklopedisi, Levh-i Mahfûz"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Fatiha suresi namazda nasıl konumlanır?",
    "Her rekatta okunan temel suredir",
    [
      "Yalnızca bayramda okunur",
      "Yalnızca cenazede okunur",
      "Hiç okunmaz"
    ],
    "Fatiha namazın temel okuyuşlarındandır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'ın korunmuşluğu ile ilgili temel inanç nedir?",
    "Allah tarafından korunması",
    [
      "Yalnızca ezbercilerin keyfine kalması",
      "Zamana göre değişmesi",
      "İnsanlarca yeniden yazılması"
    ],
    "Kur'an'ın korunacağı bildirilmiştir.",
    "Diyanet Kur'an Yolu, Hicr 15/9"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Asr suresi insanın kurtuluşu için neyi vurgular?",
    "İman, salih amel ve hakkı tavsiye",
    [
      "Yalnızca mal çoğaltmayı",
      "Yalnızca soy üstünlüğünü",
      "Yalnızca savaş gücünü"
    ],
    "Asr; iman, amel ve sabrı öne çıkarır.",
    "Diyanet Kur'an Yolu, Asr"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da geçen 'gayb' kavramı neyi ifade eder?",
    "İnsanın bilemeyeceği alanları",
    [
      "Yalnızca ticaret kârını",
      "Yalnızca savaş taktiğini",
      "Yalnızca şehir haritasını"
    ],
    "Gayb, insan idrakini aşan alandır.",
    "TDV İslam Ansiklopedisi, Gayb"
  ],
  [
    "Kur'an bilgisi",
    1,
    "İhlas suresinde Allah nasıl tanıtılır?",
    "Ehad ve Samed",
    [
      "Yalnızca mekân sahibi",
      "Yalnızca zaman bağlısı",
      "Ortaklar sahibi"
    ],
    "İhlas tevhid sıfatlarını bildirir.",
    "Diyanet Kur'an Yolu, İhlas"
  ],
  [
    "Kur'an bilgisi",
    3,
    "Kur'an'da 'müteşabih' ayetler neyi ifade eder?",
    "Yorum derinliği olan ayetleri",
    [
      "Hiçbir anlamı olmayan metni",
      "Sadece rakam listelerini",
      "Sadece kabile isimlerini"
    ],
    "Müteşabih, manası derin yönlü ayetlerdir.",
    "TDV İslam Ansiklopedisi, Muhkem"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da 'muhkem' ayetler nasıl anlaşılır?",
    "Hüküm ve mana yönü açık ayetler",
    [
      "Anlamsız ayetler",
      "Neshedilmiş tüm metin",
      "Yalnızca şiir dizeleri"
    ],
    "Muhkem ayetler anlamı açık olanlardır.",
    "TDV İslam Ansiklopedisi, Muhkem"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Bakara suresi adını hangi kıssadan alır?",
    "İsrailoğulları ve inek kıssası",
    [
      "Fil ordusu kıssası",
      "Ashab-ı Kehf kıssası",
      "Yunus ve balık kıssası"
    ],
    "Sure, bakara (inek) kıssasıyla anılır.",
    "Diyanet Kur'an Yolu, Bakara"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Fil suresi hangi olayı hatırlatır?",
    "Fil Vakası",
    [
      "Bedir Savaşı",
      "Hendek Savaşı",
      "Hayber Seferi"
    ],
    "Fil suresi Fil Vakası'nı anlatır.",
    "Diyanet Kur'an Yolu, Fil"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Nasr suresi neyi müjdelemiştir?",
    "Yardım ve fetih",
    [
      "Orucun kaldırılmasını",
      "Namazın iptalini",
      "Haccın yasaklanmasını"
    ],
    "Nasr yardım ve fethi bildirir.",
    "Diyanet Kur'an Yolu, Nasr"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da 'ümmü'l-Kitab' ifadesi hangi bağlamda geçer?",
    "Ana kitap / ana kaynak vurgusu",
    [
      "Yalnızca ticaret defteri",
      "Yalnızca savaş günlüğü",
      "Yalnızca şiir divanı"
    ],
    "Ümmü'l-Kitab ilahi kitaba dair bir ifadedir.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kur'an okumaya besmele ile başlamak neden yaygındır?",
    "Allah'ın adıyla başlama edebi",
    [
      "Sure sayısını azaltmak için",
      "Ayetleri silmek için",
      "Kıraati iptal etmek için"
    ],
    "Besmele ile başlamak yaygın bir edeptir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    3,
    "Kur'an'da geçen 'Furkan' ismi neyi vurgular?",
    "Hak ile batılı ayırt eden kitap oluşunu",
    [
      "Yalnızca tarih kitabı oluşunu",
      "Yalnızca şiir kitabı oluşunu",
      "Yalnızca hesap defteri oluşunu"
    ],
    "Furkan, ayırt edici vahiy anlamındadır.",
    "TDV İslam Ansiklopedisi, Furkân"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Hicr suresinde Kur'an'ın korunmasıyla ilgili temel mesaj nedir?",
    "Kur'an'ın Allah tarafından korunacağı",
    [
      "Kur'an'ın silineceği",
      "Kur'an'ın gizleneceği",
      "Kur'an'ın yasaklanacağı"
    ],
    "Hicr 15/9 korunma vaadini bildirir.",
    "Diyanet Kur'an Yolu, Hicr 15/9"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kur'an'da gece ibadetini teşvik eden surelerden biri hangisidir?",
    "Müzzemmil",
    [
      "Kâfirûn",
      "Tebbet",
      "Fil"
    ],
    "Müzzemmil gece ibadetini konu edinir.",
    "Diyanet Kur'an Yolu, Müzzemmil"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Duhâ suresi Hz. Peygamber'e hangi üslupta hitap eder?",
    "Teselli ve müjde üslubu",
    [
      "Savaş emri üslubu",
      "Ticaret yasağı üslubu",
      "Miras taksimi üslubu"
    ],
    "Duhâ teselli ve müjde içerir.",
    "Diyanet Kur'an Yolu, Duhâ"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kâfirûn suresinin temel mesajı nedir?",
    "İbadette net tavır ve tevhid",
    [
      "Faiz hesabı",
      "Ganimet paylaşımı",
      "Miras dilimleri"
    ],
    "Kâfirûn tevhid ve net tavrı bildirir.",
    "Diyanet Kur'an Yolu, Kâfirûn"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da 'ehl-i kitap' ifadesi kimleri kapsar?",
    "Yahudi ve Hristiyanları",
    [
      "Yalnızca müşrikleri",
      "Yalnızca put ustalarını",
      "Yalnızca şairleri"
    ],
    "Ehl-i kitap Yahudi ve Hristiyanlardır.",
    "TDV İslam Ansiklopedisi, Ehl-i kitap"
  ],
  [
    "Kur'an bilgisi",
    3,
    "Kur'an'da kıraat farklılıkları ne anlama gelir?",
    "Nakledilen okuyuş çeşitlilikleri",
    [
      "Metnin uydurma oluşu",
      "Surelerin silinmesi",
      "Ayet sayısının rastgeleliği"
    ],
    "Kıraatler güvenilir okuyuş rivayetleridir.",
    "TDV İslam Ansiklopedisi, Kıraat"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Rahmân suresinde sık tekrarlanan soru nedir?",
    "Rabbinizin hangi nimetlerini yalanlıyorsunuz?",
    [
      "Hangi savaşı kazandınız?",
      "Hangi malı sakladınız?",
      "Hangi şehri yıktınız?"
    ],
    "Rahmân'da nimet sorusu tekrarlanır.",
    "Diyanet Kur'an Yolu, Rahmân"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Mülk suresinin temel vurgularından biri nedir?",
    "Allah'ın egemenliği ve yaratılış",
    [
      "Yalnızca ticaret kârı",
      "Yalnızca kabile övgüsü",
      "Yalnızca şehir planı"
    ],
    "Mülk, rububiyet ve yaratılışı işler.",
    "Diyanet Kur'an Yolu, Mülk"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kur'an'da 'salât' emri neyi bildirir?",
    "Namazı",
    [
      "Yalnızca ticareti",
      "Yalnızca yolculuğu",
      "Yalnızca şiiri"
    ],
    "Salât namazı ifade eder.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da zekât emriyle birlikte sık anılan ibadet hangisidir?",
    "Namaz",
    [
      "Yalnızca avcılık",
      "Yalnızca denizcilik",
      "Yalnızca çiftçilik"
    ],
    "Namaz ve zekât birlikte sık geçer.",
    "Diyanet Kur'an Yolu"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Fatiha'da istenen yol nasıl nitelendirilir?",
    "Dosdoğru yol",
    [
      "Kısa ticaret yolu",
      "Gizli hazine yolu",
      "Savaş kestirme yolu"
    ],
    "Fatiha dosdoğru yolu ister.",
    "Diyanet Kur'an Yolu, Fatiha"
  ],
  [
    "Kur'an bilgisi",
    3,
    "Nesh kavramı tefsirde neyi ifade eder?",
    "Bazı hükümlerin sonraki düzenlemesi bahsini",
    [
      "Tüm Kur'an'ın iptalini",
      "Sure isimlerinin silinmesini",
      "Kıraatin yasaklanmasını"
    ],
    "Nesh, hüküm bahislerinde kullanılan bir kavramdır.",
    "TDV İslam Ansiklopedisi, Nesh"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da Ashab-ı Kehf kıssası hangi temayı işler?",
    "İman ve sabır imtihanı",
    [
      "Ticaret ortaklığı",
      "Ganimet paylaşımı",
      "Miras hesabı"
    ],
    "Ashab-ı Kehf iman ve sabır kıssasıdır.",
    "Diyanet Kur'an Yolu, Kehf"
  ],
  [
    "Kur'an bilgisi",
    1,
    "İnşirah suresi Hz. Peygamber'e neyi müjdeler?",
    "Güçlükle birlikte kolaylık",
    [
      "Namazın kalkması",
      "Orucun kalkması",
      "Haccın kalkması"
    ],
    "İnşirah kolaylık müjdesi verir.",
    "Diyanet Kur'an Yolu, İnşirah"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Kur'an'da 'takva' neyi ifade eder?",
    "Allah'a karşı sorumluluk bilinci",
    [
      "Yalnızca mal biriktirme",
      "Yalnızca soy övünme",
      "Yalnızca güç gösterme"
    ],
    "Takva sorumluluk ve sakınma bilincidir.",
    "TDV İslam Ansiklopedisi, Takvâ"
  ],
  [
    "Kur'an bilgisi",
    1,
    "Kur'an'ın dili nedir?",
    "Arapça",
    [
      "Farsça",
      "Latince",
      "Süryanice"
    ],
    "Kur'an Arapça indirilmiştir.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi, Kur'an"
  ],
  [
    "Kur'an bilgisi",
    2,
    "Mesani ve mufassal gibi terimler neyi sınıflandırır?",
    "Sure gruplarını",
    [
      "Namaz vakitlerini",
      "Zekât nisaplarını",
      "Hac menzillerini"
    ],
    "Bu terimler sure tasnifinde kullanılır.",
    "TDV İslam Ansiklopedisi, Sure"
  ],
  [
    "Siyer",
    1,
    "Hz. Muhammed hangi şehirde doğmuştur?",
    "Mekke",
    [
      "Medine",
      "Taif",
      "Kudüs"
    ],
    "Hz. Peygamber Mekke'de doğmuştur.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in babasının adı nedir?",
    "Abdullah",
    [
      "Abdülmuttalib",
      "Ebu Talib",
      "Hamza"
    ],
    "Babası Abdullah'tır.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in annesinin adı nedir?",
    "Âmine",
    [
      "Hatice",
      "Fatıma",
      "Zeynep"
    ],
    "Annesi Âmine'dir.",
    "TDV İslam Ansiklopedisi, Âmine"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'i sütanne olarak emziren kadın kimdir?",
    "Halime",
    [
      "Hatice",
      "Sümeyye",
      "Ümmü Seleme"
    ],
    "Sütannesi Halime'dir.",
    "TDV İslam Ansiklopedisi, Halîme"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in ilk eşi kimdir?",
    "Hatice",
    [
      "Âişe",
      "Hafsa",
      "Sevde"
    ],
    "İlk eşi Hz. Hatice'dir.",
    "TDV İslam Ansiklopedisi, Hatice"
  ],
  [
    "Siyer",
    2,
    "İlk vahiy geldiğinde Hz. Peygamber kaç yaşındaydı?",
    "40",
    [
      "25",
      "33",
      "63"
    ],
    "Nübüvvet 40 yaşında başlamıştır.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "İlk müslümanlardan olan eşi kimdir?",
    "Hatice",
    [
      "Hind",
      "Ümmü Cemil",
      "Reyhane"
    ],
    "İlk inananlardan biri Hz. Hatice'dir.",
    "TDV İslam Ansiklopedisi, Hatice"
  ],
  [
    "Siyer",
    1,
    "İlk erkek müslümanlar arasında kim öne çıkar?",
    "Ebu Bekir",
    [
      "Ebu Cehil",
      "Ebu Leheb",
      "Velid"
    ],
    "Hz. Ebu Bekir ilk erkek müslümanlardandır.",
    "TDV İslam Ansiklopedisi, Ebû Bekir"
  ],
  [
    "Siyer",
    2,
    "Habeşistan'a hicret neden yapılmıştır?",
    "İşkenceden korunmak için",
    [
      "Ticaret tekeli kurmak için",
      "Savaş ilan etmek için",
      "Kâbe'yi yıkmak için"
    ],
    "Müslümanlar zulümden Habeşistan'a göç etmiştir.",
    "TDV İslam Ansiklopedisi, Habeşistan Hicreti"
  ],
  [
    "Siyer",
    1,
    "Hicret hangi şehre yapılmıştır?",
    "Medine",
    [
      "Taif",
      "Kudüs",
      "San'a"
    ],
    "Hicret Yesrib/Medine'yedir.",
    "TDV İslam Ansiklopedisi, Hicret"
  ],
  [
    "Siyer",
    2,
    "Hicret yolunda sığınılan mağara hangisidir?",
    "Sevr",
    [
      "Hira",
      "Nur",
      "Uhud"
    ],
    "Hicrette Sevr Mağarası'na sığınılmıştır.",
    "TDV İslam Ansiklopedisi, Hicret"
  ],
  [
    "Siyer",
    1,
    "Medine'de inşa edilen mescidin adı nedir?",
    "Mescid-i Nebevî",
    [
      "Mescid-i Aksa",
      "Mescid-i Haram dışında bir çarşı",
      "Kuba dışı bir kale"
    ],
    "Mescid-i Nebevî Medine'dedir.",
    "TDV İslam Ansiklopedisi, Mescid-i Nebevî"
  ],
  [
    "Siyer",
    2,
    "Bedir Savaşı hangi taraflar arasında olmuştur?",
    "Müslümanlar ve Kureyş ordusu",
    [
      "Bizans ve Sasaniler",
      "Yalnızca Evs ve Hazreç",
      "Yalnızca Rum ve Berberi"
    ],
    "Bedir, müslümanlar ile Kureyş arasında geçmiştir.",
    "TDV İslam Ansiklopedisi, Bedir Gazvesi"
  ],
  [
    "Siyer",
    2,
    "Uhud Savaşı'nda şehit düşen amca kimdir?",
    "Hamza",
    [
      "Abbas",
      "Ebu Talib",
      "Zübeyr"
    ],
    "Uhud'da Hz. Hamza şehit olmuştur.",
    "TDV İslam Ansiklopedisi, Uhud Gazvesi"
  ],
  [
    "Siyer",
    2,
    "Hendek Savaşı'nda savunma yöntemi neydi?",
    "Şehrin önüne hendek kazılması",
    [
      "Denizden hücum",
      "Kaleyi yakmak",
      "Çarşıyı kapatmak"
    ],
    "Hendek kazılarak savunulmuştur.",
    "TDV İslam Ansiklopedisi, Hendek Gazvesi"
  ],
  [
    "Siyer",
    1,
    "Hudeybiye Antlaşması kimlerle yapılmıştır?",
    "Mekkeli müşriklerle",
    [
      "Bizans'la",
      "Sasanilerle",
      "Habeşistan'la"
    ],
    "Hudeybiye Mekke tarafıyla imzalanmıştır.",
    "TDV İslam Ansiklopedisi, Hudeybiye Antlaşması"
  ],
  [
    "Siyer",
    1,
    "Mekke'nin fethi hangi yılda gerçekleşmiştir?",
    "Hicri 8",
    [
      "Hicri 1",
      "Hicri 2",
      "Hicri 3"
    ],
    "Mekke fethi hicri 8. yıldadır.",
    "TDV İslam Ansiklopedisi, Mekke'nin Fethi"
  ],
  [
    "Siyer",
    2,
    "Veda Hutbesi nerede irad edilmiştir?",
    "Arafat",
    [
      "Bedir",
      "Hira",
      "Sevr"
    ],
    "Veda Hutbesi Arafat'ta irad edilmiştir.",
    "TDV İslam Ansiklopedisi, Veda Hutbesi"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber kaç yaşında vefat etmiştir?",
    "63",
    [
      "40",
      "25",
      "50"
    ],
    "63 yaşında vefat etmiştir.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in kabri nerededir?",
    "Medine",
    [
      "Mekke",
      "Kudüs",
      "Taif"
    ],
    "Kabri Medine'dedir.",
    "TDV İslam Ansiklopedisi, Ravza-i Mutahhara"
  ],
  [
    "Siyer",
    2,
    "İsra ve Miraç olayı neyi ifade eder?",
    "Gece yolculuğu ve göğe yükseliş mucizesi",
    [
      "Hicret kervanı",
      "Bedir keşfi",
      "Hendek kazısı"
    ],
    "İsra ve Miraç özel bir mucizedir.",
    "TDV İslam Ansiklopedisi, İsrâ ve Mi'râc"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber hangi boydandır?",
    "Kureyş / Haşimoğulları",
    [
      "Evs",
      "Hazreç",
      "Sakif"
    ],
    "Haşimoğulları'ndandır.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    2,
    "Taif yolculuğunun amacı neydi?",
    "İslam'ı tebliğ etmek",
    [
      "Kâbe'yi taşımak",
      "Deniz ticareti kurmak",
      "Ordu toplamak"
    ],
    "Taif'te tebliğ yapılmıştır.",
    "TDV İslam Ansiklopedisi, Tâif"
  ],
  [
    "Siyer",
    1,
    "Erkam'ın evi ne için kullanılmıştır?",
    "Gizli tebliğ ve eğitim mekânı",
    [
      "Yalnızca ticaret deposu",
      "Yalnızca silah imalathanesi",
      "Yalnızca gümrük kapısı"
    ],
    "Dârülkamm erken dönem eğitim yeridir.",
    "TDV İslam Ansiklopedisi, Dârülerkam"
  ],
  [
    "Siyer",
    2,
    "Akabe biatları nerede gerçekleşmiştir?",
    "Mina yakınlarında",
    [
      "Bedir ovasında",
      "Hayber kalesinde",
      "Hudeybiye çölünde yalnızca"
    ],
    "Akabe biatları hac döneminde yapılmıştır.",
    "TDV İslam Ansiklopedisi, Akabe Biatları"
  ],
  [
    "Siyer",
    1,
    "Medine Sözleşmesi neyi düzenlemiştir?",
    "Medine toplumunun ortak esaslarını",
    [
      "Yalnızca Kâbe örtüsünü",
      "Yalnızca Fil ordusunu",
      "Yalnızca Bizans vergisini"
    ],
    "Medine Vesikası şehir düzenini belirlemiştir.",
    "TDV İslam Ansiklopedisi, Medine Sözleşmesi"
  ],
  [
    "Siyer",
    2,
    "Huneyn Savaşı hangi olaydan sonra olmuştur?",
    "Mekke'nin fethinden sonra",
    [
      "İlk vahiyden hemen sonra",
      "Fil Vakası'ndan önce",
      "Hicretten bir gün önce"
    ],
    "Huneyn fetih sonrasındadır.",
    "TDV İslam Ansiklopedisi, Huneyn Gazvesi"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in dedesi kimdir?",
    "Abdülmuttalib",
    [
      "Ebu Cehil",
      "Ebu Leheb",
      "Utbe"
    ],
    "Dedesi Abdülmuttalib'dir.",
    "TDV İslam Ansiklopedisi, Abdülmuttalib"
  ],
  [
    "Siyer",
    2,
    "Şakk-ı sadr olayı siyerde nasıl anılır?",
    "Göğsün açılması mucizesi rivayeti",
    [
      "Hendek kazısı",
      "Kâbe tamiri",
      "Çarşı denetimi"
    ],
    "Şakk-ı sadr erken dönem mucize rivayetidir.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in süt kardeşi olarak bilinen isimlerden biri kimdir?",
    "Şeymâ",
    [
      "Ebu Cehil",
      "Ebu Leheb",
      "Velid"
    ],
    "Şeymâ süt kardeşi olarak anılır.",
    "TDV İslam Ansiklopedisi, Şeymâ"
  ],
  [
    "Siyer",
    2,
    "Boykot yılları neyi ifade eder?",
    "Hâşimoğulları'na uygulanan ambargo",
    [
      "Hac menasikinin iptali",
      "Namazın yasaklanması",
      "Orucun farz oluşu"
    ],
    "Boykot erken dönem baskı dönemidir.",
    "TDV İslam Ansiklopedisi, Boykot"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in ilk inşa ettiği mescitlerden biri hangisidir?",
    "Kuba Mescidi",
    [
      "Mescid-i Aksa'nın tamamı",
      "Eyüp Sultan",
      "Sultanahmet"
    ],
    "Kuba, hicret yolundaki önemli mescittir.",
    "TDV İslam Ansiklopedisi, Kubâ Mescidi"
  ],
  [
    "Siyer",
    3,
    "Ci'râne hangi olayla anılır?",
    "Huneyn sonrası ganimet dağıtımı",
    [
      "Bedir kuyuları",
      "Uhud şehitliği",
      "Hira inzivası"
    ],
    "Ci'râne Huneyn sonrasıyla anılır.",
    "TDV İslam Ansiklopedisi, Ci'râne"
  ],
  [
    "Siyer",
    2,
    "Rıdvan Biatı hangi süreçtedir?",
    "Hudeybiye süreci",
    [
      "Fil Vakası",
      "Ashab-ı Kehf",
      "Yalnızca Taif dönüşü"
    ],
    "Rıdvan Biatı Hudeybiye ile bağlıdır.",
    "TDV İslam Ansiklopedisi, Rıdvân Biatı"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in doğum yılı geleneksel olarak nasıl anılır?",
    "Fil Yılı",
    [
      "Bedir Yılı",
      "Fetih Yılı",
      "Hendek Yılı"
    ],
    "Doğum Fil Yılı ile anılır.",
    "TDV İslam Ansiklopedisi, Muhammed"
  ],
  [
    "Siyer",
    1,
    "Yesrib hicretten sonra hangi adla anılmıştır?",
    "Medine",
    [
      "Taif",
      "Hayber",
      "Fadak"
    ],
    "Yesrib Medine adını almıştır.",
    "TDV İslam Ansiklopedisi, Medine"
  ],
  [
    "Siyer",
    1,
    "Sahabe kimdir?",
    "Peygamber'i mümin olarak görüp müslüman ölen kimse",
    [
      "Yalnızca tabiîn",
      "Yalnızca mezhep imamı",
      "Yalnızca müfessir"
    ],
    "Sahabe, Peygamber'i gören müminlerdir.",
    "TDV İslam Ansiklopedisi, Sahâbe"
  ],
  [
    "Siyer",
    2,
    "Hicrette yolda eşlik eden sahabi kimdir?",
    "Ebu Bekir",
    [
      "Ömer",
      "Osman",
      "Hamza"
    ],
    "Hicrette Ebu Bekir refakat etmiştir.",
    "TDV İslam Ansiklopedisi, Hicret"
  ],
  [
    "Siyer",
    3,
    "Dârünnedve neydi?",
    "Kureyş'in istişare meclisi",
    [
      "Namazgâh",
      "Zekât evi",
      "Hac menzili"
    ],
    "Dârünnedve Kureyş istişare yeridir.",
    "TDV İslam Ansiklopedisi, Dârünnedve"
  ],
  [
    "Siyer",
    2,
    "Veda Haccı hangi yılda yapılmıştır?",
    "Hicri 10",
    [
      "Hicri 1",
      "Hicri 3",
      "Hicri 6"
    ],
    "Veda Haccı hicri 10. yıldadır.",
    "TDV İslam Ansiklopedisi, Veda Haccı"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in son hastalığında namazı kim kıldırmıştır?",
    "Ebu Bekir",
    [
      "Ömer",
      "Osman",
      "Ali"
    ],
    "Namazı Hz. Ebu Bekir kıldırmıştır.",
    "TDV İslam Ansiklopedisi, Ebû Bekir"
  ],
  [
    "Siyer",
    2,
    "Kıble değişikliği neyi göstermiştir?",
    "Kudüs'ten Kâbe'ye yönelişi",
    [
      "Namazın kaldırılmasını",
      "Orucun kaldırılmasını",
      "Haccın kaldırılmasını"
    ],
    "Kıble Kâbe'ye çevrilmiştir.",
    "TDV İslam Ansiklopedisi, Kıble"
  ],
  [
    "Siyer",
    1,
    "Ebu Talib kimdir?",
    "Hz. Peygamber'in amcası ve koruyucusu",
    [
      "Bizans imparatoru",
      "Taif kralı",
      "Hayber reisi"
    ],
    "Ebu Talib amca ve koruyucudur.",
    "TDV İslam Ansiklopedisi, Ebû Tâlib"
  ],
  [
    "Siyer",
    2,
    "Bedir zaferinin önemi nedir?",
    "İslam'ın ilk büyük meydan zaferi oluşu",
    [
      "Haccın farz oluşu",
      "Zekâtın kalkması",
      "Orucun kalkması"
    ],
    "Bedir ilk büyük zafer olarak anılır.",
    "TDV İslam Ansiklopedisi, Bedir Gazvesi"
  ],
  [
    "Siyer",
    2,
    "Uhud'da okçuların yerini terk etmesinin sonucu ne olmuştur?",
    "Savaşın seyri aleyhe dönmüştür",
    [
      "Hemen fetih olmuştur",
      "Hicret başlamıştır",
      "Boykot bitmiştir"
    ],
    "Okçuların ayrılması savaşı etkilemiştir.",
    "TDV İslam Ansiklopedisi, Uhud Gazvesi"
  ],
  [
    "Siyer",
    1,
    "Hz. Peygamber'in çocuklarından biri kimdir?",
    "Fatıma",
    [
      "Hatice'nin annesi",
      "Halime",
      "Âmine"
    ],
    "Hz. Fatıma kızıdır.",
    "TDV İslam Ansiklopedisi, Fâtıma"
  ],
  [
    "Siyer",
    3,
    "Mute Seferi hangi güce karşı yapılmıştır?",
    "Bizans sınır güçlerine",
    [
      "Yalnızca Sakif'e",
      "Yalnızca Evs'e",
      "Yalnızca Hazreç'e"
    ],
    "Mute, Bizans hattıyla ilgilidir.",
    "TDV İslam Ansiklopedisi, Mute"
  ],
  [
    "Siyer",
    2,
    "Hayber'in fethi neyi sağlamıştır?",
    "Kuzeydeki önemli bir kalenin alınmasını",
    [
      "Kâbe'nin yıkılmasını",
      "Namazın iptalini",
      "Orucun kalkmasını"
    ],
    "Hayber seferi stratejik bir zaferdir.",
    "TDV İslam Ansiklopedisi, Hayber"
  ],
  [
    "Siyer",
    1,
    "Ezana dair uygulamalar hangi dönemde yerleşmiştir?",
    "Medine döneminde",
    [
      "Fil Vakası'nda",
      "Yalnızca boykot yıllarında",
      "Yalnızca Taif dönüşünde"
    ],
    "Ezan Medine'de kurumsallaşmıştır.",
    "TDV İslam Ansiklopedisi, Ezan"
  ],
  [
    "Siyer",
    2,
    "Hz. Peygamber'in ahlakını özetleyen bilinen vurgu nedir?",
    "Üstün ahlak üzere oluşu",
    [
      "Mal biriktirme tutkusu",
      "Güç gösterisi tutkusu",
      "Soy övünme tutkusu"
    ],
    "Kur'an ve siyer üstün ahlakı vurgular.",
    "Diyanet Kur'an Yolu, Kalem 68/4"
  ],
  [
    "Peygamberler tarihi",
    1,
    "İlk insan ve peygamber kimdir?",
    "Hz. Âdem",
    [
      "Hz. Nuh",
      "Hz. İbrahim",
      "Hz. Musa"
    ],
    "İlk insan ve peygamber Hz. Âdem'dir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Tufan kıssası hangi peygamberle anılır?",
    "Hz. Nuh",
    [
      "Hz. Hud",
      "Hz. Salih",
      "Hz. Lut"
    ],
    "Tufan Hz. Nuh ile anlatılır.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi, Nûh"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Kâbe'nin temellerini yükselten peygamberler kimlerdir?",
    "Hz. İbrahim ve Hz. İsmail",
    [
      "Hz. Musa ve Hz. Harun",
      "Hz. Davud ve Hz. Süleyman",
      "Hz. Yahya ve Hz. İsa"
    ],
    "Kur'an İbrahim-İsmail'in Kâbe'yi yükseltmesini anlatır.",
    "Diyanet Kur'an Yolu, Bakara 2/127"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Asâ mucizesi hangi peygamberle anılır?",
    "Hz. Musa",
    [
      "Hz. İsa",
      "Hz. Yunus",
      "Hz. Eyyub"
    ],
    "Hz. Musa'nın asâ mucizesi anlatılır.",
    "Diyanet Kur'an Yolu, Şuara"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Beşikte konuşma mucizesi hangi peygamberle ilişkilendirilir?",
    "Hz. İsa",
    [
      "Hz. Musa",
      "Hz. Yusuf",
      "Hz. Yunus"
    ],
    "Kur'an Hz. İsa'nın mucizelerinden bahseder.",
    "Diyanet Kur'an Yolu, Meryem"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Kuyuya atılma kıssası hangi peygambere aittir?",
    "Hz. Yusuf",
    [
      "Hz. Yunus",
      "Hz. Eyyub",
      "Hz. Salih"
    ],
    "Yusuf kıssasında kuyuya atılma anlatılır.",
    "Diyanet Kur'an Yolu, Yusuf"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Balık kıssası hangi peygamberledir?",
    "Hz. Yunus",
    [
      "Hz. Yusuf",
      "Hz. Musa",
      "Hz. İlyas"
    ],
    "Yunus kıssası balık hadisesiyle anılır.",
    "Diyanet Kur'an Yolu, Saffat"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Sabır örneği olarak anılan peygamber kimdir?",
    "Hz. Eyyub",
    [
      "Hz. Lut",
      "Hz. Hud",
      "Hz. Şuayb"
    ],
    "Hz. Eyyub sabrıyla anılır.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi, Eyyûb"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Putları kıran peygamber hangisidir?",
    "Hz. İbrahim",
    [
      "Hz. Nuh",
      "Hz. Yunus",
      "Hz. İdris"
    ],
    "İbrahim kıssasında putların kırılması anlatılır.",
    "Diyanet Kur'an Yolu, Enbiya"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Tevrat hangi peygambere verilmiştir?",
    "Hz. Musa",
    [
      "Hz. İsa",
      "Hz. Davud",
      "Hz. İbrahim"
    ],
    "Tevrat Hz. Musa'ya verilmiştir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Zebur hangi peygambere verilmiştir?",
    "Hz. Davud",
    [
      "Hz. Musa",
      "Hz. İsa",
      "Hz. İbrahim"
    ],
    "Zebur Hz. Davud'a verilmiştir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    1,
    "İncil hangi peygambere nispet edilir?",
    "Hz. İsa",
    [
      "Hz. Musa",
      "Hz. Davud",
      "Hz. Nuh"
    ],
    "İncil Hz. İsa'ya nispet edilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Kur'an'da Halilullah diye anılan peygamber kimdir?",
    "Hz. İbrahim",
    [
      "Hz. Musa",
      "Hz. İsa",
      "Hz. Nuh"
    ],
    "Hz. İbrahim Halilullah diye anılır.",
    "TDV İslam Ansiklopedisi, İbrâhîm"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Semud kavmine gönderilen peygamber kimdir?",
    "Hz. Salih",
    [
      "Hz. Hud",
      "Hz. Lut",
      "Hz. Şuayb"
    ],
    "Semud'a Hz. Salih gönderilmiştir.",
    "TDV İslam Ansiklopedisi, Sâlih"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Âd kavmine gönderilen peygamber kimdir?",
    "Hz. Hud",
    [
      "Hz. Salih",
      "Hz. Lut",
      "Hz. Şuayb"
    ],
    "Âd kavmine Hz. Hud gönderilmiştir.",
    "TDV İslam Ansiklopedisi, Hûd"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Medyen halkına gönderilen peygamber kimdir?",
    "Hz. Şuayb",
    [
      "Hz. Hud",
      "Hz. Salih",
      "Hz. Yunus"
    ],
    "Medyen'e Hz. Şuayb gönderilmiştir.",
    "TDV İslam Ansiklopedisi, Şuayb"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İsmail kimin oğludur?",
    "Hz. İbrahim'in",
    [
      "Hz. Musa'nın",
      "Hz. Nuh'un",
      "Hz. Yusuf'un"
    ],
    "Hz. İsmail Hz. İbrahim'in oğludur.",
    "TDV İslam Ansiklopedisi, İsmâil"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İshak kimin oğludur?",
    "Hz. İbrahim'in",
    [
      "Hz. Nuh'un",
      "Hz. Hud'un",
      "Hz. Salih'in"
    ],
    "Hz. İshak Hz. İbrahim'in oğludur.",
    "TDV İslam Ansiklopedisi, İshak"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Mısır'da yönetici konumuna yükselen peygamber kimdir?",
    "Hz. Yusuf",
    [
      "Hz. Yunus",
      "Hz. Eyyub",
      "Hz. İlyas"
    ],
    "Hz. Yusuf Mısır'da görev almıştır.",
    "Diyanet Kur'an Yolu, Yusuf"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Harun hangi peygamberin kardeşidir?",
    "Hz. Musa",
    [
      "Hz. İsa",
      "Hz. İbrahim",
      "Hz. Nuh"
    ],
    "Hz. Harun Hz. Musa'nın kardeşidir.",
    "TDV İslam Ansiklopedisi, Hârûn"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Zekeriya'nın oğlu olan peygamber kimdir?",
    "Hz. Yahya",
    [
      "Hz. İsa",
      "Hz. Musa",
      "Hz. Yusuf"
    ],
    "Hz. Yahya Hz. Zekeriya'nın oğludur.",
    "TDV İslam Ansiklopedisi, Yahyâ"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Meryem'in oğlu olan peygamber kimdir?",
    "Hz. İsa",
    [
      "Hz. Yahya",
      "Hz. Musa",
      "Hz. Yusuf"
    ],
    "Hz. İsa Hz. Meryem'in oğludur.",
    "Diyanet Kur'an Yolu, Meryem"
  ],
  [
    "Peygamberler tarihi",
    3,
    "Ulu'l-azm peygamberler kimlerdir?",
    "Nuh, İbrahim, Musa, İsa ve Muhammed",
    [
      "Yalnızca Yusuf ve Yunus",
      "Yalnızca Hud ve Salih",
      "Yalnızca Davud ve Süleyman"
    ],
    "Ulu'l-azm beş büyük peygamberdir.",
    "TDV İslam Ansiklopedisi, Ulü'l-azm"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Süleyman hangi yönüyle de anılır?",
    "Hükümdar-peygamber",
    [
      "Yalnızca çiftçi",
      "Yalnızca demirci",
      "Yalnızca denizci"
    ],
    "Hz. Süleyman hükümdar-peygamber olarak anılır.",
    "TDV İslam Ansiklopedisi, Süleyman"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Davud hangi yönüyle de anılır?",
    "Hükümdar-peygamber ve Zebur sahibi",
    [
      "Yalnızca tacir",
      "Yalnızca çiftçi",
      "Yalnızca kâhin"
    ],
    "Hz. Davud Zebur ve hükümdarlıkla anılır.",
    "TDV İslam Ansiklopedisi, Dâvûd"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Lut hangi kavme gönderilmiştir?",
    "Lut kavmine",
    [
      "Âd kavmine",
      "Semud kavmine",
      "Medyen'e"
    ],
    "Hz. Lut kendi kavmine gönderilmiştir.",
    "TDV İslam Ansiklopedisi, Lût"
  ],
  [
    "Peygamberler tarihi",
    3,
    "Hz. İdris hakkında Kur'an'da geçen vurgu nedir?",
    "Doğru bir peygamber oluşu",
    [
      "Denizci oluşu",
      "Demirci oluşu",
      "Tacir oluşu"
    ],
    "Kur'an Hz. İdris'i doğru bir peygamber olarak anar.",
    "Diyanet Kur'an Yolu, Meryem 19/56"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. İsmail ile ilgili Kâbe hizmeti nasıl anılır?",
    "Babasıyla Kâbe'yi yükseltmesi",
    [
      "Tevrat yazması",
      "İncil yazması",
      "Zebur yazması"
    ],
    "İsmail, İbrahim ile Kâbe'yi yükseltmiştir.",
    "Diyanet Kur'an Yolu, Bakara 2/127"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Son peygamber kimdir?",
    "Hz. Muhammed",
    [
      "Hz. İsa",
      "Hz. Musa",
      "Hz. İbrahim"
    ],
    "Son peygamber Hz. Muhammed'dir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Musa'ya verilen mucizelerden biri nedir?",
    "Denizin yarılması",
    [
      "Balığa yutulma",
      "Kuyuya atılma",
      "Put kırma"
    ],
    "Denizin yarılması Musa kıssasındadır.",
    "Diyanet Kur'an Yolu, Şuara"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İbrahim'in ateşe atılması kıssası neyi gösterir?",
    "Allah'ın yardımını ve imanı",
    [
      "Ticaret kârını",
      "Ganimet paylaşımını",
      "Miras dilimini"
    ],
    "Ateş kıssası iman imtihanıdır.",
    "Diyanet Kur'an Yolu, Enbiya"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Nuh'un gemisi kıssası neyi anlatır?",
    "İman edenlerin kurtuluşunu",
    [
      "Çarşı kurmayı",
      "Kâbe örtüsünü",
      "Zekât nisabını"
    ],
    "Gemi kıssası kurtuluşu anlatır.",
    "Diyanet Kur'an Yolu, Hud"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Yakub hangi peygamberin babasıdır?",
    "Hz. Yusuf'un",
    [
      "Hz. Yunus'un",
      "Hz. Hud'un",
      "Hz. Salih'in"
    ],
    "Hz. Yakub Hz. Yusuf'un babasıdır.",
    "TDV İslam Ansiklopedisi, Ya'kûb"
  ],
  [
    "Peygamberler tarihi",
    3,
    "Zülkarneyn kıssası hangi surededir?",
    "Kehf",
    [
      "Yasin",
      "Mülk",
      "Rahmân"
    ],
    "Zülkarneyn Kehf suresinde anlatılır.",
    "Diyanet Kur'an Yolu, Kehf"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Salih'in kavmine verilen deve mucizesi nasıl anılır?",
    "Allah'ın ayeti olarak deve",
    [
      "Ticaret gemisi",
      "Savaş atı",
      "Hazine sandığı"
    ],
    "Semud'a deve mucizesi verilmiştir.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi, Sâlih"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İsa'ya verilen kitap hangisidir?",
    "İncil",
    [
      "Tevrat",
      "Zebur",
      "Suhuf"
    ],
    "İncil Hz. İsa'ya nispet edilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Musa'nın kardeşi yardımcı olarak kimdir?",
    "Hz. Harun",
    [
      "Hz. Yusuf",
      "Hz. Yunus",
      "Hz. Lut"
    ],
    "Harun Musa'ya yardımcı olmuştur.",
    "TDV İslam Ansiklopedisi, Hârûn"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İbrahim'e verilen sahifelere ne ad verilir?",
    "Suhuf",
    [
      "Zebur",
      "İncil",
      "Mesnevi"
    ],
    "İbrahim'e suhuf verildiği bildirilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Lokman kıssasında öne çıkan tema nedir?",
    "Hikmetli öğütler",
    [
      "Savaş taktiği",
      "Ganimet paylaşımı",
      "Miras hesabı"
    ],
    "Lokman hikmet ve öğütle anılır.",
    "Diyanet Kur'an Yolu, Lokman"
  ],
  [
    "Peygamberler tarihi",
    3,
    "Ashab-ı Ress kıssası neyi hatırlatır?",
    "Geçmiş kavimlerin ibretlik akıbetini",
    [
      "Ticaret yolunu",
      "Hac menzillerini",
      "Namaz vakitlerini"
    ],
    "Ashab-ı Ress ibret kıssalarındandır.",
    "Diyanet Kur'an Yolu; TDV İslam Ansiklopedisi"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Muhammed hangi kitabın peygamberidir?",
    "Kur'an",
    [
      "Tevrat",
      "İncil",
      "Zebur"
    ],
    "Kur'an son kitaptır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Yusuf'un rüya tabiri yeteneği kıssada neyi gösterir?",
    "Allah'ın verdiği ilmi",
    [
      "Ticaret zekâsını",
      "Savaş gücünü",
      "Soy üstünlüğünü"
    ],
    "Yusuf'a rüya ilmi verilmiştir.",
    "Diyanet Kur'an Yolu, Yusuf"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. Nuh'a uzun süre ne yapması emredilmiştir?",
    "Kavmini hakka çağırması",
    [
      "Kâbe'yi yıkması",
      "Denizi kapatması",
      "Çarşıyı yakması"
    ],
    "Nuh kavmini uzun süre davet etmiştir.",
    "Diyanet Kur'an Yolu, Nuh"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. İsa'nın havarileri nasıl anılır?",
    "Yardımcıları ve inananları",
    [
      "Düşman ordusu",
      "Ticaret ortakları",
      "Vergi memurları"
    ],
    "Havariler İsa'nın yardımcılarıdır.",
    "TDV İslam Ansiklopedisi, Havârî"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Peygamberlerin ortak tebliğ özü nedir?",
    "Allah'a kulluk ve tevhid",
    [
      "Mal biriktirme",
      "Soy övünme",
      "Güç yarışı"
    ],
    "Bütün peygamberler tevhide çağırmıştır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Kur'an'da adı geçen peygamber sayısı yaklaşık kaçtır?",
    "25 civarı",
    [
      "3",
      "7",
      "100"
    ],
    "Kur'an'da ismi geçen peygamberlerin sayısı yaygın olarak yirmi beş civarında kabul edilir.",
    "TDV İslam Ansiklopedisi, Peygamber"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Musa'nın Firavun'a karşı duruşu neyi temsil eder?",
    "Hak davetini",
    [
      "Ticaret pazarlığını",
      "Ganimet paylaşımını",
      "Miras taksimini"
    ],
    "Musa-Firavun kıssası hak-batıl mücadelesidir.",
    "Diyanet Kur'an Yolu, Tâhâ"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Hz. İbrahim'in oğlunu kurban etme kıssası neyi öğretir?",
    "Teslimiyet ve imtihanı",
    [
      "Ticaret kârını",
      "Savaş ganimetini",
      "Şehir planını"
    ],
    "Kurban kıssası teslimiyeti anlatır.",
    "Diyanet Kur'an Yolu, Saffat"
  ],
  [
    "Peygamberler tarihi",
    2,
    "Hz. Süleyman'ın kuşlarla ilgili anlatımı hangi temadadır?",
    "Allah'ın lütfu ve mucizevi hâkimiyet",
    [
      "Sıradan avcılık",
      "Vergi toplama",
      "Çarşı denetimi"
    ],
    "Süleyman kıssasında özel lütuflar anlatılır.",
    "Diyanet Kur'an Yolu, Neml"
  ],
  [
    "Peygamberler tarihi",
    1,
    "Son semavi kitap hangisidir?",
    "Kur'an",
    [
      "Tevrat",
      "İncil",
      "Zebur"
    ],
    "Son kitap Kur'an'dır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İslam tarihi",
    1,
    "İlk halife kimdir?",
    "Hz. Ebu Bekir",
    [
      "Hz. Ömer",
      "Hz. Osman",
      "Hz. Ali"
    ],
    "İlk halife Hz. Ebu Bekir'dir.",
    "TDV İslam Ansiklopedisi, Ebû Bekir"
  ],
  [
    "İslam tarihi",
    1,
    "İkinci halife kimdir?",
    "Hz. Ömer",
    [
      "Hz. Ebu Bekir",
      "Hz. Osman",
      "Hz. Ali"
    ],
    "İkinci halife Hz. Ömer'dir.",
    "TDV İslam Ansiklopedisi, Ömer"
  ],
  [
    "İslam tarihi",
    1,
    "Üçüncü halife kimdir?",
    "Hz. Osman",
    [
      "Hz. Ebu Bekir",
      "Hz. Ömer",
      "Hz. Ali"
    ],
    "Üçüncü halife Hz. Osman'dır.",
    "TDV İslam Ansiklopedisi, Osmân"
  ],
  [
    "İslam tarihi",
    1,
    "Dördüncü halife kimdir?",
    "Hz. Ali",
    [
      "Hz. Ebu Bekir",
      "Hz. Ömer",
      "Hz. Osman"
    ],
    "Dördüncü halife Hz. Ali'dir.",
    "TDV İslam Ansiklopedisi, Ali"
  ],
  [
    "İslam tarihi",
    2,
    "Kur'an'ın mushaf haline getirilmesi ilk olarak kimin döneminde hız kazanmıştır?",
    "Hz. Ebu Bekir",
    [
      "Hz. Ömer'in son yılı yalnızca",
      "Emevilerin sonu",
      "Abbasilerin sonu"
    ],
    "Yemame sonrası cem çalışması Ebu Bekir dönemindedir.",
    "TDV İslam Ansiklopedisi, Mushaf"
  ],
  [
    "İslam tarihi",
    2,
    "Mushaf'ın çoğaltılıp vilayetlere gönderilmesi kimin döneminde olmuştur?",
    "Hz. Osman",
    [
      "Hz. Ebu Bekir'in ilk günü",
      "Yalnızca Emevi sonu",
      "Yalnızca Selçuklu"
    ],
    "Osmân döneminde resmi nüshalar çoğaltılmıştır.",
    "TDV İslam Ansiklopedisi, Osmân"
  ],
  [
    "İslam tarihi",
    1,
    "Hicri takvimin esas alınması kimin dönemine bağlanır?",
    "Hz. Ömer",
    [
      "Hz. Osman",
      "Hz. Ali",
      "Muaviye'nin son yılı"
    ],
    "Hicri takvim Hz. Ömer döneminde düzenlenmiştir.",
    "TDV İslam Ansiklopedisi, Hicrî Takvim"
  ],
  [
    "İslam tarihi",
    2,
    "Yemame Savaşı neden önemlidir?",
    "Birçok hâfızın şehit olması",
    [
      "Kâbe'nin yıkılması",
      "Namazın kalkması",
      "Orucun kalkması"
    ],
    "Yemame'de birçok hâfız şehit olmuştur.",
    "TDV İslam Ansiklopedisi, Yemâme"
  ],
  [
    "İslam tarihi",
    1,
    "Dört halife dönemine ne ad verilir?",
    "Hulefâ-yi Râşidîn",
    [
      "Emevi devri",
      "Abbasi devri",
      "Endülüs devri"
    ],
    "Dört halife Râşidîn diye anılır.",
    "TDV İslam Ansiklopedisi, Hulefâ-yi Râşidîn"
  ],
  [
    "İslam tarihi",
    2,
    "Kudüs'ün fethi hangi halife dönemindedir?",
    "Hz. Ömer",
    [
      "Hz. Ebu Bekir'in ilk ayı",
      "Hz. Osman'ın son günü yalnızca",
      "Abbasi sonu"
    ],
    "Kudüs Hz. Ömer döneminde açılmıştır.",
    "TDV İslam Ansiklopedisi, Ömer"
  ],
  [
    "İslam tarihi",
    1,
    "Emevi Devleti'nin kurucusu olarak anılan isim kimdir?",
    "Muaviye b. Ebu Süfyan",
    [
      "Harun Reşid",
      "Me'mun",
      "Mutevekkil"
    ],
    "Emevi iktidarı Muaviye ile anılır.",
    "TDV İslam Ansiklopedisi, Emevîler"
  ],
  [
    "İslam tarihi",
    2,
    "Abbasi Devleti'nin merkezi sonradan hangi şehir olmuştur?",
    "Bağdat",
    [
      "Mekke",
      "Medine",
      "Taif"
    ],
    "Abbasiler Bağdat'ı merkez yapmıştır.",
    "TDV İslam Ansiklopedisi, Abbâsîler"
  ],
  [
    "İslam tarihi",
    2,
    "Endülüs İslam medeniyeti hangi coğrafyadadır?",
    "İber Yarımadası",
    [
      "Orta Asya bozkırı",
      "Güney Afrika",
      "Sibirya"
    ],
    "Endülüs İspanya coğrafyasındadır.",
    "TDV İslam Ansiklopedisi, Endülüs"
  ],
  [
    "İslam tarihi",
    1,
    "İstanbul'u fetheden Osmanlı padişahı kimdir?",
    "Fatih Sultan Mehmet",
    [
      "Yavuz Sultan Selim",
      "Kanuni Sultan Süleyman",
      "I. Murad"
    ],
    "İstanbul'u Fatih fethetmiştir.",
    "TDV İslam Ansiklopedisi, İstanbul'un Fethi"
  ],
  [
    "İslam tarihi",
    2,
    "İstanbul'un fethi hangi yıldadır?",
    "1453",
    [
      "1071",
      "1299",
      "1517"
    ],
    "Fetih 1453'tedir.",
    "TDV İslam Ansiklopedisi, İstanbul'un Fethi"
  ],
  [
    "İslam tarihi",
    1,
    "Malazgirt Zaferi hangi yılda kazanılmıştır?",
    "1071",
    [
      "1453",
      "1299",
      "1517"
    ],
    "Malazgirt 1071'dedir.",
    "TDV İslam Ansiklopedisi, Malazgirt Muharebesi"
  ],
  [
    "İslam tarihi",
    2,
    "Malazgirt'te zafer kazanan komutan kimdir?",
    "Alparslan",
    [
      "Fatih",
      "Yavuz",
      "Kanuni"
    ],
    "Alparslan Malazgirt zaferini kazanmıştır.",
    "TDV İslam Ansiklopedisi, Alparslan"
  ],
  [
    "İslam tarihi",
    1,
    "Osmanlı Devleti'nin kurucusu kimdir?",
    "Osman Bey",
    [
      "Orhan Bey'in torunu yalnızca",
      "Fatih",
      "Yavuz"
    ],
    "Kurucu Osman Bey'dir.",
    "TDV İslam Ansiklopedisi, Osman Gazi"
  ],
  [
    "İslam tarihi",
    2,
    "Yavuz Sultan Selim'in Mısır seferi neyi etkilemiştir?",
    "Hilafet ve Haremeyn hizmetlerini",
    [
      "Yalnızca Amerika keşfini",
      "Yalnızca Çin Seddi'ni",
      "Yalnızca Vikingleri"
    ],
    "Mısır seferi Osmanlı'yı Haremeyn ile bağladı.",
    "TDV İslam Ansiklopedisi, Selim I"
  ],
  [
    "İslam tarihi",
    1,
    "Kanuni Sultan Süleyman hangi devletle anılır?",
    "Osmanlı",
    [
      "Emevi",
      "Abbasi",
      "Safevi yalnızca"
    ],
    "Kanuni Osmanlı padişahıdır.",
    "TDV İslam Ansiklopedisi, Süleyman I"
  ],
  [
    "İslam tarihi",
    2,
    "Beytülmal ne demektir?",
    "Devlet hazinesi",
    [
      "Özel çarşı",
      "Yalnızca mescit avlusu",
      "Yalnızca mezarlık"
    ],
    "Beytülmal kamu hazinesidir.",
    "TDV İslam Ansiklopedisi, Beytülmâl"
  ],
  [
    "İslam tarihi",
    3,
    "Kadisiye Savaşı hangi güçle yapılmıştır?",
    "Sasanilerle",
    [
      "Vikinglerle",
      "Azteklerle",
      "Moğol öncesi Çin'le yalnızca"
    ],
    "Kadisiye Sasani cephesidir.",
    "TDV İslam Ansiklopedisi, Kādisiye"
  ],
  [
    "İslam tarihi",
    2,
    "Nihavend Savaşı'nın sonucu ne olmuştur?",
    "Sasani direnişinin kırılması",
    [
      "Kâbe'nin yıkılması",
      "Namazın kalkması",
      "Orucun kalkması"
    ],
    "Nihavend Sasani gücünü sarsmıştır.",
    "TDV İslam Ansiklopedisi, Nihâvend"
  ],
  [
    "İslam tarihi",
    1,
    "Kudüs'teki mübarek mescid hangisidir?",
    "Mescid-i Aksa",
    [
      "Mescid-i Nebevî'nin tamamı",
      "Kuba'nın tamamı",
      "Sultanahmet"
    ],
    "Mescid-i Aksa Kudüs'tedir.",
    "TDV İslam Ansiklopedisi, Mescid-i Aksâ"
  ],
  [
    "İslam tarihi",
    2,
    "Emevi döneminde İslam ordularının ulaştığı batı ucu neresidir?",
    "Endülüs / İberya",
    [
      "Japonya",
      "Avustralya",
      "Alaska"
    ],
    "Fetihler Endülüs'e uzanmıştır.",
    "TDV İslam Ansiklopedisi, Endülüs"
  ],
  [
    "İslam tarihi",
    1,
    "Hicri takvimin başlangıcı hangi olaydır?",
    "Hicret",
    [
      "Bedir",
      "Fetih",
      "Veda Haccı"
    ],
    "Takvim hicreti esas alır.",
    "TDV İslam Ansiklopedisi, Hicrî Takvim"
  ],
  [
    "İslam tarihi",
    2,
    "Ridde olayları hangi dönemde yaşanmıştır?",
    "Hz. Ebu Bekir dönemi",
    [
      "Kanuni dönemi",
      "Fatih dönemi",
      "Yavuz dönemi"
    ],
    "Ridde Ebu Bekir dönemindedir.",
    "TDV İslam Ansiklopedisi, Ridde"
  ],
  [
    "İslam tarihi",
    3,
    "Cemel Vakası hangi dönemde meydana gelmiştir?",
    "Hz. Ali dönemi",
    [
      "Hz. Ebu Bekir'in ilk günü",
      "Osmanlı kuruluşu",
      "Abbasi sonu"
    ],
    "Cemel Hz. Ali döneminde geçmiştir.",
    "TDV İslam Ansiklopedisi, Cemel Vakası"
  ],
  [
    "İslam tarihi",
    2,
    "Sıffin Savaşı hangi taraflar arasında olmuştur?",
    "Hz. Ali ile Muaviye taraftarları",
    [
      "Bizans ile Vikingler",
      "Selçuklu ile Haçlı öncesi Çin",
      "Endülüs ile Aztekler"
    ],
    "Sıffin Ali-Muaviye gerilimindedir.",
    "TDV İslam Ansiklopedisi, Sıffîn"
  ],
  [
    "İslam tarihi",
    1,
    "İslam'da ilk ezanı okuyan sahabi kimdir?",
    "Bilal-i Habeşi",
    [
      "Ebu Cehil",
      "Ebu Leheb",
      "Velid"
    ],
    "İlk müezzin Bilal'dir.",
    "TDV İslam Ansiklopedisi, Bilâl-i Habeşî"
  ],
  [
    "İslam tarihi",
    2,
    "Kâbe'nin İslamî dönemde putlardan temizlenmesi hangi olayla anılır?",
    "Mekke'nin fethi",
    [
      "Fil Vakası",
      "Bedir öncesi",
      "Uhud öncesi"
    ],
    "Fetihte Kâbe putlardan arındırılmıştır.",
    "TDV İslam Ansiklopedisi, Mekke'nin Fethi"
  ],
  [
    "İslam tarihi",
    1,
    "Ashab-ı Suffe kimlerdir?",
    "Mescid-i Nebevî'de ilimle meşgul sahabiler",
    [
      "Yalnızca tüccar kervanı",
      "Yalnızca put ustaları",
      "Yalnızca vergi memurları"
    ],
    "Suffe ashâbı ilim ehlidir.",
    "TDV İslam Ansiklopedisi, Ashâb-ı Suffe"
  ],
  [
    "İslam tarihi",
    2,
    "Tabiîn kimdir?",
    "Sahabeyi gören sonraki nesil",
    [
      "Peygamber'i görenler",
      "Yalnızca mezhep imamları",
      "Yalnızca padişahlar"
    ],
    "Tabiîn sahabeyi gören nesildir.",
    "TDV İslam Ansiklopedisi, Tâbiûn"
  ],
  [
    "İslam tarihi",
    3,
    "Tebeu't-tabiîn kimdir?",
    "Tabiîni gören nesil",
    [
      "Sahabenin tamamı",
      "Yalnızca Emevi vezirleri",
      "Yalnızca Haçlı şövalyeleri"
    ],
    "Tebeu't-tabiîn üçüncü nesildir.",
    "TDV İslam Ansiklopedisi, Tebeu't-tâbiîn"
  ],
  [
    "İslam tarihi",
    1,
    "Mescid-i Haram nerededir?",
    "Mekke",
    [
      "Medine",
      "Kudüs",
      "Taif"
    ],
    "Mescid-i Haram Mekke'dedir.",
    "TDV İslam Ansiklopedisi, Mescid-i Harâm"
  ],
  [
    "İslam tarihi",
    2,
    "Kerbela faciası hangi yılda meydana gelmiştir?",
    "Hicri 61",
    [
      "Hicri 1",
      "Hicri 2",
      "Hicri 8"
    ],
    "Kerbela hicri 61'dedir.",
    "TDV İslam Ansiklopedisi, Kerbela"
  ],
  [
    "İslam tarihi",
    1,
    "Hz. Hüseyin kimdir?",
    "Hz. Ali'nin oğlu",
    [
      "Emevi kurucusu",
      "Abbasi veziri",
      "Endülüs emiri"
    ],
    "Hz. Hüseyin Hz. Ali'nin oğludur.",
    "TDV İslam Ansiklopedisi, Hüseyin"
  ],
  [
    "İslam tarihi",
    2,
    "Selçukluların İslam tarihindeki önemi nedir?",
    "Orta Doğu'da güçlü bir Türk-İslam devleti oluşu",
    [
      "Amerika'yı keşfi",
      "Matbaayı ilk icadı iddiası",
      "Uçmayı bulması"
    ],
    "Selçuklular önemli bir İslam devletidir.",
    "TDV İslam Ansiklopedisi, Selçuklular"
  ],
  [
    "İslam tarihi",
    3,
    "Nizamiye medreseleri kimin adıyla anılır?",
    "Nizamülmülk",
    [
      "Fatih",
      "Yavuz",
      "Kanuni"
    ],
    "Nizamiye Nizamülmülk'le anılır.",
    "TDV İslam Ansiklopedisi, Nizâmiye Medresesi"
  ],
  [
    "İslam tarihi",
    2,
    "Haçlı Seferleri İslam dünyasında neyi etkilemiştir?",
    "Kudüs ve Şam hattındaki mücadeleleri",
    [
      "Yalnızca Çin çayını",
      "Yalnızca Viking mitlerini",
      "Yalnızca Aztek tapınaklarını"
    ],
    "Haçlılar Doğu Akdeniz'i etkilemiştir.",
    "TDV İslam Ansiklopedisi, Haçlılar"
  ],
  [
    "İslam tarihi",
    1,
    "Memlükler hangi coğrafyada güçlenmiştir?",
    "Mısır-Suriye",
    [
      "Japonya",
      "İskandinavya",
      "Patagonya"
    ],
    "Memlükler Mısır-Suriye'de hüküm sürmüştür.",
    "TDV İslam Ansiklopedisi, Memlûkler"
  ],
  [
    "İslam tarihi",
    2,
    "Aynicâlût Savaşı'nın önemi nedir?",
    "Moğol ilerleyişinin durdurulması",
    [
      "Kâbe'nin yıkılması",
      "Namazın kalkması",
      "Orucun kalkması"
    ],
    "Aynicâlût Moğollara karşı zaferdir.",
    "TDV İslam Ansiklopedisi, Aynicâlût"
  ],
  [
    "İslam tarihi",
    1,
    "Safevi Devleti hangi coğrafyada kurulmuştur?",
    "İran",
    [
      "Endülüs",
      "Anadolu'nun tamamı yalnızca",
      "Habeşistan"
    ],
    "Safeviler İran merkezlidir.",
    "TDV İslam Ansiklopedisi, Safevîler"
  ],
  [
    "İslam tarihi",
    2,
    "Timur hangi yüzyılda etkili bir hükümdardır?",
    "14-15. yüzyıl",
    [
      "7. yüzyıl başı",
      "3. yüzyıl",
      "21. yüzyıl"
    ],
    "Timur 14-15. yüzyılda etkilidir.",
    "TDV İslam Ansiklopedisi, Timur"
  ],
  [
    "İslam tarihi",
    1,
    "Buhari eserini ne türde yazmıştır?",
    "Hadis",
    [
      "Yalnızca coğrafya",
      "Yalnızca astronomi",
      "Yalnızca tipografi"
    ],
    "Buhari hadis âlimidir.",
    "TDV İslam Ansiklopedisi, Buhârî"
  ],
  [
    "İslam tarihi",
    2,
    "Müslim'in eseri hangi alandadır?",
    "Hadis",
    [
      "Yalnızca mimari",
      "Yalnızca denizcilik",
      "Yalnızca müzik"
    ],
    "Müslim hadis mecmuası sahibidir.",
    "TDV İslam Ansiklopedisi, Müslim"
  ],
  [
    "İslam tarihi",
    3,
    "Taberi hangi ilimlerle öne çıkar?",
    "Tarih ve tefsir",
    [
      "Yalnızca tipografi",
      "Yalnızca bahçıvanlık",
      "Yalnızca kuyumculuk"
    ],
    "Taberi tarih ve tefsir âlimidir.",
    "TDV İslam Ansiklopedisi, Taberî"
  ],
  [
    "İslam tarihi",
    1,
    "Gazali hangi alanlarda etkili bir âlimdir?",
    "Kelam, tasavvuf ve fıkıh düşüncesi",
    [
      "Yalnızca gemicilik",
      "Yalnızca madencilik",
      "Yalnızca matbaacılık"
    ],
    "Gazali çok yönlü bir âlimdir.",
    "TDV İslam Ansiklopedisi, Gazzâlî"
  ],
  [
    "İslam tarihi",
    2,
    "İbn Sina hangi alanda dünya çapında ünlenmiştir?",
    "Tıp ve felsefe",
    [
      "Yalnızca deniz savaşı",
      "Yalnızca kuyumculuk",
      "Yalnızca tipografi"
    ],
    "İbn Sina tıp ve felsefede ünlüdür.",
    "TDV İslam Ansiklopedisi, İbn Sînâ"
  ],
  [
    "İslam tarihi",
    1,
    "Hicaz demiryolu hangi dönemde gündeme gelmiştir?",
    "Osmanlı son dönemi",
    [
      "Hulefâ-yi Râşidîn başı",
      "Emevi ilk yılı",
      "Abbasi kuruluşu"
    ],
    "Hicaz demiryolu Osmanlı son dönemindedir.",
    "TDV İslam Ansiklopedisi, Hicaz Demiryolu"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "İslam'ın şartı kaçtır?",
    "5",
    [
      "3",
      "4",
      "6"
    ],
    "İslam'ın beş şartı vardır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "İmanın şartı kaçtır?",
    "6",
    [
      "3",
      "4",
      "5"
    ],
    "İmanın altı şartı vardır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Günde farz namaz kaç vakittir?",
    "5",
    [
      "3",
      "4",
      "6"
    ],
    "Beş vakit farz namaz vardır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Namazın farzlarından önce yapılan temizlik hangisidir?",
    "Abdest",
    [
      "Ticaret",
      "Yolculuk",
      "Oruç bozma"
    ],
    "Namaz için abdest alınır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Gusül ne zaman gerekir?",
    "Cünüplük ve benzeri hallerde",
    [
      "Her gülümseyişte",
      "Her alışverişte",
      "Her yolculukta zorunlu değil ifadesi yanlış"
    ],
    "Gusül belirli hallerde farzdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Oruç hangi ayda farzdır?",
    "Ramazan",
    [
      "Şevval",
      "Receb",
      "Muharrem"
    ],
    "Ramazan orucu farzdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Zekât kimlere farzdır?",
    "Nisap sahibi müslümanlara",
    [
      "Herkese yaş fark etmeksizin aynı",
      "Yalnızca çocuklara",
      "Yalnızca yolculara"
    ],
    "Zekât nisap şartıyla farzdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Hac kimlere farzdır?",
    "Gücü yeten müslümanlara",
    [
      "Yalnızca çocuklara",
      "Yalnızca yolculara zorunlu değil ifadesi yanlış",
      "Hiç kimseye"
    ],
    "Hac istitaat şartıyla farzdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Namazın kılınamayacağı vakitlerden biri hangisidir?",
    "Güneş doğarken",
    [
      "Öğle vakti girerken serbest",
      "İkindi farzı sonrası serbest",
      "Yatsı sonrası serbest"
    ],
    "Kerahiyet vakitlerinde namaz kılınmaz.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Ezan neyi bildirir?",
    "Namaz vaktinin girdiğini",
    [
      "Ticaret açılışını",
      "Savaş ilanını",
      "Miras paylaşımını"
    ],
    "Ezan namaz çağrısıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Kamet ne zaman getirilir?",
    "Farz namaza durmadan önce",
    [
      "Oruç açarken",
      "Zekât verirken",
      "Hacdan dönünce yalnızca"
    ],
    "Kamet farz namaz öncesidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Vitir namazı Diyanet Temel Dini Bilgiler'de hangi grupta yer alır?",
    "Müekked sünnet namazlar",
    [
      "Zekât nisabı hükümleri",
      "Hac menasiki",
      "Oruç bozma sebepleri"
    ],
    "Vitir namazı temel dini bilgilerde müekked sünnet namazlar arasında anlatılır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Teravih namazı hangi aya özgüdür?",
    "Ramazan",
    [
      "Şevval'in tamamı zorunlu",
      "Receb'in tamamı zorunlu",
      "Muharrem'in tamamı zorunlu"
    ],
    "Teravih Ramazan'da kılınır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Sadaka-i fıtır ne zaman verilir?",
    "Ramazan Bayramı öncesi",
    [
      "Kurban Bayramı sonrası zorunlu değil ifadesi yanlış",
      "Yalnızca hacda",
      "Yalnızca Cuma'da"
    ],
    "Fıtır sadakası bayram öncesi verilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Kurban ibadeti hangi bayramla anılır?",
    "Kurban Bayramı",
    [
      "Ramazan Bayramı",
      "Mevlid haftası",
      "Aşure günü yalnızca"
    ],
    "Kurban, Kurban Bayramı'nda kesilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Niyet ibadette neden önemlidir?",
    "Amelin sıhhati için temeldir",
    [
      "Sadece süs içindir",
      "Sadece ticaret içindir",
      "Hiç gerekli değildir"
    ],
    "Niyet ibadetin esaslarındandır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Teyemmüm ne zaman yapılır?",
    "Su bulunamadığında veya kullanılamadığında",
    [
      "Her yemekte",
      "Her alışverişte",
      "Her yolculukta zorunlu"
    ],
    "Teyemmüm özür halinde abdest yerine geçer.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Kıble neresidir?",
    "Kâbe yönü",
    [
      "Güneş doğusu daima",
      "Deniz kıyısı daima",
      "Rastgele yön"
    ],
    "Namazda kıble Kâbe'dir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Seferilik namazda neyi etkiler?",
    "Dört rekâtlı farzların kısaltılmasını",
    [
      "Orucun ebedi kalkmasını",
      "Zekâtın kalkmasını",
      "Haccın kalkmasını"
    ],
    "Yolcu namazı kısaltabilir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Cuma namazı kimlere farzdır?",
    "Belirli şartları taşıyan erkeklere",
    [
      "Yalnızca çocuklara",
      "Yalnızca yolculara her halde",
      "Hiç kimseye"
    ],
    "Cuma şartları oluşunca farzdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Hutbe hangi namazın parçasıdır?",
    "Cuma",
    [
      "Yatsı",
      "İmsak",
      "Kuşluk"
    ],
    "Cuma'da hutbe okunur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Rükû namazda ne demektir?",
    "Eğilmek",
    [
      "Oturmak",
      "Selam vermek",
      "Abdest almak"
    ],
    "Rükû eğilme rüknüdür.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Secde namazda ne demektir?",
    "Alnı yere koymak",
    [
      "Ayaktadurmak",
      "Selamlaşmak",
      "Zekât vermek"
    ],
    "Secde yer öpme/yer koyma rüknüdür.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Tahiyyat ne zaman okunur?",
    "Oturuşlarda",
    [
      "Yalnızca ezanda",
      "Yalnızca bayramda",
      "Yalnızca hacda"
    ],
    "Tahiyyat oturuşta okunur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Selam ile namaz nasıl tamamlanır?",
    "Sağa ve sola selam verilerek",
    [
      "Zekât verilerek",
      "Oruç tutularak",
      "Hacca gidilerek"
    ],
    "Namaz selamla biter.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Oruçta imsak neyi ifade eder?",
    "Oruca başlama vaktini",
    [
      "Bayramı",
      "Zekâtı",
      "Haccı"
    ],
    "İmsak oruç başlangıcıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "İftar ne demektir?",
    "Orucu açmak",
    [
      "Namaz kılmak",
      "Zekât vermek",
      "Hacca gitmek"
    ],
    "İftar orucu açmaktır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Kaza namazı neyi ifade eder?",
    "Vaktinde kılınamayan namazın sonradan kılınması",
    [
      "Namazın iptali",
      "Orucun iptali",
      "Haccın iptali"
    ],
    "Kaza, kaçırılan namazı telafidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Sünnet namazlar neye örnektir?",
    "Farza bağlı veya müstakil nafileler",
    [
      "Zekâtın kendisi",
      "Haccın kendisi",
      "Orucun kendisi"
    ],
    "Sünnetler nafile namazlardır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    3,
    "Nisap ne demektir?",
    "Zekât ve benzeri yükümlülük eşiği",
    [
      "Namaz rekâtı",
      "Oruç günü",
      "Hac menzili"
    ],
    "Nisap mali eşiktir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Fitre kimler için verilir?",
    "Kendisi ve bakmakla yükümlü olduğu kişiler için",
    [
      "Yalnızca komşu ülkeler için",
      "Yalnızca ticaret gemileri için",
      "Yalnızca hayvanlar için"
    ],
    "Fitre kişi başına hesaplanır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Tekbir namazda neyi ifade eder?",
    "Allahu ekber demeyi",
    [
      "Zekât vermeyi",
      "Oruç açmayı",
      "Hacdan dönmeyi"
    ],
    "İftitah tekbiri namaza giriştir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Abdestin farzlarından biri nedir?",
    "Yüzü yıkamak",
    [
      "Ticaret yapmak",
      "Şiir okumak",
      "Yolculuğa çıkmak"
    ],
    "Yüzün yıkanması abdest farzlarındandır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Mesh ne demektir?",
    "Islak el ile sürme",
    [
      "Oruç tutma",
      "Zekât verme",
      "Hacca gitme"
    ],
    "Mesh abdestte başa/ mestе sürülür.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Mest üzerine mesh neyi kolaylaştırır?",
    "Abdest almayı",
    [
      "Orucu",
      "Zekâtı",
      "Haccı"
    ],
    "Mest üzerine mesh ruhsattır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Cenaze namazı nasıl kılınır?",
    "Ayakta ve rükûsuz",
    [
      "Normal beş vakit gibi",
      "Oruçla birlikte",
      "Zekâtla birlikte"
    ],
    "Cenaze namazı özel kılınır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Bayram namazı ne zaman kılınır?",
    "Bayram sabahı",
    [
      "Her gece yarısı",
      "Her öğle öncesi zorunlu",
      "Her imsakta zorunlu"
    ],
    "Bayram namazı bayram sabahıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    3,
    "İtikâf nedir?",
    "Mescitte ibadetle inzivaya çekilmek",
    [
      "Ticaret gezisi",
      "Savaş eğitimi",
      "Şehir turu"
    ],
    "İtikâf özellikle Ramazan'da yapılır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Tesbih namazda ne için çekilir?",
    "Allah'ı anmak için",
    [
      "Ticaret hesabı için",
      "Yol ölçmek için",
      "Vergi için"
    ],
    "Tesbih zikir içindir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Kunut duası hangi namazla anılır?",
    "Vitir",
    [
      "Yalnızca cenaze",
      "Yalnızca bayram zorunlu değil ifadesi yanlış",
      "Yalnızca Cuma hutbesi"
    ],
    "Kunut vitirde okunur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Sahur ne demektir?",
    "Oruç öncesi gece yemeği",
    [
      "Bayram yemeği zorunlu",
      "Zekât yemeği",
      "Hac yemeği"
    ],
    "Sahur oruç öncesi yenir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Umre ibadeti kısaca nedir?",
    "Hac zamanı dışında Kâbe ziyareti ibadeti",
    [
      "Beş vakit namaz",
      "Zekâtın adı",
      "Orucun adı"
    ],
    "Umre ayrı bir ibadettir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Tavaf ibadeti kısaca nedir?",
    "Kâbe'nin etrafında dönmek",
    [
      "Arafat'ta durmak",
      "Mina'da taşlamak",
      "Müzdelife'de yatmak"
    ],
    "Tavaf Kâbe etrafında dönmektir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Sa'y ibadeti kısaca nedir?",
    "Safa ile Merve arasında yürüyüş",
    [
      "Kâbe'yi öpmek",
      "Arafat hutbesi",
      "Mina gecesi"
    ],
    "Sa'y Safa-Merve arasındadır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Hacda vakfe nerededir?",
    "Arafat",
    [
      "Bedir",
      "Uhud",
      "Hira"
    ],
    "Haccın rüknü Arafat vakfesidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Şeytan taşlama nerede yapılır?",
    "Mina",
    [
      "Arafat zirvesi",
      "Müzdelife kuyusu",
      "Kuba avlusu"
    ],
    "Cemreler Mina'dadır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    3,
    "İhram hali kısaca nedir?",
    "Hac/umre yasaklarıyla özel hale girmek",
    [
      "Normal ev kıyafeti",
      "Ticaret üniforması",
      "Askeri torba"
    ],
    "İhram hac/umre niyetidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Kelime-i şehadet İslam'ın şartlarından midir?",
    "Evet, temeldir",
    [
      "Hayır, hiç ilgili değil",
      "Yalnızca oruçtur",
      "Yalnızca zekâttır"
    ],
    "Şehadet İslam'ın ilk şartıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    2,
    "Sübhaneke ne zaman okunur?",
    "Namazın başında",
    [
      "Yalnızca oruçta",
      "Yalnızca zekâtta",
      "Yalnızca hacda"
    ],
    "Sübhaneke iftitah sonrası okunur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "İbadet ve temel dini bilgiler",
    1,
    "Amin ne zaman denir?",
    "Fatiha bitince",
    [
      "Zekât verince zorunlu",
      "Kurban kesince zorunlu",
      "Yolculukta zorunlu"
    ],
    "Fatiha sonrası âmin denir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Tevhid ne demektir?",
    "Allah'ın birliği inancı",
    [
      "Çok tanrıcılık",
      "Putperestlik",
      "Soy üstünlüğü"
    ],
    "Tevhid Allah'ın birlenmesi demektir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Şirk ne demektir?",
    "Allah'a ortak koşmak",
    [
      "Namaz kılmak",
      "Oruç tutmak",
      "Zekât vermek"
    ],
    "Şirk Allah'a ortak koşmaktır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "İman ne demektir?",
    "Kalben tasdik etmek",
    [
      "Yalnızca mal biriktirmek",
      "Yalnızca soy övünmek",
      "Yalnızca güç göstermek"
    ],
    "İman kalbi tasdiktir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "İslam sözlükte neye gelir?",
    "Teslim olmak",
    [
      "İnatlaşmak",
      "İnkâr etmek",
      "Alay etmek"
    ],
    "İslam teslimiyet anlamındadır.",
    "TDV İslam Ansiklopedisi, İslâm"
  ],
  [
    "Dini kavramlar",
    2,
    "İhsan hadiste nasıl tarif edilir?",
    "Allah'ı görüyormuş gibi kulluk",
    [
      "Yalnızca mal çoğaltma",
      "Yalnızca ün kazanma",
      "Yalnızca tartışma"
    ],
    "İhsan kullukta derin bilinçtir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Helal ne demektir?",
    "Dinen izin verilen",
    [
      "Dinen yasak olan",
      "Belirsiz olan",
      "İmkânsız olan"
    ],
    "Helal caiz olan şeydir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Haram ne demektir?",
    "Dinen yasaklanan",
    [
      "Dinen zorunlu övgü",
      "Sadece süs",
      "Sadece alışkanlık"
    ],
    "Haram yasak olan şeydir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Mekruh ne demektir?",
    "Yapılması hoş görülmeyen",
    [
      "Kesin farz",
      "Kesin vacip daima",
      "Tamamen mubah övgü"
    ],
    "Mekruh kerih görülen davranıştır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Mübah ne demektir?",
    "Yapılması serbest olan",
    [
      "Kesin haram",
      "Kesin farz",
      "Kesin küfür"
    ],
    "Mübah serbest fiildir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Farz ne demektir?",
    "Kesin delille emredilen",
    [
      "Serbest bırakılan",
      "Yasaklanan",
      "Önemsiz görülen"
    ],
    "Farz yükümlülük doğurur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Vacip Hanefi usulünde neye yakındır?",
    "Farz benzeri güçlü yükümlülük",
    [
      "Tamamen mubah",
      "Tamamen haram övgü",
      "Tamamen şirk"
    ],
    "Vacip güçlü bir sorumluluktur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Sünnet terimi dinde neyi ifade eder?",
    "Peygamber uygulaması",
    [
      "Put geleneği",
      "Rastgele alışkanlık",
      "Ticaret oyunu"
    ],
    "Sünnet nebevi yoldur.",
    "TDV İslam Ansiklopedisi, Sünnet"
  ],
  [
    "Dini kavramlar",
    1,
    "Hadis terimi nedir?",
    "Peygamber söz, fiil ve takrirleri",
    [
      "Yalnızca şiir",
      "Yalnızca ticaret kaydı",
      "Yalnızca vergi listesi"
    ],
    "Hadis sünnetin naklidir.",
    "TDV İslam Ansiklopedisi, Hadis"
  ],
  [
    "Dini kavramlar",
    2,
    "Sünnet-i müekkede ne demektir?",
    "Kuvvetli sünnet",
    [
      "Haram fiil",
      "Şirk inancı",
      "Küfür sözü"
    ],
    "Müekked sünnet önemlidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Dua ne demektir?",
    "Allah'a yalvarış",
    [
      "İnsanlara övünme",
      "Putlara tapma",
      "Mal sayma"
    ],
    "Dua Allah'a yönelmedir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Zikir ne demektir?",
    "Allah'ı anmak",
    [
      "Unutmak",
      "İnkâr etmek",
      "Alay etmek"
    ],
    "Zikir Allah'ı anmaktır.",
    "TDV İslam Ansiklopedisi, Zikir"
  ],
  [
    "Dini kavramlar",
    2,
    "Tövbe ne demektir?",
    "Günahdan dönüp pişman olmak",
    [
      "Günahı çoğaltmak",
      "İnkârı artırmak",
      "Övünmek"
    ],
    "Tövbe pişmanlık ve dönüştür.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Sabır ne demektir?",
    "Sıkıntıya göğüs germek",
    [
      "Öfkeyi kutsamak",
      "İsyanı övmek",
      "Haksızlığı yaymak"
    ],
    "Sabır imanın gereğidir.",
    "TDV İslam Ansiklopedisi, Sabır"
  ],
  [
    "Dini kavramlar",
    1,
    "Şükür ne demektir?",
    "Nimeti görüp teşekkür etmek",
    [
      "Nimeti inkâr",
      "Nimeti gizlemek zorunda kalmak daima",
      "Nimeti yok saymak"
    ],
    "Şükür nimet bilincidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Takva ne demektir?",
    "Allah'a karşı sakınma bilinci",
    [
      "Gaflet",
      "İsraf övgüsü",
      "Kibir"
    ],
    "Takva sorumluluk bilincidir.",
    "TDV İslam Ansiklopedisi, Takvâ"
  ],
  [
    "Dini kavramlar",
    1,
    "Adalet ne demektir?",
    "Hakkı gözetmek",
    [
      "Zulmü övmek",
      "Haksızlık yapmak",
      "Kayırmayı kutsamak"
    ],
    "Adalet hakkın teslimidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Emanet ne demektir?",
    "Güvenilirlik ve korunan hak",
    [
      "Hıyanet",
      "Yalan",
      "Hırsızlık"
    ],
    "Emanet güven unsurudur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Helalleşmek neyi ifade eder?",
    "Hakları karşılıklı temizlemek",
    [
      "Düşmanlığı artırmak",
      "Yalanı yaymak",
      "Kibirlenmek"
    ],
    "Helalleşme hak temizliği arayışıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Gıybet ne demektir?",
    "Birinin ardından hoşlanmayacağı söz söylemek",
    [
      "Dürüst övgü",
      "Adaletli şahitlik",
      "Hayır dua"
    ],
    "Gıybet dinen yasaklanan bir davranıştır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "İftira ne demektir?",
    "Olmayan suçu yüklemek",
    [
      "Doğru şahitlik",
      "Adalet",
      "Emanet"
    ],
    "İftira büyük günahtır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Riya ne demektir?",
    "Gösteriş için ibadet",
    [
      "İhlas",
      "İhsan",
      "İman"
    ],
    "Riya gösteriş hastalığıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "İhlas ne demektir?",
    "Ameli yalnız Allah için yapmak",
    [
      "Gösteriş",
      "Riya",
      "Şirk"
    ],
    "İhlas samimiyettir.",
    "TDV İslam Ansiklopedisi, İhlâs"
  ],
  [
    "Dini kavramlar",
    2,
    "Kader inancı neyi ifade eder?",
    "Allah'ın ilim ve takdiri",
    [
      "Tesadüfçülük",
      "İnkâr",
      "Putçuluk"
    ],
    "Kader imanın şartlarındandır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Ahiret ne demektir?",
    "Ölüm sonrası ebedi hayat",
    [
      "Yalnızca dünya ticareti",
      "Yalnızca çocukluk",
      "Yalnızca uyku"
    ],
    "Ahiret hesap ve sonsuz hayattır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Cennet ne demektir?",
    "Müminlere vaat edilen ebedi yurt",
    [
      "Dünya çarşısı",
      "Geçici gölgelik",
      "Savaş alanı"
    ],
    "Cennet ahiret yurdudur.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Cehennem ne demektir?",
    "Azap yurdu",
    [
      "Bayram yeri",
      "Ticaret limanı",
      "Oyun alanı"
    ],
    "Cehennem azap mahallidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Şefaat kavramı neyi ifade eder?",
    "İzinle aracılık dileği",
    [
      "Putlara tapma",
      "Şirk kurma",
      "İnkârı övme"
    ],
    "Şefaat ehli sünnet bahislerindendir.",
    "TDV İslam Ansiklopedisi, Şefaat"
  ],
  [
    "Dini kavramlar",
    1,
    "Tefsir ilmi nedir?",
    "Kur'an'ı açıklama ilmi",
    [
      "Hadis ezber yarışması yalnızca",
      "Fıkıh usulünün tamamı değil ifadesi yanlış",
      "Astronomi"
    ],
    "Tefsir Kur'an yorumudur.",
    "TDV İslam Ansiklopedisi, Tefsir"
  ],
  [
    "Dini kavramlar",
    1,
    "Fıkıh ilmi nedir?",
    "Ameli hükümleri bilme ilmi",
    [
      "Yalnızca şiir ilmi",
      "Yalnızca tipografi",
      "Yalnızca bahçıvanlık"
    ],
    "Fıkıh amelî hükümleri inceler.",
    "TDV İslam Ansiklopedisi, Fıkıh"
  ],
  [
    "Dini kavramlar",
    2,
    "Kelam ilmi neyi inceler?",
    "İtikadi konuları",
    [
      "Yalnızca yemek tariflerini",
      "Yalnızca gemiciliği",
      "Yalnızca madenciliği"
    ],
    "Kelam akide konularını işler.",
    "TDV İslam Ansiklopedisi, Kelâm"
  ],
  [
    "Dini kavramlar",
    1,
    "Tecvit ilmi nedir?",
    "Kur'an'ı doğru okuma kuralları",
    [
      "Zekât hesabı",
      "Hac menzili",
      "Oruç niyeti"
    ],
    "Tecvit kıraat kurallarıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "İcma ne demektir?",
    "Müçtehitlerin bir konuda birleşmesi",
    [
      "Tek kişinin hevesi",
      "Put konsensüsü",
      "Rastgele oy"
    ],
    "İcma usul delillerindendir.",
    "TDV İslam Ansiklopedisi, İcmâ"
  ],
  [
    "Dini kavramlar",
    3,
    "Kıyas usulde ne demektir?",
    "Benzer hükmü benzer olaya taşıma",
    [
      "Rastgele yasak",
      "Put kıyası",
      "Şiir benzetmesi yalnızca"
    ],
    "Kıyas fıkıh usulü delilidir.",
    "TDV İslam Ansiklopedisi, Kıyas"
  ],
  [
    "Dini kavramlar",
    2,
    "Sünnetullah ne demektir?",
    "Allah'ın âdet ve kanunları",
    [
      "İnsan uydurması",
      "Put kuralı",
      "Rastgele tesadüf"
    ],
    "Sünnetullah ilahi kanundur.",
    "TDV İslam Ansiklopedisi, Sünnetullah"
  ],
  [
    "Dini kavramlar",
    1,
    "Ümmet ne demektir?",
    "Peygambere bağlı topluluk",
    [
      "Tek aile şirketi",
      "Tek çarşı esnafı",
      "Tek ordu birliği yalnızca"
    ],
    "Ümmet inanç topluluğudur.",
    "TDV İslam Ansiklopedisi, Ümmet"
  ],
  [
    "Dini kavramlar",
    2,
    "Cihad kavramı geniş anlamda neyi kapsar?",
    "Allah yolunda gayreti",
    [
      "Sadece dünya malı yarışını",
      "Sadece soy övüncünü",
      "Sadece eğlenceyi"
    ],
    "Cihad gayret ve mücadele anlamındadır.",
    "TDV İslam Ansiklopedisi, Cihad"
  ],
  [
    "Dini kavramlar",
    1,
    "Sevap ne demektir?",
    "İyi amelin karşılığı",
    [
      "Günah",
      "Azap",
      "İnkâr"
    ],
    "Sevap hayrın mükâfatıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Günah ne demektir?",
    "Allah'ın emrine aykırı fiil",
    [
      "İbadet",
      "İhsan",
      "İhlas"
    ],
    "Günah yasak fiildir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    2,
    "Küfür ne demektir?",
    "İmanı reddetmek",
    [
      "Namaz kılmak",
      "Oruç tutmak",
      "Zekât vermek"
    ],
    "Küfür inkârdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Mümin kimdir?",
    "İman eden kimse",
    [
      "İnkâr eden",
      "Alay eden",
      "Putlara tapan"
    ],
    "Mümin iman sahibidir.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Münafık kimdir?",
    "İçi dışı ayrı olup iman iddia eden",
    [
      "Samimi mümin",
      "Açık müşrik daima aynı",
      "Çocuk"
    ],
    "Münafık ikiyüzlülükle anılır.",
    "TDV İslam Ansiklopedisi, Münâfık"
  ],
  [
    "Dini kavramlar",
    2,
    "Bidat kavramı neyi ifade eder?",
    "Dinde sonradan uydurulan eklemeler bahsini",
    [
      "Kur'an'ın kendisini",
      "Sünnetin tamamını",
      "Farzların tamamını"
    ],
    "Bidat dinde sonradan çıkarma tartışmasıdır.",
    "TDV İslam Ansiklopedisi, Bid'at"
  ],
  [
    "Dini kavramlar",
    3,
    "İstiare ve mecaz tefsirde neyi gösterir?",
    "Dil sanatlarıyla anlatım",
    [
      "Metnin yokluğunu",
      "Ayetlerin silinmesini",
      "Kıraatin yasaklanmasını"
    ],
    "Belagat tefsirde önemlidir.",
    "TDV İslam Ansiklopedisi, Tefsir"
  ],
  [
    "Dini kavramlar",
    2,
    "Helal kazanç neden önemlidir?",
    "İbadet ve bereket bilinci için",
    [
      "İsrafı kutsamak için",
      "Haramı çoğaltmak için",
      "Riya için"
    ],
    "Helal rızık temel ahlakıdır.",
    "Diyanet Temel Dini Bilgiler"
  ],
  [
    "Dini kavramlar",
    1,
    "Selam vermek İslam ahlakında neyi ifade eder?",
    "Barış ve hayır dileği",
    [
      "Düşmanlık",
      "Alay",
      "Kibir"
    ],
    "Selam barış dileğidir.",
    "Diyanet Temel Dini Bilgiler"
  ]
];

function shuffleOptions(question, correct, wrongs) {
  const options = [correct, wrongs[0], wrongs[1], wrongs[2]];
  let seed = 0;
  for (let i = 0; i < question.length; i += 1) {
    seed = (seed + question.charCodeAt(i) * (i + 1)) % 9973;
  }
  for (let i = options.length - 1; i > 0; i -= 1) {
    seed = (seed * 31 + 17) % 9973;
    const j = seed % (i + 1);
    const tmp = options[i];
    options[i] = options[j];
    options[j] = tmp;
  }
  const correctIndex = options.indexOf(correct);
  if (correctIndex < 0) {
    throw new Error("Correct option missing after shuffle: " + question);
  }
  return { options, correctIndex };
}

function normalizeQuestion(s) {
  return String(s).toLocaleLowerCase("tr-TR").replace(/\s+/g, " ").trim();
}

function buildQuestions() {
  return ROWS.map((row, i) => {
    const category = row[0];
    const difficulty = row[1];
    const question = row[2];
    const correct = row[3];
    const wrongs = row[4];
    const explanation = row[5];
    const source = row[6];
    if (!Array.isArray(wrongs) || wrongs.length !== 3) {
      throw new Error("Expected 3 wrongs for: " + question);
    }
    const shuffled = shuffleOptions(question, correct, wrongs);
    return {
      id: "iq_" + String(i + 1).padStart(3, "0"),
      category,
      difficulty,
      question,
      options: shuffled.options,
      correctIndex: shuffled.correctIndex,
      explanation,
      source,
    };
  });
}

function validate(questions) {
  const errors = [];
  if (!Array.isArray(questions)) errors.push("Root is not an array");
  if (questions.length !== 300) errors.push("Expected 300 questions, got " + questions.length);

  const seen = new Set();
  const allowed = new Set(CATEGORIES);
  const catCounts = Object.fromEntries(CATEGORIES.map((c) => [c, 0]));

  questions.forEach((q, i) => {
    const expectId = "iq_" + String(i + 1).padStart(3, "0");
    if (!q || typeof q !== "object") {
      errors.push("Invalid item at index " + i);
      return;
    }
    if (q.id !== expectId) errors.push("Bad id at " + i + ": " + q.id);
    if (!allowed.has(q.category)) errors.push("Bad category at " + q.id + ": " + q.category);
    else catCounts[q.category] += 1;
    if (![1, 2, 3].includes(q.difficulty)) errors.push("Bad difficulty at " + q.id);
    if (typeof q.question !== "string" || q.question.length < 12) {
      errors.push("Short/invalid question at " + q.id);
    }
    const nq = normalizeQuestion(q.question);
    if (seen.has(nq)) errors.push("Duplicate normalized question at " + q.id + ": " + q.question);
    seen.add(nq);
    if (!Array.isArray(q.options) || q.options.length !== 4) {
      errors.push("Options length != 4 at " + q.id);
    } else {
      const trimmed = q.options.map((o) => String(o == null ? "" : o).trim());
      if (trimmed.some((o) => !o)) errors.push("Empty option at " + q.id);
      if (new Set(trimmed).size !== 4) errors.push("Non-distinct options at " + q.id);
      if (!Number.isInteger(q.correctIndex) || q.correctIndex < 0 || q.correctIndex > 3) {
        errors.push("Bad correctIndex at " + q.id);
      }
    }
    if (typeof q.explanation !== "string" || q.explanation.length < 8) {
      errors.push("Short explanation at " + q.id);
    }
    if (typeof q.source !== "string" || q.source.length < 4) {
      errors.push("Short source at " + q.id);
    }
  });

  return { errors, catCounts, unique: seen.size };
}

function main() {
  const questions = buildQuestions();
  const { errors, catCounts, unique } = validate(questions);
  if (errors.length) {
    console.error("VALIDATION FAILED:");
    errors.slice(0, 50).forEach((e) => console.error(" - " + e));
    if (errors.length > 50) console.error(" ... and " + (errors.length - 50) + " more");
    process.exit(1);
  }

  const outPath = path.join(__dirname, "..", "data", "islamic_quiz_questions.json");
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(questions, null, 2) + "\n", "utf8");

  const idxDist = { 0: 0, 1: 0, 2: 0, 3: 0 };
  questions.forEach((q) => {
    idxDist[q.correctIndex] += 1;
  });

  console.log("OK wrote", outPath);
  console.log("count", questions.length);
  console.log("uniqueNormalizedQuestions", unique);
  console.log("categoryCounts", catCounts);
  console.log("correctIndexDistribution", idxDist);
}

if (require.main === module) {
  main();
}

module.exports = { buildQuestions, validate, CATEGORIES };
