import 'package:character_lens/domain/ink/candidate.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/model_status.dart';
import 'package:character_lens/domain/ink/stroke.dart';
import 'package:character_lens/domain/ink/stroke_point.dart';
import 'package:character_lens/domain/ink/ink_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = StrokePoint(x: 1, y: 2, timestampMs: 0);
  const b = StrokePoint(x: 3, y: 4, timestampMs: 10);

  group('Stroke', () {
    test('equal when points are equal in order', () {
      expect(Stroke([a, b]), Stroke([a, b]));
      expect(Stroke([a, b]).hashCode, Stroke([a, b]).hashCode);
      expect(Stroke([a, b]), isNot(Stroke([b, a])));
    });

    test('does not change when the source list is mutated', () {
      final source = [a];
      final stroke = Stroke(source);
      source.add(b);

      expect(stroke.points, [a]);
    });

    test('points list cannot be modified', () {
      expect(() => Stroke([a]).points.add(b), throwsUnsupportedError);
    });
  });

  test('Candidate equality includes the score', () {
    expect(
      const Candidate(character: '木', score: 1),
      const Candidate(character: '木', score: 1),
    );
    expect(
      const Candidate(character: '木'),
      isNot(const Candidate(character: '木', score: 1)),
    );
  });

  test('InkLanguage exposes the ML Kit tags', () {
    expect(InkLanguage.chinese.languageTag, 'zh-Hani');
    expect(InkLanguage.japanese.languageTag, 'ja');
  });

  test('ModelStatus values compare by content', () {
    expect(const ModelReady(), const ModelReady());
    expect(const ModelReady(), isNot(const ModelDownloading()));
    expect(
      const ModelFailed(NoCandidatesFailure()),
      const ModelFailed(NoCandidatesFailure()),
    );
    expect(
      const ModelFailed(ModelNotDownloadedFailure(InkLanguage.chinese)),
      isNot(const ModelFailed(ModelNotDownloadedFailure(InkLanguage.japanese))),
    );
  });

  test('ModelStatus switch is exhaustive', () {
    String label(ModelStatus s) => switch (s) {
      ModelNotDownloaded() => 'notDownloaded',
      ModelDownloading() => 'downloading',
      ModelReady() => 'ready',
      ModelFailed() => 'failed',
    };

    expect(label(const ModelReady()), 'ready');
  });
}
