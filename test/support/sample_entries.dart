import 'package:character_lens/domain/entities/character_entry.dart';

/// Entries copied from Unihan 18.0.0 (2026-07-31), trimmed to the fields the
/// app uses. They are the cases that matter for variants: a character with no
/// variants, a traditional and simplified pair, a pair where only one side has
/// Japanese and Korean readings, a Japanese-only form with no links, and a
/// one-to-many variant.
abstract final class SampleEntries {
  static final mu = CharacterEntry(
    character: '木',
    definition: 'tree; wood, lumber; wooden',
    mandarin: ['mù'],
    japaneseOn: ['BOKU', 'MOKU'],
    japaneseKun: ['KI'],
    hangul: ['목'],
    totalStrokes: 4,
  );

  /// Traditional form. Has a simplified variant and readings in all languages.
  static final go = CharacterEntry(
    character: '語',
    definition: 'language, words; saying, expression',
    mandarin: ['yǔ'],
    japaneseOn: ['GO', 'GYO'],
    japaneseKun: ['KATARU', 'KOTOBA', 'TSUGERU'],
    hangul: ['어'],
    simplified: ['语'],
    totalStrokes: 14,
  );

  /// Simplified form of 語. Unihan gives it no Japanese or Korean readings.
  static final goSimplified = CharacterEntry(
    character: '语',
    definition: 'language, words; saying, expression',
    mandarin: ['yǔ'],
    traditional: ['語'],
    totalStrokes: 9,
  );

  /// Simplified in China and the form Japan uses. Has its own readings.
  static final gaku = CharacterEntry(
    character: '学',
    definition: 'learning, knowledge; school',
    mandarin: ['xué'],
    japaneseOn: ['GAKU'],
    japaneseKun: ['MANABU'],
    hangul: ['학'],
    traditional: ['學'],
    totalStrokes: 8,
  );

  static final gakuTraditional = CharacterEntry(
    character: '學',
    definition: 'learning, knowledge; school',
    mandarin: ['xué'],
    japaneseOn: ['GAKU'],
    japaneseKun: ['MANABU'],
    hangul: ['학'],
    simplified: ['学'],
    totalStrokes: 16,
  );

  /// Japanese form of 氣. Unihan has no variant link from it to 氣 or 气.
  static final kiJapanese = CharacterEntry(
    character: '気',
    definition: 'air, gas, steam, vapor; spirit',
    mandarin: ['qì'],
    japaneseOn: ['KI', 'KE'],
    japaneseKun: ['IKI'],
  );

  /// Variants point at itself and at 氣 (kTraditionalVariant is `气 氣`).
  static final kiSimplified = CharacterEntry(
    character: '气',
    definition: 'steam, vapor; Kangxi radical 84',
    mandarin: ['qì'],
    japaneseOn: ['KI', 'KE'],
    japaneseKun: ['IKI'],
    simplified: ['气'],
    traditional: ['气', '氣'],
  );

  static final kiTraditional = CharacterEntry(
    character: '氣',
    definition: 'air, gas, steam, vapor; spirit',
    mandarin: ['qì'],
    japaneseOn: ['KI', 'KE'],
    japaneseKun: ['IKI'],
    hangul: ['기'],
    simplified: ['气'],
  );

  /// A character with a reading in one language and no definition.
  static final noDefinition = CharacterEntry(character: '丂', mandarin: ['kǎo']);

  /// A character with neither readings nor a definition.
  static final bare = CharacterEntry(character: '〇');
}
