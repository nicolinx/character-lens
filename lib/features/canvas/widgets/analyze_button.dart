import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/controllers/model_status_controller.dart';

/// Recognizes now instead of waiting for the pause. Also the way to try again
/// after an error.
class AnalyzeButton extends ConsumerWidget {
  const AnalyzeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasControllerProvider);
    final drawingEnabled = ref.watch(drawingEnabledProvider);
    final busy = state is CanvasRecognizing;
    final canAnalyze = drawingEnabled && !busy && state.strokes.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canAnalyze
            ? ref.read(canvasControllerProvider.notifier).analyze
            : null,
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
              busy ? 'Recognizing…' : 'Analyze',
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
