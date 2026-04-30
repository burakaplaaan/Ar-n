import 'package:flutter/widgets.dart';

String trEnAr(
  BuildContext context, {
  required String tr,
  required String en,
  required String ar,
}) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return trEnArByCode(code, tr: tr, en: en, ar: ar);
}

String trEnArByCode(
  String? localeCode, {
  required String tr,
  required String en,
  required String ar,
}) {
  final code = (localeCode ?? 'tr').toLowerCase();
  if (code.startsWith('ar')) return ar;
  if (code.startsWith('en')) return en;
  return tr;
}
