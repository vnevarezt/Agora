import 'package:web/web.dart' as web;

/// Writes `<html lang>` so the page declares the language it is actually
/// showing. The shell ships with the base locale hard-coded, which is right
/// until somebody switches the app to English and the document keeps claiming
/// Spanish — WCAG 3.1.1 is about what the page says it is, not what it was
/// built as.
void setDocumentLang(String languageTag) {
  web.document.documentElement?.setAttribute('lang', languageTag);
}
