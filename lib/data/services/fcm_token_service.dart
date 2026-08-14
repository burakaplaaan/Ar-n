// Uygulama başlangıcında FCM dinleyicilerini kurar. Sistem bildirim izni
// veren kullanıcılar otomatik olarak `broadcast_all`, görünür bildirim
// üretmeyen işlevsel widget kilit senkronu ise `widget_gate_all` topic'i
// üzerinden mesaj alır.
// Topic tabanlı mesajlaşma: Cloud Function bu topic'e push atınca tüm
// aboneler bildirimi alır — tek tek token yönetimi gerekmez.
//
// Moment Verse yönlendirmesi:
//   Bildirimde data['type'] == 'moment_verse' gelirse uygulama
//   /moment-verse ekranına yönlendirilir. Yönlendirme callback'i
//   setNavigationCallback() ile dışarıdan enjekte edilir; callback
//   henüz hazır değilse rota _pendingNavigationRoute'da saklanır
//   ve callback set edildiğinde otomatik tetiklenir.

import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../core/router/app_router.dart';
import 'arin_local_notifications_plugin.dart';
import 'product_metrics_service.dart';
import 'startup_permission_policy.dart';
import 'widget_global_lock_push_service.dart';

/// Uygulama arka planda iken gelen FCM mesajlarını işler.
/// Top-level fonksiyon olması zorunlu (Flutter embedding kuralı).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (await WidgetGlobalLockPushService.applyMessageData(
    message.data,
    persistFlutterState: false,
  )) {
    debugPrint('FCM arka plan widget kilidi uygulandı: ${message.messageId}');
    return;
  }
  // Görünür yayın bildirimlerini arka planda işletim sistemi gösterir.
  debugPrint('FCM arka plan mesajı: ${message.messageId}');
}

abstract final class FcmTokenService {
  static const _broadcastTopic = 'broadcast_all';
  static const _widgetGateTopic = 'widget_gate_all';
  static const _broadcastPromptHandledKey =
      'arin_broadcast_permission_prompt_handled_v1';
  static bool _initialized = false;
  static bool _backgroundHandlerRegistered = false;
  static bool _broadcastSubscribed = false;
  static bool _widgetGateSubscribed = false;
  static bool _localTapHandlerRegistered = false;
  static bool _initialLocalNotificationChecked = false;
  static bool _initialMessageChecked = false;
  static Future<void>? _initializeFuture;
  static Future<void>? _widgetGateSubscribeFuture;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static Future<bool>? _broadcastSyncInFlight;
  static Future<bool>? _broadcastUnsubscribeInFlight;
  static Future<void> _audienceSyncTail = Future<void>.value();
  static bool _broadcastSuspended = false;

