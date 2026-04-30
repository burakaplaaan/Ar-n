// Günlük dönüşümlü teselli ayet/hadis — İyileştirici Frekanslar hadis kartı.

import '../../../core/constants/quote_pool_ids.dart';
import '../../../data/repositories/quote_pools_repository.dart';

/// Tek bir kayıt: Arapça metin, Türkçe anlam, kaynak satırı.
class HealingComfortEntry {
  const HealingComfortEntry(this.arabic, this.turkish, this.ref);

  final String arabic;
  final String turkish;
  final String ref;
}

/// Yerel takvim gününe göre [entries] içinden biri (100 öğe, döngüsel).
abstract final class HealingDailyComfort {
  static const List<HealingComfortEntry> entries = <HealingComfortEntry>[
    HealingComfortEntry(
      'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
      'Hastalandığım zaman beni şifa ile iyileştiren O’dur.',
      'Şuara 80',
    ),
    HealingComfortEntry(
      'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'Şüphesiz zorlukla beraber bir kolaylık vardır.',
      'İnşirah 6',
    ),
    HealingComfortEntry(
      'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'Şüphesiz zorlukla beraber bir kolaylık vardır.',
      'İnşirah 5',
    ),
    HealingComfortEntry(
      'فَلَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
      'Allah’ın rahmetinden ümidinizi kesmeyin.',
      'Yusuf 87',
    ),
    HealingComfortEntry(
      'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      'Allah hiçbir kimseye gücünün yeteceğinden başkasını yüklemez.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'وَبَشِّرِ الصَّابِرِينَ',
      'Sabredenleri müjdele.',
      'Bakara 155',
    ),
    HealingComfortEntry(
      'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
      'Şüphesiz Allah sabredenlerle beraberdir.',
      'Bakara 153',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
      'Kim Allah’tan korkarsa Allah ona bir çıkış yolu yaratır.',
      'Talak 2',
    ),
    HealingComfortEntry(
      'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      'Kim Allah’a tevekkül ederse O, ona yeter.',
      'Talak 3',
    ),
    HealingComfortEntry(
      'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'Allah bize yeter; O ne güzel vekildir.',
      'Âl İmrân 173',
    ),
    HealingComfortEntry(
      'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ',
      'Gevşemeyin, üzülmeyin; eğer inanıyorsanız üstün olan sizsiniz.',
      'Âl İmrân 139',
    ),
    HealingComfortEntry(
      'وَاصْبِرْ وَمَا صَبْرُكَ إِلَّا بِاللَّهِ',
      'Sabret; sabrın ancak Allah’ın yardımıyladır.',
      'Nahl 126',
    ),
    HealingComfortEntry(
      'وَمَن يَصْبِرْ وَيَغْفِرْ إِنَّ ذَلِكَ لَمِنْ عَزْمِ الْأُمُورِ',
      'Kim sabreder ve bağışlarsa işte bu, azmedilmeye değer işlerdendir.',
      'Şûrâ 43',
    ),
    HealingComfortEntry(
      'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
      'Kullarım sana Beni sorduğunda şüphesiz Ben yakınım.',
      'Bakara 186',
    ),
    HealingComfortEntry(
      'ادْعُونِي أَسْتَجِبْ لَكُمْ',
      'Bana dua edin, duanıza karşılık vereyim.',
      'Mü’min 60',
    ),
    HealingComfortEntry(
      'مَّا عِندَكُمْ يَنفَدُ ۖ وَمَا عِندَ اللَّهِ بَاقٍ',
      'Yanınızdakiler tükenir; Allah katındaki ise kalıcıdır.',
      'Nahl 96',
    ),
    HealingComfortEntry(
      'وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ',
      'Rahmetim her şeyi kuşatmıştır.',
      'A’râf 156',
    ),
    HealingComfortEntry(
      'قُلْ يَا عِبَادِي الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
      'De ki: “Nefislerine kötülük eden kullarım! Allah’ın rahmetinden ümidinizi kesmeyin.”',
      'Zumer 53',
    ),
    HealingComfortEntry(
      'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'Bilesiniz ki kalpler ancak Allah’ı anmakla huzura erer.',
      'Ra’d 28',
    ),
    HealingComfortEntry(
      'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ',
      'Kur’an’dan insanlara şifa olan indiriyoruz.',
      'İsrâ 82',
    ),
    HealingComfortEntry(
      'وَمَا أُوتِيتُم مِّن شَيْءٍ فَمَتَاعُ الْحَيَاةِ الدُّنْيَا ۖ وَمَا عِندَ اللَّهِ خَيْرٌ',
      'Size verilen her şey dünya hayatının geçici menfaatidir; Allah katındaki daha hayırlıdır.',
      'Şûrâ 36',
    ),
    HealingComfortEntry(
      'فَإِنَّهُ مَعَ الَّذِينَ اتَّقَوا وَالَّذِينَ هُم مُّحْسِنُونَ',
      'Şüphesiz O, takva sahipleri ve iyilik edenlerle beraberdir.',
      'Nahl 128',
    ),
    HealingComfortEntry(
      'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ',
      'Allah’ın rahmetinden asla ümidinizi kesmeyin.',
      'Yusuf 87',
    ),
    HealingComfortEntry(
      'إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ',
      'Şüphesiz Allah iyilik edenlerin mükâfatını zayi etmez.',
      'Tevbe 120',
    ),
    HealingComfortEntry(
      'وَاللَّهُ خَيْرٌ حَافِظًا وَهُوَ أَرْحَمُ الرَّاحِمِينَ',
      'Allah en iyi koruyucudur; O, rahmetlilerin en merhametlisidir.',
      'Yûsuf 64',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مِنْ أَمْرِهِ يُسْرًا',
      'Kim Allah’tan korkarsa Allah ona işinde bir kolaylık verir.',
      'Talak 4',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَكْفُرْ عَنْهُ سَيِّئَاتِهِ',
      'Kim Allah’tan korkarsa Allah onun kötülüklerini örter.',
      'Talak 5',
    ),
    HealingComfortEntry(
      'وَاصْبِرْ فَإِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ',
      'Sabret; şüphesiz Allah iyilik edenlerin mükâfatını zayi etmez.',
      'Hûd 115',
    ),
    HealingComfortEntry(
      'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ',
      'Bilesiniz ki Allah’ın dostlarına korku yoktur; onlar üzülmezler.',
      'Yûnus 62',
    ),
    HealingComfortEntry(
      'إِنَّمَا أُمِرْتُ أَنْ أَعْبُدَ رَبَّ هَٰذِهِ الْبَلْدَةِ',
      'Ben yalnızca bu beldenin Rabbine kulluk etmekle emrolundum.',
      'Şems 9',
    ),
    HealingComfortEntry(
      'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ',
      'Benim başarım ancak Allah’a dayanır.',
      'Hûd 88',
    ),
    HealingComfortEntry(
      'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
      'Rabbim! Göğsüme genişlik ver, işimi bana kolaylaştır.',
      'Tâhâ 25–26 (özet)',
    ),
    HealingComfortEntry(
      'وَقُل رَّبِّ زِدْنِي عِلْمًا',
      'De ki: “Rabbim! İlmimi artır.”',
      'Tâhâ 114',
    ),
    HealingComfortEntry(
      'وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ',
      'Ben cinleri ve insanları ancak Bana kulluk etsinler diye yarattım.',
      'Zâriyât 56',
    ),
    HealingComfortEntry(
      'وَمَا أُرْسِلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
      'Seni ancak âlemlere rahmet olarak gönderdik.',
      'Enbiyâ 107',
    ),
    HealingComfortEntry(
      'وَمَا يُلَقَّاهَا إِلَّا الصَّابِرُونَ',
      'Bunu ancak sabredenlere veririz.',
      'Fussilet 35',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ مِنَ الصَّالِحَاتِ وَهُوَ مُؤْمِنٌ فَلَا يَخَافُ ظُلْمًا وَلَا هَضْمًا',
      'Kim mümin olarak salih amel işlerse zulme uğramaktan ve hakkının yenmesinden korkmaz.',
      'Tâhâ 112',
    ),
    HealingComfortEntry(
      'وَمَا كَانَ اللَّهُ لِيُضَيِّعَ إِيمَانَكُمْ',
      'Allah sizin imanınızı zayi edecek değildir.',
      'Bakara 143',
    ),
    HealingComfortEntry(
      'وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ',
      'Hoşunuza gitmeyen bir şey sizin için hayırlı olabilir.',
      'Bakara 216',
    ),
    HealingComfortEntry(
      'وَلَا تَقُولُوا لِمَن يُقْتَلُ فِي سَبِيلِ اللَّهِ أَمْوَاتٌ ۚ بَلْ أَحْيَاءٌ',
      'Allah yolunda öldürülenlere “ölüler” demeyin; bilakis onlar diridirler.',
      'Bakara 154',
    ),
    HealingComfortEntry(
      'وَبَشِّرِ الْمُخْبِتِينَ',
      'Alçakgönüllü olanları müjdele.',
      'Hacc 34',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ نُورًا',
      'Kim Allah’tan korkarsa ona bir nur verir.',
      'Talak 11',
    ),
    HealingComfortEntry(
      'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
      'Ey iman edenler! Sabır ve namazla yardım isteyin.',
      'Bakara 45',
    ),
    HealingComfortEntry(
      'إِنَّ اللَّهَ يُحِبُّ التَّوَّابِينَ',
      'Şüphesiz Allah tövbe edenleri sever.',
      'Bakara 222',
    ),
    HealingComfortEntry(
      'وَهُوَ الَّذِي يَقْبَلُ التَّوْبَةَ عَنْ عِبَادِهِ',
      'Kullarından tövbeyi kabul eden O’dur.',
      'Şûrâ 25',
    ),
    HealingComfortEntry(
      'وَإِنَّكَ لَعَلَىٰ خُلُقٍ عَظِيمٍ',
      'Sen elbette yüce bir ahlak üzeresin.',
      'Kalem 4',
    ),
    HealingComfortEntry(
      'فَاذْكُرُونِي أَذْكُرْكُمْ',
      'Beni anın ki Ben de sizi anayım.',
      'Bakara 152',
    ),
    HealingComfortEntry(
      'وَلَا تَقْنَطُوا مِن رَّوْحِ اللَّهِ ۖ إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ',
      'Allah’ın rahmetinden ümidinizi kesmeyin; kâfirlerden başkası Allah’ın rahmetinden ümidini kesmez.',
      'Yûsuf 87',
    ),
    HealingComfortEntry(
      'وَمَا أَصَابَكُم مِّن مُّصِيبَةٍ فَبِمَا كَسَبَتْ أَيْدِيكُمْ وَيَعْفُو عَن كَثِيرٍ',
      'Başınıza gelen musibet ellerinizin kazandığındandır; O çoğunu affeder.',
      'Şûrâ 30',
    ),
    HealingComfortEntry(
      'وَلَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا',
      'Üzülme; şüphesiz Allah bizimle beraberdir.',
      'Tevbe 40',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      'Kim Allah’tan korkarsa ona çıkış yolu yaratır ve hesap etmediği yerden rızık verir.',
      'Talak 2–3 (birleşik anlam)',
    ),
    HealingComfortEntry(
      'وَمَا يُلْقَاهَا إِلَّا الَّذِينَ صَبَرُوا',
      'Bunu ancak sabredenlere veririz.',
      'Fussilet 35',
    ),
    HealingComfortEntry(
      'وَاللَّهُ يُحِبُّ الصَّابِرِينَ',
      'Allah sabredenleri sever.',
      'Âl İmrân 146',
    ),
    HealingComfortEntry(
      'وَاصْبِرْ وَمَا صَبْرُكَ إِلَّا بِاللَّهِ وَلَا تَحْزَنْ عَلَيْهِمْ',
      'Sabret; sabrın ancak Allah’ın yardımıyladır. Onlar için üzülme.',
      'Nahl 127',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ صَالِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَأُولَٰئِكَ يَدْخُلُونَ الْجَنَّةَ',
      'Erkek veya kadın, kim mümin olarak salih amel işlerse işte onlar cennete girerler.',
      'Nisâ 124',
    ),
    HealingComfortEntry(
      'وَمَا تَفْعَلُوا مِنْ خَيْرٍ يَعْلَمْهُ اللَّهُ',
      'İşlediğiniz her hayrı Allah bilir.',
      'Bakara 197',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُ',
      'Kim zerre kadar hayır işlerse onu görür.',
      'Zilzâl 7',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ شَرًّا يَرَهُ',
      'Kim zerre kadar şer işlerse onu görür.',
      'Zilzâl 8',
    ),
    HealingComfortEntry(
      'وَمَا أَرْسَلْنَاكَ إِلَّا كَافَّةً لِّلنَّاسِ بَشِيرًا وَنَذِيرًا',
      'Seni ancak insanlara müjdeleyici ve uyarıcı olarak gönderdik.',
      'Sebe’ 28',
    ),
    HealingComfortEntry(
      'وَمَا خَلَقْنَا السَّمَاوَاتِ وَالْأَرْضَ وَمَا بَيْنَهُمَا بَاطِلًا',
      'Gökleri, yeri ve aralarındakileri boş yere yaratmadık.',
      'Sâd 27',
    ),
    HealingComfortEntry(
      'وَمَا أُوتِيتُم مِّن شَيْءٍ فَمَتَاعُ الْحَيَاةِ الدُّنْيَا ۖ وَمَا عِندَ اللَّهِ خَيْرٌ',
      'Size verilen her şey dünya hayatının geçici menfaatidir; Allah katındaki daha hayırlıdır.',
      'Şûrâ 36',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مِنْ أَمْرِهِ يُسْرًا',
      'Kim Allah’tan korkarsa Allah ona işinde kolaylık verir.',
      'Talak 4',
    ),
    HealingComfortEntry(
      'وَإِنَّ رَبَّكَ لَذُو مَغْفِرَةٍ لِّلنَّاسِ',
      'Şüphesiz Rabbin insanlara karşı çok bağışlayıcıdır.',
      'Ra’d 6',
    ),
    HealingComfortEntry(
      'وَإِنَّهُ لَيُحِبُّ الْمُتَوَكِّلِينَ',
      'Şüphesiz O, tevekkül edenleri sever.',
      'Âl İmrân 159',
    ),
    HealingComfortEntry(
      'وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ',
      'Üzülmeyin; eğer inanıyorsanız üstün olan sizsiniz.',
      'Âl İmrân 139',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
      'Kim Allah’tan korkarsa ona bir çıkış yolu yaratır.',
      'Talak 2',
    ),
    HealingComfortEntry(
      'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      'Kim Allah’a tevekkül ederse O ona yeter.',
      'Talak 3',
    ),
    HealingComfortEntry(
      'وَمَا أَصَابَكُم مِّن مُّصِيبَةٍ فِي الْأَرْضِ وَلَا فِي أَنفُسِكُمْ إِلَّا فِي كِتَابٍ مِّن قَبْلِ أَن نَّبْرَأَهَا',
      'Yeryüzünde veya nefislerinizde başınıza gelen hiçbir musibet, onu yaratmadan önce bir kitapta yazılmamıştır.',
      'Hadîd 22',
    ),
    HealingComfortEntry(
      'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ',
      'Allah hiçbir kimseye gücünün yeteceğinden fazlasını yüklemez.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا',
      'Rabbimiz! Unutursak veya hataya düşersek bizi hesaba çekme.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا',
      'Rabbimiz! Bize, öncekilere yüklediğin gibi ağır yük yükleme.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ',
      'Rabbimiz! Gücümüzün yetmeyeceği yükü bize yükleme.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا',
      'Bizi affet, bizi bağışla, bize merhamet et.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'Sen Mevlamızsın; bizi kâfir topluma karşı yardım et.',
      'Bakara 286',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ مِنَ الصَّالِحَاتِ مِن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَأُولَٰئِكَ يَدْخُلُونَ الْجَنَّةَ',
      'Kim mümin olarak salih amel işlerse — erkek veya kadın — işte onlar cennete girerler.',
      'Nisâ 124',
    ),
    HealingComfortEntry(
      'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
      'Seni ancak âlemlere rahmet olarak gönderdik.',
      'Enbiyâ 107',
    ),
    HealingComfortEntry(
      'وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ',
      'Ben cinleri ve insanları ancak Bana kulluk etsinler diye yarattım.',
      'Zâriyât 56',
    ),
    HealingComfortEntry(
      'وَإِذَا مَسَّ الْإِنسَانَ الضُّرُّ دَعَانَا',
      'İnsana bir darlık dokunduğunda Bize dua eder.',
      'Zumer 8',
    ),
    HealingComfortEntry(
      'ثُمَّ إِذَا خَوَّلْنَاهُ نِعْمَةً مِّنَّا قَالَ إِنَّمَا أُوتِيتُهُ عَلَىٰ عِلْمٍ',
      'Sonra ona tarafımızdan bir nimet verdiğimizde “Bu bana ilmimle verildi” der.',
      'Zumer 49',
    ),
    HealingComfortEntry(
      'بَلْ هِيَ فِتْنَةٌ وَلَٰكِنَّ أَكْثَرَهُمْ لَا يَعْلَمُونَ',
      'Hayır, o bir imtihandır; fakat çoğu bilmez.',
      'Zumer 49',
    ),
    HealingComfortEntry(
      'وَلَقَدْ خَلَقْنَا الْإِنسَانَ وَنَعْلَمُ مَا تُوَسْوِسُ بِهِ نَفْسُهُ',
      'Andolsun insanı Biz yarattık; nefsinin ona fısıldadığını Biliriz.',
      'Kaf 16',
    ),
    HealingComfortEntry(
      'وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ',
      'Biz ona şahdamarından daha yakınız.',
      'Kaf 16',
    ),
    HealingComfortEntry(
      'وَمَا أُمِرْتُ إِلَّا لِأَعْبُدَ رَبَّ هَٰذِهِ الْبَلْدَةِ',
      'Ben yalnızca bu beldenin Rabbine kulluk etmekle emrolundum.',
      'Şems 9',
    ),
    HealingComfortEntry(
      'وَمَن يَعْمَلْ مِنَ الصَّالِحَاتِ وَهُوَ مُؤْمِنٌ فَلَا يَخَافُ ظُلْمًا وَلَا هَضْمًا',
      'Kim mümin olarak salih amel işlerse zulme uğramaktan korkmaz.',
      'Tâhâ 112',
    ),
    HealingComfortEntry(
      'إِنَّ رَبَّكَ لَسَرِيعُ الْعِقَابِ وَإِنَّهُ لَغَفُورٌ رَّحِيمٌ',
      'Şüphesiz Rabbin cezada çok çabuktur; şüphesiz O çok bağışlayan, çok merhamet edendir.',
      'En’âm 165',
    ),
    HealingComfortEntry(
      'وَمَا كَانَ اللَّهُ لِيُعَذِّبَهُمْ وَأَنتَ فِيهِمْ',
      'Allah, sen onların içindeyken onları azap etmeyecek.',
      'Enfâl 33',
    ),
    HealingComfortEntry(
      'وَمَا كَانَ اللَّهُ مُعَذِّبَهُمْ وَهُمْ يَسْتَغْفِرُونَ',
      'Onlar istiğfar ederken Allah onları azap etmeyecek.',
      'Enfâl 33',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
      'Kim Allah’tan korkarsa ona bir çıkış yolu yaratır.',
      'Talak 2',
    ),
    HealingComfortEntry(
      'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      'Kim Allah’a tevekkül ederse O ona yeter.',
      'Talak 3',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مِنْ أَمْرِهِ يُسْرًا',
      'Kim Allah’tan korkarsa Allah ona işinde kolaylık verir.',
      'Talak 4',
    ),
    HealingComfortEntry(
      'ذَٰلِكَ أَمْرُ اللَّهِ أَنزَلَهُ إِلَيْكُمْ ۚ وَمَن يَتَّقِ اللَّهَ يُكَفِّرْ عَنْهُ سَيِّئَاتِهِ',
      'Bu Allah’ın emridir. Kim Allah’tan korkarsa kötülüklerini örter.',
      'Talak 5',
    ),
    HealingComfortEntry(
      'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      'Kim Allah’tan korkarsa ona çıkış ve hesap etmediği yerden rızık verir.',
      'Talak 2–3',
    ),
    HealingComfortEntry(
      'وَمَا تُفَرِّقُوا إِلَّا مِن بَعْدِ مَا جَاءَهُمُ الْعِلْمُ بَغْيًا بَيْنَهُمْ',
      'Onlar kendilerine ilim geldikten sonra ancak aralarında düşmanlıktan ayrılığa düştüler.',
      'Şûrâ 14',
    ),
    HealingComfortEntry(
      'وَلَوْلَا فَضْلُ اللَّهِ عَلَيْكَ وَرَحْمَتُهُ لَهَتَّ فَرِيقٌ مِّنْهُمْ',
      'Eğer Allah’ın sana lütfu ve rahmeti olmasaydı, onlardan bir grup seni saptırmaya yeltenirdi.',
      'Nisâ 113',
    ),
    HealingComfortEntry(
      'وَمَا أَصَابَكُم مِّن مُّصِيبَةٍ فَبِمَا كَسَبَتْ أَيْدِيكُمْ وَيَعْفُو عَن كَثِيرٍ',
      'Başınıza gelen musibet ellerinizin kazandığındandır; O çoğunu affeder.',
      'Şûrâ 30',
    ),
    HealingComfortEntry(
      'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
      'Seni ancak âlemlere rahmet olarak gönderdik.',
      'Enbiyâ 107',
    ),
    HealingComfortEntry(
      'وَمَا خَلَقْنَا السَّمَاوَاتِ وَالْأَرْضَ وَمَا بَيْنَهُمَا لَاعِبِينَ',
      'Gökleri, yeri ve aralarındakileri oyun olsun diye yaratmadık.',
      'Enbiyâ 16',
    ),
    HealingComfortEntry(
      'وَلَوْ كَانَ فِيهِمَا آلِهَةٌ إِلَّا اللَّهُ لَفَسَدَتَا',
      'İkisinde de Allah’tan başka ilâhlar olsaydı bozulurlardı.',
      'Enbiyâ 22',
    ),
    HealingComfortEntry(
      'وَلَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
      'Allah’ın rahmetinden ümidinizi kesmeyin.',
      'Yûsuf 87',
    ),
    HealingComfortEntry(
      'إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ',
      'Kâfirlerden başkası Allah’ın rahmetinden ümidini kesmez.',
      'Yûsuf 87',
    ),
  ];

