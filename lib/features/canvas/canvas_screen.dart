import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/model_status.dart';
import 'language_selector.dart';
import 'model_status_controller.dart';
import 'model_status_line.dart';

class CanvasScreen extends StatelessWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Brand(),
              SizedBox(height: 18),
              LanguageSelector(),
              SizedBox(height: 4),
              ModelStatusLine(),
              SizedBox(height: 10),
              WritingPad(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.rotate(
          angle: -0.07,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.seal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '字',
              style: TextStyle(
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Character Lens',
          style: TextStyle(fontSize: 22, height: 1, color: AppColors.text),
        ),
      ],
    );
  }
}

/// The square writing area. Step 7 draws the grid and strokes inside it; for
/// now it only shows whether drawing is allowed and why not.
class WritingPad extends ConsumerWidget {
  const WritingPad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(selectedModelStatusProvider);
    final enabled = status is ModelReady;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.seal, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: enabled
            ? const _PadHint(
                title: 'Write one character',
                subtitle: 'Strokes stay on your device',
              )
            : Semantics(
                liveRegion: true,
                child: Text(
                  status == null
                      ? 'Checking the model…'
                      : 'Download the model to start',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ),
      ),
    );
  }
}

class _PadHint extends StatelessWidget {
  const _PadHint({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            height: 1.2,
            fontStyle: FontStyle.italic,
            color: Color(0xFF7B705C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
      ],
    );
  }
}
