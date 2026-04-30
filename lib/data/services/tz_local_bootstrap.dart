// lib/data/services/tz_local_bootstrap.dart
// Namaz + uygulama bildirimleri için ortak [tz.local] — tek kaynak.
//
// v1.2: offset eşleştirme yerine `flutter_timezone` paketi ile cihazdan
// doğrudan IANA bölge adı (ör. "Europe/Istanbul") alınır. Offset listesi
// DST geçişinde ve aynı offset'i paylaşan coğrafyalarda (ör. Türkiye +
// Moskova) yanlış bölge seçebiliyordu; gerçek bölge adı ile bu sınıf
// hatası kalkıyor. Platform çağrısı başarısız olursa (çok nadir) eski
// offset-eşleştirme fallback'i yine devrede.

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;
bool _tzDatabaseLoaded = false;
String? _lastKnownTimeZoneId;

/// Cihazın IANA zaman dilimi adını kullanarak `tz.local`'i yapılandırır.
/// İdempotent — tekrarlı çağrılar zaten kurulu bölgeyi korur.
Future<void> configureArinLocalTimeZone() async {
  if (!_tzDatabaseLoaded) {
    tzdata.initializeTimeZones();
    _tzDatabaseLoaded = true;
  }

  try {
    // flutter_timezone 5.x: `TimezoneInfo.identifier` — standart IANA adı
    // (ör. "Europe/Istanbul"). Eski paketlerdeki String dönüşünü hatırlayan
    // refactorların bu sürüm için `.identifier` okuması kritik.
    final info = await FlutterTimezone.getLocalTimezone();
    final zoneId = info.identifier;
    if (!_initialized || _lastKnownTimeZoneId != zoneId) {
      final loc = tz.getLocation(zoneId);
      tz.setLocalLocation(loc);
      _lastKnownTimeZoneId = zoneId;
      _initialized = true;
      debugPrint('tz_local_bootstrap: local zone set to $zoneId');
    }
    return;
  } catch (e) {
    debugPrint('tz_local_bootstrap: native tz fetch failed → fallback ($e)');
  }

  // Uygulama daha önce başarılı şekilde bir bölge kurduysa, geçici platform
  // hatasında mevcut `tz.local` değerini koru; yanlış fallback ile üstüne
  // yazma.
  if (_initialized) return;

  // Fallback: cihaz offset'ini adaylar listesiyle karşılaştır. DST anında
  // yanlış seçilme riski var ama hiç bölge kurulmamasından yeğdir.
  final want = DateTime.now().timeZoneOffset;
  try {
    final ist = tz.getLocation('Europe/Istanbul');
    if (tz.TZDateTime.now(ist).timeZoneOffset == want) {
      tz.setLocalLocation(ist);
      _lastKnownTimeZoneId = 'Europe/Istanbul';
      _initialized = true;
      return;
    }
  } catch (_) {}
  const candidates = <String>[
    'Europe/Istanbul',
    'Asia/Riyadh',
    'Asia/Dubai',
    'Europe/Moscow',
    'Europe/Athens',
    'Africa/Cairo',
    'Asia/Jerusalem',
    'Asia/Tehran',
    'Asia/Karachi',
    'Asia/Kolkata',
    'Asia/Dhaka',
    'Asia/Bangkok',
    'Asia/Singapore',
    'Asia/Shanghai',
    'Asia/Seoul',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Pacific/Auckland',
    'UTC',
    'Europe/Lisbon',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Africa/Johannesburg',
    'America/Sao_Paulo',
    'America/Halifax',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Anchorage',
    'Pacific/Honolulu',
  ];
  for (final name in candidates) {
    try {
      final loc = tz.getLocation(name);
      if (tz.TZDateTime.now(loc).timeZoneOffset == want) {
        tz.setLocalLocation(loc);
        _lastKnownTimeZoneId = name;
        _initialized = true;
        return;
      }
    } catch (_) {}
  }
  tz.setLocalLocation(tz.UTC);
  _lastKnownTimeZoneId = 'UTC';
  _initialized = true;
}
