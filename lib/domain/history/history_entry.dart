import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/ink/ink_language.dart';

/// A character the user looked up, and the language they drew it in.
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.character,
    required this.language,
    required this.openedAt,
  });

  final String character;
  final InkLanguage language;
  final DateTime openedAt;

  @override
  List<Object?> get props => [character, language, openedAt];
}
