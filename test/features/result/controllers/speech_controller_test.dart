import 'dart:async';

import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/repositories/tts_service.dart';
import 'package:character_lens/features/result/controllers/speech_controller.dart';
import 'package:character_lens/features/result/controllers/speech_state.dart';
import 'package:character_lens/features/result/controllers/tts_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_tts_service.dart';

void main() {
  late FakeTtsService tts;
  late ProviderContainer container;
  late SpeechController controller;
  late List<SpeechState> states;

  SpeechState state() => container.read(speechControllerProvider);

  setUp(() {
    tts = FakeTtsService();
    container = ProviderContainer(
      overrides: [ttsServiceProvider.overrideWithValue(tts)],
    );
    states = [];
    container.listen(
      speechControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    controller = container.read(speechControllerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('starts idle', () {
    expect(state(), const SpeechIdle());
  });

  test('goes Idle, Speaking, Idle when the speech ends', () async {
    await controller.speak('語', HanLanguage.japanese);

    expect(states, [
      const SpeechIdle(),
      const SpeechSpeaking(),
      const SpeechIdle(),
    ]);
    expect(tts.spoken, [('語', HanLanguage.japanese)]);
  });

  test('no voice is shown as NoVoice', () async {
    tts.result = SpeakResult.noVoice;

    await controller.speak('語', HanLanguage.korean);

    expect(state(), const SpeechNoVoice());
  });

  test('a failure is shown as Failed', () async {
    tts.result = SpeakResult.failed;

    await controller.speak('語', HanLanguage.chinese);

    expect(state(), const SpeechFailed());
  });

  test('can be tried again after no voice', () async {
    tts.result = SpeakResult.noVoice;
    await controller.speak('語', HanLanguage.korean);

    tts.result = SpeakResult.spoken;
    await controller.speak('語', HanLanguage.korean);

    expect(state(), const SpeechIdle());
  });

  group('stop', () {
    test('while speaking stops the engine and goes Idle', () async {
      tts.gate = Completer<void>();
      final pending = controller.speak('語', HanLanguage.japanese);
      expect(state(), const SpeechSpeaking());

      await controller.stop();

      expect(state(), const SpeechIdle());
      expect(tts.stops, 1);
      tts.gate!.complete();
      await pending;
    });

    test('drops the answer of the speech it stopped', () async {
      tts.gate = Completer<void>();
      tts.result = SpeakResult.failed;
      final pending = controller.speak('語', HanLanguage.japanese);

      await controller.stop();
      tts.gate!.complete();
      await pending;

      // The engine reports a stopped speech as failed. That is not an error.
      expect(state(), const SpeechIdle());
    });

    test('clears a message', () async {
      tts.result = SpeakResult.noVoice;
      await controller.speak('語', HanLanguage.korean);

      await controller.stop();

      expect(state(), const SpeechIdle());
    });

    test('when idle does not touch the engine', () async {
      await controller.stop();

      expect(tts.stops, 0);
    });

    test(
      'a second tap while speaking stops instead of speaking again',
      () async {
        tts.gate = Completer<void>();
        final pending = controller.speak('語', HanLanguage.japanese);

        await controller.speak('語', HanLanguage.japanese);

        expect(tts.spoken, hasLength(1));
        expect(tts.stops, 1);
        expect(state(), const SpeechIdle());
        tts.gate!.complete();
        await pending;
      },
    );
  });

  test('does not throw when disposed while speaking', () async {
    tts.gate = Completer<void>();
    final pending = controller.speak('語', HanLanguage.japanese);

    container.dispose();
    tts.gate!.complete();

    await expectLater(pending, completes);
  });
}
