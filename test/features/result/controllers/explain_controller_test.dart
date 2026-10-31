import 'dart:async';

import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/result/controllers/explain_controller.dart';
import 'package:character_lens/features/result/controllers/explain_state.dart';
import 'package:character_lens/features/result/controllers/explainer_provider.dart';
import 'package:character_lens/features/result/controllers/explanation_cache_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_dictionary.dart';
import '../../../support/fake_explainer.dart';
import '../../../support/fake_explanation_cache.dart';
import '../../../support/sample_entries.dart';

const _cn = InkLanguage.chinese;
const _jp = InkLanguage.japanese;

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        dictionaryProvider.overrideWithValue(dictionary),
        explainerProvider.overrideWithValue(explainer),
        explanationCacheProvider.overrideWithValue(cache),
      ],
    );
    container.listen(
      lookupControllerProvider,
      (_, next) => lookups.add(next),
      fireImmediately: true,
    );
    container.listen(
      explainControllerProvider,
      (_, next) => explains.add(next),
      fireImmediately: true,
    );
    lookup = container.read(lookupControllerProvider.notifier);
  }

  final dictionary = FakeDictionary([
    SampleEntries.mu,
    SampleEntries.go,
    SampleEntries.goSimplified,
  ]);
  final explainer = FakeExplainer();
  final cache = FakeExplanationCache();
  final lookups = <LookupState>[];
  final explains = <ExplainState>[];
  late final ProviderContainer container;
  late final LookupController lookup;

  ExplainState get state => container.read(explainControllerProvider);

  Future<void> settle() => pumpEventQueue();

  List<Type> get trail {
    final types = <Type>[];
    for (final s in explains) {
      if (types.isEmpty || types.last != s.runtimeType) {
        types.add(s.runtimeType);
      }
    }
    return types;
  }
}

