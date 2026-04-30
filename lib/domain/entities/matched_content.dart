// lib/domain/entities/matched_content.dart
// İçerik eşleştirme algoritmasının döndürdüğü entity.

class MatchedContent {
  final String id;
  final List<String> tags;
  final String? arabic;
  final String text;
  final String source;

  const MatchedContent({
    required this.id,
    required this.tags,
    this.arabic,
    required this.text,
    required this.source,
  });

  factory MatchedContent.fromJson(Map<String, dynamic> json) => MatchedContent(
        id: json['id'] as String,
        tags: (json['tags'] as List).cast<String>(),
        arabic: json['arabic'] as String?,
        text: json['text'] as String,
        source: json['source'] as String,
      );

  bool get hasArabic => arabic != null && arabic!.isNotEmpty;
}
