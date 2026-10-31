import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const part = ExplanationComponent(part: '木', role: 'tree');
  const example = ExplanationExample(
    word: '木头',
    reading: 'mùtou',
    meaning: 'wood',
  );

  Explanation make({String? usageNote}) => Explanation(
    components: const [part],
    mnemonic: 'A tree with branches and roots.',
    examples: const [example],
    usageNote: usageNote,
  );

  group('Explanation', () {
    test('is equal when every field is equal', () {
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('differs when the usage note differs', () {
      expect(
        make(usageNote: 'Used for trees in both languages.'),
        isNot(make()),
      );
    });

    test('the usage note is optional', () {
      expect(make().usageNote, isNull);
    });
  });

  group('ExplanationFailure', () {
    test('failures of the same kind with the same detail are equal', () {
      expect(
        const ExplainerInvalidOutputFailure(detail: 'no mnemonic'),
        const ExplainerInvalidOutputFailure(detail: 'no mnemonic'),
      );
      expect(
        const ExplainerInvalidOutputFailure(detail: 'a'),
        isNot(const ExplainerInvalidOutputFailure(detail: 'b')),
      );
    });

    test('different kinds are not equal', () {
      expect(
        const ExplainerOfflineFailure(),
        isNot(const ExplainerTimeoutFailure()),
      );
    });

    test('a failure can be thrown and caught as an Exception', () {
      expect(
        () => throw const ExplainerNotConfiguredFailure(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
