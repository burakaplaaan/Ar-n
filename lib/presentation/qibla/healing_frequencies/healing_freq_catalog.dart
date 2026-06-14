// Frekans meta verisi — başlık ve kısa açıklamalar (UI + seçim listesi).

import 'package:flutter/widgets.dart';

import 'package:arin/l10n/app_localizations.dart';

/// Hub kartında gösterilen kısa rol etiketi (büyük daire altı).
abstract final class HealingFreqCatalog {
  static const List<int> orderedHz = <int>[
    174,
    285,
    396,
    417,
    528,
    639,
    741,
    852,
  ];

  static String toneAssetPath(int hz) =>
      'sounds/healing/tones/tone_${hz}hz.wav';

  static String shortTitle(BuildContext context, int hz) {
    final l10n = AppLocalizations.of(context)!;
    switch (hz) {
      case 174:
        return l10n.healingFreq174Short;
      case 285:
        return l10n.healingFreq285Short;
      case 396:
        return l10n.healingFreq396Short;
      case 417:
        return l10n.healingFreq417Short;
      case 528:
        return l10n.healingFreq528Short;
      case 639:
        return l10n.healingFreq639Short;
      case 741:
        return l10n.healingFreq741Short;
      case 852:
        return l10n.healingFreq852Short;
      default:
        return '$hz Hz';
    }
  }

  /// “Tüm Frekanslar” yatay liste altı — başlıktaki “Hz - ” sonrası tam metin.
  static String listCaption(BuildContext context, int hz) {
    final full = heading(context, hz);
    const sep = ' - ';
    final i = full.indexOf(sep);
    if (i >= 0) {
      return full.substring(i + sep.length);
    }
    return shortTitle(context, hz);
  }

  static String heading(BuildContext context, int hz) {
    final l10n = AppLocalizations.of(context)!;
    switch (hz) {
      case 174:
        return l10n.healingFreq174Heading;
      case 285:
        return l10n.healingFreq285Heading;
      case 396:
        return l10n.healingFreq396Heading;
      case 417:
        return l10n.healingFreq417Heading;
      case 528:
        return l10n.healingFreq528Heading;
      case 639:
        return l10n.healingFreq639Heading;
      case 741:
        return l10n.healingFreq741Heading;
      case 852:
        return l10n.healingFreq852Heading;
      default:
        return '$hz Hz';
    }
  }

  static String body(BuildContext context, int hz) {
    final l10n = AppLocalizations.of(context)!;
    switch (hz) {
      case 174:
        return l10n.healingFreq174Body;
      case 285:
        return l10n.healingFreq285Body;
      case 396:
        return l10n.healingFreq396Body;
      case 417:
        return l10n.healingFreq417Body;
      case 528:
        return l10n.healingFreq528Body;
      case 639:
        return l10n.healingFreq639Body;
      case 741:
        return l10n.healingFreq741Body;
      case 852:
        return l10n.healingFreq852Body;
      default:
        return '';
    }
  }

}
