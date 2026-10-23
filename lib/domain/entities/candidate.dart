import 'package:equatable/equatable.dart';

class Candidate extends Equatable {
  const Candidate({required this.character, this.score});

  final String character;

  /// Recognizer score, when the engine reports one. Its meaning is specific
  /// to the engine, so rely on list order, not on this value.
  final double? score;

  @override
  List<Object?> get props => [character, score];
}
