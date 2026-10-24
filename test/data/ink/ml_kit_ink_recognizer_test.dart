import 'package:character_lens/data/ink/ink_plugin.dart';
import 'package:character_lens/data/ink/ml_kit_ink_recognizer.dart';
import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/stroke_point.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

class _FakeModelManager implements InkModelManager {
  bool downloaded = true;
  bool downloadResult = true;
  Exception? checkError;
  Exception? downloadError;
  final checkedTags = <String>[];
  final downloadedTags = <String>[];

  @override
  Future<bool> isModelDownloaded(String languageTag) async {
    checkedTags.add(languageTag);
    if (checkError != null) throw checkError!;
    return downloaded;
  }

  @override
  Future<bool> downloadModel(String languageTag) async {
    downloadedTags.add(languageTag);
    if (downloadError != null) throw downloadError!;
    return downloadResult;
  }
}

class _FakeEngine {
  List<Candidate> result = const [];
  Exception? error;
  final created = <_FakeRecognizer>[];

  InkTextRecognizer create(String languageTag) {
    final recognizer = _FakeRecognizer(this, languageTag);
    created.add(recognizer);
    return recognizer;
  }
}

class _FakeRecognizer implements InkTextRecognizer {
  _FakeRecognizer(this._engine, this.languageTag);

  final _FakeEngine _engine;
  final String languageTag;
  mlkit.Ink? lastInk;
  WritingArea? lastWritingArea;
  bool closed = false;

  @override
  Future<List<Candidate>> recognize(
    mlkit.Ink ink, {
    required WritingArea writingArea,
  }) async {
    lastInk = ink;
    lastWritingArea = writingArea;
    if (_engine.error != null) throw _engine.error!;
    return _engine.result;
  }

  @override
  Future<void> close() async => closed = true;
}

List<Candidate> _candidates(int count) => [
  for (var i = 0; i < count; i++) Candidate(character: 'c$i'),
];

final _dot = [
  Stroke([const StrokePoint(x: 1, y: 2, timestampMs: 100)]),
];
const _area = WritingArea(width: 300, height: 400);

void main() {
  late _FakeModelManager models;
  late _FakeEngine engine;
  late MlKitInkRecognizer recognizer;

  setUp(() {
    models = _FakeModelManager();
    engine = _FakeEngine();
    recognizer = MlKitInkRecognizer(
      modelManager: models,
      recognizerFactory: engine.create,
    );
  });

  group('modelStatus', () {
    test('is ready when the model is downloaded', () async {
      expect(
        await recognizer.modelStatus(InkLanguage.chinese),
        isA<ModelReady>(),
      );
      expect(models.checkedTags, ['zh-Hani']);
    });

    test('is not downloaded when the model is missing', () async {
      models.downloaded = false;

      expect(
        await recognizer.modelStatus(InkLanguage.japanese),
        const ModelNotDownloaded(),
      );
      expect(models.checkedTags, ['ja']);
    });

    test('is failed when the plugin throws', () async {
      final error = PlatformException(code: 'check failed');
      models.checkError = error;

      expect(
        await recognizer.modelStatus(InkLanguage.chinese),
        ModelFailed(RecognitionFailure(cause: error)),
      );
    });
  });

  group('downloadModel', () {
    test('is ready when the download succeeds', () async {
      expect(
        await recognizer.downloadModel(InkLanguage.japanese),
        const ModelReady(),
      );
      expect(models.downloadedTags, ['ja']);
    });

    test('is failed when the plugin reports no success', () async {
      models.downloadResult = false;

      expect(
        await recognizer.downloadModel(InkLanguage.chinese),
        const ModelFailed(ModelDownloadFailure(InkLanguage.chinese)),
      );
    });

    test('is failed with the cause when the plugin throws', () async {
      final error = PlatformException(code: 'no network');
      models.downloadError = error;

      expect(
        await recognizer.downloadModel(InkLanguage.chinese),
        ModelFailed(ModelDownloadFailure(InkLanguage.chinese, cause: error)),
      );
    });
  });

  group('recognize', () {
    test('returns only the top 5 candidates, in order', () async {
      engine.result = _candidates(7);

      final result = await recognizer.recognize(
        _dot,
        InkLanguage.chinese,
        writingArea: _area,
      );

      expect(result, _candidates(5));
    });

    test('returns fewer than 5 when the recognizer gives fewer', () async {
      engine.result = _candidates(2);

      final result = await recognizer.recognize(
        _dot,
        InkLanguage.chinese,
        writingArea: _area,
      );

      expect(result, _candidates(2));
    });

    test(
      'returns nothing and skips the plugin when there are no strokes',
      () async {
        final result = await recognizer.recognize(
          [],
          InkLanguage.chinese,
          writingArea: _area,
        );

        expect(result, isEmpty);
        expect(engine.created, isEmpty);
      },
    );

    test('passes the mapped ink and the writing area through', () async {
      await recognizer.recognize(
        _dot,
        InkLanguage.japanese,
        writingArea: _area,
      );

      final fake = engine.created.single;
      expect(fake.languageTag, 'ja');
      expect(fake.lastWritingArea, _area);
      final point = fake.lastInk!.strokes.single.points.single;
      expect((point.x, point.y, point.t), (1.0, 2.0, 0));
    });

    test(
      'creates one recognizer per language, lazily, and reuses it',
      () async {
        expect(engine.created, isEmpty);

        await recognizer.recognize(
          _dot,
          InkLanguage.chinese,
          writingArea: _area,
        );
        await recognizer.recognize(
          _dot,
          InkLanguage.chinese,
          writingArea: _area,
        );
        expect(engine.created.map((r) => r.languageTag), ['zh-Hani']);

        await recognizer.recognize(
          _dot,
          InkLanguage.japanese,
          writingArea: _area,
        );
        expect(engine.created.map((r) => r.languageTag), ['zh-Hani', 'ja']);
      },
    );

    test(
      'throws ModelNotDownloadedFailure when it fails and the model is missing',
      () async {
        engine.error = PlatformException(code: 'recognition Error');
        models.downloaded = false;

        expect(
          recognizer.recognize(_dot, InkLanguage.chinese, writingArea: _area),
          throwsA(const ModelNotDownloadedFailure(InkLanguage.chinese)),
        );
      },
    );

    test(
      'throws RecognitionFailure with the cause when the model is present',
      () async {
        final error = PlatformException(code: 'recognition Error');
        engine.error = error;

        expect(
          recognizer.recognize(_dot, InkLanguage.chinese, writingArea: _area),
          throwsA(RecognitionFailure(cause: error)),
        );
      },
    );

    test('throws RecognitionFailure with the original cause when the model check also fails', () async {
      final error = PlatformException(code: 'recognition Error');
      engine.error = error;
      models.checkError = PlatformException(code: 'check failed');

      expect(
        recognizer.recognize(_dot, InkLanguage.chinese, writingArea: _area),
        throwsA(RecognitionFailure(cause: error)),
      );
    });
  });

  test('dispose closes the recognizers that were created', () async {
    await recognizer.recognize(_dot, InkLanguage.chinese, writingArea: _area);
    await recognizer.recognize(_dot, InkLanguage.japanese, writingArea: _area);

    await recognizer.dispose();

    expect(engine.created.map((r) => r.closed), [true, true]);
  });

  test('dispose without any recognition closes nothing', () async {
    await recognizer.dispose();

    expect(engine.created, isEmpty);
  });
}
