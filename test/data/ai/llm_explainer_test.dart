import 'dart:async';
import 'dart:convert';

import 'package:character_lens/data/ai/llm_explainer.dart';
import 'package:character_lens/data/ai/prompt_v1.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_explanation_model.dart';
import '../../support/sample_entries.dart';

final _valid = jsonEncode({
  'components': <Object?>[],
  'mnemonic': 'A tree.',
  'examples': [
    {'word': '木头', 'reading': 'mùtou', 'meaning': 'wood'},
  ],
});

const _expected = Explanation(
  components: [],
  mnemonic: 'A tree.',
  examples: [ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood')],
);

/// Runs [explain] with fake time. Returns the explanation or the thrown error.
Object? _run(
  FakeExplanationModel model, {
  Duration elapse = Duration.zero,
  Duration timeout = const Duration(seconds: 15),
}) {
  Object? outcome;
  fakeAsync((async) {
    LlmExplainer(model, timeout: timeout)
        .explain(SampleEntries.mu, HanLanguage.chinese)
        .then<void>(
          (value) {
            outcome = value;
          },
          onError: (Object error) {
            outcome = error;
          },
        );
    async.elapse(elapse);
    async.flushMicrotasks();
  });
  return outcome;
}

void main() {
  test('names the prompt version of the prompts it sends', () {
    final explainer = LlmExplainer(FakeExplanationModel([_valid]));

    expect(explainer.promptVersion, promptVersion);
  });

  group('a valid answer', () {
    test('becomes an Explanation, with one call', () {
      final model = FakeExplanationModel([_valid]);

      expect(_run(model), _expected);
      expect(model.calls, 1);
    });

    test('asks with the prompt built from the entry and the language', () {
      final model = FakeExplanationModel([_valid]);

      _run(model);

      final prompt = model.prompts.single;
      expect(prompt.version, promptVersion);
      expect(prompt.user, contains('Character: 木'));
      expect(prompt.user, contains('reader of Chinese'));
      expect(prompt.system, contains('source of truth'));
    });
  });

  group('an invalid answer', () {
    test('is asked for once more, and the second one is used', () {
      final model = FakeExplanationModel(['Sure! Here you go', _valid]);

      expect(_run(model), _expected);
      expect(model.calls, 2);
    });

    test('twice is dropped, after exactly one retry', () {
      final model = FakeExplanationModel(['nope', '{"mnemonic": 1}', _valid]);

      final outcome = _run(model);

      expect(outcome, isA<ExplainerInvalidOutputFailure>());
      expect(model.calls, 2);
    });

    test('keeps the detail of the last attempt', () {
      final model = FakeExplanationModel(['nope', '{}']);

      final outcome = _run(model) as ExplainerInvalidOutputFailure;

      expect(outcome.detail, contains('components'));
    });

    test('an empty answer is invalid too', () {
      final model = FakeExplanationModel(['', '']);

      expect(_run(model), isA<ExplainerInvalidOutputFailure>());
      expect(model.calls, 2);
    });
  });

  group('other failures', () {
    for (final failure in <ExplanationFailure>[
      const ExplainerOfflineFailure(),
      const ExplainerRejectedFailure(),
      const ExplainerFailure(),
    ]) {
      test('${failure.runtimeType} is passed on and not retried', () {
        final model = FakeExplanationModel([failure, _valid]);

        expect(_run(model), failure);
        expect(model.calls, 1);
      });
    }

    test('an exception that is not a failure becomes ExplainerFailure', () {
      final boom = Exception('boom');
      final model = FakeExplanationModel([boom]);

      expect(_run(model), ExplainerFailure(cause: boom));
      expect(model.calls, 1);
    });
  });

  group('the timeout', () {
    test('ends a call that never answers, with no retry', () {
      final model = FakeExplanationModel([Completer<String>().future, _valid]);

      final outcome = _run(model, elapse: const Duration(seconds: 16));

      expect(outcome, const ExplainerTimeoutFailure());
      expect(model.calls, 1);
    });

    test('is not reached by an answer that comes in time', () {
      Object? outcome;
      fakeAsync((async) {
        // Made inside, so the fake clock drives it.
        final slow = Completer<String>();
        final model = FakeExplanationModel([slow.future]);
        LlmExplainer(model)
            .explain(SampleEntries.mu, HanLanguage.chinese)
            .then<void>((value) {
              outcome = value;
            });
        async.elapse(const Duration(seconds: 14));
        slow.complete(_valid);
        async.flushMicrotasks();
      });

      expect(outcome, _expected);
    });

    test('applies to each attempt, including the retry', () {
      final model = FakeExplanationModel(['nope', Completer<String>().future]);

      final outcome = _run(model, elapse: const Duration(seconds: 16));

      expect(outcome, const ExplainerTimeoutFailure());
      expect(model.calls, 2);
    });

    test('is 15 seconds by default', () {
      expect(LlmExplainer.defaultTimeout, const Duration(seconds: 15));
      expect(LlmExplainer.attempts, 2);
    });
  });
}
