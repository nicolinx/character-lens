import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../domain/entities/ink_language.dart';
import '../../../domain/entities/model_status.dart';
import '../controllers/canvas_controller.dart';
import '../ink_language_labels.dart';
import '../controllers/model_status_controller.dart';

/// Short state of a model, for the screen reader and the tabs.
String describeModelStatus(ModelStatus? status) => switch (status) {
  null => 'checking model',
  ModelNotDownloaded() => 'model not downloaded',
  ModelDownloading() => 'downloading model',
  ModelReady() => 'model ready',
  ModelFailed() => 'model download failed',
};

/// One line under the tabs: the selected language's model state, with a
/// Download or Retry button when there is something to do.
class ModelStatusLine extends ConsumerWidget {
  const ModelStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      canvasControllerProvider.select((s) => s.language),
    );
    final status = ref.watch(selectedModelStatusProvider);

    final action = switch (status) {
      ModelNotDownloaded() => 'Download',
      ModelFailed() => 'Retry',
      _ => null,
    };

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _text(language, status),
                      style: AppText.sans(size: 12.5, color: AppColors.muted),
                    ),
                  ),
                ),
                if (action != null)
                  _ActionButton(
                    label: action,
                    onTap: () => ref
                        .read(modelStatusControllerProvider.notifier)
                        .download(language),
                  ),
              ],
            ),
          ),
        ),
        if (status is ModelDownloading)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.seal,
              backgroundColor: AppColors.line,
            ),
          ),
      ],
    );
  }

  String _text(InkLanguage language, ModelStatus? status) => switch (status) {
    null => 'Checking ${language.name} model…',
    ModelNotDownloaded() => '${language.name} model · not downloaded',
    ModelDownloading() => 'Downloading ${language.name} model…',
    ModelReady() => '${language.name} model ready · on-device',
    ModelFailed() => 'Download failed. Check your connection',
  };
}

/// A 32 dp pill inside a 48 dp tap target.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.seal, width: 1.5),
            ),
            child: Text(
              label,
              style: AppText.sans(
                size: 12.5,
                weight: 600,
                color: AppColors.seal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
