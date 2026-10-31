import 'package:equatable/equatable.dart';

class StrokePoint extends Equatable {
  const StrokePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
  });

  final double x;
  final double y;
  final int timestampMs;

  @override
  List<Object?> get props => [x, y, timestampMs];
}
