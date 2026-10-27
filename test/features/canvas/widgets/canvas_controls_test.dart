import 'dart:async';

import 'package:character_lens/app.dart';
import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/canvas/widgets/writing_pad.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_dictionary.dart';
import '../../../support/fake_ink_recognizer.dart';

class _Screen {
  _Screen(this.tester, this.recognizer, this.container);

  final WidgetTester tester;
  final FakeInkRecognizer recognizer;
  final ProviderContainer container;

  CanvasState get state => container.read(canvasControllerProvider);

  Future<void> draw({bool pause = true}) async {
    final origin = tester.getTopLeft(find.byType(WritingPad));
    final gesture = await tester.startGesture(origin + const Offset(60, 60));
    await gesture.moveBy(const Offset(40, 40));
    await gesture.up();
    await tester.pump();
    if (pause) await settle();
  }

  Future<void> settle() async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> tapButton(String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pump();
  }
}

Future<_Screen> _pump(
  WidgetTester tester, {
  FakeInkRecognizer? recognizer,
  double textScale = 1,
  bool modelReady = true,
}) async {
  // Tall enough that the controls under the pad are on screen.
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fake = recognizer ?? FakeInkRecognizer();
  if (modelReady) fake.statuses[InkLanguage.chinese] = const ModelReady();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inkRecognizerProvider.overrideWithValue(fake),
        dictionaryProvider.overrideWithValue(FakeDictionary.bare('木末本朮禾')),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const CharacterLensApp(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _Screen(
    tester,
    fake,
    ProviderScope.containerOf(tester.element(find.byType(WritingPad))),
  );
}

bool _enabled(WidgetTester tester, Finder finder) {
  // A tooltip finder matches the wrapper, so look for the button inside it.
  final button = find.descendant(
    of: finder,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    matchRoot: true,
  );
  return tester
      .widget<ButtonStyleButton>(
        button.evaluate().isNotEmpty
            ? button
            : find.ancestor(
                of: finder,
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
      )
      .enabled;
}

Finder _chipOf(String c) =>
    find.ancestor(of: find.text(c), matching: find.byType(Container)).first;

Finder get _analyze => find.widgetWithText(FilledButton, 'Analyze');

void main() {
  group('status line', () {
    testWidgets('invites drawing when the pad is empty', (tester) async {
      await _pump(tester);

      expect(find.text('Ready. Draw one character'), findsOneWidget);
    });

    testWidgets('asks for the model when it is missing', (tester) async {
      await _pump(tester, modelReady: false);

      expect(find.text('Download the model to start drawing'), findsOneWidget);
    });

    testWidgets('says it will recognize once strokes exist', (tester) async {
      final s = await _pump(tester);

      await s.draw(pause: false);

      expect(find.textContaining('Pause and I'), findsOneWidget);
    });

    testWidgets('shows Recognizing while the recognizer works', (tester) async {
      final fake = FakeInkRecognizer()..recognizeGate = Completer<void>();
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(find.text('Recognizing…'), findsNWidgets(2)); // status + button
    });

    testWidgets('an empty recognition is a readable error', (tester) async {
      final fake = FakeInkRecognizer()..candidates = const [];
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(s.state, isA<CanvasError>());
      expect(find.text('No match. Try writing it larger'), findsOneWidget);
    });

    testWidgets('a recognizer error is a readable error', (tester) async {
      final fake = FakeInkRecognizer()..recognizeError = Exception('boom');
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(s.state, isA<CanvasError>());
      expect(find.text('Recognition failed. Try again'), findsOneWidget);
    });

    testWidgets('a missing model reported by the recognizer is readable', (
      tester,
    ) async {
      final fake = FakeInkRecognizer()
        ..recognizeError = const ModelNotDownloadedFailure(InkLanguage.chinese);
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(find.text('Download the Chinese model first'), findsOneWidget);
    });
  });

  group('undo and clear', () {
    testWidgets('are disabled while the pad is empty', (tester) async {
      await _pump(tester);

      expect(_enabled(tester, find.byTooltip('Undo last stroke')), isFalse);
      expect(_enabled(tester, find.byTooltip('Clear canvas')), isFalse);
    });

    testWidgets('undo removes the last stroke', (tester) async {
      final s = await _pump(tester);
      await s.draw(pause: false);
      await s.draw(pause: false);
      expect(s.state.strokes, hasLength(2));

      await s.tapButton('Undo last stroke');

      expect(s.state.strokes, hasLength(1));
    });

    testWidgets('clear empties the pad and the candidates', (tester) async {
      final s = await _pump(tester);
      await s.draw();
      expect(s.state, isA<CanvasResult>());

      await s.tapButton('Clear canvas');

      expect(s.state.strokes, isEmpty);
      expect(find.text('Matches appear here after you draw'), findsOneWidget);
    });

    testWidgets('are disabled while recognizing', (tester) async {
      final fake = FakeInkRecognizer()..recognizeGate = Completer<void>();
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(_enabled(tester, find.byTooltip('Undo last stroke')), isFalse);
      expect(_enabled(tester, find.byTooltip('Clear canvas')), isFalse);
    });
  });

  group('candidate chips', () {
    FakeInkRecognizer five() => FakeInkRecognizer()
      ..candidates = const [
        Candidate(character: '木'),
        Candidate(character: '末'),
        Candidate(character: '本'),
        Candidate(character: '朮'),
        Candidate(character: '禾'),
      ];

    testWidgets('show the empty message before a result', (tester) async {
      await _pump(tester);

      expect(find.text('Matches appear here after you draw'), findsOneWidget);
    });

    testWidgets('render from a result, first one selected', (tester) async {
      final s = await _pump(tester, recognizer: five());

      await s.draw();

      for (final c in ['木', '末', '本', '朮', '禾']) {
        expect(find.text(c), findsOneWidget);
      }
      expect((s.state as CanvasResult).selectedIndex, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Candidate 1: 木')),
        matchesSemantics(
          label: 'Candidate 1: 木',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: false,
        ),
      );
    });

    testWidgets('tapping a chip selects it', (tester) async {
      final s = await _pump(tester, recognizer: five());
      await s.draw();

      await tester.tap(find.text('本'));
      await tester.pump();

      expect((s.state as CanvasResult).selectedIndex, 2);
      expect(s.state.strokes, hasLength(1));
    });

    testWidgets('sit side by side, as wide as their character', (tester) async {
      final s = await _pump(tester, recognizer: five());
      await s.draw();

      final tops = [
        for (final c in ['木', '末', '本', '朮', '禾'])
          tester.getTopLeft(find.text(c)).dy,
      ];
      expect(tops.toSet(), hasLength(1), reason: 'one row');
      expect(tester.getSize(_chipOf('木')).width, lessThan(80));
    });

    testWidgets('are at least 48 dp square', (tester) async {
      final s = await _pump(tester, recognizer: five());
      await s.draw();

      for (final c in ['木', '末', '本', '朮', '禾']) {
        final size = tester.getSize(
          find
              .ancestor(of: find.text(c), matching: find.byType(Container))
              .first,
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('analyze button', () {
    testWidgets('is disabled with nothing drawn', (tester) async {
      await _pump(tester);

      expect(_enabled(tester, _analyze), isFalse);
    });

    testWidgets('recognizes without waiting for the pause', (tester) async {
      final s = await _pump(tester);
      await s.draw(pause: false);
      expect(s.state, isA<CanvasIdle>());

      await tester.tap(_analyze);
      await tester.pump();
      await tester.pump();

      expect(s.state, isA<CanvasResult>());
      expect(s.recognizer.areas, hasLength(1));
    });

    testWidgets('is disabled while recognizing', (tester) async {
      final fake = FakeInkRecognizer()..recognizeGate = Completer<void>();
      final s = await _pump(tester, recognizer: fake);

      await s.draw();

      expect(
        _enabled(tester, find.widgetWithText(FilledButton, 'Recognizing…')),
        isFalse,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('retries after an error', (tester) async {
      final fake = FakeInkRecognizer()..recognizeError = Exception('boom');
      final s = await _pump(tester, recognizer: fake);
      await s.draw();
      expect(s.state, isA<CanvasError>());

      fake.recognizeError = null;
      await tester.tap(_analyze);
      await tester.pump();
      await tester.pump();

      expect(s.state, isA<CanvasResult>());
    });
  });

  testWidgets('every control stays usable at 1.5x text scale', (tester) async {
    final fake = FakeInkRecognizer()
      ..candidates = const [
        Candidate(character: '木'),
        Candidate(character: '末'),
        Candidate(character: '本'),
        Candidate(character: '朮'),
        Candidate(character: '禾'),
      ];
    final s = await _pump(tester, recognizer: fake, textScale: 1.5);
    await s.draw();

    expect(tester.takeException(), isNull);
    expect(find.text('Pick the match'), findsOneWidget);
    expect(find.byTooltip('Undo last stroke'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Look up 木'), findsOneWidget);
  });
}
