import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import 'assistant_context_builder.dart';
import 'assistant_page.dart';
import 'assistant_prayer_countdown.dart';

/// CarPlay native katmanı Gemini'ye bu kanaldan sorar. Telefon asistanı yazı kalır.
abstract final class CarPlayAssistantHost {
  static const _channel = MethodChannel('com.arin.arin/carplay');
  static const _maxUserChars = 100;

  static void bind(WidgetRef ref) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'ask') return null;
      final raw = call.arguments is String ? call.arguments as String : '';
      return _answer(ref, raw);
    });
  }

  static Future<String> _answer(WidgetRef ref, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return '';
    if (ref.read(premiumAccessStateProvider) != PremiumAccessState.premium) {
      return 'Arabada Hilal Premium içindir.';
    }
    final clipped = text.characters.take(_maxUserChars).toString();
    final locale = ref.read(appLocaleProvider).languageCode;
    final l10n = lookupAppLocalizations(Locale(locale));

    final prayerTarget = matchAssistantPrayerTarget(clipped);
    if (prayerTarget != null) {
      return formatPrayerCountdownReply(
            l10n: l10n,
            times: ref.read(prayerTimesProvider).asData?.value,
            now: DateTime.now(),
            target: prayerTarget,
          ) ??
          l10n.assistantPrayerTimesMissing;
    }

    try {
      final result = await ref.read(assistantRepositoryProvider).send(
            message: clipped,
            history: const [],
            context: buildAssistantContext(ref: ref, locale: locale),
          );
      return result.reply.trim();
    } catch (_) {
      return l10n.userGenericError;
    }
  }
}
