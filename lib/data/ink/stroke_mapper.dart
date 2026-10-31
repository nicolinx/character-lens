import 'dart:math' as math;

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

import 'package:character_lens/domain/ink/stroke.dart';

class StrokeMapper {
  const StrokeMapper();

  /// Timestamps are made relative to the first point of the drawing, so the
  /// gaps between strokes are kept, and never decrease.
  mlkit.Ink toInk(List<Stroke> strokes) {
    final ink = mlkit.Ink();
    int? origin;
    var previous = 0;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final mapped = mlkit.Stroke();
      for (final point in stroke.points) {
        origin ??= point.timestampMs;
        final t = math.max(point.timestampMs - origin, previous);
        previous = t;
        mapped.points.add(mlkit.StrokePoint(x: point.x, y: point.y, t: t));
      }
      ink.strokes.add(mapped);
    }
    return ink;
  }
}
