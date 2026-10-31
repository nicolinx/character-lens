import 'dart:async';

import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/history/controllers/history_controller.dart';
import 'package:character_lens/features/history/controllers/history_state.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_dictionary.dart';
import '../../../support/fake_lookup_history.dart';
import '../../../support/sample_entries.dart';

const _cn = InkLanguage.chinese;
const _jp = InkLanguage.japanese;

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        dictionaryProvider.overrideWithValue(dictionary),
        lookupHistoryProvider.overrideWithValue(history),
      ],
    );
    lookup = container.read(lookupControllerProvider.notifier);
  }

  /// Creates the history controller. Called after a test has set up its fakes,
  /// because the controller loads as soon as it exists.
  void start() => container.listen(
    historyControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  final dictionary = FakeDictionary([
    SampleEntries.mu,
    SampleEntries.go,
    SampleEntries.goSimplified,
  ]);
  final history = FakeLookupHistory();
  final states = <HistoryState>[];
  late final ProviderContainer container;
  late final LookupController lookup;

  HistoryState get state => container.read(historyControllerProvider);

  List<String> get characters => [
    for (final item in (state as HistoryLoaded).items) item.entry.character,
  ];

  Future<void> settle() => pumpEventQueue();
}

void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.container.dispose());

  group('loading', () {
    test('starts Loading, then shows the history', () async {
      h.start();
      expect(h.state, const HistoryLoading());

      await h.settle();

      expect(h.state, const HistoryLoaded([]));
    });

    test('lists what was already there, with the dictionary views', () async {
      h.history.entries.add(
        HistoryEntry(
          character: '語',
          language: _cn,
          openedAt: DateTime.utc(2026, 10, 31),
        ),
      );

      h.start();
      await h.settle();

      final item = (h.state as HistoryLoaded).items.single;
      expect(item.entry.character, '語');
      expect(item.view!.form, '语');
    });

    test('a history that cannot be read is Unavailable', () async {
      h.history.recentError = const LookupHistoryUnavailableFailure();

      h.start();
      await h.settle();

      expect(
        h.state,
        const HistoryUnavailable(LookupHistoryUnavailableFailure()),
      );
    });

    test('refresh recovers once the history can be read again', () async {
      h.history.recentError = const LookupHistoryUnavailableFailure();
      h.start();
      await h.settle();

      h.history.recentError = null;
      await h.container.read(historyControllerProvider.notifier).refresh();

      expect(h.state, isA<HistoryLoaded>());
    });
  });

  group('recording', () {
    setUp(() => h.start());

    test('notes a character once its entry is loaded', () async {
      await h.settle();

      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.history.recorded, [('木', _cn)]);
      expect(h.characters, ['木']);
    });

    test('notes the language the character was drawn in', () async {
      await h.settle();

      await h.lookup.open('語', _jp);
      await h.settle();

      expect(h.history.recorded, [('語', _jp)]);
      expect(
        (h.state as HistoryLoaded).items.single.view!.selected,
        HanLanguage.japanese,
      );
    });

    test('puts the newest first and moves a repeat to the top', () async {
      await h.settle();

      await h.lookup.open('木', _cn);
      await h.lookup.open('語', _cn);
      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.characters, ['木', '語']);
    });

    test('also notes the character the user switches to', () async {
      await h.settle();

      await h.lookup.open('語', _cn);
      await h.lookup.open('木', _cn);
      await h.settle();

      expect(h.characters, ['木', '語']);
    });

    test('does not note a character the dictionary does not have', () async {
      await h.settle();

      await h.lookup.open('水', _cn);
      await h.settle();

      expect(h.history.recorded, isEmpty);
    });

    test(
      'does not note a lookup that failed, or one that is only loading',
      () async {
        await h.settle();
        h.dictionary.gates['木'] = Completer<void>();

        final opening = h.lookup.open('木', _cn);
        await h.settle();
        expect(h.history.recorded, isEmpty);

        h.lookup.close();
        h.dictionary.gates['木']!.complete();
        await opening;
        await h.settle();
        expect(h.history.recorded, isEmpty);

        h.dictionary.error = Exception('boom');
        await h.lookup.open('語', _cn);
        await h.settle();
        expect(h.history.recorded, isEmpty);
      },
    );

    test('closing the sheet notes nothing more', () async {
      await h.settle();
      await h.lookup.open('木', _cn);
      await h.settle();

      h.lookup.close();
      await h.settle();

      expect(h.history.recorded, hasLength(1));
    });

    test(
      'a history that cannot be written does not break the lookup',
      () async {
        await h.settle();
        h.history.recordError = const LookupHistoryUnavailableFailure();

        await h.lookup.open('木', _cn);
        await h.settle();

        expect(h.state, isA<HistoryLoaded>());
      },
    );
  });
}
