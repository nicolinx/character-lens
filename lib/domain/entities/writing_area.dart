import 'package:equatable/equatable.dart';

/// Size of the drawing surface, in the same units as stroke coordinates.
class WritingArea extends Equatable {
  const WritingArea({required this.width, required this.height});

  final double width;
  final double height;

  @override
  List<Object?> get props => [width, height];
}
