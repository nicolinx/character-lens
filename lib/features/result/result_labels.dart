import 'package:flutter/widgets.dart';

import 'package:character_lens/domain/entities/character_view.dart';
import 'package:character_lens/domain/entities/han_language.dart';

extension HanLanguageLabels on HanLanguage {
  /// Short code, as on the "Across languages" items.
  String get code => switch (this) {
    HanLanguage.chinese => 'CN',
    HanLanguage.japanese => 'JP',
    HanLanguage.korean => 'KO',
  };

  String get name => switch (this) {
    HanLanguage.chinese => 'Chinese',
    HanLanguage.japanese => 'Japanese',
    HanLanguage.korean => 'Korean (Hanja)',
  };

  /// What the reading row is called for this language.
  String get readingLabel => switch (this) {
    HanLanguage.chinese => 'Pinyin',
    HanLanguage.japanese => 'On · Kun',
    HanLanguage.korean => 'Hangul',
  };

  /// Picks the right regional shape of Han glyphs.
  Locale get locale => switch (this) {
    HanLanguage.chinese => const Locale('zh', 'Hans'),
    HanLanguage.japanese => const Locale('ja'),
    HanLanguage.korean => const Locale('ko'),
  };
}

/// The readings as one line: on, then kun. Empty when there are none.
String readingText(LanguageReading reading) => [
  reading.readings.join(', '),
  reading.kun.join(', '),
].where((part) => part.isNotEmpty).join(' · ');

String variantText(FormVariant variant) => switch (variant.kind) {
  VariantKind.traditional => 'Traditional ${variant.character}',
  VariantKind.simplified => 'Simplified ${variant.character}',
};
