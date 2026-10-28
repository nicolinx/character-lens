import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';

class LanguageReading extends Equatable {
  const LanguageReading({
    this.readings = const [],
    this.kun = const [],
    this.borrowedFrom,
  });

  final List<String> readings;

  final List<String> kun;

  /// The variant character the readings came from, when the drawn character
  /// had none of its own. Null for the character's own readings.
  final String? borrowedFrom;

  bool get isEmpty => readings.isEmpty && kun.isEmpty;

  @override
  List<Object?> get props => [readings, kun, borrowedFrom];
}

enum VariantKind { simplified, traditional }

class FormVariant extends Equatable {
  const FormVariant(this.kind, this.character);

  final VariantKind kind;
  final String character;

  @override
  List<Object?> get props => [kind, character];
}

class CharacterView extends Equatable {
  const CharacterView({
    required this.entry,
    required this.selected,
    required this.forms,
    required this.readings,
    this.variantNote,
  });

  final CharacterEntry entry;

  final HanLanguage selected;

  final Map<HanLanguage, String> forms;

  final Map<HanLanguage, LanguageReading> readings;

  /// Null when the selected language's form has no other written form to show.
  final FormVariant? variantNote;

  String get form => forms[selected]!;

  @override
  List<Object?> get props => [entry, selected, forms, readings, variantNote];
}
