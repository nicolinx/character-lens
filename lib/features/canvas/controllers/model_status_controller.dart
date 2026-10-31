import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/model_status.dart';
import 'package:character_lens/domain/ink/ink_failure.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';

typedef ModelStatuses = Map<InkLanguage, ModelStatus>;

final modelStatusControllerProvider =
    NotifierProvider<ModelStatusController, ModelStatuses>(
      ModelStatusController.new,
    );

final selectedModelStatusProvider = Provider<ModelStatus?>((ref) {
  final language = ref.watch(
    canvasControllerProvider.select((s) => s.language),
  );
  return ref.watch(modelStatusControllerProvider)[language];
});

final drawingEnabledProvider = Provider<bool>(
  (ref) => ref.watch(selectedModelStatusProvider) is ModelReady,
);

class ModelStatusController extends Notifier<ModelStatuses> {
  @override
  ModelStatuses build() {
    ref.listen(
      canvasControllerProvider.select((s) => s.language),
      (_, language) => refresh(language),
    );
    // State is not set until build returns, so the first check waits a tick.
    Future.microtask(() {
      if (ref.mounted) refresh(ref.read(canvasControllerProvider).language);
    });
    return const {};
  }

  Future<void> refresh(InkLanguage language) async {
    if (state[language] is ModelDownloading) return;

    final checked = await _check(language);
    if (!ref.mounted) return;

    // A download may have started while the check was running.
    final current = state[language];
    if (current is ModelDownloading) return;
    // A failure stays visible until a retry, unless the model turned up.
    if (current is ModelFailed && checked is ModelNotDownloaded) return;
    _set(language, checked);
  }

  Future<void> download(InkLanguage language) async {
    final current = state[language];
    if (current is ModelDownloading || current is ModelReady) return;

    _set(language, const ModelDownloading());

    ModelStatus result;
    try {
      result = await ref.read(inkRecognizerProvider).downloadModel(language);
    } on Exception catch (e) {
      result = ModelFailed(ModelDownloadFailure(language, cause: e));
    }
    if (!ref.mounted) return;
    _set(language, result);
  }

  Future<ModelStatus> _check(InkLanguage language) async {
    try {
      return await ref.read(inkRecognizerProvider).modelStatus(language);
    } on Exception catch (e) {
      return ModelFailed(RecognitionFailure(cause: e));
    }
  }

  void _set(InkLanguage language, ModelStatus status) {
    state = {...state, language: status};
  }
}
