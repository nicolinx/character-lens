import 'package:character_lens/domain/entities/character_view.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/failures/dictionary_failure.dart';
import 'package:character_lens/domain/usecases/resolve_character.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/sample_entries.dart';

const cn = HanLanguage.chinese;
const jp = HanLanguage.japanese;
const ko = HanLanguage.korean;

FakeDictionary _dictionary() => FakeDictionary([
  SampleEntries.mu,
  SampleEntries.go,
  SampleEntries.goSimplified,
  SampleEntries.gaku,
  SampleEntries.gakuTraditional,
  SampleEntries.kiJapanese,
  SampleEntries.kiSimplified,
  SampleEntries.kiTraditional,
]);

void main() {
  late FakeDictionary dictionary;
  late ResolveCharacter resolve;

  setUp(() {
    dictionary = _dictionary();
    resolve = ResolveCharacter(dictionary);
  });

  group('a character with no variants', () {
    test(
      'shows the same form and its own readings in every language',
      () async {
        final view = await resolve(SampleEntries.mu, jp);

        expect(view.forms, {cn: '木', jp: '木', ko: '木'});
        expect(view.readings[cn]!.readings, ['mù']);
        expect(view.readings[jp]!.readings, ['BOKU', 'MOKU']);
        expect(view.readings[jp]!.kun, ['KI']);
        expect(view.readings[ko]!.readings, ['목']);
        expect(view.variantNote, isNull);
      },
    );

    test('asks the dictionary for nothing', () async {
      await resolve(SampleEntries.mu, cn);

      expect(dictionary.lookups, isEmpty);
    });
  });

  group('語, traditional with a simplified variant', () {
    test('shows 语 for Chinese and 語 for Japanese and Korean', () async {
      final view = await resolve(SampleEntries.go, jp);

      expect(view.forms, {cn: '语', jp: '語', ko: '語'});
      expect(view.form, '語');
    });

    test('uses its own readings and borrows nothing', () async {
      final view = await resolve(SampleEntries.go, jp);

      for (final language in HanLanguage.values) {
        expect(view.readings[language]!.borrowedFrom, isNull);
        expect(view.readings[language]!.isEmpty, isFalse);
      }
      expect(dictionary.lookups, isEmpty);
    });

    test('notes the simplified form when Japanese is selected', () async {
      final view = await resolve(SampleEntries.go, jp);

      expect(view.variantNote, const FormVariant(VariantKind.simplified, '语'));
    });

    test('notes the traditional form when Chinese is selected', () async {
      final view = await resolve(SampleEntries.go, cn);

      expect(view.form, '语');
      expect(view.variantNote, const FormVariant(VariantKind.traditional, '語'));
    });
  });

  group('语, simplified with no Japanese or Korean readings', () {
    test('borrows those readings from 語 and says so', () async {
      final view = await resolve(SampleEntries.goSimplified, cn);

      expect(view.readings[jp]!.readings, ['GO', 'GYO']);
      expect(view.readings[jp]!.kun, ['KATARU', 'KOTOBA', 'TSUGERU']);
      expect(view.readings[jp]!.borrowedFrom, '語');
      expect(view.readings[ko]!.readings, ['어']);
      expect(view.readings[ko]!.borrowedFrom, '語');
    });

    test('keeps its own Chinese reading, not borrowed', () async {
      final view = await resolve(SampleEntries.goSimplified, cn);

      expect(view.readings[cn]!.readings, ['yǔ']);
      expect(view.readings[cn]!.borrowedFrom, isNull);
    });

    test('shows 语 for Chinese and 語 for Japanese and Korean', () async {
      final view = await resolve(SampleEntries.goSimplified, cn);

      expect(view.forms, {cn: '语', jp: '語', ko: '語'});
      expect(view.variantNote, const FormVariant(VariantKind.traditional, '語'));
    });

    test('looks the variant up once for both borrowing languages', () async {
      await resolve(SampleEntries.goSimplified, cn);

      expect(dictionary.lookups, ['語']);
    });
  });

  group('学, simplified in China and used in Japan', () {
    test('keeps 学 for Chinese and Japanese and shows 學 for Korean', () async {
      final view = await resolve(SampleEntries.gaku, cn);

      expect(view.forms, {cn: '学', jp: '学', ko: '學'});
    });

    test(
      'has its own readings in every language, so borrows nothing',
      () async {
        final view = await resolve(SampleEntries.gaku, jp);

        expect(view.readings[ko]!.readings, ['학']);
        expect(
          view.readings.values.map((r) => r.borrowedFrom),
          everyElement(isNull),
        );
        expect(dictionary.lookups, isEmpty);
      },
    );

    test('notes the traditional form for Chinese and for Japanese', () async {
      const expected = FormVariant(VariantKind.traditional, '學');

      expect((await resolve(SampleEntries.gaku, cn)).variantNote, expected);
      expect((await resolve(SampleEntries.gaku, jp)).variantNote, expected);
    });
  });

  group('學, the traditional form drawn directly', () {
    test('shows 学 for Chinese, and 學 for Japanese (a known limit)', () async {
      // Unihan gives 學 its own Japanese readings, so it is not replaced by 学.
      final view = await resolve(SampleEntries.gakuTraditional, ko);

      expect(view.forms, {cn: '学', jp: '學', ko: '學'});
    });

    test('notes the simplified form when Korean is selected', () async {
      final view = await resolve(SampleEntries.gakuTraditional, ko);

      expect(view.variantNote, const FormVariant(VariantKind.simplified, '学'));
    });
  });

  group('気, a Japanese form with no variant links', () {
    test('shows only its own readings and does not look anything up', () async {
      final view = await resolve(SampleEntries.kiJapanese, jp);

      expect(view.forms, {cn: '気', jp: '気', ko: '気'});
      expect(view.readings[jp]!.readings, ['KI', 'KE']);
      expect(view.variantNote, isNull);
      expect(dictionary.lookups, isEmpty);
    });

    test('has an empty Korean row, not a borrowed or invented one', () async {
      final view = await resolve(SampleEntries.kiJapanese, jp);

      expect(view.readings[ko]!.isEmpty, isTrue);
      expect(view.readings[ko]!.borrowedFrom, isNull);
    });
  });

  group('气, with a one-to-many traditional variant', () {
    test(
      'skips itself and takes the first other variant as Korean form',
      () async {
        final view = await resolve(SampleEntries.kiSimplified, cn);

        expect(view.forms, {cn: '气', jp: '气', ko: '氣'});
      },
    );

    test('borrows the Korean reading from 氣, never from itself', () async {
      final view = await resolve(SampleEntries.kiSimplified, cn);

      expect(view.readings[ko]!.readings, ['기']);
      expect(view.readings[ko]!.borrowedFrom, '氣');
      expect(dictionary.lookups, ['氣']);
    });
  });

  group('missing data', () {
    test('a character with no definition keeps a null definition', () async {
      final view = await resolve(SampleEntries.noDefinition, cn);

      expect(view.entry.definition, isNull);
      expect(view.readings[cn]!.readings, ['kǎo']);
    });

    test(
      'a character with no readings gives empty rows and no crash',
      () async {
        final view = await resolve(SampleEntries.bare, cn);

        expect(view.forms, {cn: '〇', jp: '〇', ko: '〇'});
        for (final language in HanLanguage.values) {
          expect(view.readings[language]!.isEmpty, isTrue);
        }
        expect(view.variantNote, isNull);
      },
    );

    test(
      'a variant missing from the dictionary leaves the row empty',
      () async {
        final view = await ResolveCharacter(FakeDictionary([]))(
          SampleEntries.goSimplified,
          cn,
        );

        expect(view.readings[jp]!.isEmpty, isTrue);
        expect(view.readings[jp]!.borrowedFrom, isNull);
      },
    );
  });

  test('a dictionary failure reaches the caller', () async {
    dictionary.error = const DictionaryUnavailableFailure();

    await expectLater(
      resolve(SampleEntries.goSimplified, cn),
      throwsA(isA<DictionaryUnavailableFailure>()),
    );
  });
}
