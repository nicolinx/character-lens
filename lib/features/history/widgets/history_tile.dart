import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/history/history_item.dart';
import 'package:character_lens/features/history/history_labels.dart';
import 'package:character_lens/features/result/result_labels.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
  });

  final HistoryItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final language = entry.language.han;
    final view = item.view;
    final reading = view?.readings[language];
    final ago = agoText(entry.openedAt, now);

    // Beside the text there is no room for the tag and the time at large
    // sizes, so they go underneath.
    final large = MediaQuery.textScalerOf(context).scale(10) > 13;
    final side = _Side(code: language.code, ago: ago);

    return Semantics(
      button: true,
      label: 'Open ${entry.character}, ${language.name}, $ago',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                // Already large, so it does not grow with the text scale.
                child: Text(
                  view?.form ?? entry.character,
                  locale: language.locale,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: AppText.serif(size: 38, weight: 500, height: 1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (view == null)
                      Text(
                        'Dictionary data is not available',
                        style: AppText.sans(size: 13, color: AppColors.muted),
                      )
                    else ...[
                      Text(
                        reading == null || reading.isEmpty
                            ? 'No reading'
                            : readingText(reading),
                        style: AppText.sans(size: 15, weight: 600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        view.entry.definition ?? 'No definition in Unihan',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 13, color: AppColors.muted),
                      ),
                    ],
                    if (large) ...[const SizedBox(height: 6), side],
                  ],
                ),
              ),
              if (!large) ...[const SizedBox(width: 14), side],
            ],
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.code, required this.ago});

  final String code;
  final String ago;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.seal,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            code,
            style: AppText.sans(
              size: 11.5,
              weight: 600,
              color: const Color(0xFFFFFFFF),
              letterSpacing: 0.4,
            ),
          ),
        ),
        Text(ago, style: AppText.sans(size: 11.5, color: AppColors.muted)),
      ],
    );
  }
}
