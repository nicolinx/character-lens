import 'package:equatable/equatable.dart';

import '../../../domain/entities/candidate.dart';
import '../../../domain/entities/ink_language.dart';
import '../../../domain/entities/stroke.dart';
import '../../../domain/failures/ink_failure.dart';

/// Strokes and language are part of every state, so a result can never be
/// shown for strokes other than the ones it was recognized from.
sealed class CanvasState extends Equatable {
  CanvasState({required List<Stroke> strokes, required this.language})
    : strokes = List.unmodifiable(strokes);

  final List<Stroke> strokes;
  final InkLanguage language;
}

/// Nothing recognized yet. Also the state while the user is drawing.
class CanvasIdle extends CanvasState {
  CanvasIdle({super.strokes = const [], required super.language});

  @override
  List<Object?> get props => [strokes, language];
}

class CanvasRecognizing extends CanvasState {
  CanvasRecognizing({required super.strokes, required super.language});

  @override
  List<Object?> get props => [strokes, language];
}

class CanvasResult extends CanvasState {
  CanvasResult({
    required super.strokes,
    required super.language,
    required List<Candidate> candidates,
    required this.selectedIndex,
  }) : candidates = List.unmodifiable(candidates);

  final List<Candidate> candidates;
  final int selectedIndex;

  Candidate get selected => candidates[selectedIndex];

  @override
  List<Object?> get props => [strokes, language, candidates, selectedIndex];
}

class CanvasError extends CanvasState {
  CanvasError({
    required super.strokes,
    required super.language,
    required this.failure,
  });

  final InkFailure failure;

  @override
  List<Object?> get props => [strokes, language, failure];
}
