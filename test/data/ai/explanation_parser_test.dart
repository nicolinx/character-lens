import 'dart:convert';

import 'package:character_lens/data/ai/explanation_parser.dart';
import 'package:character_lens/data/ai/explanation_schema.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _valid() => {
  'components': [
    {'part': '木', 'role': 'tree'},
  ],
  'mnemonic': 'A tree with branches and roots.',
  'examples': [
    {'word': '木头', 'reading': 'mùtou', 'meaning': 'wood'},
    {'word': '树木', 'reading': 'shùmù', 'meaning': 'trees'},
  ],
  'usage_note': 'Used for trees in both languages.',
};

String _json(Map<String, Object?> value) => jsonEncode(value);

Matcher _invalid([String? detail]) => throwsA(
  isA<ExplainerInvalidOutputFailure>().having(
    (f) => f.detail,
    'detail',
    detail == null ? anything : contains(detail),
  ),
);

/// A value that has every field of [schema], with `x` for text.
Object? _fromSchema(Map<String, Object?> schema) {
  switch (schema['type']) {
    case 'string':
      return 'x';
    case 'array':
      return [_fromSchema(schema['items']! as Map<String, Object?>)];
    case 'object':
      final properties = schema['properties']! as Map<String, Object?>;
      return {
        for (final entry in properties.entries)
          entry.key: _fromSchema(entry.value! as Map<String, Object?>),
      };
  }
  throw StateError('unexpected schema: $schema');
}

void main() {
  group('a valid answer', () {
    test('becomes an Explanation', () {
      final explanation = parseExplanation(_json(_valid()));

      expect(
        explanation,
        const Explanation(
          components: [ExplanationComponent(part: '木', role: 'tree')],
          mnemonic: 'A tree with branches and roots.',
          examples: [
            ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood'),
            ExplanationExample(word: '树木', reading: 'shùmù', meaning: 'trees'),
          ],
          usageNote: 'Used for trees in both languages.',
        ),
      );
    });

    test('does not need a usage note', () {
      final json = _valid()..remove('usage_note');

      expect(parseExplanation(_json(json)).usageNote, isNull);
    });

    test('treats a null or blank usage note as none', () {
      expect(
        parseExplanation(_json(_valid()..['usage_note'] = null)).usageNote,
        isNull,
      );
      expect(
        parseExplanation(_json(_valid()..['usage_note'] = '  ')).usageNote,
        isNull,
      );
    });

    test('trims the text', () {
      final json = _valid()..['mnemonic'] = '  A tree.  ';

      expect(parseExplanation(_json(json)).mnemonic, 'A tree.');
    });

    test('accepts empty lists', () {
      final json = _valid()
        ..['components'] = <Object?>[]
        ..['examples'] = <Object?>[];

      final explanation = parseExplanation(_json(json));

      expect(explanation.components, isEmpty);
      expect(explanation.examples, isEmpty);
    });

    test('ignores a field it does not know', () {
      final json = _valid()..['confidence'] = 0.9;

      expect(() => parseExplanation(_json(json)), returnsNormally);
    });

    test('built from the schema, so the schema and the parser agree', () {
      final value = _fromSchema(explanationSchemaV1)! as Map<String, Object?>;

      expect(() => parseExplanation(_json(value)), returnsNormally);
    });
  });

  group('the text is not what the schema promises', () {
    test('plain text is not JSON', () {
      expect(
        () => parseExplanation('Sure! Here is the answer'),
        _invalid('not JSON'),
      );
    });

    test('an empty answer is not JSON', () {
      expect(() => parseExplanation(''), _invalid('not JSON'));
    });

    test('JSON wrapped in a code fence is extra text', () {
      expect(
        () => parseExplanation('```json\n${_json(_valid())}\n```'),
        _invalid('not JSON'),
      );
    });

    test('JSON followed by extra text is not JSON', () {
      expect(
        () => parseExplanation('${_json(_valid())} Hope this helps!'),
        _invalid('not JSON'),
      );
    });

    test('an array is not an object', () {
      expect(() => parseExplanation('[]'), _invalid('not an object'));
    });
  });

  group('a field is missing or has the wrong type', () {
    test('without a mnemonic', () {
      final json = _valid()..remove('mnemonic');

      expect(
        () => parseExplanation(_json(json)),
        _invalid('mnemonic is missing'),
      );
    });

    test('with an empty mnemonic', () {
      final json = _valid()..['mnemonic'] = '   ';

      expect(
        () => parseExplanation(_json(json)),
        _invalid('mnemonic is missing'),
      );
    });

    test('with a mnemonic that is not text', () {
      final json = _valid()..['mnemonic'] = 42;

      expect(() => parseExplanation(_json(json)), _invalid('mnemonic'));
    });

    test('without examples', () {
      final json = _valid()..remove('examples');

      expect(
        () => parseExplanation(_json(json)),
        _invalid('examples is not a list'),
      );
    });

    test('with examples that are an object, not a list', () {
      final json = _valid()..['examples'] = {'word': '木'};

      expect(
        () => parseExplanation(_json(json)),
        _invalid('examples is not a list'),
      );
    });

    test('without components', () {
      final json = _valid()..remove('components');

      expect(
        () => parseExplanation(_json(json)),
        _invalid('components is not a list'),
      );
    });

    test('an example without a reading names it', () {
      final json = _valid()
        ..['examples'] = [
          {'word': '木头', 'meaning': 'wood'},
        ];

      expect(
        () => parseExplanation(_json(json)),
        _invalid('examples[0].reading is missing'),
      );
    });

    test('the second example is named by its position', () {
      final json = _valid()
        ..['examples'] = [
          {'word': '木头', 'reading': 'mùtou', 'meaning': 'wood'},
          {'word': '', 'reading': 'x', 'meaning': 'y'},
        ];

      expect(() => parseExplanation(_json(json)), _invalid('examples[1].word'));
    });

    test('an example that is not an object', () {
      final json = _valid()..['examples'] = ['木头'];

      expect(
        () => parseExplanation(_json(json)),
        _invalid('examples[0] is not an object'),
      );
    });

    test('a component without a role', () {
      final json = _valid()
        ..['components'] = [
          {'part': '木'},
        ];

      expect(
        () => parseExplanation(_json(json)),
        _invalid('components[0].role is missing'),
      );
    });

    test('a usage note that is not text', () {
      final json = _valid()..['usage_note'] = ['a'];

      expect(() => parseExplanation(_json(json)), _invalid('usage_note'));
    });
  });

  test('the failure detail names the field and never repeats the answer', () {
    final json = _valid()..['mnemonic'] = 7;

    try {
      parseExplanation(_json(json));
      fail('expected a failure');
    } on ExplainerInvalidOutputFailure catch (failure) {
      expect(failure.detail, isNot(contains('7')));
      expect(failure.detail, isNot(contains('branches')));
    }
  });
}