void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.container.dispose());

  test('starts idle', () {
    expect(h.state, const ExplainIdle());
  });

  group('after the dictionary entry is loaded', () {
    test('goes Idle, Loading, Ready', () async {
      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.trail, [ExplainIdle, ExplainLoading, ExplainReady]);
    });

    test('Ready holds the explanation and the check of each example', () async {
      await h.lookup.open('木', _cn);
      await h.settle();

      final ready = h.state as ExplainReady;
      expect(ready.result.explanation, h.explainer.result);
      expect(ready.result.checks, [ReadingCheck.verified]);
    });

    test('explains the character in the language it was drawn in', () async {
      await h.lookup.open('語', _jp);
      await h.settle();

      expect(h.explainer.calls, [('語', HanLanguage.japanese)]);
    });
  });

  group('the dictionary card comes first', () {
    test('is loaded while the explanation is still on its way', () async {
      h.explainer.gates['木'] = Completer<void>();

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.lookups.last, isA<LookupLoaded>());
      expect(h.state, const ExplainLoading());

      h.explainer.gates['木']!.complete();
      await h.settle();
      expect(h.state, isA<ExplainReady>());
    });

    test('nothing is explained while the entry is still loading', () async {
      h.dictionary.gates['木'] = Completer<void>();

      final opening = h.lookup.open('木', _cn);
      await h.settle();

      expect(h.state, const ExplainIdle());
      expect(h.explainer.calls, isEmpty);

      h.dictionary.gates['木']!.complete();
      await opening;
      await h.settle();
      expect(h.explainer.calls, hasLength(1));
    });

    test(
      'a character that is not in the dictionary is not explained',
      () async {
        await h.lookup.open('水', _cn);
        await h.settle();

        expect(h.state, const ExplainIdle());
        expect(h.explainer.calls, isEmpty);
      },
    );

    test('a dictionary that cannot be read is not explained either', () async {
      h.dictionary.error = Exception('boom');

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.state, const ExplainIdle());
      expect(h.explainer.calls, isEmpty);
    });

    test('explaining never changes the lookup', () async {
      h.explainer.error = const ExplainerTimeoutFailure();

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.lookups.map((s) => s.runtimeType), [
        LookupClosed,
        LookupLoading,
        LookupLoaded,
      ]);
    });
  });

  group('the cache', () {
    test(
      'a miss asks the explainer exactly once and stores the answer',
      () async {
        await h.lookup.open('木', _cn);
        await h.settle();

        expect(h.explainer.calls, hasLength(1));
        expect(h.cache.puts, hasLength(1));
      },
    );

    test('a hit asks nobody and is shown at once', () async {
      h.cache.entries[const ExplanationKey(
        character: '木',
        language: HanLanguage.chinese,
        promptVersion: 'prompt_test',
      )] = const Explanation(
        components: [],
        mnemonic: 'From the cache.',
        examples: [],
      );

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.explainer.calls, isEmpty);
      expect(
        (h.state as ExplainReady).result.explanation.mnemonic,
        'From the cache.',
      );
    });
  });

  group('when there is no explanation', () {
    test(
      'a failure is Unavailable, with the reason, and is not stored',
      () async {
        h.explainer.error = const ExplainerOfflineFailure();

        await h.lookup.open('木', _cn);
        await h.settle();

        expect(h.state, const ExplainUnavailable(ExplainerOfflineFailure()));
        expect(h.cache.puts, isEmpty);
      },
    );

    test('an exception that is not a failure is Unavailable too', () async {
      final boom = Exception('boom');
      h.explainer.error = boom;

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.state, ExplainUnavailable(ExplainerFailure(cause: boom)));
    });

    test('not configured is Unavailable', () async {
      h.explainer.error = const ExplainerNotConfiguredFailure();

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(
        h.state,
        const ExplainUnavailable(ExplainerNotConfiguredFailure()),
      );
    });

    test('opening the character again tries again', () async {
      h.explainer.error = const ExplainerTimeoutFailure();
      await h.lookup.open('木', _cn);
      await h.settle();

      h.explainer.error = null;
      h.lookup.close();
      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.state, isA<ExplainReady>());
    });
  });

  group('closing and switching', () {
    test('closing the sheet while explaining goes back to Idle', () async {
      h.explainer.gates['木'] = Completer<void>();
      await h.lookup.open('木', _cn);
      await h.settle();

      h.lookup.close();
      await h.settle();

      expect(h.state, const ExplainIdle());
    });

    test('an answer that arrives after the sheet closed is dropped', () async {
      h.explainer.gates['木'] = Completer<void>();
      await h.lookup.open('木', _cn);
      await h.settle();
      h.lookup.close();

      h.explainer.gates['木']!.complete();
      await h.settle();

      expect(h.state, const ExplainIdle());
    });

    test(
      'switching explains the new character and drops the old answer',
      () async {
        h.explainer.gates['語'] = Completer<void>();
        await h.lookup.open('語', _cn);
        await h.settle();

        await h.lookup.open('木', _cn);
        await h.settle();
        expect(
          (h.state as ExplainReady).result.explanation,
          h.explainer.result,
        );

        h.explainer.gates['語']!.complete();
        await h.settle();

        expect(h.explainer.calls.map((c) => c.$1), ['語', '木']);
        expect(h.state, isA<ExplainReady>());
        expect(h.cache.puts.map((k) => k.character), contains('木'));
      },
    );

    test(
      'keeps showing the old explanation until the new entry arrives',
      () async {
        await h.lookup.open('木', _cn);
        await h.settle();
        final before = h.state;

        h.dictionary.gates['語'] = Completer<void>();
        final switching = h.lookup.open('語', _cn);
        await h.settle();

        expect(h.state, before);

        h.dictionary.gates['語']!.complete();
        await switching;
        await h.settle();
        expect(h.explainer.calls.map((c) => c.$1), ['木', '語']);
      },
    );
  });

  test(
    'explains a sheet that was already loaded when it is first read',
    () async {
      // The explain controller is only created after the lookup is done.
      final container = ProviderContainer(
        overrides: [
          dictionaryProvider.overrideWithValue(h.dictionary),
          explainerProvider.overrideWithValue(h.explainer),
          explanationCacheProvider.overrideWithValue(h.cache),
        ],
      );
      addTearDown(container.dispose);
      await container.read(lookupControllerProvider.notifier).open('木', _cn);

      container.read(explainControllerProvider);
      await pumpEventQueue();

      expect(container.read(explainControllerProvider), isA<ExplainReady>());
      expect(h.explainer.calls, hasLength(1));
    },
  );
}
