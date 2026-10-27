import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/stroke_point.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/recognize_characters_provider.dart';

final canvasControllerProvider =
    NotifierProvider<CanvasController, CanvasState>(CanvasController.new);

class CanvasController extends Notifier<CanvasState> {
  static const debounce = Duration(milliseconds: 600);

  Timer? _debounceTimer;
  bool _drawing = false;
  WritingArea? _writingArea;

  @override
  CanvasState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return CanvasIdle(language: InkLanguage.chinese);
  }

  /// Strokes are measured in this size, so a different size (rotation, split
  /// screen) clears them.
  void updateWritingArea(WritingArea area) {
    final previous = _writingArea;
    _writingArea = area;
    if (previous != null &&
        previous != area &&
        !_locked &&
        state.strokes.isNotEmpty) {
      _reset(const [], state.language);
    }
  }

  void startStroke(StrokePoint point) {
    if (_locked) return;
    _debounceTimer?.cancel();
    _drawing = true;
    state = CanvasIdle(
      strokes: [
        ...state.strokes,
        Stroke([point]),
      ],
      language: state.language,
    );
  }

  void addPoint(StrokePoint point) {
    if (_locked || !_drawing) return;
    final strokes = [...state.strokes];
    final last = strokes.removeLast();
    strokes.add(Stroke([...last.points, point]));
    state = CanvasIdle(strokes: strokes, language: state.language);
  }

  void endStroke() {
    if (_locked || !_drawing) return;
    _drawing = false;
    _debounceTimer = Timer(debounce, analyze);
  }

  void undo() {
    if (_locked || state.strokes.isEmpty) return;
    _reset(state.strokes.sublist(0, state.strokes.length - 1), state.language);
  }

  void clear() {
    if (_locked) return;
    _reset(const [], state.language);
  }

  void selectLanguage(InkLanguage language) {
    if (_locked || language == state.language) return;
    _reset(const [], language);
  }

  Future<void> analyze() async {
    _debounceTimer?.cancel();
    _drawing = false;
    final current = state;
    if (current is CanvasRecognizing || current.strokes.isEmpty) return;

    final strokes = current.strokes;
    final language = current.language;
    final area = _writingArea;
    if (area == null) {
      state = CanvasError(
        strokes: strokes,
        language: language,
        failure: RecognitionFailure(cause: StateError('writing area not set')),
      );
      return;
    }

    final recognizeCharacters = ref.read(recognizeCharactersProvider);
    state = CanvasRecognizing(strokes: strokes, language: language);

    CanvasState next;
    try {
      final candidates = await recognizeCharacters(
        strokes,
        language,
        writingArea: area,
      );
      next = candidates.isEmpty
          ? CanvasError(
              strokes: strokes,
              language: language,
              failure: const NoCandidatesFailure(),
            )
          : CanvasResult(
              strokes: strokes,
              language: language,
              candidates: candidates,
              selectedIndex: 0,
            );
    } on InkFailure catch (failure) {
      next = CanvasError(
        strokes: strokes,
        language: language,
        failure: failure,
      );
    } on Exception catch (e) {
      next = CanvasError(
        strokes: strokes,
        language: language,
        failure: RecognitionFailure(cause: e),
      );
    }

    if (!ref.mounted) return;
    state = next;
  }

  void selectCandidate(int index) {
    final current = state;
    if (current is! CanvasResult ||
        index < 0 ||
        index >= current.candidates.length) {
      return;
    }
    state = CanvasResult(
      strokes: current.strokes,
      language: current.language,
      candidates: current.candidates,
      selectedIndex: index,
    );
  }

  bool get _locked => state is CanvasRecognizing;

  void _reset(List<Stroke> strokes, InkLanguage language) {
    _debounceTimer?.cancel();
    _drawing = false;
    state = CanvasIdle(strokes: strokes, language: language);
  }
}
