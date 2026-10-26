import 'package:flutter/rendering.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/stroke.dart';

/// The ruled practice sheet: an inner ring, a cross and two diagonals.
/// It never changes, so it sits on its own layer and is painted once per size.
class PracticeSheetPainter extends CustomPainter {
  const PracticeSheetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..strokeWidth = 1;

    canvas
      ..drawLine(
        Offset.zero,
        Offset(size.width, size.height),
        line..color = AppColors.padDiagonal,
      )
      ..drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        line..color = AppColors.padDiagonal,
      )
      ..drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        line..color = AppColors.padCross,
      )
      ..drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        line,
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height).deflate(5.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.padRing,
    );
  }

  @override
  bool shouldRepaint(PracticeSheetPainter oldDelegate) => false;
}

/// Draws the strokes with ink. Each stroke is smoothed through the midpoints
/// of its points, like the prototype's canvas.
class StrokePainter extends CustomPainter {
  const StrokePainter(this.strokes);

  static const strokeWidth = 9.0;

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.text;

    for (final stroke in strokes) {
      final path = pathFor(stroke);
      if (path != null) canvas.drawPath(path, paint);
    }
  }

  /// Null for a stroke with no points.
  static Path? pathFor(Stroke stroke) {
    final p = stroke.points;
    if (p.isEmpty) return null;

    final path = Path()..moveTo(p.first.x, p.first.y);
    if (p.length == 1) {
      // A tap becomes a dot, thanks to the round cap.
      return path..lineTo(p.first.x + 0.1, p.first.y);
    }
    for (var i = 1; i < p.length - 1; i++) {
      path.quadraticBezierTo(
        p[i].x,
        p[i].y,
        (p[i].x + p[i + 1].x) / 2,
        (p[i].y + p[i + 1].y) / 2,
      );
    }
    return path..lineTo(p.last.x, p.last.y);
  }

  /// Compares by identity: the controller makes a new list on every change,
  /// and a deep comparison per frame would cost more than the repaint.
  @override
  bool shouldRepaint(StrokePainter oldDelegate) =>
      !identical(oldDelegate.strokes, strokes);
}
