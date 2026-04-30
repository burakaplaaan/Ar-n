// Kaza takibi — SharedPreferences kalıcılığı.

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kaza_tracking_state.dart';

abstract final class KazaTrackingPrefsKeys {
  static const sabah = 'kaza_count_sabah';
  static const ogle = 'kaza_count_ogle';
  static const ikindi = 'kaza_count_ikindi';
  static const aksam = 'kaza_count_aksam';
  static const yatsi = 'kaza_count_yatsi';
  static const vitir = 'kaza_count_vitir';
  static const isFemale = 'kaza_is_female';
  static const birthMillis = 'kaza_birth_millis';
  static const pubertyAge = 'kaza_puberty_age';
  static const prayedDays = 'kaza_prayed_days';
  static const hasEverCalculated = 'kaza_has_ever_calculated';
  static const hubEnabled = 'kaza_hub_enabled';
}

class KazaTrackingRepository {
  KazaTrackingRepository(this._prefs);

  final SharedPreferences _prefs;

  KazaTrackingState load() {
    final bm = _prefs.getInt(KazaTrackingPrefsKeys.birthMillis);
    final sabah = _prefs.getInt(KazaTrackingPrefsKeys.sabah) ?? 0;
    final ogle = _prefs.getInt(KazaTrackingPrefsKeys.ogle) ?? 0;
    final ikindi = _prefs.getInt(KazaTrackingPrefsKeys.ikindi) ?? 0;
    final aksam = _prefs.getInt(KazaTrackingPrefsKeys.aksam) ?? 0;
    final yatsi = _prefs.getInt(KazaTrackingPrefsKeys.yatsi) ?? 0;
    final vitir = _prefs.getInt(KazaTrackingPrefsKeys.vitir) ?? 0;
    final hasEverCalculated =
        _prefs.getBool(KazaTrackingPrefsKeys.hasEverCalculated) ?? false;
    // Sadece Rutin atölyesinde Kaza kurulunca yazılan bayrak; eski otomatik geri dönüş yok.
    final hubEnabled =
        _prefs.getBool(KazaTrackingPrefsKeys.hubEnabled) ?? false;

    return KazaTrackingState(
      sabah: sabah,
      ogle: ogle,
      ikindi: ikindi,
      aksam: aksam,
      yatsi: yatsi,
      vitir: vitir,
      isFemale: _prefs.getBool(KazaTrackingPrefsKeys.isFemale) ?? false,
      birthDate: bm != null
          ? DateTime.fromMillisecondsSinceEpoch(bm)
          : null,
      pubertyAge: _prefs.getInt(KazaTrackingPrefsKeys.pubertyAge) ?? 0,
      prayedDaysRecorded:
          _prefs.getInt(KazaTrackingPrefsKeys.prayedDays) ?? 0,
      hasEverCalculated: hasEverCalculated,
      hubEnabled: hubEnabled,
    );
  }

  Future<void> save(KazaTrackingState s) async {
    await _prefs.setInt(KazaTrackingPrefsKeys.sabah, s.sabah);
    await _prefs.setInt(KazaTrackingPrefsKeys.ogle, s.ogle);
    await _prefs.setInt(KazaTrackingPrefsKeys.ikindi, s.ikindi);
    await _prefs.setInt(KazaTrackingPrefsKeys.aksam, s.aksam);
    await _prefs.setInt(KazaTrackingPrefsKeys.yatsi, s.yatsi);
    await _prefs.setInt(KazaTrackingPrefsKeys.vitir, s.vitir);
    await _prefs.setBool(KazaTrackingPrefsKeys.isFemale, s.isFemale);
    if (s.birthDate != null) {
      await _prefs.setInt(
        KazaTrackingPrefsKeys.birthMillis,
        s.birthDate!.millisecondsSinceEpoch,
      );
    } else {
      await _prefs.remove(KazaTrackingPrefsKeys.birthMillis);
    }
    await _prefs.setInt(KazaTrackingPrefsKeys.pubertyAge, s.pubertyAge);
    await _prefs.setInt(
      KazaTrackingPrefsKeys.prayedDays,
      s.prayedDaysRecorded,
    );
    await _prefs.setBool(
      KazaTrackingPrefsKeys.hasEverCalculated,
      s.hasEverCalculated,
    );
    await _prefs.setBool(KazaTrackingPrefsKeys.hubEnabled, s.hubEnabled);
  }
}
