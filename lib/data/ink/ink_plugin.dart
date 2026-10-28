import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

import 'package:character_lens/domain/ink/candidate.dart';
import 'package:character_lens/domain/ink/writing_area.dart';

/// Thin seams over the ML Kit plugin, so the recognizer can be tested with
/// fakes.
abstract interface class InkModelManager {
  Future<bool> isModelDownloaded(String languageTag);

  /// Completes with false, or throws, when the download did not succeed.
  Future<bool> downloadModel(String languageTag);
}

abstract interface class InkTextRecognizer {
  Future<List<Candidate>> recognize(
    mlkit.Ink ink, {
    required WritingArea writingArea,
  });

  Future<void> close();
}

typedef InkTextRecognizerFactory = InkTextRecognizer Function(
  String languageTag,
);

class PluginInkModelManager implements InkModelManager {
  final _manager = mlkit.DigitalInkRecognizerModelManager();

  @override
  Future<bool> isModelDownloaded(String languageTag) =>
      _manager.isModelDownloaded(languageTag);

  @override
  Future<bool> downloadModel(String languageTag) =>
      _manager.downloadModel(languageTag, isWifiRequired: false);
}

class PluginInkTextRecognizer implements InkTextRecognizer {
  PluginInkTextRecognizer(String languageTag)
    : _recognizer = mlkit.DigitalInkRecognizer(languageCode: languageTag);

  final mlkit.DigitalInkRecognizer _recognizer;

  @override
  Future<List<Candidate>> recognize(
    mlkit.Ink ink, {
    required WritingArea writingArea,
  }) async {
    final candidates = await _recognizer.recognize(
      ink,
      context: mlkit.DigitalInkRecognitionContext(
        writingArea: mlkit.WritingArea(
          width: writingArea.width,
          height: writingArea.height,
        ),
      ),
    );
    return [
      for (final c in candidates) Candidate(character: c.text, score: c.score),
    ];
  }

  @override
  Future<void> close() => _recognizer.close();
}
