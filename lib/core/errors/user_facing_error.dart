import 'package:arin/l10n/app_localizations.dart';

/// Kullanıcıya giden varsayılan hata. Ham exception, kod veya sunucu metni
/// buraya asla eklenmez.
const kUserGenericErrorFallback = 'Bir şeyler ters gitti. Lütfen tekrar dene.';

/// Beklenmeyen hatalarda yalnızca genel, güvenli metin döner.
String userFacingErrorMessage([AppLocalizations? l10n]) {
  return l10n?.userGenericError ?? kUserGenericErrorFallback;
}
