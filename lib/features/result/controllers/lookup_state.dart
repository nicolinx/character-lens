import 'package:equatable/equatable.dart';

import '../../../domain/entities/character_view.dart';
import '../../../domain/entities/ink_language.dart';
import '../../../domain/failures/dictionary_failure.dart';

/// The result sheet's own state. It is separate from `CanvasState` because the
/// sheet opens and closes on its own, and closing it must leave the strokes and
/// the candidates as they were.
sealed class LookupState extends Equatable {
  const LookupState();
}

/// No sheet.
class LookupClosed extends LookupState {
  const LookupClosed();

  @override
  List<Object?> get props => [];
}

/// A sheet is open for [character]. Every open state names the character and
/// the language it was drawn in, so the sheet can show a header while it loads
/// and a retry knows what to ask for.
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

/// The dictionary was read and has no entry for [character].
class LookupNotFound extends LookupOpen {
  const LookupNotFound({required super.character, required super.language});
}

/// The dictionary could not be read.
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
