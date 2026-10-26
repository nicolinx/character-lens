import 'dart:async';

import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/canvas/controllers/model_status_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_ink_recognizer.dart';

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [inkRecognizerProvider.overrideWithValue(recognizer)],
    );
  }

  final recognizer = FakeInkRecognizer();
  late final ProviderContainer container;

  ModelStatuses get statuses => container.read(modelStatusControllerProvider);
  ModelStatusController get controller =>
      container.read(modelStatusControllerProvider.notifier);

  /// Starts the controller, as the screen does by watching it, and lets the
  /// first check finish. Call it after configuring the fake.
  Future<void> settle() {
    container.read(modelStatusControllerProvider);
    return Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.container.dispose());

  group('checking', () {
    test(
      'checks the starting language on startup, and only that one',
      () async {
        await h.settle();

        expect(h.recognizer.checked, [InkLanguage.chinese]);
        expect(h.statuses, {InkLanguage.chinese: const ModelNotDownloaded()});
      },
    );

    test('has no status for a language until it is checked', () async {
      h.recognizer.checkGate = Completer<void>();
      await h.settle();

      expect(h.statuses, isEmpty);

      h.recognizer.checkGate!.complete();
      await h.settle();
      expect(h.statuses, isNotEmpty);
    });

    test('reports a model that is already on the device as ready', () async {
      h.recognizer.statuses[InkLanguage.chinese] = const ModelReady();
      await h.settle();

      expect(h.statuses[InkLanguage.chinese], const ModelReady());
    });

    test('checks the new language when the language is switched', () async {
      h.recognizer.statuses[InkLanguage.japanese] = const ModelReady();
      await h.settle();

      h.container
          .read(canvasControllerProvider.notifier)
          .selectLanguage(InkLanguage.japanese);
      await h.settle();

      expect(h.recognizer.checked, [InkLanguage.chinese, InkLanguage.japanese]);
      expect(h.statuses, {
        InkLanguage.chinese: const ModelNotDownloaded(),
        InkLanguage.japanese: const ModelReady(),
      });
    });

    test('a check that throws becomes a failed status', () async {
      final error = Exception('plugin');
      h.recognizer.checkError = error;
      await h.settle();

      expect(
        h.statuses[InkLanguage.chinese],
        ModelFailed(RecognitionFailure(cause: error)),
      );
    });

    test('a check never replaces a download in progress', () async {
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();
      unawaited(h.controller.download(InkLanguage.chinese));

      await h.controller.refresh(InkLanguage.chinese);

      expect(h.statuses[InkLanguage.chinese], const ModelDownloading());
    });

    test('a check that finishes after a download started is dropped', () async {
      h.recognizer.checkGate = Completer<void>();
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();
      unawaited(h.controller.download(InkLanguage.chinese));

      h.recognizer.checkGate!.complete();
      await h.settle();

      expect(h.statuses[InkLanguage.chinese], const ModelDownloading());
    });
  });

  group('download', () {
    test('goes Downloading, then Ready', () async {
      final seen = <ModelStatus?>[];
      h.container.listen(
        modelStatusControllerProvider,
        (_, next) => seen.add(next[InkLanguage.chinese]),
      );
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();

      final done = h.controller.download(InkLanguage.chinese);
      expect(h.statuses[InkLanguage.chinese], const ModelDownloading());

      h.recognizer.downloadGate!.complete();
      await done;

      expect(seen.last, const ModelReady());
      expect(h.recognizer.downloaded, [InkLanguage.chinese]);
    });

    test('a failed download shows the failure', () async {
      const failure = ModelDownloadFailure(InkLanguage.chinese);
      h.recognizer.downloadResult = const ModelFailed(failure);
      await h.settle();

      await h.controller.download(InkLanguage.chinese);

      expect(h.statuses[InkLanguage.chinese], const ModelFailed(failure));
    });

    test('a download that throws becomes a failed status', () async {
      final error = Exception('offline');
      h.recognizer.downloadError = error;
      await h.settle();

      await h.controller.download(InkLanguage.chinese);

      expect(
        h.statuses[InkLanguage.chinese],
        ModelFailed(ModelDownloadFailure(InkLanguage.chinese, cause: error)),
      );
    });

    test('retry after a failure recovers', () async {
      h.recognizer.downloadResult = const ModelFailed(
        ModelDownloadFailure(InkLanguage.chinese),
      );
      await h.settle();
      await h.controller.download(InkLanguage.chinese);
      expect(h.statuses[InkLanguage.chinese], isA<ModelFailed>());

      h.recognizer.downloadResult = const ModelReady();
      await h.controller.download(InkLanguage.chinese);

      expect(h.statuses[InkLanguage.chinese], const ModelReady());
      expect(h.recognizer.downloaded, hasLength(2));
    });

    test('ignores a second request while one is running', () async {
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();

      final first = h.controller.download(InkLanguage.chinese);
      await h.controller.download(InkLanguage.chinese);
      h.recognizer.downloadGate!.complete();
      await first;

      expect(h.recognizer.downloaded, hasLength(1));
    });

    test('does not download a model that is already ready', () async {
      h.recognizer.statuses[InkLanguage.chinese] = const ModelReady();
      await h.settle();

      await h.controller.download(InkLanguage.chinese);

      expect(h.recognizer.downloaded, isEmpty);
    });

    test('languages download independently', () async {
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();

      final cn = h.controller.download(InkLanguage.chinese);
      final jp = h.controller.download(InkLanguage.japanese);
      expect(h.statuses, {
        InkLanguage.chinese: const ModelDownloading(),
        InkLanguage.japanese: const ModelDownloading(),
      });

      h.recognizer.downloadGate!.complete();
      await Future.wait([cn, jp]);
      expect(h.statuses.values, everyElement(const ModelReady()));
    });

    test('does not throw when disposed during a download', () async {
      h.recognizer.downloadGate = Completer<void>();
      await h.settle();
      final done = h.controller.download(InkLanguage.chinese);

      h.container.dispose();
      h.recognizer.downloadGate!.complete();

      await done;
    });
  });

  group('failed status survives a re-check', () {
    test('stays failed when the model is still missing', () async {
      const failure = ModelDownloadFailure(InkLanguage.chinese);
      h.recognizer.downloadResult = const ModelFailed(failure);
      await h.settle();
      await h.controller.download(InkLanguage.chinese);

      await h.controller.refresh(InkLanguage.chinese);

      expect(h.statuses[InkLanguage.chinese], const ModelFailed(failure));
    });

    test('becomes ready when the model turned up', () async {
      h.recognizer.downloadResult = const ModelFailed(
        ModelDownloadFailure(InkLanguage.chinese),
      );
      await h.settle();
      await h.controller.download(InkLanguage.chinese);

      h.recognizer.statuses[InkLanguage.chinese] = const ModelReady();
      await h.controller.refresh(InkLanguage.chinese);

      expect(h.statuses[InkLanguage.chinese], const ModelReady());
    });
  });

  group('drawing enabled', () {
    bool enabled() => h.container.read(drawingEnabledProvider);

    test('is off until the selected language is ready', () async {
      expect(enabled(), isFalse); // not checked yet
      await h.settle();
      expect(enabled(), isFalse); // not downloaded

      await h.controller.download(InkLanguage.chinese);
      expect(enabled(), isTrue);
    });

    test('follows the selected language, not the other one', () async {
      h.recognizer.statuses[InkLanguage.chinese] = const ModelReady();
      await h.settle();
      expect(enabled(), isTrue);

      h.container
          .read(canvasControllerProvider.notifier)
          .selectLanguage(InkLanguage.japanese);
      await h.settle();

      expect(enabled(), isFalse);
    });
  });
}
