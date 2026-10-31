import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/explainer/explanation.dart';

enum ReadingCheck {
  /// The reading of the character inside the word matches the dictionary.
  verified,

  /// The dictionary does not confirm it. This does not mean it is wrong.
  unverified,
}

/// An explanation with the result of checking each example's reading against
/// the dictionary. Nothing is removed from the explanation.
class ValidatedExplanation extends Equatable {
  ValidatedExplanation({required this.explanation, required this.checks})
    : assert(
        checks.length == explanation.examples.length,
        'one check for each example',
      );

  final Explanation explanation;

  /// [checks] at index i is the result for `explanation.examples[i]`.
  final List<ReadingCheck> checks;

  @override
  List<Object?> get props => [explanation, checks];
}
