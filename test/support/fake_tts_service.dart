import 'dart:async';

import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/tts/tts_service.dart';

class FakeTtsService implements TtsService {
  SpeakResult result = SpeakResult.spoken;

  /// When set, a speech waits for it, which keeps the speech in progress.
  Completer<void>? gate;

  final spoken = <(String, HanLanguage)>[];
  var stops = 0;

  @override
  Future<SpeakResult> speak(String text, HanLanguage language) async {
    spoken.add((text, language));
    await gate?.future;
    return result;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}
