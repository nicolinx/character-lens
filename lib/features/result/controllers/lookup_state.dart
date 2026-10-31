import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/dictionary/dictionary_failure.dart';

/// Separate from `CanvasState`: closing the sheet must leave the strokes and
/// the candidates as they were.
sealed class LookupState extends Equatable {
  const LookupState();
}

class LookupClosed extends LookupState {
  const LookupClosed();

  @override
  List<Object?> get props => [];
}

sealed class LookupOpen extends LookupState {
  const LookupOpen({required this.character, required this.language});

  final String character;
  final InkLanguage language;

  @override
  List<Object?> get props => [character, language];
}

class LookupLoading extends LookupOpen {
  const LookupLoading({required super.character, required super.language});
}

class LookupLoaded extends LookupOpen {
  const LookupLoaded({
    required super.character,
    required super.language,
    required this.view,
  });

  final CharacterView view;

  @override
  List<Object?> get props => [...super.props, view];
}

class LookupNotFound extends LookupOpen {
  const LookupNotFound({required super.character, required super.language});
}

class LookupFailed extends LookupOpen {
  const LookupFailed({
    required super.character,
    required super.language,
    required this.failure,
  });

  final DictionaryFailure failure;

  @override
  List<Object?> get props => [...super.props, failure];
}