  /// Yerel tarihin gece yarısından itibaren geçen gün sayısına göre indeks.
  static HealingComfortEntry forLocalToday() {
    final now = DateTime.now();
    final localDay = DateTime(now.year, now.month, now.day);
    final origin = DateTime(2020, 1, 1);
    final days = localDay.difference(origin).inDays;
    final i = days % entries.length;
    return entries[i < 0 ? i + entries.length : i];
  }

  /// Firestore `healing_comfort` havuzu; boşsa [forLocalToday].
  static HealingComfortEntry forLocalTodayWithPool(QuotePoolsRepository r) {
    final poolItems = r.itemsFromCache(QuotePoolIds.healingComfort);
    if (poolItems.isEmpty) return forLocalToday();
    final now = DateTime.now();
    final localDay = DateTime(now.year, now.month, now.day);
    final origin = DateTime(2020, 1, 1);
    final days = localDay.difference(origin).inDays;
    final i = days % poolItems.length;
    final idx = i < 0 ? i + poolItems.length : i;
    final m = poolItems[idx];
    final turkish = m['turkish'] as String? ?? m['text'] as String? ?? '';
    final arabic = m['arabic'] as String? ?? '';
    final refStr = m['ref'] as String? ?? m['reference'] as String? ?? '';
    if (turkish.isEmpty && arabic.isEmpty) return forLocalToday();
    return HealingComfortEntry(arabic, turkish, refStr);
  }
}
