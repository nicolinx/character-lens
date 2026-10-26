import 'package:flutter/widgets.dart';

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

  /// Picks the right regional shape of Han glyphs.
  Locale get locale => switch (this) {
    InkLanguage.chinese => const Locale('zh', 'Hans'),
    InkLanguage.japanese => const Locale('ja'),
  };
}
