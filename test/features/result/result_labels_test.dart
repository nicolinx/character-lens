import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/features/result/result_labels.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HanLanguage labels', () {
    test('short codes', () {
      expect(HanLanguage.values.map((l) => l.code), ['CN', 'JP', 'KO']);
    });

    test('names, as in the prototype', () {
      expect(HanLanguage.values.map((l) => l.name), [
        'Chinese',
        'Japanese',
        'Korean (Hanja)',
      ]);
    });

    test('reading labels', () {
      expect(HanLanguage.values.map((l) => l.readingLabel), [
        'Pinyin',
        'On · Kun',
        'Hangul',
      ]);
    });

    test('locales pick the regional glyph shapes', () {
      expect(HanLanguage.chinese.locale, const Locale('zh', 'Hans'));
      expect(HanLanguage.japanese.locale, const Locale('ja'));
      expect(HanLanguage.korean.locale, const Locale('ko'));
    });
  });

  group('readingText', () {
    test('joins several readings with commas', () {
      expect(
        readingText(const LanguageReading(readings: ['gèng', 'gēng'])),
        'gèng, gēng',
      );
    });

    test('puts Japanese kun after on, separated by a dot', () {
      expect(
        readingText(
          const LanguageReading(readings: ['BOKU', 'MOKU'], kun: ['KI']),
        ),
        'BOKU, MOKU · KI',
      );
    });

    test('shows kun alone when there is no on', () {
      expect(readingText(const LanguageReading(kun: ['KI'])), 'KI');
    });

    test('is empty when there is no reading', () {
      expect(readingText(const LanguageReading()), '');
    });
  });

  group('variantText', () {
    test('traditional', () {
      expect(
        variantText(const FormVariant(VariantKind.traditional, '學')),
        'Traditional 學',
      );
    });

    test('simplified', () {
      expect(
        variantText(const FormVariant(VariantKind.simplified, '语')),
        'Simplified 语',
      );
    });
  });
}
