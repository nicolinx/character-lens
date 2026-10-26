import 'package:character_lens/app.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/canvas/widgets/writing_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_ink_recognizer.dart';

class _Pad {
  _Pad(this.tester, this.recognizer, this.container);

  final WidgetTester tester;
  final FakeInkRecognizer recognizer;
  final ProviderContainer container;

  CanvasState get state => container.read(canvasControllerProvider);
  Finder get pad => find.byType(WritingPad);
  Offset get topLeft => tester.getTopLeft(pad);
}

Future<_Pad> _pump(
  WidgetTester tester, {
  bool modelReady = true,
  Size? surface,
}) async {
  if (surface != null) {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final recognizer = FakeInkRecognizer();
  if (modelReady) {
    recognizer.statuses[InkLanguage.chinese] = const ModelReady();
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inkRecognizerProvider.overrideWithValue(recognizer)],
      child: const CharacterLensApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _Pad(
    tester,
    recognizer,
    ProviderScope.containerOf(tester.element(find.byType(WritingPad))),
  );
}

void main() {
  testWidgets('a drag becomes one stroke with the points in pad coordinates', (
    tester,
  ) async {
    final p = await _pump(tester);
    final start = p.pad.evaluate().isEmpty ? Offset.zero : p.topLeft;

    final gesture = await tester.startGesture(start + const Offset(52, 62));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final stroke = p.state.strokes.single;
    expect(stroke.points, hasLength(3));
    // The pad has a 2 dp border, so pad coordinates start 2 dp in.
    expect(stroke.points.first.x, closeTo(50, 0.01));
    expect(stroke.points.first.y, closeTo(60, 0.01));
    expect(stroke.points.last.x, closeTo(70, 0.01));
    expect(stroke.points.last.y, closeTo(90, 0.01));
  });

  testWidgets('recognition runs after the pause, with the pad size', (
    tester,
  ) async {
    final p = await _pump(tester);

    final gesture = await tester.startGesture(p.topLeft + const Offset(60, 60));
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 599));
    expect(p.recognizer.areas, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    final inner = tester.getSize(find.byType(LayoutBuilder).last);
    expect(
      p.recognizer.areas.single,
      WritingArea(width: inner.width, height: inner.height),
    );
    expect(p.state, isA<CanvasResult>());
  });

  testWidgets('nothing is drawn while the model is missing', (tester) async {
    final p = await _pump(tester, modelReady: false);

    final gesture = await tester.startGesture(p.topLeft + const Offset(60, 60));
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(p.state.strokes, isEmpty);
    expect(p.recognizer.areas, isEmpty);
  });

  testWidgets('a second finger is ignored while the first one draws', (
    tester,
  ) async {
    final p = await _pump(tester);

    final first = await tester.startGesture(
      p.topLeft + const Offset(60, 60),
      pointer: 11,
    );
    final at = p.topLeft + const Offset(150, 150);
    tester.binding.handlePointerEvent(
      PointerDownEvent(pointer: 12, position: at),
    );
    tester.binding.handlePointerEvent(
      PointerMoveEvent(
        pointer: 12,
        position: at + const Offset(20, 20),
        delta: const Offset(20, 20),
      ),
    );
    await first.moveBy(const Offset(10, 10));
    tester.binding.handlePointerEvent(
      PointerUpEvent(pointer: 12, position: at + const Offset(20, 20)),
    );
    await first.up();
    await tester.pump(const Duration(seconds: 1));

    final stroke = p.state.strokes.single;
    expect(stroke.points, hasLength(2));
    expect(stroke.points.first.x, closeTo(58, 0.01));
  });

  testWidgets('a vertical stroke draws and does not scroll the page', (
    tester,
  ) async {
    final p = await _pump(tester);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    final gesture = await tester.startGesture(
      p.topLeft + const Offset(60, 300),
    );
    await gesture.moveBy(const Offset(0, -40));
    await gesture.moveBy(const Offset(0, -40));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(scrollable.position.pixels, 0);
    expect(p.state.strokes.single.points, hasLength(3));
  });

  testWidgets('a finger that leaves the pad stays on its edge', (tester) async {
    final p = await _pump(tester);
    final size = tester.getSize(find.byType(LayoutBuilder).last);

    final gesture = await tester.startGesture(p.topLeft + const Offset(60, 60));
    await gesture.moveBy(const Offset(2000, 0));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(p.state.strokes.single.points.last.x, size.width);
  });

  testWidgets('the prompt hides once there are strokes', (tester) async {
    final p = await _pump(tester);
    expect(find.text('Write one character'), findsOneWidget);

    final gesture = await tester.startGesture(p.topLeft + const Offset(60, 60));
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Write one character'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a new pad size clears the strokes and reports the new area', (
    tester,
  ) async {
    final p = await _pump(tester, surface: const Size(400, 800));
    final gesture = await tester.startGesture(p.topLeft + const Offset(60, 60));
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(p.state.strokes, hasLength(1));

    await tester.binding.setSurfaceSize(const Size(300, 800));
    await tester.pump();
    await tester.pump();

    expect(p.state.strokes, isEmpty);
    expect(find.byType(WritingPad), findsOneWidget);
  });

  testWidgets('the light theme is the only theme', (tester) async {
    await _pump(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.themeMode, ThemeMode.light);
    expect(app.theme!.brightness, Brightness.light);
  });
}
