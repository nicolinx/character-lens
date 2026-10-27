import 'package:equatable/equatable.dart';

class WritingArea extends Equatable {
  const WritingArea({required this.width, required this.height});

  final double width;
  final double height;

  @override
  List<Object?> get props => [width, height];
}
