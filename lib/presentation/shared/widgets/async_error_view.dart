// lib/presentation/shared/widgets/async_error_view.dart
// Ortak hata ekranı — `AsyncValue.when(error: ...)` veya FutureBuilder/
// StreamBuilder error state'leri için.
//
// Tasarım: arin dark temasıyla uyumlu; orta-ekran centered, `RefreshIndicator`
// ile eşleşecek biçimde scrollable (kullanıcı aşağı çekince de tekrar denesin).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';

class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
    this.error,
    this.retryLabel,
    this.icon = Icons.cloud_off_rounded,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  /// "Tekrar dene"ye basınca çağrılır. Genelde `ref.invalidate(provider)`
  /// veya `provider.future` tetikleyen bir fonksiyon.
  final VoidCallback onRetry;

  final String? title;

  /// Opsiyonel alt satır; null ise generic açıklama gösterilir.
  final String? message;

  /// `debug` için ham hata; release'de de **expand** ile gösteririz ki
  /// kullanıcı admin'e ekran görüntüsü gönderirken bilgi yazılı olsun.
  final Object? error;

  final String? retryLabel;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = title ?? l10n.asyncErrorDefaultTitle;
    final msg = message ??
        l10n.asyncErrorDefaultMessage;
    final resolvedRetry = retryLabel ?? l10n.asyncErrorRetryAction;
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(
                icon,
                size: 34,
                color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(resolvedRetry),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldMid,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              _ErrorDetailsTile(error: error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorDetailsTile extends StatelessWidget {
  const _ErrorDetailsTile({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final raw = error.toString();
    // Çok uzun stack'i kısalt — admin'e göndermek için kopyalanabilir.
    final preview = raw.length > 220 ? '${raw.substring(0, 220)}…' : raw;
    return ExpansionTile(
      title: Text(
        l10n.asyncErrorTechnicalDetailsTitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
      iconColor: Colors.white.withValues(alpha: 0.5),
      collapsedIconColor: Colors.white.withValues(alpha: 0.5),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: raw));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.asyncErrorCopiedToClipboard)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              preview,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
