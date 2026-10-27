import 'package:character_lens/domain/entities/han_language.dart';

/// How a call to [TtsService.speak] ended.
enum SpeakResult {
  /// The text was spoken to the end.
  spoken,

  /// The device has no voice for the language.
  noVoice,

  /// Speech started and failed, or was stopped before the end.
  failed,
}

abstract interface class TtsService {
  /// Speaks [text] with a voice for [language] and completes when the speech
  /// ends. Never throws: a problem is [SpeakResult.failed].
  Future<SpeakResult> speak(String text, HanLanguage language);

  /// Stops the speech in progress, if any.
  Future<void> stop();
}
