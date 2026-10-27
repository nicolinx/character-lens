import 'package:flutter_tts/flutter_tts.dart';

import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/repositories/tts_service.dart';

class FlutterTtsService implements TtsService {
  FlutterTtsService(this._tts);

  final FlutterTts _tts;

  static String tagOf(HanLanguage language) => switch (language) {
    HanLanguage.chinese => 'zh-CN',
    HanLanguage.japanese => 'ja-JP',
    HanLanguage.korean => 'ko-KR',
  };

  @override
  Future<SpeakResult> speak(String text, HanLanguage language) async {
    final tag = tagOf(language);
    try {
      // Android answers false when the engine lacks the language or its voice
      // data, iOS when no installed voice matches the tag.
      if (await _tts.isLanguageAvailable(tag) != true) {
        return SpeakResult.noVoice;
      }
      await _tts.setLanguage(tag);
      // Without this, speak() answers as soon as the speech is queued.
      await _tts.awaitSpeakCompletion(true);
      // The plugin answers 1 when the speech ended and 0 when it did not.
      return await _tts.speak(text) == 1
          ? SpeakResult.spoken
          : SpeakResult.failed;
    } on Exception {
      return SpeakResult.failed;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Exception {
      // Nothing is speaking, or the engine is gone.
    }
  }
}
