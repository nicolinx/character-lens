import 'package:equatable/equatable.dart';

/// A part of the character and what it contributes, like a radical or a
/// phonetic component.
class ExplanationComponent extends Equatable {
  const ExplanationComponent({required this.part, required this.role});

  final String part;
  final String role;

  @override
  List<Object?> get props => [part, role];
}

/// A common word that uses the character. [reading] is the reading of the
/// whole word, as the explainer wrote it.
class ExplanationExample extends Equatable {
  const ExplanationExample({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  final String word;
  final String reading;
  final String meaning;

  @override
  List<Object?> get props => [word, reading, meaning];
}

/// What the explainer says about a character. None of it is a source of
/// truth: readings and definitions come from the dictionary only.
class Explanation extends Equatable {
  const Explanation({
    required this.components,
    required this.mnemonic,
    required this.examples,
    this.usageNote,
  });

  final List<ExplanationComponent> components;
  final String mnemonic;
  final List<ExplanationExample> examples;

  /// A difference in usage between Chinese and Japanese, when there is one.
  final String? usageNote;

  @override
  List<Object?> get props => [components, mnemonic, examples, usageNote];
}
