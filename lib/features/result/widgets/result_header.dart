import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/entities/character_view.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/features/result/result_labels.dart';

/// The large character, the language it was drawn in, a tag when the written
/// form differs, and the definition.
class ResultHeader extends StatelessWidget {
  const ResultHeader({
    super.key,
    required this.character,
    required this.language,
    this.variant,
    this.definition,
  });

  final String character;
  final HanLanguage language;
  final FormVariant? variant;
  final String? definition;

  @override
  Widget build(BuildContext context) {
    final definition = this.definition;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          // Already large, so it does not grow with the text scale. Letting it
          // would push the tags off a narrow screen.
          Text(
            character,
            locale: language.locale,
            textScaler: TextScaler.noScaling,
            style: AppText.serif(size: 104, weight: 500, height: 1.05),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      language.name,
                      color: AppColors.seal,
                      textColor: const Color(0xFFFFFFFF),
                    ),
                    if (variant != null)
                      _Tag(
                        variantText(variant!),
                        border: AppColors.line,
                        textColor: AppColors.muted,
                      ),
                  ],
                ),
                if (definition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    definition,
                    style: AppText.serif(
                      size: 17,
                      italic: true,
                      color: AppColors.muted,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color, this.border, required this.textColor});

  final String text;
  final Color? color;
  final Color? border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        text,
        style: AppText.sans(
          size: 11.5,
          weight: border == null ? 600 : 500,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
