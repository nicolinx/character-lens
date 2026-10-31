import 'package:character_lens/core/theme/app_theme.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:character_lens/features/history/history_screen.dart';
import 'package:character_lens/features/result/controllers/explainer_provider.dart';
import 'package:character_lens/features/result/controllers/explanation_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_explainer.dart';
import '../../support/fake_explanation_cache.dart';
import '../../support/fake_lookup_history.dart';
import '../../support/sample_entries.dart';

HistoryEntry _entry(
  String character,
  InkLanguage language, {
  Duration ago = const Duration(minutes: 5),
}) => HistoryEntry(
  character: character,
  language: language,
  openedAt: DateTime.now().subtract(ago),
);

class _Screen {
  final history = FakeLookupHistory();
  final explainer = FakeExplainer();
  final cache = FakeExplanationCache();
}

Future<_Screen> _pump(
  WidgetTester tester, {
  List<HistoryEntry> entries = const [],
  Object? recentError,
  double textScale = 1,
  Size size = const Size(400, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final screen = _Screen()
    ..history.entries.addAll(entries)
    ..history.recentError = recentError;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dictionaryProvider.overrideWithValue(
          FakeDictionary([
            SampleEntries.mu,
            SampleEntries.go,
            SampleEntries.goSimplified,
          ]),
        ),
        lookupHistoryProvider.overrideWithValue(screen.history),
        explainerProvider.overrideWithValue(screen.explainer),
        explanationCacheProvider.overrideWithValue(screen.cache),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HistoryScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return screen;
}

void main() {
  group('empty', () {
    testWidgets('says where characters will appear', (tester) async {
      await _pump(tester);

      expect(find.text('History'), findsOneWidget);
      expect(
        find.text(
          'Characters you look up appear here, and open instantly offline.',
        ),
        findsOneWidget,
      );
    });
  });

  group('with entries', () {
    testWidgets('counts them', (tester) async {
      await _pump(
        tester,
        entries: [
          _entry('木', InkLanguage.chinese),
          _entry('語', InkLanguage.japanese),
        ],
      );

      expect(find.text('2 characters · saved on this device'), findsOneWidget);
    });

    testWidgets('says "1 character", not "1 characters"', (tester) async {
      await _pump(tester, entries: [_entry('木', InkLanguage.chinese)]);

      expect(find.text('1 character · saved on this device'), findsOneWidget);
    });

    testWidgets('a tile shows the form, the reading, the meaning, the language '
        'and when', (tester) async {
      await _pump(tester, entries: [_entry('語', InkLanguage.chinese)]);

      expect(find.text('语'), findsOneWidget);
      expect(find.text('yǔ'), findsOneWidget);
      expect(find.text('language, words; saying, expression'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
      expect(find.text('5 min ago'), findsOneWidget);
    });

    testWidgets('a Japanese tile shows the on and kun readings', (
      tester,
    ) async {
      await _pump(tester, entries: [_entry('語', InkLanguage.japanese)]);

      expect(find.text('語'), findsOneWidget);
      expect(find.text('GO, GYO · KATARU, KOTOBA, TSUGERU'), findsOneWidget);
      expect(find.text('JP'), findsOneWidget);
    });

    testWidgets('keeps the order it is given', (tester) async {
      await _pump(
        tester,
        entries: [
          _entry('木', InkLanguage.chinese),
          _entry('語', InkLanguage.chinese),
        ],
      );

      final first = tester.getTopLeft(find.text('木')).dy;
      final second = tester.getTopLeft(find.text('语')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('a character the dictionary no longer has is still listed', (
      tester,
    ) async {
      await _pump(tester, entries: [_entry('水', InkLanguage.chinese)]);

      expect(find.text('水'), findsOneWidget);
      expect(find.text('Dictionary data is not available'), findsOneWidget);
    });

    testWidgets('a tile is labeled for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, entries: [_entry('語', InkLanguage.chinese)]);

      expect(
        find.bySemanticsLabel('Open 語, Chinese, 5 min ago'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a screen reader can open a tile', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, entries: [_entry('語', InkLanguage.chinese)]);

      tester.semantics.tap(
        find.semantics.byLabel('Open 語, Chinese, 5 min ago'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified · Unihan'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a tile is at least 48 dp tall', (tester) async {
      await _pump(tester, entries: [_entry('木', InkLanguage.chinese)]);

      final size = tester.getSize(find.byType(InkWell).first);
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('fits at 1.5x text on a narrow screen', (tester) async {
      await _pump(
        tester,
        entries: [
          _entry('語', InkLanguage.japanese),
          _entry('木', InkLanguage.chinese, ago: const Duration(days: 12)),
        ],
        textScale: 1.5,
        size: const Size(320, 1000),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('when the history cannot be read', () {
    testWidgets('says so quietly', (tester) async {
      await _pump(tester, recentError: const LookupHistoryUnavailableFailure());

      expect(find.text('History is not available right now.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('tapping a tile', () {
    testWidgets('opens the sheet with the dictionary card', (tester) async {
      await _pump(tester, entries: [_entry('語', InkLanguage.chinese)]);

      await tester.tap(find.text('语'));
      await tester.pumpAndSettle();

      expect(find.text('Verified · Unihan'), findsOneWidget);
      expect(find.text('Explain it'), findsOneWidget);
    });

    testWidgets('has no "Not it?" list, there is nothing to switch to', (
      tester,
    ) async {
      await _pump(tester, entries: [_entry('語', InkLanguage.chinese)]);

      await tester.tap(find.text('语'));
      await tester.pumpAndSettle();

      expect(find.text('Not it?'), findsNothing);
    });

    testWidgets('shows the cached explanation without asking the explainer', (
      tester,
    ) async {
      final screen = await _pump(
        tester,
        entries: [_entry('語', InkLanguage.chinese)],
      );
      screen.cache.entries[const ExplanationKey(
        character: '語',
        language: HanLanguage.chinese,
        promptVersion: 'prompt_test',
      )] = const Explanation(
        components: [],
        mnemonic: 'From an earlier visit.',
        examples: [],
      );

      await tester.tap(find.text('语'));
      await tester.pumpAndSettle();

      expect(find.text('From an earlier visit.'), findsOneWidget);
      expect(screen.explainer.calls, isEmpty);
    });

    testWidgets('moves the character to the top of the history', (
      tester,
    ) async {
      final screen = await _pump(
        tester,
        entries: [
          _entry('木', InkLanguage.chinese),
          _entry('語', InkLanguage.chinese),
        ],
      );

      await tester.tap(find.text('语'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect([for (final e in screen.history.entries) e.character], ['語', '木']);
      expect(screen.history.recorded, [('語', InkLanguage.chinese)]);
    });
  });
}
