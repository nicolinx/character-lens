import 'package:equatable/equatable.dart';

import 'character_entry.dart';
import 'han_language.dart';

/// The readings of a character in one language.
class LanguageReading extends Equatable {
  const LanguageReading({
    this.readings = const [],
    this.kun = const [],
    this.borrowedFrom,
  });

  /// Pinyin, Japanese on, or Hangul, depending on the language.
  final List<String> readings;

  /// Japanese kun. Empty for the other languages.
  final List<String> kun;

  /// The variant character the readings came from, when the drawn character
  /// had none of its own. Null for the character's own readings.
  final String? borrowedFrom;

  bool get isEmpty => readings.isEmpty && kun.isEmpty;

  @override
  List<Object?> get props => [readings, kun, borrowedFrom];
}

enum VariantKind { simplified, traditional }

/// The other written form shown next to the character, like "Traditional 學".
class FormVariant extends Equatable {
  const FormVariant(this.kind, this.character);

  final VariantKind kind;
  final String character;

  @override
  List<Object?> get props => [kind, character];
}

/// A character prepared for the result sheet.
class CharacterView extends Equatable {
  const CharacterView({
    required this.entry,
    required this.selected,
    required this.forms,
    required this.readings,
    this.variantNote,
  });

  /// The entry of the character that was drawn.
  final CharacterEntry entry;

  /// The language the user drew in.
  final HanLanguage selected;

  /// How the character is written in each language.
  final Map<HanLanguage, String> forms;

  final Map<HanLanguage, LanguageReading> readings;

  /// Null when the selected language's form has no other written form to show.
  final FormVariant? variantNote;

  /// The character as written in the selected language.
  String get form => forms[selected]!;

  @override
  List<Object?> get props => [entry, selected, forms, readings, variantNote];
}
