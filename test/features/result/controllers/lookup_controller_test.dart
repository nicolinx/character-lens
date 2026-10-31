import 'dart:async';

import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/dictionary/dictionary_failure.dart';
import 'package:character_lens/domain/dictionary/resolve_character.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_dictionary.dart';
import '../../../support/sample_entries.dart';

const _cn = InkLanguage.chinese;
const _jp = InkLanguage.japanese;

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [dictionaryProvider.overrideWithValue(dictionary)],
    );
    container.listen(
      lookupControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    controller = container.read(lookupControllerProvider.notifier);
  }

  final dictionary = FakeDictionary([
    SampleEntries.mu,
    SampleEntries.go,
    SampleEntries.goSimplified,
    SampleEntries.gaku,
    SampleEntries.gakuTraditional,
  ]);
  final states = <LookupState>[];
  late final ProviderContainer container;
  late final LookupController controller;

  LookupState get state => container.read(lookupControllerProvider);

  List<Type> get trail {
    final types = <Type>[];
    for (final s in states) {
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

  test('starts closed', () {
    expect(h.state, const LookupClosed());
  });

  group('open', () {
    test('goes Closed, Loading, Loaded', () async {
      await h.controller.open('語', _jp);

      expect(h.trail, [LookupClosed, LookupLoading, LookupLoaded]);
    });

    test('Loading names the character and language being looked up', () async {
      await h.controller.open('語', _jp);

      expect(h.states[1], const LookupLoading(character: '語', language: _jp));
    });

    test('Loaded holds what ResolveCharacter makes of the entry', () async {
      await h.controller.open('語', _jp);

      final expected = await ResolveCharacter(h.dictionary)(
        SampleEntries.go,
        HanLanguage.japanese,
      );
      final state = h.state as LookupLoaded;
      expect(state.view, expected);
      expect(state.character, '語');
      expect(state.language, _jp);
    });

    test('maps the drawn language to the language of the view', () async {
      await h.controller.open('語', _cn);

      expect((h.state as LookupLoaded).view.selected, HanLanguage.chinese);
    });

    test('a character that is not in the dictionary is NotFound', () async {
      await h.controller.open('水', _cn);

      expect(h.trail, [LookupClosed, LookupLoading, LookupNotFound]);
      expect(h.state, const LookupNotFound(character: '水', language: _cn));
    });

    test('an unavailable dictionary is Failed, not a crash', () async {
      h.dictionary.error = const DictionaryUnavailableFailure();

      await h.controller.open('木', _cn);

      expect(h.trail, [LookupClosed, LookupLoading, LookupFailed]);
      expect(
        h.state,
        const LookupFailed(
          character: '木',
          language: _cn,
          failure: DictionaryUnavailableFailure(),
        ),
      );
    });

    test('a failure while reading a variant is Failed too', () async {
      // 语 has no Japanese or Korean readings, so resolving it reads 語.
      h.dictionary.lookupErrors['語'] = const DictionaryUnavailableFailure();

      await h.controller.open('语', _cn);

      expect(h.state, isA<LookupFailed>());
    });

    test(
      'an unexpected Exception becomes a DictionaryUnavailableFailure',
      () async {
        final error = Exception('boom');
        h.dictionary.error = error;

        await h.controller.open('木', _cn);

        expect(
          (h.state as LookupFailed).failure,
          DictionaryUnavailableFailure(cause: error),
        );
      },
    );

    test('can be tried again after a failure', () async {
      h.dictionary.error = const DictionaryUnavailableFailure();
      await h.controller.open('木', _cn);

      h.dictionary.error = null;
      await h.controller.open('木', _cn);

      expect(h.state, isA<LookupLoaded>());
    });
  });

  group('switching candidate', () {
    test('goes from one Loaded straight to Loaded for the new one', () async {
      await h.controller.open('語', _jp);
      h.states.clear();

      await h.controller.open('木', _jp);

      expect(h.states, [isA<LookupLoaded>()]);
      expect((h.state as LookupLoaded).character, '木');
    });

    test('keeps the old result while the new one is on its way', () async {
      await h.controller.open('語', _jp);
      h.dictionary.gates['木'] = Completer<void>();

      final pending = h.controller.open('木', _jp);

      expect((h.state as LookupLoaded).character, '語');
      h.dictionary.gates['木']!.complete();
      await pending;
      expect((h.state as LookupLoaded).character, '木');
    });

    test('switching to a character that is missing is NotFound', () async {
      await h.controller.open('語', _jp);

      await h.controller.open('水', _jp);

      expect(h.state, const LookupNotFound(character: '水', language: _jp));
    });
  });

  group('stale answers', () {
    test('an answer for a character the user left is dropped', () async {
      h.dictionary.gates['語'] = Completer<void>();
      final first = h.controller.open('語', _jp);
      await h.controller.open('木', _jp);

      h.dictionary.gates['語']!.complete();
      await first;

      expect((h.state as LookupLoaded).character, '木');
      expect(h.states.whereType<LookupLoaded>().map((s) => s.character), ['木']);
    });

    test('an answer that arrives after close is dropped', () async {
      h.dictionary.gates['語'] = Completer<void>();
      final pending = h.controller.open('語', _jp);

      h.controller.close();
      h.dictionary.gates['語']!.complete();
      await pending;

      expect(h.state, const LookupClosed());
    });

    test('does not throw when disposed while looking up', () async {
      h.dictionary.gates['語'] = Completer<void>();
      final pending = h.controller.open('語', _jp);

      h.container.dispose();
      h.dictionary.gates['語']!.complete();

      await expectLater(pending, completes);
    });
  });

  group('close', () {
    test('goes from Loaded to Closed', () async {
      await h.controller.open('語', _jp);

      h.controller.close();

      expect(h.state, const LookupClosed());
    });

    test('closing while loading goes straight to Closed', () async {
      h.dictionary.gates['語'] = Completer<void>();
      final pending = h.controller.open('語', _jp);
      expect(h.state, isA<LookupLoading>());

      h.controller.close();

      expect(h.state, const LookupClosed());
      h.dictionary.gates['語']!.complete();
      await pending;
    });

    test('closing when already closed changes nothing', () async {
      final before = h.states.length;

      h.controller.close();

      expect(h.states, hasLength(before));
    });
  });
}
