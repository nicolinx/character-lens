import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/failures/dictionary_failure.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/domain/usecases/recognize_characters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_ink_recognizer.dart';

const _area = WritingArea(width: 300, height: 400);

List<Candidate> _of(List<String> characters) => [
  for (final c in characters) Candidate(character: c),
];

void main() {
  late FakeInkRecognizer recognizer;

  setUp(() => recognizer = FakeInkRecognizer());

  RecognizeCharacters useCase(FakeDictionary dictionary) =>
      RecognizeCharacters(recognizer, dictionary);

  Future<List<String>> run(FakeDictionary dictionary, List<String> raw) async {
    recognizer.candidates = _of(raw);
    final result = await useCase(dictionary)(
      [],
      InkLanguage.chinese,
      writingArea: _area,
    );
    return [for (final c in result) c.character];
  }

  group('filtering', () {
    test(
      'keeps single characters that are in the dictionary, in order',
      () async {
        // Recognition of 木 on a device: the real answer, then noise.
        final kept = await run(FakeDictionary.bare('木本小'), [
          '木',
          '十木',
          '才木',
          '大木',
          '+木',
          '本',
          '木木',
          '小',
          't木',
          '一木',
        ]);

        expect(kept, ['木', '本', '小']);
      },
    );

    test('removes strings of more than one character', () async {
      final kept = await run(FakeDictionary.bare('言二語'), ['言二', '言', '語']);

      expect(kept, ['言', '語']);
    });

    test('removes symbols, digits and letters', () async {
      final kept = await run(FakeDictionary.bare('口'), [
        '7',
        '〉',
        ',',
        't',
        'D',
        '口',
      ]);

      expect(kept, ['口']);
    });

    test('removes characters that are not in the dictionary', () async {
      final kept = await run(FakeDictionary.bare('三二'), ['三', 'ミ', 'シ', '二']);

      expect(kept, ['三', '二']);
    });

    test(
      'keeps a character above the BMP, which is two UTF-16 units',
      () async {
        final rare = String.fromCharCode(0x20000);

        final kept = await run(FakeDictionary.bare(rare), [rare]);

        expect(kept, [rare]);
      },
    );

    test('does not ask the dictionary about multi-character strings', () async {
      final dictionary = FakeDictionary.bare('木');

      await run(dictionary, ['十木', '木木', '木']);

      expect(dictionary.checks, ['木']);
    });

    test('hands back the candidates it received, scores untouched', () async {
      recognizer.candidates = const [Candidate(character: '木', score: 0.5)];

      final result = await useCase(FakeDictionary.bare('木'))(
        [],
        InkLanguage.chinese,
        writingArea: _area,
      );

      expect(result, const [Candidate(character: '木', score: 0.5)]);
    });
  });

  group('the cap of 5', () {
    test('keeps at most 5, in order', () async {
      final kept = await run(FakeDictionary.bare('一二三四五六七'), [
        '一',
        '二',
        '三',
        '四',
        '五',
        '六',
        '七',
      ]);

      expect(kept, ['一', '二', '三', '四', '五']);
    });

    test('counts only the characters that survived', () async {
      // The raw top 5 holds a single real character. The cap applies after
      // the filter, so the later ones are not lost.
      final kept = await run(FakeDictionary.bare('木本小'), [
        '十木',
        '才木',
        '大木',
        '+木',
        '木',
        '本',
        '小',
      ]);

      expect(kept, ['木', '本', '小']);
    });

    test('fewer than 5 survivors is fine', () async {
      final kept = await run(FakeDictionary.bare('三二'), ['三', 'ミ', '二']);

      expect(kept, hasLength(2));
    });

    test('stops asking the dictionary once it has 5', () async {
      final dictionary = FakeDictionary.bare('一二三四五六七八');

      await run(dictionary, ['一', '二', '三', '四', '五', '六', '七', '八']);

      expect(dictionary.checks, ['一', '二', '三', '四', '五']);
    });
  });

  group('nothing usable', () {
    test(
      'returns an empty list when every candidate is filtered out',
      () async {
        final kept = await run(FakeDictionary.bare('木'), ['十木', '+', 'ミ']);

        expect(kept, isEmpty);
      },
    );

    test('returns an empty list when the recognizer found nothing', () async {
      final dictionary = FakeDictionary.bare('木');

      final kept = await run(dictionary, []);

      expect(kept, isEmpty);
      expect(dictionary.checks, isEmpty);
    });
  });

  group('delegation', () {
    test('passes the writing area to the recognizer', () async {
      await run(FakeDictionary.bare('木'), ['木']);

      expect(recognizer.areas, [_area]);
    });

    test('lets an InkFailure from the recognizer through', () async {
      recognizer.recognizeError = const ModelNotDownloadedFailure(
        InkLanguage.chinese,
      );

      await expectLater(
        useCase(FakeDictionary.bare('木'))(
          [],
          InkLanguage.chinese,
          writingArea: _area,
        ),
        throwsA(isA<ModelNotDownloadedFailure>()),
      );
    });

    test('lets a DictionaryFailure from the dictionary through', () async {
      recognizer.candidates = _of(['木']);
      final dictionary = FakeDictionary.bare('木')
        ..error = const DictionaryUnavailableFailure();

      await expectLater(
        useCase(dictionary)([], InkLanguage.chinese, writingArea: _area),
        throwsA(isA<DictionaryUnavailableFailure>()),
      );
    });
  });
}
