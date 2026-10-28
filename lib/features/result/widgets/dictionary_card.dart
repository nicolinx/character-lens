import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/entities/character_view.dart';
import 'package:character_lens/features/result/result_labels.dart';
import 'package:character_lens/features/result/widgets/result_card.dart';

class DictionaryCard extends StatelessWidget {
  const DictionaryCard({super.key, required this.view});

  final CharacterView view;

  @override
  Widget build(BuildContext context) {
    final definition = view.entry.definition;
    return ResultCard(
      title: 'Dictionary',
      trailing: const _VerifiedBadge(),
      child: Column(
        children: [
          _Row(
            label: view.selected.readingLabel,
            child: _Reading(view.readings[view.selected]!),
          ),
          _Row(
            label: 'Meaning',
            child: definition == null
                ? Text(
                    'No definition in Unihan',
                    style: AppText.serif(
                      size: 16,
                      italic: true,
                      color: AppColors.muted,
                    ),
                  )
                : Text(definition, style: AppText.serif(size: 19, weight: 600)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppText.sans(size: 12, color: AppColors.muted),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading(this.reading);

  final LanguageReading reading;

  @override
  Widget build(BuildContext context) {
    if (reading.isEmpty) {
      return Text(
        'No reading in Unihan',
        style: AppText.serif(size: 16, italic: true, color: AppColors.muted),
      );
    }
    final borrowedFrom = reading.borrowedFrom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(readingText(reading), style: AppText.serif(size: 19, weight: 600)),
        if (borrowedFrom != null)
          Text(
            'from $borrowedFrom',
            style: AppText.sans(size: 12, color: AppColors.muted),
          ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mossSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: AppColors.moss),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Verified · Unihan',
              style: AppText.sans(
                size: 11.5,
                weight: 600,
                color: AppColors.moss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
