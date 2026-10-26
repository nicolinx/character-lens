import 'dart:async';

import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/stroke_point.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/domain/repositories/ink_recognizer.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Call = ({
  List<Stroke> strokes,
  InkLanguage language,
  WritingArea area,
});

class _FakeRecognizer implements InkRecognizer {
  List<Candidate> result = const [Candidate(character: '木')];
  Object? error;

  /// When set, recognition waits for it, which keeps the state Recognizing.
  Completer<void>? gate;
  final calls = <_Call>[];

  @override
  Future<List<Candidate>> recognize(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  }) async {
    calls.add((strokes: strokes, language: language, area: writingArea));
    await gate?.future;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<ModelStatus> modelStatus(InkLanguage language) =>
      throw UnimplementedError();

  @override
  Future<ModelStatus> downloadModel(InkLanguage language) =>
      throw UnimplementedError();
}

const _area = WritingArea(width: 300, height: 400);

StrokePoint _pt(double x, [int t = 0]) =>
    StrokePoint(x: x, y: 0, timestampMs: t);

class _Harness {
  _Harness({bool setArea = true}) {
    container = ProviderContainer(
      overrides: [inkRecognizerProvider.overrideWithValue(recognizer)],
    );
    container.listen(
      canvasControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    controller = container.read(canvasControllerProvider.notifier);
    if (setArea) controller.updateWritingArea(_area);
  }

  final recognizer = _FakeRecognizer();
  final states = <CanvasState>[];
  late final ProviderContainer container;
  late final CanvasController controller;

  CanvasState get state => container.read(canvasControllerProvider);

  /// Types of the states seen, without consecutive repeats.
  List<Type> get trail {
    final types = <Type>[];
    for (final s in states) {
      if (types.isEmpty || types.last != s.runtimeType) {
        types.add(s.runtimeType);
      }
    }
    return types;
  }

  /// One finished stroke of two points.
  void drawStroke(double x) {
    controller
      ..startStroke(_pt(x))
      ..addPoint(_pt(x + 1, 10))
      ..endStroke();
  }

  void dispose() => container.dispose();
}

void _test(String name, void Function(FakeAsync async, _Harness h) body) {
  test(name, () {
    fakeAsync((async) {
      final h = _Harness();
      body(async, h);
      h.dispose();
    });
  });
}

void main() {
  group('drawing', () {
    _test('starts idle, with no strokes, in Chinese', (async, h) {
      expect(h.state, CanvasIdle(language: InkLanguage.chinese));
    });

    _test('builds a stroke from start and added points', (async, h) {
      h.controller
        ..startStroke(_pt(1))
        ..addPoint(_pt(2, 10))
        ..addPoint(_pt(3, 20));

      expect(h.state.strokes, [
        Stroke([_pt(1), _pt(2, 10), _pt(3, 20)]),
      ]);
    });

    _test('ignores added points when no stroke was started', (async, h) {
      h.controller.addPoint(_pt(1));

      expect(h.state.strokes, isEmpty);
    });

    _test('ignores added points after the stroke ended', (async, h) {
      h.drawStroke(1);
      h.controller.addPoint(_pt(9));

      expect(h.state.strokes.single.points, hasLength(2));
    });
  });

  group('debounce', () {
    _test('recognizes 600 ms after the last stroke ends, not before', (
      async,
      h,
    ) {
      h.drawStroke(1);

      async.elapse(const Duration(milliseconds: 599));
      expect(h.recognizer.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(h.recognizer.calls, hasLength(1));
    });

    _test('a new stroke during the wait cancels and restarts it', (async, h) {
      h.drawStroke(1);
      async.elapse(const Duration(milliseconds: 400));
      h.drawStroke(5);

      async.elapse(const Duration(milliseconds: 400));
      expect(h.recognizer.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 200));
      expect(h.recognizer.calls, hasLength(1));
      expect(h.recognizer.calls.single.strokes, hasLength(2));
    });

    _test('no timer starts while the finger is still down', (async, h) {
      h.controller
        ..startStroke(_pt(1))
        ..addPoint(_pt(2, 10));

      async.elapse(const Duration(seconds: 2));

      expect(h.recognizer.calls, isEmpty);
    });

    _test('analyze cancels the pending wait so it runs only once', (async, h) {
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 2));

      expect(h.recognizer.calls, hasLength(1));
    });
  });

  group('analyze', () {
    _test('goes Idle, Recognizing, Result with the first candidate selected', (
      async,
      h,
    ) {
      h.recognizer.result = const [
        Candidate(character: '木'),
        Candidate(character: '本'),
      ];
      h.drawStroke(1);

      h.controller.analyze();
      async.flushMicrotasks();

      expect(h.trail, [CanvasIdle, CanvasRecognizing, CanvasResult]);
      final result = h.state as CanvasResult;
      expect(result.candidates.map((c) => c.character), ['木', '本']);
      expect(result.selectedIndex, 0);
      expect(result.selected, const Candidate(character: '木'));
    });

    _test('gives the recognizer the strokes, language and writing area', (
      async,
      h,
    ) {
      h.controller.selectLanguage(InkLanguage.japanese);
      h.drawStroke(1);

      h.controller.analyze();
      async.flushMicrotasks();

      final call = h.recognizer.calls.single;
      expect(call.language, InkLanguage.japanese);
      expect(call.area, _area);
      expect(call.strokes, h.state.strokes);
    });

    _test('goes Idle, Recognizing, Error when the recognizer fails', (
      async,
      h,
    ) {
      h.recognizer.error = const ModelNotDownloadedFailure(InkLanguage.chinese);
      h.drawStroke(1);

      h.controller.analyze();
      async.flushMicrotasks();

      expect(h.trail, [CanvasIdle, CanvasRecognizing, CanvasError]);
      expect(
        (h.state as CanvasError).failure,
        const ModelNotDownloadedFailure(InkLanguage.chinese),
      );
    });

    _test('wraps an unexpected exception in a RecognitionFailure', (async, h) {
      final error = Exception('boom');
      h.recognizer.error = error;
      h.drawStroke(1);

      h.controller.analyze();
      async.flushMicrotasks();

      expect(
        (h.state as CanvasError).failure,
        RecognitionFailure(cause: error),
      );
    });

    _test('turns an empty recognition into a NoCandidates error', (async, h) {
      h.recognizer.result = const [];
      h.drawStroke(1);

      h.controller.analyze();
      async.flushMicrotasks();

      expect(h.state, isA<CanvasError>());
      expect((h.state as CanvasError).failure, const NoCandidatesFailure());
      expect(h.state.strokes, hasLength(1));
    });

    _test('does nothing when there are no strokes', (async, h) {
      h.controller.analyze();
      async.flushMicrotasks();

      expect(h.recognizer.calls, isEmpty);
      expect(h.state, isA<CanvasIdle>());
    });

    _test('reports an error when the writing area was never set', (async, h) {
      final bare = _Harness(setArea: false);
      bare.drawStroke(1);

      bare.controller.analyze();
      async.flushMicrotasks();

      expect(bare.state, isA<CanvasError>());
      expect(bare.recognizer.calls, isEmpty);
      bare.dispose();
    });

    _test('a new stroke after a result goes back to Idle and keeps strokes', (
      async,
      h,
    ) {
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();
      expect(h.state, isA<CanvasResult>());

      h.controller.startStroke(_pt(5));

      expect(h.state, isA<CanvasIdle>());
      expect(h.state.strokes, hasLength(2));
    });

    _test('does not throw when disposed while recognizing', (async, h) {
      h.recognizer.gate = Completer<void>();
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      h.container.dispose();
      h.recognizer.gate!.complete();
      async.flushMicrotasks();
    });
  });

  group('input lock while recognizing', () {
    _test('ignores every input until recognition finishes', (async, h) {
      h.recognizer.gate = Completer<void>();
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();
      final locked = h.state;
      expect(locked, isA<CanvasRecognizing>());

      h.controller
        ..startStroke(_pt(7))
        ..addPoint(_pt(8))
        ..endStroke()
        ..undo()
        ..clear()
        ..selectLanguage(InkLanguage.japanese)
        ..selectCandidate(0);
      h.controller.analyze();
      async.elapse(const Duration(seconds: 2));

      expect(h.state, locked);
      expect(h.recognizer.calls, hasLength(1));

      h.recognizer.gate!.complete();
      async.flushMicrotasks();
      expect(h.state, isA<CanvasResult>());
    });
  });

  group('undo, clear and language', () {
    _test('undo removes the last stroke and returns to Idle', (async, h) {
      h.drawStroke(1);
      h.drawStroke(5);
      h.controller.analyze();
      async.flushMicrotasks();

      h.controller.undo();

      expect(h.state, isA<CanvasIdle>());
      expect(h.state.strokes, hasLength(1));
      expect(h.state.strokes.single.points.first.x, 1);
    });

    _test('undo with no strokes does nothing', (async, h) {
      h.controller.undo();

      expect(h.state, CanvasIdle(language: InkLanguage.chinese));
    });

    _test('clear removes all strokes and cancels the pending recognition', (
      async,
      h,
    ) {
      h.drawStroke(1);

      h.controller.clear();
      async.elapse(const Duration(seconds: 2));

      expect(h.state, CanvasIdle(language: InkLanguage.chinese));
      expect(h.recognizer.calls, isEmpty);
    });

    _test('clear resets a result back to Idle', (async, h) {
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      h.controller.clear();

      expect(h.state, CanvasIdle(language: InkLanguage.chinese));
    });

    _test('switching language clears the strokes and keeps the new language', (
      async,
      h,
    ) {
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      h.controller.selectLanguage(InkLanguage.japanese);

      expect(h.state, CanvasIdle(language: InkLanguage.japanese));
    });

    _test('selecting the current language keeps the strokes', (async, h) {
      h.drawStroke(1);

      h.controller.selectLanguage(InkLanguage.chinese);

      expect(h.state.strokes, hasLength(1));
    });
  });

  group('writing area', () {
    _test('a different size clears the strokes', (async, h) {
      h.drawStroke(1);

      h.controller.updateWritingArea(
        const WritingArea(width: 200, height: 200),
      );

      expect(h.state, CanvasIdle(language: InkLanguage.chinese));
    });

    _test('the same size keeps the strokes', (async, h) {
      h.drawStroke(1);

      h.controller.updateWritingArea(_area);

      expect(h.state.strokes, hasLength(1));
    });

    _test('a size set for the first time keeps the strokes', (async, h) {
      final bare = _Harness(setArea: false);
      bare.drawStroke(1);

      bare.controller.updateWritingArea(_area);

      expect(bare.state.strokes, hasLength(1));
      bare.dispose();
    });

    _test('a new size cancels the pending recognition', (async, h) {
      h.drawStroke(1);

      h.controller.updateWritingArea(
        const WritingArea(width: 200, height: 200),
      );
      async.elapse(const Duration(seconds: 2));

      expect(h.recognizer.calls, isEmpty);
    });
  });

  group('selectCandidate', () {
    _test('changes the selected index of a result', (async, h) {
      h.recognizer.result = const [
        Candidate(character: '木'),
        Candidate(character: '本'),
      ];
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      h.controller.selectCandidate(1);

      expect((h.state as CanvasResult).selected.character, '本');
    });

    _test('ignores an index outside the candidates', (async, h) {
      h.drawStroke(1);
      h.controller.analyze();
      async.flushMicrotasks();

      h.controller
        ..selectCandidate(5)
        ..selectCandidate(-1);

      expect((h.state as CanvasResult).selectedIndex, 0);
    });

    _test('is ignored when there is no result', (async, h) {
      h.controller.selectCandidate(0);

      expect(h.state, isA<CanvasIdle>());
    });
  });
}
