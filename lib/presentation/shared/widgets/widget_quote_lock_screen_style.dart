// Kilit ekranı / widget sözü için premium tipografi (Google Fonts).
// Sistem home widget'ı native; bu bileşen uygulama içi önizleme ve tutarlı stil için.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Yumuşak, okunabilir gölge (sert siyah offset yerine).
List<Shadow> get widgetQuoteSoftShadows => <Shadow>[
  Shadow(
    color: Colors.black.withValues(alpha: 0.22),
    blurRadius: 14,
    offset: const Offset(0, 2),
  ),
  Shadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 22,
    offset: const Offset(0, 4),
  ),
];

/// Kaynak satırı: Montserrat (modern sans).
TextStyle widgetQuoteSourceStyle({required Color color, double fontSize = 15}) {
  return GoogleFonts.montserrat(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
    color: color,
    height: 1.2,
    shadows: widgetQuoteSoftShadows,
  );
}

/// Gövde: Playfair Display (premium serif).
TextStyle widgetQuoteBodyStyle({required Color color, double fontSize = 23}) {
  return GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    height: 1.38,
    color: color,
    letterSpacing: 0.15,
    shadows: widgetQuoteSoftShadows,
  );
}

/// Genişliği ~%80 ile sınırlı, ortalanmış, kenarlardan padding’li söz bloğu.
class WidgetQuoteLockScreenTextBlock extends StatelessWidget {
  const WidgetQuoteLockScreenTextBlock({
    super.key,
    required this.source,
    required this.body,
    this.foregroundColor = Colors.white,
    this.widthFactor = 0.8,
    this.horizontalPadding = 24,
    this.verticalPadding = 22,
  });

  final String source;
  final String body;
  final Color foregroundColor;
  final double widthFactor;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final hasSource = source.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = (constraints.maxWidth * widthFactor).clamp(0.0, 560.0);
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasSource) ...[
                    Text(
                      source,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 3,
                      style: widgetQuoteSourceStyle(color: foregroundColor),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: widgetQuoteBodyStyle(
                      color: foregroundColor,
                      fontSize: 23,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String? _widgetQuotePickField(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

/// Admin: widget_quote havuzundaki ilk öğeyle kilit ekranına yakın önizleme.
class WidgetQuoteLockScreenPreviewCard extends StatelessWidget {
  const WidgetQuoteLockScreenPreviewCard({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  static const _defaultSource = '';
  static const _defaultBody = 'İşitirim ve görürüm.';

  @override
  Widget build(BuildContext context) {
    var source = _defaultSource;
    var body = _defaultBody;
    if (items.isNotEmpty) {
      final m = items.first;
      source =
          _widgetQuotePickField(m, const [
            'source',
            'title',
            'reference',
            'ref',
            'surah',
          ]) ??
          _defaultSource;
      body =
          _widgetQuotePickField(m, const ['text', 'turkish', 'body']) ??
          _defaultBody;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF1E3A5F),
              const Color(0xFF2A1F0A).withValues(alpha: 0.92),
              const Color(0xFFC9A227).withValues(alpha: 0.75),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: WidgetQuoteLockScreenTextBlock(source: source, body: body),
      ),
    );
  }
}
