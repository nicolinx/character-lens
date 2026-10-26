import '../../domain/entities/ink_language.dart';

extension InkLanguageLabels on InkLanguage {
  String get name => switch (this) {
    InkLanguage.chinese => 'Chinese',
    InkLanguage.japanese => 'Japanese',
  };

  /// One glyph in the language's own script, as shown on the selector.
  String get glyph => switch (this) {
    InkLanguage.chinese => '中',
    InkLanguage.japanese => '日',
  };
}
