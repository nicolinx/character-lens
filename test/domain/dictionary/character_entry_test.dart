import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterEntry', () {
    test('is equal to another entry with the same data', () {
      final a = CharacterEntry(character: '木', mandarin: ['mù']);
      final b = CharacterEntry(character: '木', mandarin: ['mù']);

      expect(a, b);
    });

    test('differs when a reading differs', () {
      final a = CharacterEntry(character: '木', mandarin: ['mù']);
      final b = CharacterEntry(character: '木', mandarin: ['mu']);

      expect(a, isNot(b));
    });

    test('reports its code point', () {
      expect(CharacterEntry(character: '木').codePoint, 0x6728);
    });

    test('works for a character outside the basic plane', () {
      expect(CharacterEntry(character: '𠀀').codePoint, 0x20000);
    });

    test('refuses more than one character', () {
      expect(
        () => CharacterEntry(character: '木木'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('refuses an empty character', () {
      expect(
        () => CharacterEntry(character: ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('InkLanguage to HanLanguage', () {
    test('maps the two input languages', () {
      expect(InkLanguage.chinese.han, HanLanguage.chinese);
      expect(InkLanguage.japanese.han, HanLanguage.japanese);
    });
  });
}
