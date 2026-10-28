import 'package:character_lens/domain/dictionary/han_language.dart';

enum SpeakResult {
  spoken,

  noVoice,

  /// Speech started and failed, or was stopped before the end.
  failed,
}

abstract interface class TtsService {
  /// Never throws: a problem is [SpeakResult.failed].
  Future<SpeakResult> speak(String text, HanLanguage language);

  Future<void> stop();
}
