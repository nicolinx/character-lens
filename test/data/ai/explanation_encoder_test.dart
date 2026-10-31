import 'dart:convert';

import 'package:character_lens/data/ai/explanation_encoder.dart';
import 'package:character_lens/data/ai/explanation_parser.dart';
import 'package:character_lens/data/ai/explanation_schema.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:flutter_test/flutter_test.dart';

const _full = Explanation(
  components: [ExplanationComponent(part: '言', role: 'speech')],
  mnemonic: 'Speech about "I".',
  examples: [
    ExplanationExample(word: '语言', reading: 'yǔyán', meaning: 'language'),
    ExplanationExample(word: '日本語', reading: 'にほんご', meaning: 'Japanese'),
  ],
  usageNote: 'Same meaning in both languages.',
);

void main() {
  test('is read back by the parser, with every field', () {
    expect(parseExplanation(encodeExplanation(_full)), _full);
  });

  test('keeps an explanation with no components and no usage note', () {
    const explanation = Explanation(
      components: [],
      mnemonic: 'A tree.',
      examples: [ExplanationExample(word: '木', reading: 'mù', meaning: 'tree')],
    );

    expect(parseExplanation(encodeExplanation(explanation)), explanation);
  });

  test('leaves the usage note out when there is none', () {
    const explanation = Explanation(
      components: [],
      mnemonic: 'A tree.',
      examples: [],
    );

    final json = jsonDecode(encodeExplanation(explanation)) as Map;

    expect(json.containsKey('usage_note'), isFalse);
  });

  test('keeps quotes, newlines and non-Latin text intact', () {
    const explanation = Explanation(
      components: [],
      mnemonic: 'He said "木"\nand left.',
      examples: [],
    );

    expect(parseExplanation(encodeExplanation(explanation)), explanation);
  });

  test('uses the keys of the answer schema', () {
    final json = jsonDecode(encodeExplanation(_full)) as Map<String, Object?>;
    final properties =
        explanationSchemaV1['properties']! as Map<String, Object?>;

    expect(json.keys.toSet(), properties.keys.toSet());
  });
}
