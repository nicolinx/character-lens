import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:character_lens/domain/explainer/explanation_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const _cn = HanLanguage.chinese;
const _jp = HanLanguage.japanese;
const _ko = HanLanguage.korean;

final _mu = CharacterEntry(
  character: '木',
  mandarin: ['mù'],
  japaneseOn: ['BOKU', 'MOKU'],
  japaneseKun: ['KI'],
  hangul: ['목'],
);

ExplanationExample _word(String word, String reading) =>
    ExplanationExample(word: word, reading: reading, meaning: 'meaning');

Explanation _explain(List<ExplanationExample> examples) => Explanation(
  components: const [ExplanationComponent(part: '木', role: 'tree')],
  mnemonic: 'A tree.',
  examples: examples,
);

ReadingCheck _check(
  CharacterEntry entry,
  HanLanguage language,
  String reading,
) {
  final result = ExplanationValidator().validate(
    _explain([_word('木头', reading)]),
    entry,
    language,
  );
  return result.checks.single;
}

void main() {
  const verified = ReadingCheck.verified;
  const unverified = ReadingCheck.unverified;

  group('Chinese', () {
    test(
      'is verified when the word reading contains the dictionary reading',
      () {
        expect(_check(_mu, _cn, 'mùtou'), verified);
        expect(_check(_mu, _cn, 'běnmù'), verified);
      },
    );

    test('ignores case, spaces, hyphens and apostrophes', () {
      expect(_check(_mu, _cn, 'Mù tou'), verified);
      expect(_check(_mu, _cn, 'mù-tou'), verified);
      expect(_check(_mu, _cn, "mù'tou"), verified);
    });

    test('the tone must match', () {
      expect(_check(_mu, _cn, 'mutou'), unverified);
      expect(_check(_mu, _cn, 'mútou'), unverified);
    });

    test('a reading of another character does not verify', () {
      expect(_check(_mu, _cn, 'běn'), unverified);
    });

    test('any of several dictionary readings verifies', () {
      final xing = CharacterEntry(character: '行', mandarin: ['xíng', 'háng']);

      expect(_check(xing, _cn, 'yínháng'), verified);
      expect(_check(xing, _cn, 'xíngli'), verified);
      expect(_check(xing, _cn, 'hàng'), unverified);
    });

    test('an empty reading is unverified', () {
      expect(_check(_mu, _cn, ''), unverified);
      expect(_check(_mu, _cn, ' - '), unverified);
    });

    test('an entry with no Mandarin reading verifies nothing', () {
      final bare = CharacterEntry(character: '语');

      expect(_check(bare, _cn, 'yǔ'), unverified);
    });

    test('a one-letter reading only matches a one-letter word reading', () {
      // Otherwise "é" would verify every word that happens to contain it.
      final goose = CharacterEntry(character: '鹅', mandarin: ['é']);

      expect(_check(goose, _cn, 'é'), verified);
      expect(_check(goose, _cn, 'zhéme'), unverified);
    });

    test('tone marks written as separate combining marks are unverified', () {
      // A known limit: the dictionary uses precomposed letters (ù).
      expect(_check(_mu, _cn, 'mùtou'), unverified);
    });
  });

  group('Japanese', () {
    test('hiragana is verified by an on reading', () {
      expect(_check(_mu, _jp, 'もくようび'), verified);
    });

    test('katakana is accepted too', () {
      expect(_check(_mu, _jp, 'モクヨウビ'), verified);
    });

    test('a kun reading verifies as well', () {
      expect(_check(_mu, _jp, 'きぎ'), verified);
    });

    test('the spelling follows Unihan: じゅう is JUU, しょう is SHOU', () {
      final ten = CharacterEntry(character: '十', japaneseOn: ['JUU', 'JITSU']);
      final small = CharacterEntry(character: '小', japaneseOn: ['SHOU']);

      expect(_check(ten, _jp, 'じゅうがつ'), verified);
      expect(_check(small, _jp, 'しょうがく'), verified);
    });

    test('a reading of another character does not verify', () {
      expect(_check(_mu, _jp, 'ほん'), unverified);
    });

    test('romaji from the model is unverified, not guessed', () {
      expect(_check(_mu, _jp, 'mokuyoubi'), unverified);
    });

    test('a sound change flags a correct reading as unverified', () {
      // A known limit: 学校 is がっこう (GAKKOU), which does not contain GAKU.
      final gaku = CharacterEntry(character: '学', japaneseOn: ['GAKU']);

      expect(_check(gaku, _jp, 'がっこう'), unverified);
    });

    test('a one-letter kun reading does not verify every word with that '
        'vowel', () {
      final small = CharacterEntry(
        character: '小',
        japaneseOn: ['SHOU'],
        japaneseKun: ['KO', 'O', 'CHIISAI'],
      );

      expect(_check(small, _jp, 'おおきい'), unverified);
      expect(_check(small, _jp, 'こいぬ'), verified);
    });

    test('an entry with no Japanese reading verifies nothing', () {
      final bare = CharacterEntry(character: '语', mandarin: ['yǔ']);

      expect(_check(bare, _jp, 'ご'), unverified);
    });

    test('Mandarin readings are not used for Japanese', () {
      final onlyChinese = CharacterEntry(character: '木', mandarin: ['mù']);

      expect(_check(onlyChinese, _jp, 'もく'), unverified);
    });
  });

  group('Korean', () {
    test('is verified when the word contains a Hangul reading', () {
      expect(_check(_mu, _ko, '목요일'), verified);
    });

    test('is unverified for another syllable', () {
      expect(_check(_mu, _ko, '수요일'), unverified);
    });
  });

  group('the whole explanation', () {
    test('has one check for each example, in order', () {
      final result = ExplanationValidator().validate(
        _explain([
          _word('木头', 'mùtou'),
          _word('木头', 'mutou'),
          _word('本木', 'běnmù'),
        ]),
        _mu,
        _cn,
      );

      expect(result.checks, [verified, unverified, verified]);
    });

    test('keeps the explanation as it was, unverified examples included', () {
      final explanation = _explain([_word('木头', 'mutou')]);

      final result = ExplanationValidator().validate(explanation, _mu, _cn);

      expect(result.explanation, explanation);
    });

    test('an explanation with no examples has no checks', () {
      final result = ExplanationValidator().validate(_explain([]), _mu, _cn);

      expect(result.checks, isEmpty);
    });
  });
}
