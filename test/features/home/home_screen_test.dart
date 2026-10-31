import 'package:character_lens/app.dart';
import 'package:character_lens/core/theme/app_theme.dart';
import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/features/home/home_screen.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/model_status.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/canvas/widgets/writing_pad.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:character_lens/features/result/controllers/explainer_provider.dart';
import 'package:character_lens/features/result/controllers/explanation_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_explainer.dart';
import '../../support/fake_explanation_cache.dart';
import '../../support/fake_ink_recognizer.dart';
import '../../support/fake_lookup_history.dart';
import '../../support/sample_entries.dart';

const _emptyHistory =
    'Characters you look up appear here, and open instantly offline.';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double textScale = 1,
  Size size = const Size(400, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inkRecognizerProvider.overrideWithValue(
          FakeInkRecognizer()
            ..statuses[InkLanguage.chinese] = const ModelReady(),
        ),
        dictionaryProvider.overrideWithValue(FakeDictionary.bare('木')),
        lookupHistoryProvider.overrideWithValue(FakeLookupHistory()),
        explainerProvider.overrideWithValue(FakeExplainer()),
        explanationCacheProvider.overrideWithValue(FakeExplanationCache()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const CharacterLensApp(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(WritingPad)));
}

void main() {
  group('the tabs', () {
    testWidgets('start on Write, with the history out of sight', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Character Lens'), findsOneWidget);
      expect(find.text(_emptyHistory), findsNothing);
    });

    testWidgets('History shows the history and hides the canvas', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('History'));
      await tester.pump();

      expect(find.text(_emptyHistory), findsOneWidget);
      expect(find.text('Character Lens'), findsNothing);
    });

    testWidgets('Write brings the canvas back', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('History'));
      await tester.pump();

      await tester.tap(find.text('Write'));
      await tester.pump();

      expect(find.text('Character Lens'), findsOneWidget);
      expect(find.text(_emptyHistory), findsNothing);
    });

    testWidgets('the strokes survive a visit to the history', (tester) async {
      final container = await _pump(tester);
      final origin = tester.getTopLeft(find.byType(WritingPad));
      final gesture = await tester.startGesture(origin + const Offset(60, 60));
      await gesture.moveBy(const Offset(40, 40));
      await gesture.up();
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pump();
      await tester.tap(find.text('Write'));
      await tester.pump();

      expect(container.read(canvasControllerProvider).strokes, isNotEmpty);
    });
  });

  group('the tab bar', () {
    testWidgets('is a normal bar, and leaves the page its room', (
      tester,
    ) async {
      await _pump(tester);

      final tab = tester.getSize(
        find.ancestor(of: find.text('Write'), matching: find.byType(InkWell)),
      );
      final page = tester.getSize(find.byType(IndexedStack));

      expect(tab.height, inInclusiveRange(48, 80));
      expect(page.height, greaterThan(800));
    });

    testWidgets('has tabs that are at least 48 dp', (tester) async {
      await _pump(tester);

      for (final label in ['Write', 'History']) {
        final size = tester.getSize(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
        );
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('marks the current tab, and lets a screen reader tap it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Write')),
        matchesSemantics(
          label: 'Write',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('History')),
        matchesSemantics(
          label: 'History',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a screen reader can switch tabs', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      tester.semantics.tap(find.semantics.byLabel('History'));
      await tester.pump();

      expect(find.text(_emptyHistory), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fits at 1.5x text on a narrow screen', (tester) async {
      await _pump(tester, textScale: 1.5, size: const Size(320, 1000));

      expect(tester.takeException(), isNull);
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });
  });

  group('the times in the history', () {
    testWidgets('are counted again each time the tab is shown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final opened = DateTime(2026, 10, 31, 12);
      var now = opened.add(const Duration(minutes: 1));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inkRecognizerProvider.overrideWithValue(
              FakeInkRecognizer()
                ..statuses[InkLanguage.chinese] = const ModelReady(),
            ),
            dictionaryProvider.overrideWithValue(
              FakeDictionary([SampleEntries.mu]),
            ),
            lookupHistoryProvider.overrideWithValue(
              FakeLookupHistory(
                entries: [
                  HistoryEntry(
                    character: '木',
                    language: InkLanguage.chinese,
                    openedAt: opened,
                  ),
                ],
              ),
            ),
            explainerProvider.overrideWithValue(FakeExplainer()),
            explanationCacheProvider.overrideWithValue(FakeExplanationCache()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: HomeScreen(clock: () => now),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pump();
      expect(find.text('1 min ago'), findsOneWidget);

      await tester.tap(find.text('Write'));
      await tester.pump();
      now = opened.add(const Duration(minutes: 10));
      await tester.tap(find.text('History'));
      await tester.pump();

      expect(find.text('10 min ago'), findsOneWidget);
      expect(find.text('1 min ago'), findsNothing);
    });
  });
}
