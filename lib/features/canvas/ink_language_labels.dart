import 'package:flutter/widgets.dart';

import 'package:character_lens/domain/entities/ink_language.dart';

extension InkLanguageLabels on InkLanguage {
  String get name => switch (this) {
    InkLanguage.chinese => 'Chinese',
    InkLanguage.japanese => 'Japanese',
  };

  String get glyph => switch (this) {
    InkLanguage.chinese => '中',
    InkLanguage.japanese => '日',
  };

  Locale get locale => switch (this) {
    InkLanguage.chinese => const Locale('zh', 'Hans'),
    InkLanguage.japanese => const Locale('ja'),
  };
}
