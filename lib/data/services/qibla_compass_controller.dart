// lib/data/services/qibla_compass_controller.dart
//
// Kibla pusulasi icin sensor + Qibla bearing katmani.
//
// Qibla bearing kaynagi (oncelik sirasi):
//   1. AlAdhan REST API — resmi kaynaklar tarafindan kullanilan, otoriter.
//      GET https://api.aladhan.com/v1/qibla/{lat}/{lng}
//   2. Lokal Haversine/atan2 hesabi — internet yoksa veya API basarisizsa.
//
// Heading kaynagi:
//   Native EventChannel 'com.arin.arin/rotation_compass'
//   Kotlin kodu: TYPE_GEOMAGNETIC_ROTATION_VECTOR (yoksa ham accel+mag)
//   + GeomagneticField deklinasyonu → TRUE north heading, 0-360 derece.
//
// MethodChannel 'com.arin.arin/compass_geomagnetic':
//   GPS koordinatlari ile GeomagneticField hesaplanip Kotlin'e gonderilir.

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

const _compassChannel = EventChannel('com.arin.arin/rotation_compass');
const _geomagChannel  = MethodChannel('com.arin.arin/compass_geomagnetic');

/// Tek bir pusula okuması.
class QiblaSensorReading {
  const QiblaSensorReading({
    required this.heading,
    required this.qiblaFromNorth,
    required this.rawHeading,
    required this.pitch,
    required this.roll,
    required this.accuracy,
    required this.jitter,
    required this.stable,
    required this.guidance,
  });

  /// Cihazın mevcut yönü — 0..360 derece, kuzeyden saat yönüne (TRUE north).
  final double heading;

  /// Mevcut konumdan Kâbe'ye yön — 0..360 derece, kuzeyden saat yönüne.
  final double qiblaFromNorth;

  /// Native taraftaki filtre öncesi heading. Debug/diagnostic amaçlı taşınır.
  final double rawHeading;

  /// Android orientation pitch/roll değerleri, derece.
  final double pitch;
  final double roll;

  /// Android sensor accuracy değeri.
  final int accuracy;

  /// Native kısa pencere jitter değeri, derece.
  final double jitter;

  /// Telefon tutuşu ve sensör güvenilirliği ölçüm için uygun mu?
  final bool stable;

  /// Kullanıcıya gösterilecek kısa yönlendirme tipi.
  final QiblaGuidance guidance;
}

enum QiblaGuidance {
  good,
  tilt,
  calibrate,
  unstable,
}

class QiblaCompassController {
  // --- throttle -----------------------------------------------------------
  static const _emitInterval = Duration(milliseconds: 140);
  static const _minDeltaDeg  = 0.7;

  // --- Kâbe koordinatları (WGS-84) ----------------------------------------
  static const double _kLat = 21.4225  * math.pi / 180;
  static const double _kLon = 39.82619 * math.pi / 180;

  // --- İç durum -----------------------------------------------------------
  final _out  = StreamController<QiblaSensorReading>.broadcast();
  final _dio  = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Stream<QiblaSensorReading> get stream => _out.stream;

  StreamSubscription<dynamic>? _compassSub;
  bool   _disposed       = false;
  bool   _started        = false;
  double _qiblaFromNorth = 0;
  double _lastHeading    = double.nan;
  QiblaGuidance? _lastGuidance;
  bool? _lastStable;
  DateTime _lastEmitAt   = DateTime.fromMillisecondsSinceEpoch(0);

  // ── API: AlAdhan Qibla bearing ───────────────────────────────────────────

