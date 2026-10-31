import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:character_lens/domain/explainer/kana_romanizer.dart';

/// Checks the reading of each example against the dictionary entry.
///
/// An example's reading is the reading of a whole word. It is verified when it
/// contains one of the dictionary readings of the character. This is a loose
/// test with known limits, and when it cannot decide the answer is
/// [ReadingCheck.unverified], never verified:
///
/// - A sound change (学校 is がっこう, GAKKOU, which does not contain GAKU)
///   makes a correct reading unverified.
/// - Japanese must be written in kana. Romaji, or anything else, is unverified.
/// - Tone marks must be precomposed letters, as in the dictionary.
/// - A reading of one letter only matches a one-letter word reading, so it
///   cannot verify every word that happens to contain it.
class ExplanationValidator {
  ValidatedExplanation validate(
    Explanation explanation,
    CharacterEntry entry,
    HanLanguage language,
  ) {
    return ValidatedExplanation(
      explanation: explanation,
      checks: [
        for (final example in explanation.examples)
          _check(example.reading, entry, language)
              ? ReadingCheck.verified
              : ReadingCheck.unverified,
      ],
    );
  }

  bool _check(String reading, CharacterEntry entry, HanLanguage language) =>
      switch (language) {
        HanLanguage.chinese => _containsLatin(
          _latin(reading),
          entry.mandarin.map(_latin),
        ),
        HanLanguage.japanese => switch (romanizeKana(reading)) {
          final romaji? => _containsLatin(romaji, [
            ...entry.japaneseOn,
            ...entry.japaneseKun,
          ]),
          null => false,
        },
        HanLanguage.korean => _containsHangul(reading, entry.hangul),
      };

  String _latin(String text) =>
      text.toLowerCase().replaceAll(RegExp(r"[\s\-'’]"), '');

  bool _containsLatin(String reading, Iterable<String> dictionary) {
    for (final candidate in dictionary) {
      if (candidate.isEmpty) continue;
      final matches = candidate.length == 1
          ? reading == candidate
          : reading.contains(candidate);
      if (matches) return true;
    }
    return false;
  }

  bool _containsHangul(String reading, List<String> dictionary) {
    final word = reading.replaceAll(RegExp(r'\s'), '');
    return dictionary.any(
      (syllable) => syllable.isNotEmpty && word.contains(syllable),
    );
  }
}
