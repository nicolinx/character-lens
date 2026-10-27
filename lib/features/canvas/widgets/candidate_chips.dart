import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/controllers/canvas_state.dart';
import 'package:character_lens/features/canvas/ink_language_labels.dart';

/// The recognized candidates, best first. Tapping one selects it.
class CandidateChips extends ConsumerWidget {
  const CandidateChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasControllerProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Align(
        alignment: Alignment.centerLeft,
        child: switch (state) {
          CanvasResult() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, candidate) in state.candidates.indexed)
                _Chip(
                  character: candidate.character,
                  rank: i + 1,
                  locale: state.language.locale,
                  selected: i == state.selectedIndex,
                  onTap: () => ref
                      .read(canvasControllerProvider.notifier)
                      .selectCandidate(i),
                ),
            ],
          ),
          _ => Text(
            'Matches appear here after you draw',
            style: AppText.serif(
              size: 13,
              italic: true,
              color: const Color(0xFF8F8672),
            ),
          ),
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.character,
    required this.rank,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final String character;
  final int rank;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Candidate $rank: $character',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.sealSoft : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.seal : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          // Container's own alignment would fill the whole row; a shrink-wrapped
          // Align centers the character inside the 48 dp minimum instead.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              character,
              locale: locale,
              style: AppText.serif(size: 25, weight: 500, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
