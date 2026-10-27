import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';

class CandidateSwitcher extends StatelessWidget {
  const CandidateSwitcher({
    super.key,
    required this.candidates,
    required this.current,
    required this.locale,
    required this.onSelected,
  });

  final List<String> candidates;
  final String current;
  final Locale locale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (candidates.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Not it?',
            style: AppText.sans(size: 12, color: AppColors.muted),
          ),
          for (final candidate in candidates)
            _SwitchChip(
              character: candidate,
              locale: locale,
              selected: candidate == current,
              onTap: () => onSelected(candidate),
            ),
        ],
      ),
    );
  }
}

class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.character,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final String character;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Switch to $character',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          key: Key('switch-$character'),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.sealSoft : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.seal : AppColors.line,
            ),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              character,
              locale: locale,
              style: AppText.serif(size: 21, weight: 500, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
