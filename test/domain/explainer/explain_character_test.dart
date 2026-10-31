import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explain_character.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/explainer/explanation_cache_failure.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_explainer.dart';
import '../../support/fake_explanation_cache.dart';
import '../../support/sample_entries.dart';

const _cn = HanLanguage.chinese;
const _jp = HanLanguage.japanese;

const _key = ExplanationKey(
  character: '木',
  language: _cn,
  promptVersion: 'prompt_test',
);

const _cached = Explanation(
  components: [],
  mnemonic: 'From the cache.',
  examples: [ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood')],
);

void main() {
  late FakeExplainer explainer;
  late FakeExplanationCache cache;
  late ExplainCharacter explain;

  setUp(() {
    explainer = FakeExplainer();
    cache = FakeExplanationCache();
    explain = ExplainCharacter(explainer: explainer, cache: cache);
  });

  group('with an answer in the cache', () {
    setUp(() => cache.entries[_key] = _cached);

    test('uses it and does not ask the explainer', () async {
      final result = await explain(SampleEntries.mu, _cn);

      expect(result.explanation, _cached);
      expect(explainer.calls, isEmpty);
      expect(cache.puts, isEmpty);
    });

    test('checks it against the dictionary entry it is shown with', () async {
      cache.entries[_key] = const Explanation(
        components: [],
        mnemonic: 'x',
        examples: [
          ExplanationExample(word: '木头', reading: 'mutou', meaning: 'wood'),
        ],
      );

      final result = await explain(SampleEntries.mu, _cn);

      expect(result.checks, [ReadingCheck.unverified]);
    });

    test('works while the explainer cannot answer at all', () async {
      explainer.error = const ExplainerNotConfiguredFailure();

      final result = await explain(SampleEntries.mu, _cn);

      expect(result.explanation, _cached);
    });
  });

  group('without an answer in the cache', () {
    test('asks the explainer exactly once', () async {
      await explain(SampleEntries.mu, _cn);

      expect(explainer.calls, [('木', _cn)]);
    });

    test('stores the answer under the key of the character, language and '
        'prompt version', () async {
      final result = await explain(SampleEntries.mu, _cn);

      expect(cache.puts, [_key]);
      expect(cache.entries[_key], result.explanation);
    });

    test('checks the examples against the entry', () async {
      explainer.result = const Explanation(
        components: [],
        mnemonic: 'x',
        examples: [
          ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood'),
          ExplanationExample(word: '木头', reading: 'mǔtou', meaning: 'wood'),
        ],
      );

      final result = await explain(SampleEntries.mu, _cn);

      expect(result.checks, [ReadingCheck.verified, ReadingCheck.unverified]);
    });

    test('a second call is served from the cache', () async {
      await explain(SampleEntries.mu, _cn);
      await explain(SampleEntries.mu, _cn);

      expect(explainer.calls, hasLength(1));
    });

    test('another language is explained on its own', () async {
      await explain(SampleEntries.mu, _cn);
      await explain(SampleEntries.mu, _jp);

      expect(explainer.calls, [('木', _cn), ('木', _jp)]);
      expect(cache.puts, hasLength(2));
    });

    test('a new prompt version asks again', () async {
      await explain(SampleEntries.mu, _cn);
      final newer = ExplainCharacter(
        explainer: FakeExplainer(promptVersion: 'prompt_newer')
          ..result = explainer.result,
        cache: cache,
      );

      await newer(SampleEntries.mu, _cn);

      expect(cache.puts.map((k) => k.promptVersion), [
        'prompt_test',
        'prompt_newer',
      ]);
    });
  });

  group('when the explainer fails', () {
    test('the failure reaches the caller and nothing is stored', () async {
      explainer.error = const ExplainerTimeoutFailure();

      await expectLater(
        explain(SampleEntries.mu, _cn),
        throwsA(const ExplainerTimeoutFailure()),
      );
      expect(cache.puts, isEmpty);
    });

    test('the next call tries again', () async {
      explainer.error = const ExplainerOfflineFailure();
      await expectLater(explain(SampleEntries.mu, _cn), throwsA(anything));

      explainer.error = null;
      final result = await explain(SampleEntries.mu, _cn);

      expect(result.explanation, explainer.result);
      expect(explainer.calls, hasLength(2));
    });
  });

  group('when the cache fails', () {
    test('a cache that cannot be read is a miss', () async {
      cache.getError = const ExplanationCacheUnavailableFailure();

      final result = await explain(SampleEntries.mu, _cn);

      expect(result.explanation, explainer.result);
      expect(explainer.calls, hasLength(1));
    });

    test('a cache that cannot be written does not lose the answer', () async {
      cache.putError = const ExplanationCacheUnavailableFailure();

      final result = await explain(SampleEntries.mu, _cn);

      expect(result.explanation, explainer.result);
    });
  });
}
