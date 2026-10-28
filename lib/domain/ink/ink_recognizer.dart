import 'package:character_lens/domain/ink/candidate.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/model_status.dart';
import 'package:character_lens/domain/ink/stroke.dart';
import 'package:character_lens/domain/ink/writing_area.dart';

abstract interface class InkRecognizer {
  /// Whether the model for [language] is on the device. Never downloads.
  Future<ModelStatus> modelStatus(InkLanguage language);

  /// Downloads the model. A Future, not a Stream: ML Kit reports no progress,
  /// only a result when the download ends.
  Future<ModelStatus> downloadModel(InkLanguage language);

  /// Returns candidates best first, or an empty list when nothing was
  /// recognized. Throws an [InkFailure] on error.
  Future<List<Candidate>> recognize(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  });
}
