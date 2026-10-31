import 'package:character_lens/data/ai/explanation_prompt_builder.dart';
import 'package:character_lens/data/ai/prompt_v1.dart';
import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_entries.dart';

void main() {
  final builder = ExplanationPromptBuilder();

  ExplanationPrompt build(CharacterEntry entry, HanLanguage language) =>
      builder.build(entry, language);

  group('the entry in the message', () {
    test('carries the character, the definition and every reading', () {
      final user = build(SampleEntries.go, HanLanguage.japanese).user;

      expect(user, contains('Character: 語'));
      expect(user, contains('Definition: language, words; saying, expression'));
      expect(user, contains('Mandarin: yǔ'));
      expect(user, contains('Japanese on: GO, GYO'));
      expect(user, contains('Japanese kun: KATARU, KOTOBA, TSUGERU'));
      expect(user, contains('Korean (Hangul): 어'));
    });

    test('lists the other written forms but not the character itself', () {
      // Unihan lists 气 among its own variants.
      final user = build(SampleEntries.kiSimplified, HanLanguage.chinese).user;

      expect(user, contains('Other written forms: 氣'));
      expect(user, isNot(contains('气, 氣')));
    });

    test('leaves out a field the entry does not have', () {
      final user = build(
        CharacterEntry(character: '语', mandarin: ['yǔ']),
        HanLanguage.chinese,
      ).user;

      expect(user, contains('Mandarin: yǔ'));
      expect(user, isNot(contains('Definition:')));
      expect(user, isNot(contains('Japanese')));
      expect(user, isNot(contains('Korean')));
      expect(user, isNot(contains('Other written forms')));
    });

    test('lists a form that Unihan gives twice only once', () {
      final user = build(SampleEntries.kiSimplified, HanLanguage.chinese).user;

      expect(
        '氣'.allMatches(user.split('Other written forms:')[1]),
        hasLength(1),
      );
    });

    test('has no drawing data, only dictionary fields', () {
      final user = build(
        SampleEntries.mu,
        HanLanguage.chinese,
      ).user.toLowerCase();

      expect(user, isNot(contains('stroke')));
      expect(user, isNot(contains('ink')));
    });
  });

  group('the language', () {
    test('names the language of the reader', () {
      expect(
        build(SampleEntries.mu, HanLanguage.chinese).user,
        contains('reader of Chinese'),
      );
      expect(
        build(SampleEntries.mu, HanLanguage.japanese).user,
        contains('reader of Japanese'),
      );
    });

    test('asks for pinyin with tone marks in Chinese', () {
      expect(
        build(SampleEntries.mu, HanLanguage.chinese).user,
        contains('pinyin with tone marks'),
      );
    });

    test('asks for hiragana and no romaji in Japanese', () {
      final user = build(SampleEntries.mu, HanLanguage.japanese).user;

      expect(user, contains('hiragana only'));
      expect(user, contains('no romaji'));
    });

    test('asks for Hangul in Korean', () {
      expect(
        build(SampleEntries.mu, HanLanguage.korean).user,
        contains('Hangul'),
      );
    });
  });

  group('the instructions', () {
    final system = build(SampleEntries.mu, HanLanguage.chinese).system;

    test('make the dictionary the source of truth', () {
      expect(system, contains('source of truth'));
      expect(
        system,
        contains('Never give a reading or a definition that differs'),
      );
    });

    test('say a mnemonic is a memory aid and not etymology', () {
      expect(system, contains('not the real history'));
    });

    test('name every field of the schema', () {
      for (final field in [
        'components',
        'mnemonic',
        'examples',
        'usage_note',
      ]) {
        expect(system, contains(field), reason: field);
      }
    });
  });

  test('carries the prompt version, for the cache key', () {
    expect(build(SampleEntries.mu, HanLanguage.chinese).version, promptVersion);
    expect(promptVersion, 'prompt_v1');
  });

  test('builds the same text for the same input', () {
    final a = build(SampleEntries.go, HanLanguage.japanese);
    final b = build(SampleEntries.go, HanLanguage.japanese);

    expect(a.user, b.user);
    expect(a.system, b.system);
  });
}
