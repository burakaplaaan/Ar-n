// Kaza namazı takibi — cihaz içi durum (SharedPreferences).

class KazaTrackingState {
  const KazaTrackingState({
    required this.sabah,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
    required this.vitir,
    this.isFemale = false,
    this.birthDate,
    this.pubertyAge = 0,
    this.prayedDaysRecorded = 0,
    this.hasEverCalculated = false,
    this.hubEnabled = false,
  });

  final int sabah;
  final int ogle;
  final int ikindi;
  final int aksam;
  final int yatsi;
  final int vitir;

  final bool isFemale;
  final DateTime? birthDate;
  final int pubertyAge;
  final int prayedDaysRecorded;
  final bool hasEverCalculated;

  /// Gelişim’de kaza kartı: yalnızca Rutin atölyesinde Kaza kurulup bayrak yazılınca true.
  final bool hubEnabled;

  int get total =>
      sabah + ogle + ikindi + aksam + yatsi + vitir;

  List<int> get counts => [sabah, ogle, ikindi, aksam, yatsi, vitir];

  KazaTrackingState copyWith({
    int? sabah,
    int? ogle,
    int? ikindi,
    int? aksam,
    int? yatsi,
    int? vitir,
    bool? isFemale,
    DateTime? birthDate,
    bool clearBirthDate = false,
    int? pubertyAge,
    int? prayedDaysRecorded,
    bool? hasEverCalculated,
    bool? hubEnabled,
  }) {
    return KazaTrackingState(
      sabah: sabah ?? this.sabah,
      ogle: ogle ?? this.ogle,
      ikindi: ikindi ?? this.ikindi,
      aksam: aksam ?? this.aksam,
      yatsi: yatsi ?? this.yatsi,
      vitir: vitir ?? this.vitir,
      isFemale: isFemale ?? this.isFemale,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      pubertyAge: pubertyAge ?? this.pubertyAge,
      prayedDaysRecorded: prayedDaysRecorded ?? this.prayedDaysRecorded,
      hasEverCalculated: hasEverCalculated ?? this.hasEverCalculated,
      hubEnabled: hubEnabled ?? this.hubEnabled,
    );
  }

  static const KazaTrackingState empty = KazaTrackingState(
    sabah: 0,
    ogle: 0,
    ikindi: 0,
    aksam: 0,
    yatsi: 0,
    vitir: 0,
    hubEnabled: false,
  );
}
