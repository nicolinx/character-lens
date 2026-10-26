import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../domain/failures/ink_failure.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/canvas_state.dart';
import '../controllers/model_status_controller.dart';
import '../ink_language_labels.dart';

/// What the line under the pad says. Errors come from the state, so a failed
/// recognition keeps its message until the user draws again.
String describeCanvasStatus(CanvasState state, {required bool drawingEnabled}) {
  if (!drawingEnabled) return 'Download the model to start drawing';
  return switch (state) {
    CanvasIdle(:final strokes) =>
      strokes.isEmpty
          ? 'Ready. Draw one character'
          : 'Looking good. Pause and I’ll recognize it',
    CanvasRecognizing() => 'Recognizing…',
    CanvasResult() => 'Pick the match',
    CanvasError(:final failure) => switch (failure) {
      ModelNotDownloadedFailure(:final language) =>
        'Download the ${language.name} model first',
      ModelDownloadFailure() => 'Model download failed',
      NoCandidatesFailure() => 'No match. Try writing it larger',
      RecognitionFailure() => 'Recognition failed. Try again',
    },
  };
}

/// Status text on the left, Undo and Clear on the right.
class CanvasStatusLine extends ConsumerWidget {
  const CanvasStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasControllerProvider);
    final enabled = ref.watch(drawingEnabledProvider);
    final controller = ref.read(canvasControllerProvider.notifier);

    final canEdit = state is! CanvasRecognizing && state.strokes.isNotEmpty;
    final isError = state is CanvasError && enabled;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              describeCanvasStatus(state, drawingEnabled: enabled),
              style: AppText.sans(
                size: 13,
                weight: isError ? 500 : 400,
                color: isError ? AppColors.sealDark : AppColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ToolButton(
          icon: Icons.undo_rounded,
          label: 'Undo last stroke',
          onPressed: canEdit ? controller.undo : null,
        ),
        const SizedBox(width: 6),
        _ToolButton(
          icon: Icons.delete_outline_rounded,
          label: 'Clear canvas',
          onPressed: canEdit ? controller.clear : null,
        ),
      ],
    );
  }
}

/// A round 48 dp button. The tooltip doubles as the screen reader label.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  static const _disabled = Color(0xFFBDB4A0);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        foregroundColor: AppColors.text,
        disabledForegroundColor: _disabled,
        backgroundColor: enabled ? AppColors.card : Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        side: enabled ? const BorderSide(color: AppColors.line) : null,
      ),
    );
  }
}
