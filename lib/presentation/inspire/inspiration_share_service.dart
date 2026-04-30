import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share/platform_channel_share_errors.dart';

/// Keşfet kartı [RepaintBoundary] → PNG paylaşım katmanı.
///
/// İki yol:
///  • [shareCapture]             → sistem chooser'ı (share_plus 11+).
///  • [shareToInstagramStories]  → doğrudan Instagram Stories (MethodChannel).
///  • [shareToFacebookStories]   → doğrudan Facebook Stories (MethodChannel).
///
/// Filigran zaten ekrandaki `_watermark()` widget'ı ile RepaintBoundary'ye
/// dahil edildiği için burada ek Canvas drawImage yapılmaz — bazı Android
/// cihazlarda ek `Picture.toImage` çağrısı frame scheduler ile kilitlenip
/// paylaşım butonunun "sessiz" kalmasına yol açıyordu.
abstract final class InspirationShareService {
  static const MethodChannel _storiesChannel =
      MethodChannel('com.arin.arin/kesfet_share');

  /// Share sheet'te metin olarak geçer.
  static const String _shareText = 'ARINAPP — https://arinapp.com';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // ─── Pixel ratio ─────────────────────────────────────────────────────
  /// Android'de biraz daha düşük bitmap — bellek + bitmap upload süresi.
  static double _capturePixelRatio(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (_isAndroid) {
      return (dpr * 0.9).clamp(1.0, 2.0);
    }
    return (dpr * 1.25).clamp(1.5, 2.25);
  }

  // ─── Capture ─────────────────────────────────────────────────────────
  static Future<_CaptureResult> _captureToFile(
    GlobalKey boundaryKey,
    BuildContext context,
  ) async {
    if (!context.mounted) {
      debugPrint('[kesfet/share] capture: context not mounted');
      return const _CaptureResult.error('Görünüm hazır değil.');
    }
    final pixelRatio = _capturePixelRatio(context);
    await WidgetsBinding.instance.endOfFrame;

    final ctx = boundaryKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('[kesfet/share] capture: boundary ctx null/unmounted');
      return const _CaptureResult.error(
        'Görünüm henüz hazır değil. Bir an sonra tekrar deneyin.',
      );
    }

    final ro = ctx.findRenderObject();
    if (ro is! RenderRepaintBoundary) {
      debugPrint('[kesfet/share] capture: bad RO=${ro.runtimeType}');
      return const _CaptureResult.error('Paylaşım alanı bulunamadı.');
    }

    // Not: render objesinin debug-only "needs paint" getter'ı release modunda
    // `LateInitializationError`
    // atıyor (debug-only assert üzerinden set ediliyor). Bu yüzden bir
    // ekstra endOfFrame bekleyerek çizimin oturmasını garanti altına
    // alıyoruz — koşullu kontrol etmiyoruz.
    await WidgetsBinding.instance.endOfFrame;

    if (!ro.hasSize || ro.size.isEmpty) {
      return const _CaptureResult.error('Kart henüz çizilmedi. Tekrar deneyin.');
    }

