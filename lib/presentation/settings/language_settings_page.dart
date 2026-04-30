import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/quote_pool_ids.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/arin_widget_sync.dart';
import '../../data/services/location_service.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/quotes_providers.dart';

class LanguageSettingsPage extends ConsumerStatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  ConsumerState<LanguageSettingsPage> createState() =>
      _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends ConsumerState<LanguageSettingsPage> {
  String? _switchingCode;

  String _languageLabelForLocale(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageEnglishLabel;
      case 'ar':
        return l10n.languageArabicLabel;
      default:
        return l10n.languageTurkishLabel;
    }
  }

  String _languageNativeLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Türkçe';
    }
  }

  Future<void> _setLocale(Locale locale) async {
    if (_switchingCode != null) return;
    final current = ref.read(appLocaleProvider);
    if (current.languageCode == locale.languageCode) return;

    setState(() => _switchingCode = locale.languageCode);
    try {
      await ref.read(appLocaleProvider.notifier).setLocale(locale);

      try {
        final pools = ref.read(quotePoolsRepositoryProvider);
        await pools.ensureSyncedToday(QuotePoolIds.widgetQuote);
        ref.read(prayerTimesProvider).whenData((model) {
          unawaited(
            ArinWidgetSync.refreshPrayer(
              model: model,
              location: ref.read(locationServiceProvider),
              localeCode: locale.languageCode,
            ),
          );
        });
      } catch (e) {
        debugPrint('Language switch widget refresh skipped: $e');
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final selectedLabel = _languageLabelForLocale(context, locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageChangedMessage(selectedLabel))),
      );
    } catch (e) {
      debugPrint('Language switch failed: $e');
      if (!mounted) return;
      final lang = Localizations.localeOf(context).languageCode;
      final message = switch (lang) {
        'en' => 'Language could not be changed. Please try again.',
        'ar' => 'تعذر تغيير اللغة. يرجى المحاولة مرة أخرى.',
        _ => 'Dil degistirilemedi. Lutfen tekrar dene.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _switchingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(appLocaleProvider);
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;
    final subtitleColor =
        onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;

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
                    ? Colors.black.withValues(alpha: 0.24)
                    : Colors.white.withValues(alpha: 0.54),
                leading: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go(AppRoutes.settings);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.languageSettingsTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      l10n.languageSettingsSheetTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final locale in kSupportedAppLocales) ...[
                      _LanguageOptionTile(
                        title: _languageLabelForLocale(context, locale),
                        subtitle: _languageNativeLabel(locale),
                        selected: current.languageCode == locale.languageCode,
                        loading: _switchingCode == locale.languageCode,
                        onDark: onDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _setLocale(locale);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
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

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.loading,
    required this.onDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool loading;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AppColors.accentNeonGreen.withValues(alpha: 0.52)
        : (onDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.creamDark.withValues(alpha: 0.5));
    final fill = selected
        ? (onDark
            ? AppColors.accentNeonGreen.withValues(alpha: 0.12)
            : AppColors.emeraldFaint.withValues(alpha: 0.58))
        : (onDark
            ? AppColors.cardSurface.withValues(alpha: 0.44)
            : Colors.white.withValues(alpha: 0.67));
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subtitleColor =
        onDark ? AppColors.textOnDarkMuted : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: fill,
            border: Border.all(color: border, width: selected ? 1.25 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.accentNeonGreen.withValues(alpha: 0.2)
                      : (onDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.emeraldDark.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 22,
                  color: selected
                      ? AppColors.accentNeonGreen
                      : (onDark ? Colors.white70 : AppColors.emeraldDark),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: titleColor.withValues(alpha: 0.65),
                  ),
                )
              else if (selected)
                Icon(
                  Icons.check_rounded,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: subtitleColor.withValues(alpha: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
