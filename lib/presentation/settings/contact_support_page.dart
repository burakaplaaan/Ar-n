import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/android_oem_settings_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

/// Destek mailine yazılacak marka + model satırı.
String formatContactDeviceLabel({
  required String brand,
  required String model,
}) {
  final brandText = brand.trim();
  final modelText = model.trim();
  if (brandText.isEmpty) return modelText;
  if (modelText.isEmpty) return brandText;
  if (modelText.toLowerCase().startsWith(brandText.toLowerCase())) {
    return modelText;
  }
  return '$brandText $modelText';
}

/// OEM `displayName` "Android" ise gerçek markayı kullan (Pixel vb.).
String contactDeviceBrand({
  required String displayName,
  required String brand,
}) {
  final display = displayName.trim();
  if (display.isNotEmpty && display.toLowerCase() != 'android') {
    return display;
  }
  return brand.trim();
}

Future<String> resolveContactDeviceLabel() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return '';
  final oem = await AndroidOemSettingsService.getInfo();
  if (oem == null) return '';
  return formatContactDeviceLabel(
    brand: contactDeviceBrand(
      displayName: oem.displayName,
      brand: oem.brand,
    ),
    model: oem.model,
  );
}

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  static const String _supportEmail = 'arinapphelp@gmail.com';
  bool _mailOpening = false;

  Future<Uri> _buildMailUri(AppLocalizations l10n) async {
    final device = await resolveContactDeviceLabel();
    final subject = Uri.encodeComponent(l10n.settingsContactMailSubject);
    final body = Uri.encodeComponent(l10n.settingsContactMailBody(device));
    return Uri.parse(
      'mailto:$_supportEmail?subject=$subject&body=$body',
    );
  }

  Future<void> _copyEmail(
    AppLocalizations l10n, {
    bool showSnack = true,
  }) async {
    try {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (!mounted || !showSnack) return;
      showArinTopToast(context, l10n.settingsContactEmailCopied);
    } catch (_) {
      if (!mounted || !showSnack) return;
      showArinTopToast(context, l10n.settingsContactCopyFailed);
    }
  }

  Future<void> _copyWithFailureFallback(AppLocalizations l10n) async {
    try {
      await _copyEmail(l10n, showSnack: false);
      if (!mounted) return;
      showArinTopToast(context, l10n.settingsContactOpenFailed);
    } catch (_) {
      if (!mounted) return;
      showArinTopToast(context, l10n.settingsContactCopyFailed);
    }
  }

  Future<void> _openMail(AppLocalizations l10n) async {
    if (_mailOpening) return;
    setState(() => _mailOpening = true);
    unawaited(ArinAnalytics.log('contact_mail_tap'));
    try {
      final ok = await launchUrl(
        await _buildMailUri(l10n),
        mode: LaunchMode.externalApplication,
      );
      if (ok) return;
      await _copyWithFailureFallback(l10n);
    } catch (_) {
      await _copyWithFailureFallback(l10n);
    } finally {
      if (mounted) {
        setState(() => _mailOpening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;
    final bodyColor =
        onDark ? Colors.white.withValues(alpha: 0.82) : AppColors.textPrimary;
    final cardBg = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.56)
        : Colors.white.withValues(alpha: 0.75);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.creamDark.withValues(alpha: 0.54);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: onDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor.withValues(alpha: 0.9),
                  ),
                ),
                title: Text(
                  l10n.settingsContactPageTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.settingsContactSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 1.45,
                              color: bodyColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SelectableText(
                            _supportEmail,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _mailOpening ? null : () => _openMail(l10n),
                            icon: _mailOpening
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: ArinLoader(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.email_outlined),
                            label: Text(l10n.settingsContactOpenMailAction),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _copyEmail(l10n),
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(l10n.settingsContactCopyMailAction),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
