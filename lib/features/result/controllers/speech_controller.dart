import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/repositories/tts_service.dart';
import 'package:character_lens/features/result/controllers/speech_state.dart';
import 'package:character_lens/features/result/controllers/tts_service_provider.dart';

final speechControllerProvider =
    NotifierProvider<SpeechController, SpeechState>(SpeechController.new);

class SpeechController extends Notifier<SpeechState> {
  /// Counts speeches. An answer is used only if the speech was not stopped or
  /// replaced while it was running.
  int _request = 0;

  @override
  SpeechState build() => const SpeechIdle();

  /// Speaks [text] in [language]. While speaking, a second call stops instead.
  Future<void> speak(String text, HanLanguage language) async {
    if (state is SpeechSpeaking) return stop();

    final tts = ref.read(ttsServiceProvider);
    final request = ++_request;
    state = const SpeechSpeaking();

    final result = await tts.speak(text, language);

    if (!ref.mounted || request != _request) return;
    state = switch (result) {
      SpeakResult.spoken => const SpeechIdle(),
      SpeakResult.noVoice => const SpeechNoVoice(),
      SpeakResult.failed => const SpeechFailed(),
    };
  }

  /// Stops any speech and clears a message. Safe to call when idle.
  Future<void> stop() async {
    _request++;
    final wasSpeaking = state is SpeechSpeaking;
    if (state is! SpeechIdle) state = const SpeechIdle();
    if (wasSpeaking) await ref.read(ttsServiceProvider).stop();
  }
}
