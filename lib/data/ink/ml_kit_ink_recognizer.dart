import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/domain/repositories/ink_recognizer.dart';
import 'package:character_lens/data/ink/ink_plugin.dart';
import 'package:character_lens/data/ink/stroke_mapper.dart';

class MlKitInkRecognizer implements InkRecognizer {
  MlKitInkRecognizer({
    InkModelManager? modelManager,
    InkTextRecognizerFactory? recognizerFactory,
    this._mapper = const StrokeMapper(),
  }) : _modelManager = modelManager ?? PluginInkModelManager(),
       _recognizerFactory = recognizerFactory ?? PluginInkTextRecognizer.new;

  final InkModelManager _modelManager;
  final InkTextRecognizerFactory _recognizerFactory;
  final StrokeMapper _mapper;
  final _recognizers = <InkLanguage, InkTextRecognizer>{};

  @override
  Future<ModelStatus> modelStatus(InkLanguage language) async {
    try {
      final downloaded = await _modelManager.isModelDownloaded(
        language.languageTag,
      );
      return downloaded ? const ModelReady() : const ModelNotDownloaded();
    } on Exception catch (e) {
      return ModelFailed(RecognitionFailure(cause: e));
    }
  }

  @override
  Future<ModelStatus> downloadModel(InkLanguage language) async {
    try {
      final done = await _modelManager.downloadModel(language.languageTag);
      return done
          ? const ModelReady()
          : ModelFailed(ModelDownloadFailure(language));
    } on Exception catch (e) {
      return ModelFailed(ModelDownloadFailure(language, cause: e));
    }
  }

  @override
  Future<List<Candidate>> recognize(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  }) async {
    final ink = _mapper.toInk(strokes);
    if (ink.strokes.isEmpty) return const [];

    final recognizer = _recognizers.putIfAbsent(
      language,
      () => _recognizerFactory(language.languageTag),
    );
    try {
      final candidates = await recognizer.recognize(
        ink,
        writingArea: writingArea,
      );
      return candidates;
    } on Exception catch (e) {
      throw await _failureFor(language, e);
    }
  }

  Future<void> dispose() async {
    final recognizers = _recognizers.values.toList();
    _recognizers.clear();
    await Future.wait(recognizers.map((r) => r.close()));
  }

  /// The plugin gives no typed error, so a missing model is detected by asking.
  Future<InkFailure> _failureFor(InkLanguage language, Exception cause) async {
    try {
      final downloaded = await _modelManager.isModelDownloaded(
        language.languageTag,
      );
      if (!downloaded) return ModelNotDownloadedFailure(language);
    } on Exception catch (_) {
      // The check failed as well, so report the original error.
    }
    return RecognitionFailure(cause: cause);
  }
}
