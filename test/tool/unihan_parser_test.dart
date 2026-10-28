import 'package:flutter_test/flutter_test.dart';

import '../../tool/unihan_parser.dart';

void main() {
  group('parseHeader', () {
    test('reads the Unicode version and the file date', () {
      final header = parseHeader([
        '# Unihan_Readings.txt',
        '# Date: 2026-07-31 00:00:00 GMT [KL]',
        '# Unicode Version 18.0.0',
        'U+3400\tkCantonese\tjau1',
      ]);

      expect(header.version, '18.0.0');
      expect(header.date, '2026-07-31');
    });

    test('is null for a missing line, and stops at the first data line', () {
      final header = parseHeader([
        '# Unihan_Readings.txt',
        'U+3400\tkCantonese\tjau1',
        '# Unicode Version 99.0.0',
      ]);

      expect(header.version, isNull);
      expect(header.date, isNull);
    });
  });

  group('parseUnihanLines', () {
    test('collects the wanted fields by code point', () {
      final into = <int, Map<String, String>>{};

      parseUnihanLines([
        '# a comment line',
        '',
        'U+6728\tkMandarin\tmù',
        'U+6728\tkDefinition\ttree; wood, lumber; wooden',
        'U+6C34\tkMandarin\tshuǐ',
      ], into);

      expect(into, {
        0x6728: {
          'kMandarin': 'mù',
          'kDefinition': 'tree; wood, lumber; wooden',
        },
        0x6C34: {'kMandarin': 'shuǐ'},
      });
    });

    test('ignores fields the dictionary does not use', () {
      final into = <int, Map<String, String>>{};

      parseUnihanLines(['U+6728\tkCantonese\tmuk6'], into);

      expect(into, isEmpty);
    });

    test('reads code points above the BMP', () {
      final into = <int, Map<String, String>>{};

      parseUnihanLines(['U+20000\tkMandarin\thē'], into);

      expect(into.keys, [0x20000]);
    });

    test('adds to what earlier files already collected', () {
      final into = <int, Map<String, String>>{
        0x8A9E: {'kMandarin': 'yǔ'},
      };

      parseUnihanLines(['U+8A9E\tkSimplifiedVariant\tU+8BED'], into);

      expect(into[0x8A9E], {'kMandarin': 'yǔ', 'kSimplifiedVariant': 'U+8BED'});
    });

    test('skips a malformed line instead of failing', () {
      final into = <int, Map<String, String>>{};

      parseUnihanLines([
        'U+6728 kMandarin mù',
        'not a code point\tkMandarin\tmù',
        'U+6728\tkMandarin\tmù',
      ], into);

      expect(into, {
        0x6728: {'kMandarin': 'mù'},
      });
    });
  });

  group('splitValues', () {
    test('splits on spaces', () {
      expect(splitValues('BOKU MOKU'), ['BOKU', 'MOKU']);
    });

    test('keeps a single value as one item', () {
      expect(splitValues('mù'), ['mù']);
    });

    test('drops empty items from repeated spaces', () {
      expect(splitValues('gèng  gēng'), ['gèng', 'gēng']);
    });
  });

  group('parseHangul', () {
    test('strips the source code after the colon', () {
      expect(parseHangul('목:0E'), ['목']);
    });

    test('keeps several syllables in order', () {
      expect(parseHangul('온:N 은:N'), ['온', '은']);
    });

    test('keeps a syllable once when it repeats with different sources', () {
      expect(parseHangul('가:0E 가:N'), ['가']);
    });

    test('keeps a value that has no source code', () {
      expect(parseHangul('목'), ['목']);
    });
  });

  group('parseVariants', () {
    test('turns a code point into its character', () {
      expect(parseVariants('U+8BED'), ['语']);
    });

    test('keeps several values in the order Unihan lists them', () {
      expect(parseVariants('U+6C14 U+6C23'), ['气', '氣']);
    });

    test('strips a source suffix', () {
      expect(parseVariants('U+6C35<kMatthews'), ['氵']);
    });

    test('strips a source suffix with several sources', () {
      expect(parseVariants('U+6C35<kMatthews,kMeyerWempe U+6C34'), ['氵', '水']);
    });

    test('reads a code point above the BMP', () {
      expect(parseVariants('U+2BAC7'), [String.fromCharCode(0x2BAC7)]);
    });

    test('skips a value that is not a code point', () {
      expect(parseVariants('U+8BED oops'), ['语']);
    });
  });

  group('parseStrokes', () {
    test('reads the count', () {
      expect(parseStrokes('14'), 14);
    });

    test('takes the first when several are listed', () {
      expect(parseStrokes('9 10'), 9);
    });

    test('is null for text that is not a number', () {
      expect(parseStrokes('many'), isNull);
    });
  });

  group('toRow', () {
    test('maps every field of a full entry', () {
      final row = toRow(0x8A9E, {
        'kDefinition': 'language, words; saying, expression',
        'kMandarin': 'yǔ',
        'kJapaneseOn': 'GO GYO',
        'kJapaneseKun': 'KATARU KOTOBA TSUGERU',
        'kJapanese': 'ゴ ギョ かたる かたらう ことば つげる',
        'kHangul': '어:0E',
        'kSimplifiedVariant': 'U+8BED',
        'kTotalStrokes': '14',
      })!;

      expect(row.codepoint, 0x8A9E);
      expect(row.character, '語');
      expect(row.definition, 'language, words; saying, expression');
      expect(row.mandarin, ['yǔ']);
      expect(row.japaneseOn, ['GO', 'GYO']);
      expect(row.japaneseKun, ['KATARU', 'KOTOBA', 'TSUGERU']);
      expect(row.japaneseKana, ['ゴ', 'ギョ', 'かたる', 'かたらう', 'ことば', 'つげる']);
      expect(row.hangul, ['어']);
      expect(row.simplified, ['语']);
      expect(row.traditional, isEmpty);
      expect(row.strokes, 14);
    });

    test('leaves a missing field empty or null', () {
      final row = toRow(0x8BED, {
        'kTraditionalVariant': 'U+8A9E',
        'kMandarin': 'yǔ',
      })!;

      expect(row.definition, isNull);
      expect(row.japaneseOn, isEmpty);
      expect(row.hangul, isEmpty);
      expect(row.strokes, isNull);
      expect(row.traditional, ['語']);
    });

    test('keeps a character that has a definition and no reading', () {
      final row = toRow(0x4E02, {'kDefinition': 'obstruction of breath'});

      expect(row, isNotNull);
    });

    test('keeps a character that has a reading and no definition', () {
      final row = toRow(0x4E02, {'kHangul': '고:N'});

      expect(row, isNotNull);
    });

    test('drops a character that has only a stroke count', () {
      expect(toRow(0x20002, {'kTotalStrokes': '2'}), isNull);
    });

    test('drops a character that has only variants', () {
      expect(toRow(0x6C14, {'kTraditionalVariant': 'U+6C23'}), isNull);
    });

    test('drops a character whose definition is blank', () {
      expect(toRow(0x4E02, {'kDefinition': '  '}), isNull);
    });
  });
}
