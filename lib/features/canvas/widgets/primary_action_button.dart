import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/result/result_sheet.dart';
import 'package:character_lens/features/canvas/controllers/model_status_controller.dart';

/// The one main action. "Analyze" recognizes now instead of waiting for the
/// pause, and is the way to try again after an error. Once there is a result it
/// becomes "Look up" plus the selected character and opens the result sheet.
class PrimaryActionButton extends ConsumerWidget {
  const PrimaryActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasControllerProvider);
    final drawingEnabled = ref.watch(drawingEnabledProvider);
    final busy = state is CanvasRecognizing;
    final canAnalyze = drawingEnabled && !busy && state.strokes.isNotEmpty;
    final controller = ref.read(canvasControllerProvider.notifier);

    final VoidCallback? onPressed;
    final String label;
    if (state case CanvasResult(:final selected, :final language)) {
      label = 'Look up ${selected.character}';
      onPressed = () => showResultSheet(
        context,
        ref,
        character: selected.character,
        language: language,
        candidates: [for (final c in state.candidates) c.character],
        onSwitched: (character) => controller.selectCandidate(
          state.candidates.indexWhere((c) => c.character == character),
        ),
      );
    } else {
      label = busy ? 'Recognizing…' : 'Analyze';
      onPressed = canAnalyze ? controller.analyze : null;
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.seal,
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: AppColors.seal.withValues(alpha: 0.6),
          disabledForegroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: AppText.sans(
                size: 16,
                weight: 600,
                color: const Color(0xFFFFFFFF),
                letterSpacing: 0.16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
