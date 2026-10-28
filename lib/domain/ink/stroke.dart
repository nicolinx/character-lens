import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/ink/stroke_point.dart';

class Stroke extends Equatable {
  Stroke(List<StrokePoint> points) : points = List.unmodifiable(points);

  final List<StrokePoint> points;

  @override
  List<Object?> get props => [points];
}
