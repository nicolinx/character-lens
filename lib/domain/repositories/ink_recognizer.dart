import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/writing_area.dart';

abstract interface class InkRecognizer {
  /// Whether the model for [language] is on the device. Never downloads.
  Future<ModelStatus> modelStatus(InkLanguage language);

  /// Downloads the model for [language] and completes with [ModelReady] or
  /// [ModelFailed].
  ///
  /// A Future rather than a Stream: ML Kit reports no progress, only a result
  /// when the download ends, so a stream could emit nothing but start and end.
  /// Callers show [ModelDownloading] themselves while they await.
  Future<ModelStatus> downloadModel(InkLanguage language);

  /// Returns candidates best first, or an empty list when nothing was
  /// recognized. Throws an [InkFailure] on error.
  Future<List<Candidate>> recognize(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  });
}
