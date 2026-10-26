import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/stroke_point.dart';
import 'package:character_lens/features/canvas/widgets/canvas_painters.dart';
import 'package:flutter_test/flutter_test.dart';

StrokePoint _pt(double x, double y) => StrokePoint(x: x, y: y, timestampMs: 0);

void main() {
  group('StrokePainter.shouldRepaint', () {
    final strokes = [
      Stroke([_pt(1, 1)]),
    ];

    test('is false for the same list', () {
      expect(
        StrokePainter(strokes).shouldRepaint(StrokePainter(strokes)),
        false,
      );
    });

    test('is true for a new list, even with equal content', () {
      final copy = [...strokes];

      expect(StrokePainter(copy).shouldRepaint(StrokePainter(strokes)), true);
    });
  });

  test('the practice sheet never repaints on its own', () {
    expect(
      const PracticeSheetPainter().shouldRepaint(const PracticeSheetPainter()),
      false,
    );
  });

  group('StrokePainter.pathFor', () {
    test('has no path for a stroke without points', () {
      expect(StrokePainter.pathFor(Stroke([])), isNull);
    });

    test('turns a single point into a dot', () {
      final bounds = StrokePainter.pathFor(Stroke([_pt(10, 20)]))!.getBounds();

      expect(bounds.left, 10);
      expect(bounds.top, 20);
      expect(bounds.width, closeTo(0.1, 1e-5));
    });

    test('ends exactly on the last point', () {
      final path = StrokePainter.pathFor(
        Stroke([_pt(0, 0), _pt(10, 0), _pt(20, 10), _pt(30, 10)]),
      )!;

      final metric = path.computeMetrics().single;
      final end = metric.getTangentForOffset(metric.length)!.position;

      expect(end.dx, closeTo(30, 1e-6));
      expect(end.dy, closeTo(10, 1e-6));
    });
  });
}