    try {
      final image = await ro
          .toImage(pixelRatio: pixelRatio)
          .timeout(const Duration(seconds: 6));
      final bd = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bd == null) {
        return const _CaptureResult.error('Görüntü oluşturulamadı.');
      }
      final bytes = bd.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/arin_kesfet_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await f.writeAsBytes(bytes, flush: true);
      debugPrint('[kesfet/share] capture ok: ${f.path} (${bytes.length}B)');
      return _CaptureResult.success(f);
    } catch (e, st) {
      debugPrint('[kesfet/share] capture fail: $e\n$st');
      return _CaptureResult.error(_formatShareError(e, android: _isAndroid));
    }
  }

  // ─── Public API: Sistem paylaşım sayfası ─────────────────────────────
  /// Hata varsa kullanıcıya gösterilecek Türkçe mesaj; başarılıysa `null`.
  static Future<String?> shareCapture(
    GlobalKey boundaryKey,
    BuildContext context, {
    Rect? sharePositionOrigin,
  }) async {
    debugPrint('[kesfet/share] shareCapture START');
    final capture = await _captureToFile(boundaryKey, context);
    if (capture.file == null) {
      return capture.errorMessage ?? 'Paylaşım açılamadı. Tekrar deneyin.';
    }
    if (!context.mounted) {
      debugPrint('[kesfet/share] shareCapture: ctx unmounted after capture');
      return null;
    }

    try {
      debugPrint('[kesfet/share] invoking SharePlus.share');
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(capture.file!.path, mimeType: 'image/png')],
          text: _shareText,
          // iOS iPad popover anchor'ı. Android'de bazı cihazlarda rect
          // yorumu chooser'ı açmadan geri döndürüyordu → Android'de geçme.
          sharePositionOrigin: _isIOS ? sharePositionOrigin : null,
        ),
      );
      debugPrint('[kesfet/share] SharePlus result: ${result.status}');
      return switch (result.status) {
        ShareResultStatus.success => null,
        ShareResultStatus.dismissed => null,
        // Android 14+ callback belirsizliği: chooser açılmış olabilir.
        ShareResultStatus.unavailable => null,
      };
    } catch (e, st) {
      debugPrint('[kesfet/share] SharePlus throw: $e\n$st');
      return _formatShareError(e, android: _isAndroid);
    }
  }

  // ─── Public API: Instagram Stories derin paylaşım ────────────────────
  static Future<DeepShareOutcome> shareToInstagramStories(
    GlobalKey boundaryKey,
    BuildContext context,
  ) async {
    debugPrint('[kesfet/share] shareToInstagramStories START');
    if (!_isAndroid && !_isIOS) {
      return const DeepShareOutcome.failed(
        'Bu platformda Stories paylaşımı desteklenmiyor.',
      );
    }

    final capture = await _captureToFile(boundaryKey, context);
    if (capture.file == null) {
      return DeepShareOutcome.failed(
        capture.errorMessage ?? 'Paylaşım açılamadı.',
      );
    }

    try {
      debugPrint('[kesfet/share] invoking native shareToInstagramStories');
      final ok = await _storiesChannel
          .invokeMethod<bool>('shareToInstagramStories', capture.file!.path)
          .timeout(const Duration(seconds: 10));
      debugPrint('[kesfet/share] native IG result: $ok');
      if (ok == true) return const DeepShareOutcome.success();
      return const DeepShareOutcome.notInstalled();
    } on PlatformException catch (e, st) {
      debugPrint('[kesfet/share] IG PlatformException: $e\n$st');
      if (e.code == 'not_installed') {
        return const DeepShareOutcome.notInstalled();
      }
      return DeepShareOutcome.failed(
        _formatShareError(e, android: _isAndroid),
      );
    } catch (e, st) {
      debugPrint('[kesfet/share] IG throw: $e\n$st');
      if (isMethodChannelLateInitResultError(e)) {
        return const DeepShareOutcome.success();
      }
      return DeepShareOutcome.failed(
        _formatShareError(e, android: _isAndroid),
      );
    }
  }

  // ─── Public API: Facebook Stories derin paylaşım ─────────────────────
  static Future<DeepShareOutcome> shareToFacebookStories(
    GlobalKey boundaryKey,
    BuildContext context, {
    String facebookAppId = '',
  }) async {
    debugPrint('[kesfet/share] shareToFacebookStories START');
    if (!_isAndroid && !_isIOS) {
      return const DeepShareOutcome.failed(
        'Bu platformda Stories paylaşımı desteklenmiyor.',
      );
    }

    final capture = await _captureToFile(boundaryKey, context);
    if (capture.file == null) {
      return DeepShareOutcome.failed(
        capture.errorMessage ?? 'Paylaşım açılamadı.',
      );
    }

    try {
      final ok = await _storiesChannel.invokeMethod<bool>(
        'shareToFacebookStories',
        <String, Object?>{
          'path': capture.file!.path,
          'appId': facebookAppId,
        },
      ).timeout(const Duration(seconds: 10));
      debugPrint('[kesfet/share] native FB result: $ok');
      if (ok == true) return const DeepShareOutcome.success();
      return const DeepShareOutcome.notInstalled();
    } on PlatformException catch (e, st) {
      debugPrint('[kesfet/share] FB PlatformException: $e\n$st');
      if (e.code == 'not_installed') {
        return const DeepShareOutcome.notInstalled();
      }
      return DeepShareOutcome.failed(
        _formatShareError(e, android: _isAndroid),
      );
    } catch (e, st) {
      debugPrint('[kesfet/share] FB throw: $e\n$st');
      if (isMethodChannelLateInitResultError(e)) {
        return const DeepShareOutcome.success();
      }
      return DeepShareOutcome.failed(
        _formatShareError(e, android: _isAndroid),
      );
    }
  }

  // ─── Error formatter ─────────────────────────────────────────────────
  static String _formatShareError(Object e, {required bool android}) {
    if (isMethodChannelLateInitResultError(e)) {
      return platformShareTransientErrorMessage();
    }
    if (e is TimeoutException) {
      return 'Paylaşım zaman aşımına uğradı. Tekrar deneyin.';
    }
    if (e is PlatformException) {
      final code = e.code;
      final m = e.message;
      if (code == 'not_found') {
        return 'Paylaşım dosyası bulunamadı. Tekrar deneyin.';
      }
      if (code == 'not_installed') {
        return 'Bu uygulama cihazınızda yüklü değil.';
      }
      if (code == 'share_failed' || code == 'bad_args') {
        return 'Paylaşım açılamadı. Tekrar deneyin.';
      }
      final combined = '${m ?? ''} ${e.details ?? ''}'.toLowerCase();
      if (android) {
        if (combined.contains('activitynotfound') ||
            combined.contains('no activity')) {
          return 'Paylaşım menüsü açılamadı. Gerçek cihazda deneyin.';
        }
        if (combined.contains('ioexception') ||
            combined.contains('permission') ||
            combined.contains('eacces')) {
          return 'Dosya paylaşılamadı. Depolama izni veya cihaz kısıtı olabilir.';
        }
      }
      if (m != null && m.trim().isNotEmpty) {
        return 'Paylaşım (${code.isNotEmpty ? '$code: ' : ''}'
            '${m.length > 160 ? '${m.substring(0, 160)}…' : m})';
      }
      if (code.isNotEmpty) return 'Paylaşım hatası: $code';
    }
    final s = e.toString();
    if (s.isNotEmpty && s != 'Instance of \'Exception\'') {
      if (s.contains('LateInitializationError')) {
        return platformShareTransientErrorMessage();
      }
      final short = s.length > 200 ? '${s.substring(0, 200)}…' : s;
      return 'Paylaşım açılamadı: $short';
    }
    return 'Paylaşım açılamadı. Tekrar deneyin.';
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sonuç tipleri — sealed + pattern matching friendly (public varyantlar).
// ─────────────────────────────────────────────────────────────────────────

sealed class DeepShareOutcome {
  const DeepShareOutcome();
  const factory DeepShareOutcome.success() = DeepShareSuccess;
  const factory DeepShareOutcome.notInstalled() = DeepShareNotInstalled;
  const factory DeepShareOutcome.failed(String message) = DeepShareFailed;
}

final class DeepShareSuccess extends DeepShareOutcome {
  const DeepShareSuccess();
}

final class DeepShareNotInstalled extends DeepShareOutcome {
  const DeepShareNotInstalled();
}

final class DeepShareFailed extends DeepShareOutcome {
  const DeepShareFailed(this.message);
  final String message;
}

class _CaptureResult {
  const _CaptureResult.success(File this.file) : errorMessage = null;
  const _CaptureResult.error(String this.errorMessage) : file = null;

  final File? file;
  final String? errorMessage;
}