  /// Firebase Messaging bu callback'in runApp'ten önce kaydedilmesini ister.
  /// Firebase'in kendisinin henüz initialize edilmesi gerekmez.
  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) return;
    _backgroundHandlerRegistered = true;
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  }

  /// GoRouter.go() referansı — ArinApp.initState() içinde set edilir.
  static void Function(String route)? _navigationCallback;

  /// Callback henüz set edilmemişse buraya park edilir.
  static String? _pendingNavigationRoute;

  /// ArinApp, router hazır olduğunda bu callback'i enjekte eder.
  /// Bekleyen rota varsa anında tetiklenir.
  static void setNavigationCallback(void Function(String route) callback) {
    _navigationCallback = callback;
    final pending = _pendingNavigationRoute;
    if (pending != null) {
      _pendingNavigationRoute = null;
      Future.microtask(() => callback(pending));
    }
  }

  /// Callback hazırsa hemen navigate eder; değilse rota park edilir.
  static void _navigate(String route) {
    final cb = _navigationCallback;
    if (cb != null) {
      cb(route);
    } else {
      _pendingNavigationRoute = route;
    }
  }

  static void _openMomentVerse({String? deliveryId}) {
    final normalized = deliveryId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      unawaited(ProductMetricsService.notificationClick(normalized));
    }
    _navigate(AppRoutes.momentVerse);
  }

  static void _openPrayerCircle({String? requestId}) {
    final normalized = requestId?.trim();
    _navigate(
      normalized == null || normalized.isEmpty
          ? AppRoutes.prayerCircle
          : AppRoutes.prayerCircleRequest(normalized),
    );
  }

  static void _openHilalDuel() {
    _navigate(AppRoutes.hilalDuel);
  }

  static Future<bool> _queueAudienceSync({required bool active}) {
    final completer = Completer<bool>();
    _audienceSyncTail = _audienceSyncTail
        .then((_) async {
          final result = await ProductMetricsService.syncNotificationAudience(
            active: active,
          );
          completer.complete(result);
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) completer.complete(false);
          debugPrint('══ ARIN FCM ══ audience sync queue hatası: $error');
        });
    return completer.future;
  }

  /// Onboarding tamamlandıktan sonra bir kez çağrılır.
  static Future<void> initIfNeeded() {
    if (_initialized) return Future<void>.value();
    return _initializeFuture ??= _initializeWithRetry().whenComplete(
      () => _initializeFuture = null,
    );
  }

  static Future<void> _initializeWithRetry() async {
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 8),
    ];
    for (final delay in retryDelays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (await _initializeOnce()) return;
    }
  }

  static Future<bool> _initializeOnce() async {
    try {
      registerBackgroundHandler();

      // Android 8.0+'da FCM bildirimleri channelId'si tanımlı bir kanala
      // ihtiyaç duyar; kanal yoksa bildirim sessizce düşer.
      await _ensureAndroidBroadcastChannel();

      // Foreground'da manuel olarak gösterdiğimiz local notification'a
      // (payload: "moment_verse") tıklanınca uygulama içi navigate edilsin.
      // Background/closed durumunda zaten FCM `onMessageOpenedApp` ve
      // `getInitialMessage` üzerinden yönlendirme yapılıyor.
      if (!_localTapHandlerRegistered) {
        registerLocalNotificationTapHandler('moment_verse', (payload) {
          final parts = payload.split('|');
          _openMomentVerse(deliveryId: parts.length > 1 ? parts[1] : null);
        });
        registerLocalNotificationTapHandler('prayer_circle', (payload) {
          final parts = payload.split('|');
          _openPrayerCircle(requestId: parts.length > 1 ? parts[1] : null);
        });
        registerLocalNotificationTapHandler('hilal_duel', (_) {
          _openHilalDuel();
        });
        _localTapHandlerRegistered = true;
      }
      if (!_initialLocalNotificationChecked) {
        await dispatchInitialLocalNotificationTap();
        _initialLocalNotificationChecked = true;
      }

      // ── Uygulama kapalıyken bildirime tıklanmış mı? ──────────────────
      if (!_initialMessageChecked) {
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        _initialMessageChecked = true;
        if (initial != null && initial.data['type'] == 'moment_verse') {
          _openMomentVerse(deliveryId: initial.data['deliveryId']?.toString());
        } else if (initial?.data['type'] == 'prayer_circle') {
          _openPrayerCircle(requestId: initial?.data['requestId']?.toString());
        } else if (initial?.data['type'] == 'hilal_duel') {
          _openHilalDuel();
        }
      }

      // ── Uygulama arka plandayken bildirime tıklanmış mı? ─────────────
      _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {
            if (message.data['type'] == 'moment_verse') {
              _openMomentVerse(
                deliveryId: message.data['deliveryId']?.toString(),
              );
            } else if (message.data['type'] == 'prayer_circle') {
              _openPrayerCircle(
                requestId: message.data['requestId']?.toString(),
              );
            } else if (message.data['type'] == 'hilal_duel') {
              _openHilalDuel();
            }
          });

      // iOS'ta uygulama ön plandayken bildirimleri sistem banner'ı olarak göster.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // İzin zaten verilmişse topic kaydını sessizce onar. Sistem izin
      // diyaloğu uygulama tamamen açıldıktan sonra ayrı çağrıyla gösterilir.
      await syncBroadcastSubscriptionIfAuthorized();

      // Widget kilidi uygulamanın işlevsel durumudur ve görünür bildirim
      // üretmez. Bildirim izninden bağımsız ayrı topic kullanılır.
      _widgetGateSubscribeFuture ??= _subscribeToWidgetGateTopicWithRetry()
          .whenComplete(() => _widgetGateSubscribeFuture = null);
      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((_) {
            _broadcastSubscribed = false;
            unawaited(_subscribeToWidgetGateTopic());
            unawaited(syncBroadcastSubscriptionIfAuthorized());
          });

      // Uygulama ön plandayken Android sistem bildirimi otomatik göstermez;
      // manuel olarak `arin_ntf_broadcast` kanalına yerel bildirim atıyoruz.
      // iOS tarafı `setForegroundNotificationPresentationOptions` ile zaten
      // banner gösteriyor, burada Android'i hizalıyoruz.
      _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_handleForegroundMessage(message)),
      );
      _initialized = true;
      return true;
    } catch (e) {
      // FCM başlatma başarısız olsa da uygulama çalışmaya devam etmeli.
      _initialized = false;
      debugPrint('══ ARIN FCM ══ başlatma başarısız (sessiz): $e');
      return false;
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (await WidgetGlobalLockPushService.applyMessageData(
      message.data,
      persistFlutterState: true,
    )) {
      debugPrint(
        '══ ARIN FCM ══ ön plan widget kilidi uygulandı: ${message.messageId}',
      );
      return;
    }
    final ntf = message.notification;
    debugPrint(
      '══ ARIN FCM ══ ön plan mesajı: ${ntf?.title} / data=${message.data}',
    );
    if (ntf == null) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final type = message.data['type']?.toString() ?? '';
      final reason = message.data['reason']?.toString() ?? '';
      final isPrayerCircle = type == 'prayer_circle';
      final isHilalDuel = type == 'hilal_duel';
      // Herkese hediye can: genel yayın kanalı (düello kanalı kapalı olsa da düşsün).
      final isHilalPromo = isHilalDuel && reason == 'admin_heart_grant_all';
      final channelId = isPrayerCircle
          ? 'arin_prayer_circle'
          : isHilalPromo
              ? 'arin_ntf_broadcast'
              : isHilalDuel
                  ? 'arin_hilal_duel'
                  : 'arin_ntf_broadcast';
      final channelName = isPrayerCircle
          ? 'Dua Halkası'
          : isHilalPromo
              ? 'Ayet Bildirimleri'
              : isHilalDuel
                  ? 'Bilgi Düellosu'
                  : 'Ayet Bildirimleri';
      final channelDescription = isPrayerCircle
          ? 'Dua taleplerine eşlik bildirimleri'
          : isHilalPromo
              ? 'Günlük ayet ve anlık bildirimler'
              : isHilalDuel
                  ? 'Bilgi Düellosu sıralama ve hatırlatma bildirimleri'
                  : 'Günlük ayet ve anlık bildirimler';
      await arinLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        ntf.title,
        ntf.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        payload: [
          type,
          isPrayerCircle
              ? message.data['requestId']?.toString() ?? ''
              : isHilalDuel
                  ? ''
                  : message.data['deliveryId']?.toString() ?? '',
        ].join('|'),
      );
    } catch (e) {
      debugPrint('══ ARIN FCM ══ foreground show hatası: $e');
    }
  }

  static Future<void> _subscribeToWidgetGateTopicWithRetry() {
    if (_widgetGateSubscribed) return Future<void>.value();
    return _widgetGateSubscribeFuture ??=
        _subscribeToWidgetGateTopicWithRetryInternal().whenComplete(
          () => _widgetGateSubscribeFuture = null,
        );
  }

  static Future<void> _subscribeToWidgetGateTopicWithRetryInternal() async {
    for (final delay in const [
      Duration.zero,
      Duration(seconds: 5),
      Duration(seconds: 30),
    ]) {
      if (_widgetGateSubscribed) return;
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (await _subscribeToWidgetGateTopic()) return;
    }
  }

  static Future<bool> _subscribeToWidgetGateTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(_widgetGateTopic);
      _widgetGateSubscribed = true;
      debugPrint('══ ARIN FCM ══ $_widgetGateTopic topic kaydı tamam');
      return true;
    } catch (e) {
      // Özellikle iOS'ta APNs token ilk açılışta birkaç saniye gecikebilir.
      // onTokenRefresh ve sonraki uygulama açılışı yeniden deneyecek.
      debugPrint('══ ARIN FCM ══ $_widgetGateTopic topic kaydı ertelendi: $e');
      return false;
    }
  }

  /// Android 8.0+'da FCM push'larının düşmemesi için `arin_ntf_broadcast`
  /// kanalını oluşturur. İdempotent: kanal zaten varsa Android sessizce geçer.
  static Future<void> _ensureAndroidBroadcastChannel() async {
    try {
      // Plugin initialize edilmemiş olabilir; burada güvenli şekilde başlat.
      await initializeArinLocalNotificationsPlugin();
      final android = arinLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return;
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'arin_ntf_broadcast',
          'Ayet Bildirimleri',
          description: 'Günlük ayet ve anlık bildirimler',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'arin_prayer_circle',
          'Dua Halkası',
          description: 'Dua taleplerine eşlik bildirimleri',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'arin_hilal_duel',
          'Bilgi Düellosu',
          description: 'Bilgi Düellosu sıralama ve hatırlatma bildirimleri',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
      debugPrint('══ ARIN FCM ══ bildirim kanalları hazır');
    } on PlatformException catch (e) {
      debugPrint('══ ARIN FCM ══ broadcast kanalı oluşturulamadı: $e');
    }
  }

  static bool _broadcastAllowed(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  /// Mevcut sistem iznini değiştirmeden yayın topic kaydını onarır.
  ///
  /// Uygulama güncelleyen mevcut kullanıcılar, iOS APNs token'ı geç oluşan
  /// cihazlar ve FCM token yenilemeleri için idempotent olarak çağrılabilir.
  static Future<bool> syncBroadcastSubscriptionIfAuthorized() {
    return _broadcastSyncInFlight ??= _syncBroadcastSubscription().whenComplete(
      () => _broadcastSyncInFlight = null,
    );
  }

  static Future<bool> _syncBroadcastSubscription() async {
    try {
      if (_broadcastSuspended) return false;
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (!_broadcastAllowed(settings.authorizationStatus)) {
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          await _unsubscribeFromBroadcastsInternal(waitForBroadcastSync: false);
        }
        return false;
      }
      if (_broadcastSubscribed) {
        if (_broadcastSuspended) return false;
        await _queueAudienceSync(active: true);
        return true;
      }
      await FirebaseMessaging.instance.subscribeToTopic(_broadcastTopic);
      if (_broadcastSuspended) return false;
      _broadcastSubscribed = true;
      await _queueAudienceSync(active: true);
      debugPrint('══ ARIN FCM ══ $_broadcastTopic topic kaydı tamam');
      return true;
    } catch (e) {
      // Özellikle iOS'ta APNs token ilk açılışta gecikebilir. Token refresh
      // veya sonraki uygulama açılışı tekrar deneyecek.
      debugPrint('══ ARIN FCM ══ $_broadcastTopic topic kaydı ertelendi: $e');
      return false;
    }
  }

  /// İzin daha önce kararlaştırılmadıysa Android 13+ / iOS sistem diyaloğunu
  /// bir kez gösterir. İzin zaten verilmişse yalnız topic kaydını onarır;
  /// reddedilmiş izni tekrar tekrar sormaz.
  static Future<bool> requestBroadcastPermissionIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') == true;
      final promptHandled = prefs.getBool(_broadcastPromptHandledKey) == true;
      if (!shouldAutoRequestBroadcastPermission(
        onboardingCompleted: onboardingCompleted,
        promptAlreadyHandled: promptHandled,
      )) {
        return syncBroadcastSubscriptionIfAuthorized();
      }
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return requestBroadcastPermissions();
      }
      await markBroadcastPermissionPromptHandled();
      return syncBroadcastSubscriptionIfAuthorized();
    } catch (e) {
      debugPrint('══ ARIN FCM ══ permission status check failed: $e');
      return false;
    }
  }

  /// Android 13+ ve iOS sistem bildirim iznini ister; izin verilirse kullanıcıyı
  /// ayet/yayın topic'ine otomatik kaydeder.
  static Future<bool> requestBroadcastPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus != AuthorizationStatus.notDetermined) {
        await markBroadcastPermissionPromptHandled();
      }
      if (_broadcastAllowed(settings.authorizationStatus)) {
        _broadcastSuspended = false;
      }
      return syncBroadcastSubscriptionIfAuthorized();
    } catch (e) {
      debugPrint('══ ARIN FCM ══ permission request failed: $e');
      return false;
    }
  }

  /// Wipe sonrası aynı process içinde onboarding yeniden tamamlanırsa geçici
  /// suspension'ı kaldırır ve mevcut OS izniyle topic kaydını yeniden kurar.
  static Future<bool> resumeBroadcastSubscriptionIfAuthorized() {
    _broadcastSuspended = false;
    return syncBroadcastSubscriptionIfAuthorized();
  }

  /// Onboarding'de izin verildiğinde, reddedildiğinde veya kullanıcı bilinçli
  /// olarak "Şimdilik geç" dediğinde otomatik açılış prompt'unu bastırır.
  static Future<void> markBroadcastPermissionPromptHandled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_broadcastPromptHandledKey, true);
    } catch (e) {
      debugPrint('══ ARIN FCM ══ permission prompt state kaydedilemedi: $e');
    }
  }

  /// Kullanıcı abonelikten çıkmak istediğinde veya veri silindiğinde çağrılır.
  static Future<bool> unsubscribeFromBroadcasts({bool suspendForWipe = false}) {
    if (suspendForWipe) _broadcastSuspended = true;
    return _broadcastUnsubscribeInFlight ??= _unsubscribeFromBroadcastsInternal(
      waitForBroadcastSync: true,
    ).whenComplete(() => _broadcastUnsubscribeInFlight = null);
  }

  static Future<bool> _unsubscribeFromBroadcastsInternal({
    required bool waitForBroadcastSync,
  }) async {
    if (waitForBroadcastSync) {
      final activeSync = _broadcastSyncInFlight;
      if (activeSync != null) await activeSync;
    }
    var unsubscribed = false;
    for (final delay in const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 3),
    ]) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_broadcastTopic);
        unsubscribed = true;
        break;
      } catch (e) {
        debugPrint('══ ARIN FCM ══ unsubscribeFromTopic ertelendi: $e');
      }
    }
    _broadcastSubscribed = false;
    if (!unsubscribed) return false;
    for (final delay in const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 3),
    ]) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (await _queueAudienceSync(active: false)) {
        return true;
      }
    }
    return false;
  }
}
