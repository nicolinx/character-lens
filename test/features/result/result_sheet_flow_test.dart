import 'dart:async';

import 'package:character_lens/app.dart';
import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/failures/dictionary_failure.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/canvas/widgets/writing_pad.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/speech_controller.dart';
import 'package:character_lens/features/result/controllers/speech_state.dart';
import 'package:character_lens/features/result/controllers/tts_service_provider.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/repositories/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_ink_recognizer.dart';
import '../../support/fake_tts_service.dart';
import '../../support/sample_entries.dart';

class _Screen {
  _Screen(this.tester, this.container, this.dictionary, this.tts);

  final WidgetTester tester;
  final ProviderContainer container;
  final FakeDictionary dictionary;
  final FakeTtsService tts;

  CanvasState get canvas => container.read(canvasControllerProvider);
  LookupState get lookup => container.read(lookupControllerProvider);

  Future<void> drawAndRecognize() async {
    final origin = tester.getTopLeft(find.byType(WritingPad));
    final gesture = await tester.startGesture(origin + const Offset(60, 60));
    await gesture.moveBy(const Offset(40, 40));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> tapLookUp(String character) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Look up $character'));
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet() async {
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
  }
}

Future<_Screen> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final recognizer = FakeInkRecognizer()
    ..statuses[InkLanguage.chinese] = const ModelReady()
    ..candidates = const [Candidate(character: '語'), Candidate(character: '学')];
  final dictionary = FakeDictionary([
    SampleEntries.go,
    SampleEntries.goSimplified,
    SampleEntries.gaku,
    SampleEntries.gakuTraditional,
  ]);
  final tts = FakeTtsService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inkRecognizerProvider.overrideWithValue(recognizer),
        dictionaryProvider.overrideWithValue(dictionary),
        ttsServiceProvider.overrideWithValue(tts),
      ],
      child: const CharacterLensApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _Screen(
    tester,
    ProviderScope.containerOf(tester.element(find.byType(WritingPad))),
    dictionary,
    tts,
  );
}

void main() {
  group('the main button', () {
    testWidgets('says Analyze until there is a result', (tester) async {
      final screen = await _pump(tester);

      expect(find.widgetWithText(FilledButton, 'Analyze'), findsOneWidget);

      await screen.drawAndRecognize();

      expect(find.widgetWithText(FilledButton, 'Analyze'), findsNothing);
    });

    testWidgets('then says Look up, with the selected character', (
      tester,
    ) async {
      final screen = await _pump(tester);

      await screen.drawAndRecognize();

      expect(find.widgetWithText(FilledButton, 'Look up 語'), findsOneWidget);
    });

    testWidgets('goes back to Analyze when the strokes are cleared', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();

      await tester.tap(find.byTooltip('Clear canvas'));
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Analyze'), findsOneWidget);
    });
  });

  group('the sheet', () {
    testWidgets('opens with the dictionary card for the selected character', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();

      await screen.tapLookUp('語');

      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.text('Verified · Unihan'), findsOneWidget);
      expect(find.text('yǔ'), findsWidgets);
      expect(screen.lookup, isA<LookupLoaded>());
    });

    testWidgets('closing it leaves the strokes and the candidates alone', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();
      final before = screen.canvas as CanvasResult;
      await screen.tapLookUp('語');

      await screen.closeSheet();

      expect(find.text('Dictionary'), findsNothing);
      expect(screen.lookup, const LookupClosed());
      final after = screen.canvas as CanvasResult;
      expect(after.strokes, before.strokes);
      expect(after.candidates, before.candidates);
      expect(find.widgetWithText(FilledButton, 'Look up 語'), findsOneWidget);
    });

    testWidgets('tapping outside it closes it too', (tester) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');

      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(find.text('Dictionary'), findsNothing);
      expect(screen.lookup, const LookupClosed());
    });

    testWidgets('"Not it?" switches the match and selects it on the canvas', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');

      await tester.tap(find.byKey(const Key('switch-学')));
      await tester.pumpAndSettle();

      expect((screen.lookup as LookupLoaded).character, '学');
      expect(find.text('xué'), findsWidgets);
      expect((screen.canvas as CanvasResult).selectedIndex, 1);

      await screen.closeSheet();
      expect(find.widgetWithText(FilledButton, 'Look up 学'), findsOneWidget);
    });

    testWidgets('a dictionary that cannot be read shows a retry that works', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();
      screen.dictionary.lookupErrors['語'] =
          const DictionaryUnavailableFailure();

      await screen.tapLookUp('語');

      expect(find.text('The dictionary could not be opened'), findsOneWidget);

      screen.dictionary.lookupErrors.clear();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.text('The dictionary could not be opened'), findsNothing);
    });
  });

  group('the speaker button', () {
    testWidgets('speaks the written form in the language drawn', (
      tester,
    ) async {
      final screen = await _pump(tester);
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');

      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pumpAndSettle();

      // The fake recognizer draws in Chinese, so the form is simplified.
      expect(screen.tts.spoken, [('语', HanLanguage.chinese)]);
    });

    testWidgets('shows a note when no voice is installed', (tester) async {
      final screen = await _pump(tester);
      screen.tts.result = SpeakResult.noVoice;
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');

      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pumpAndSettle();

      expect(find.text('No voice installed for this language'), findsOneWidget);
    });

    testWidgets('closing the sheet stops the speech', (tester) async {
      final screen = await _pump(tester);
      screen.tts.gate = Completer<void>();
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');
      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();
      expect(find.byTooltip('Stop pronunciation'), findsOneWidget);

      await screen.closeSheet();

      expect(screen.tts.stops, 1);
      expect(
        screen.container.read(speechControllerProvider),
        const SpeechIdle(),
      );
      screen.tts.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('switching candidate stops the speech', (tester) async {
      final screen = await _pump(tester);
      screen.tts.gate = Completer<void>();
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');
      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('switch-学')));
      await tester.pumpAndSettle();

      expect(screen.tts.stops, 1);
      expect(find.byTooltip('Play pronunciation'), findsOneWidget);
      screen.tts.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a note about no voice is gone after switching candidate', (
      tester,
    ) async {
      final screen = await _pump(tester);
      screen.tts.result = SpeakResult.noVoice;
      await screen.drawAndRecognize();
      await screen.tapLookUp('語');
      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('switch-学')));
      await tester.pumpAndSettle();

      expect(find.text('No voice installed for this language'), findsNothing);
    });
  });
}
