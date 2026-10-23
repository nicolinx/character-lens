enum InkLanguage {
  chinese('zh-Hani'),
  japanese('ja');

  const InkLanguage(this.languageTag);

  /// ML Kit Digital Ink model identifier for this language.
  final String languageTag;
}
