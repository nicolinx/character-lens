import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../domain/entities/ink_language.dart';
import '../../domain/entities/model_status.dart';
import 'canvas_controller.dart';
import 'ink_language_labels.dart';
import 'model_status_controller.dart';
import 'model_status_line.dart';

/// CN / JP tabs. The dot on each tab shows that language's model state.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      canvasControllerProvider.select((s) => s.language),
    );
    final statuses = ref.watch(modelStatusControllerProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (final language in InkLanguage.values)
            Expanded(
              child: _LanguageTab(
                language: language,
                status: statuses[language],
                selected: language == selected,
                onTap: () => ref
                    .read(canvasControllerProvider.notifier)
                    .selectLanguage(language),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTab extends StatelessWidget {
  const _LanguageTab({
    required this.language,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final InkLanguage language;
  final ModelStatus? status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.text : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '${language.name}, ${describeModelStatus(status)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.only(top: 8, bottom: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.seal : const Color(0x00000000),
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    language.glyph,
                    locale: language.locale,
                    style: AppText.serif(
                      size: 22,
                      weight: 500,
                      height: 1,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StatusDot(status),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                language.name.toUpperCase(),
                style: AppText.sans(
                  size: 11,
                  weight: 600,
                  letterSpacing: 1.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.status);

  final ModelStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ModelReady() => AppColors.moss,
      ModelDownloading() || ModelFailed() => AppColors.seal,
      ModelNotDownloaded() || null => AppColors.idleDot,
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
