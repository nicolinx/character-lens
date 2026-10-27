import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/entities/character_view.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/features/result/result_labels.dart';
import 'package:character_lens/features/result/widgets/result_card.dart';

/// The same character in Chinese, Japanese and Korean: how it is written and
/// read in each, with the language it was drawn in highlighted.
class AcrossLanguagesCard extends StatelessWidget {
  const AcrossLanguagesCard({super.key, required this.view});

  final CharacterView view;

  @override
  Widget build(BuildContext context) {
    // Three columns do not fit large text, so the items stack instead.
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 12;
    final items = [
      for (final language in HanLanguage.values)
        _Item(
          language: language,
          form: view.forms[language]!,
          reading: view.readings[language]!,
          selected: language == view.selected,
          stacked: stacked,
        ),
    ];

    return ResultCard(
      title: 'Across languages',
      trailing: Text(
        'same character',
        style: AppText.serif(size: 12, italic: true, color: AppColors.muted),
      ),
      child: stacked
          ? Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  item,
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: item),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.language,
    required this.form,
    required this.reading,
    required this.selected,
    required this.stacked,
  });

  final HanLanguage language;
  final String form;
  final LanguageReading reading;
  final bool selected;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final text = readingText(reading);
    final borrowedFrom = reading.borrowedFrom;

    final code = Text(
      language.code,
      style: AppText.sans(
        size: 10.5,
        weight: 600,
        color: AppColors.muted,
        letterSpacing: 1,
      ),
    );
    final glyph = Text(
      form,
      locale: language.locale,
      style: AppText.serif(size: 34, weight: 500, height: 1.1),
    );
    final readingWidgets = [
      Text(
        text.isEmpty ? 'No reading' : text,
        textAlign: stacked ? TextAlign.start : TextAlign.center,
        style: text.isEmpty
            ? AppText.serif(size: 12, italic: true, color: AppColors.muted)
            : AppText.sans(size: 12, weight: 500, height: 1.3),
      ),
      if (borrowedFrom != null)
        Text(
          'from $borrowedFrom',
          textAlign: stacked ? TextAlign.start : TextAlign.center,
          style: AppText.sans(size: 11, color: AppColors.muted),
        ),
    ];

    return Semantics(
      label: [
        language.name,
        form,
        text.isEmpty ? 'no reading' : text,
        if (borrowedFrom != null) 'borrowed from $borrowedFrom',
      ].join(', '),
      selected: selected,
      excludeSemantics: true,
      child: Container(
        key: Key('across-${language.code}'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.sealSoft : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.seal : AppColors.line),
        ),
        child: stacked
            ? Row(
                children: [
                  SizedBox(width: 44, child: Center(child: code)),
                  glyph,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: readingWidgets,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  code,
                  const SizedBox(height: 2),
                  glyph,
                  const SizedBox(height: 2),
                  ...readingWidgets,
                ],
              ),
      ),
    );
  }
}
