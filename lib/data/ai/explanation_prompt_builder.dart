import 'package:character_lens/data/ai/prompt_v1.dart';
import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';

class ExplanationPrompt {
  const ExplanationPrompt({
    required this.version,
    required this.system,
    required this.user,
  });

  final String version;
  final String system;
  final String user;
}

/// Builds the request for one character. It only reads the dictionary entry,
/// so nothing about the drawing can reach the model.
class ExplanationPromptBuilder {
  ExplanationPrompt build(CharacterEntry entry, HanLanguage language) {
    final others = [
      ...entry.simplified,
      ...entry.traditional,
    ].where((form) => form != entry.character).toSet();

    final lines = <String>[
      'Explain this character for a reader of ${_name(language)}.',
      '',
      'Character: ${entry.character}',
      if (entry.definition case final definition?) 'Definition: $definition',
      if (entry.mandarin.isNotEmpty) 'Mandarin: ${entry.mandarin.join(', ')}',
      if (entry.japaneseOn.isNotEmpty)
        'Japanese on: ${entry.japaneseOn.join(', ')}',
      if (entry.japaneseKun.isNotEmpty)
        'Japanese kun: ${entry.japaneseKun.join(', ')}',
      if (entry.hangul.isNotEmpty)
        'Korean (Hangul): ${entry.hangul.join(', ')}',
      if (others.isNotEmpty) 'Other written forms: ${others.join(', ')}',
      '',
      _readingFormat(language),
    ];

    return ExplanationPrompt(
      version: promptVersion,
      system: systemInstructionV1,
      user: lines.join('\n'),
    );
  }

  String _name(HanLanguage language) => switch (language) {
    HanLanguage.chinese => 'Chinese',
    HanLanguage.japanese => 'Japanese',
    HanLanguage.korean => 'Korean',
  };

  String _readingFormat(HanLanguage language) => switch (language) {
    HanLanguage.chinese => 'Write each example reading in pinyin with tone marks, for example mùtou.',
    HanLanguage.japanese => 'Write each example reading in hiragana only, with no romaji, for example もくようび.',
    HanLanguage.korean => 'Write each example reading in Hangul.',
  };
}
