import 'package:equatable/equatable.dart';

import 'stroke_point.dart';

class Stroke extends Equatable {
  Stroke(List<StrokePoint> points) : points = List.unmodifiable(points);

  final List<StrokePoint> points;

  @override
  List<Object?> get props => [points];
}
