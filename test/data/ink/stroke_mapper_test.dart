import 'package:character_lens/data/ink/stroke_mapper.dart';
import 'package:character_lens/domain/ink/stroke.dart';
import 'package:character_lens/domain/ink/stroke_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

StrokePoint _pt(double x, double y, int t) =>
    StrokePoint(x: x, y: y, timestampMs: t);

/// Flattens an ML Kit ink to plain records so values can be compared.
List<List<(double, double, int)>> _flatten(mlkit.Ink ink) => [
  for (final stroke in ink.strokes)
    [for (final p in stroke.points) (p.x, p.y, p.t)],
];

void main() {
  const mapper = StrokeMapper();

  group('StrokeMapper.toInk', () {
    test('maps no strokes to an ink with no strokes', () {
      final ink = mapper.toInk([]);

      expect(ink.strokes, isEmpty);
    });

    test('maps a single-point stroke (a dot) to one stroke with one point', () {
      final ink = mapper.toInk([
        Stroke([_pt(10, 20, 500)]),
      ]);

      expect(_flatten(ink), [
        [(10.0, 20.0, 0)],
      ]);
    });

    test('keeps the order of strokes and of points within each stroke', () {
      final ink = mapper.toInk([
        Stroke([_pt(1, 1, 0), _pt(2, 2, 10)]),
        Stroke([_pt(3, 3, 20), _pt(4, 4, 30)]),
        Stroke([_pt(5, 5, 40)]),
      ]);

      expect(_flatten(ink), [
        [(1.0, 1.0, 0), (2.0, 2.0, 10)],
        [(3.0, 3.0, 20), (4.0, 4.0, 30)],
        [(5.0, 5.0, 40)],
      ]);
    });

    test(
      'makes timestamps relative to the first point of the first stroke',
      () {
        final ink = mapper.toInk([
          Stroke([_pt(0, 0, 5000), _pt(1, 1, 5010)]),
          Stroke([_pt(2, 2, 5300), _pt(3, 3, 5320)]),
        ]);

        final times = [
          for (final s in _flatten(ink)) [for (final p in s) p.$3],
        ];
        expect(times, [
          [0, 10],
          [300, 320],
        ]);
      },
    );

    test('never lets a timestamp go backwards', () {
      final ink = mapper.toInk([
        Stroke([_pt(0, 0, 1000), _pt(1, 1, 1010)]),
        Stroke([_pt(2, 2, 1005), _pt(3, 3, 1020)]),
      ]);

      final times = [
        for (final s in _flatten(ink))
          for (final p in s) p.$3,
      ];
      expect(times, [0, 10, 10, 20]);
    });

    test('passes coordinates through without scaling or rounding', () {
      final ink = mapper.toInk([
        Stroke([_pt(123.456, 789.012, 0), _pt(-5.5, 0, 1)]),
      ]);

      expect(_flatten(ink), [
        [(123.456, 789.012, 0), (-5.5, 0.0, 1)],
      ]);
    });

    test('skips strokes that have no points', () {
      final ink = mapper.toInk([
        Stroke([]),
        Stroke([_pt(1, 1, 100)]),
      ]);

      expect(_flatten(ink), [
        [(1.0, 1.0, 0)],
      ]);
    });
  });
}