  /// AlAdhan REST API'den Qibla yönünü alır.
  /// Başarısız olursa lokal Haversine hesabını döner (hiç hata fırlatmaz).
  Future<double> _fetchQiblaFromApi(double lat, double lng) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        'https://api.aladhan.com/v1/qibla/$lat/$lng',
      );
      final data = resp.data?['data'] as Map<String, dynamic>?;
      final dir  = data?['direction'];
      if (dir != null) {
        return (dir as num).toDouble() % 360;
      }
    } catch (_) {
      // API erişilemez — lokal hesaba düş.
    }
    return bearingToKaaba(lat, lng);
  }

  // ── Lokal yedek hesap ────────────────────────────────────────────────────

  /// Büyük daire yayı: konum → Kâbe yönü (derece, 0-360, TRUE north).
  static double bearingToKaaba(double lat, double lon) {
    final latRad = lat * math.pi / 180;
    final lonRad = lon * math.pi / 180;
    final dLon   = _kLon - lonRad;
    final y      = math.sin(dLon) * math.cos(_kLat);
    final x      = math.cos(latRad) * math.sin(_kLat) -
                   math.sin(latRad) * math.cos(_kLat) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // ── Manyetik deklinasyonu Kotlin'e gönder ────────────────────────────────

  static Future<void> _syncDeclination(Position p) async {
    try {
      await _geomagChannel.invokeMethod<double>('update', {
        'latitude':  p.latitude,
        'longitude': p.longitude,
        'altitude':  p.altitude,
      });
    } catch (_) {
      // Başarısızlık kabul edilebilir; sensor manyetik north'a göre devam eder.
    }
  }

  // ── Başlatma ─────────────────────────────────────────────────────────────

  Future<bool> start() async {
    if (_started || _disposed) return _started;

    // Konum izni.
    var perm = await Geolocator.checkPermission();
    if (_disposed) return false;
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (_disposed) return false;
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _out.addError(Exception('location_permission_denied'));
      return false;
    }

    // GPS konumu.
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      if (_disposed) return false;
      _out.addError(e);
      return false;
    }
    if (_disposed) return false;

    // AlAdhan API (veya lokal fallback) ile Qibla yönü.
    _qiblaFromNorth = await _fetchQiblaFromApi(pos.latitude, pos.longitude);
    if (_disposed) return false;

    // Deklinasyonu Kotlin'e gönder (async, critical path değil).
    _syncDeclination(pos);

    // Native pusula stream'ini başlat.
    _compassSub = _compassChannel.receiveBroadcastStream().listen(
      (dynamic raw) {
        if (_disposed) return;

        final reading = _readingFromNative(raw);
        final h = reading.heading;

        final now     = DateTime.now();
        final elapsed = now.difference(_lastEmitAt);
        final rawDelta = _lastHeading.isNaN
            ? double.infinity
            : (h - _lastHeading).abs();
        final delta = rawDelta > 180 ? 360 - rawDelta : rawDelta;
        final stateChanged = _lastGuidance != reading.guidance ||
            _lastStable != reading.stable;

        if (!stateChanged && elapsed < _emitInterval && delta < _minDeltaDeg) {
          return;
        }

        _lastEmitAt   = now;
        _lastHeading  = h;
        _lastGuidance = reading.guidance;
        _lastStable   = reading.stable;
        _out.add(reading);
      },
      onError: (Object e) {
        if (!_disposed && !_out.isClosed) _out.addError(e);
      },
    );

    _started = true;
    return true;
  }

  void dispose() {
    _disposed = true;
    _compassSub?.cancel();
    _compassSub = null;
    _dio.close();
    if (!_out.isClosed) _out.close();
  }

  QiblaSensorReading _readingFromNative(dynamic raw) {
    if (raw is num) {
      final h = raw.toDouble();
      return QiblaSensorReading(
        heading: h,
        qiblaFromNorth: _qiblaFromNorth,
        rawHeading: h,
        pitch: 0,
        roll: 0,
        accuracy: 0,
        jitter: 0,
        stable: true,
        guidance: QiblaGuidance.good,
      );
    }

    final map = (raw as Map).cast<dynamic, dynamic>();
    final guidance = _guidanceFrom(map['guidance']);
    return QiblaSensorReading(
      heading: _asDouble(map['heading']),
      qiblaFromNorth: _qiblaFromNorth,
      rawHeading: _asDouble(map['rawHeading']),
      pitch: _asDouble(map['pitch']),
      roll: _asDouble(map['roll']),
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      jitter: _asDouble(map['jitter']),
      stable: map['stable'] == true && guidance == QiblaGuidance.good,
      guidance: guidance,
    );
  }

  static double _asDouble(dynamic value) {
    return (value as num?)?.toDouble() ?? 0;
  }

  static QiblaGuidance _guidanceFrom(dynamic raw) {
    return switch (raw) {
      'tilt' => QiblaGuidance.tilt,
      'calibrate' => QiblaGuidance.calibrate,
      'unstable' => QiblaGuidance.unstable,
      _ => QiblaGuidance.good,
    };
  }
}
