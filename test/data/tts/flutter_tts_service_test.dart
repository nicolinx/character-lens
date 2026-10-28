import 'package:character_lens/data/tts/flutter_tts_service.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/repositories/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late Object? Function(MethodCall call) answer;
  late FlutterTtsService service;

  setUp(() {
    calls = [];
    answer = (call) => switch (call.method) {
      'isLanguageAvailable' => true,
      'speak' => 1,
      _ => 1,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          calls.add(call);
          return answer(call);
        });
    service = FlutterTtsService(FlutterTts());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Iterable<String> methods() => calls.map((c) => c.method);

  group('language tags', () {
    test('are the ones Android and iOS take', () {
      expect(FlutterTtsService.tagOf(HanLanguage.chinese), 'zh-CN');
      expect(FlutterTtsService.tagOf(HanLanguage.japanese), 'ja-JP');
      expect(FlutterTtsService.tagOf(HanLanguage.korean), 'ko-KR');
    });
  });

  group('speak', () {
    test('checks the language, sets it, then speaks and waits', () async {
      final result = await service.speak('語', HanLanguage.japanese);

      expect(result, SpeakResult.spoken);
      expect(
        methods(),
        containsAllInOrder([
          'isLanguageAvailable',
          'setLanguage',
          'awaitSpeakCompletion',
          'speak',
        ]),
      );
      expect(
        calls.firstWhere((c) => c.method == 'isLanguageAvailable').arguments,
        'ja-JP',
      );
      expect(
        calls.firstWhere((c) => c.method == 'setLanguage').arguments,
        'ja-JP',
      );
      expect(
        calls.firstWhere((c) => c.method == 'awaitSpeakCompletion').arguments,
        true,
      );
    });

    test('without a voice it is noVoice and never speaks', () async {
      answer = (call) => call.method == 'isLanguageAvailable' ? false : 1;

      final result = await service.speak('語', HanLanguage.korean);

      expect(result, SpeakResult.noVoice);
      expect(methods(), isNot(contains('speak')));
      expect(methods(), isNot(contains('setLanguage')));
    });

    test('an answer other than true for the language is noVoice', () async {
      answer = (call) => call.method == 'isLanguageAvailable' ? null : 1;

      expect(
        await service.speak('語', HanLanguage.chinese),
        SpeakResult.noVoice,
      );
    });

    test('a speech that does not end well is failed', () async {
      answer = (call) => switch (call.method) {
        'isLanguageAvailable' => true,
        'speak' => 0,
        _ => 1,
      };

      expect(
        await service.speak('語', HanLanguage.japanese),
        SpeakResult.failed,
      );
    });

    test('a platform error is failed, not thrown', () async {
      answer = (call) =>
          call.method == 'speak' ? throw PlatformException(code: 'boom') : true;

      expect(
        await service.speak('語', HanLanguage.japanese),
        SpeakResult.failed,
      );
    });
  });

  group('stop', () {
    test('stops the engine', () async {
      await service.stop();

      expect(methods(), ['stop']);
    });

    test('does not throw when the engine fails', () async {
      answer = (_) => throw PlatformException(code: 'boom');

      await expectLater(service.stop(), completes);
    });
  });
}
