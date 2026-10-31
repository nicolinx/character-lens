import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:character_lens/features/result/controllers/explain_state.dart';
import 'package:character_lens/features/result/result_labels.dart';
import 'package:character_lens/features/result/widgets/result_card.dart';

/// The AI section. Kept apart from the dictionary card and always labeled.
class ExplainCard extends StatelessWidget {
  const ExplainCard({super.key, required this.state, required this.locale});

  final ExplainState state;

  /// The language of the sheet, so the characters take the right glyphs.
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return ResultCard(
      title: 'Explain it',
      trailing: const _AiBadge(),
      child: Semantics(
        liveRegion: true,
        child: switch (state) {
          // The card only shows once the entry is loaded, so idle is a moment
          // before loading starts.
          ExplainIdle() || ExplainLoading() => const _Skeleton(),
          ExplainReady(:final result) => _Body(result: result, locale: locale),
          ExplainUnavailable(:final failure) => Text(
            explainUnavailableMessage(failure),
            style: AppText.sans(size: 14, color: AppColors.muted, height: 1.4),
          ),
        },
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.aiSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: AppColors.ai),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'AI-generated',
              style: AppText.sans(size: 11.5, weight: 600, color: AppColors.ai),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: width,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Semantics(
      label: 'Generating explanation',
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            bar(0.38),
            bar(0.92),
            bar(0.8),
            const SizedBox(height: 4),
            bar(0.55),
            bar(0.86),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.result, required this.locale});

  final ValidatedExplanation result;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final explanation = result.explanation;
    final note = explanation.usageNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        if (explanation.components.isNotEmpty)
          _Block(
            title: 'Components',
            child: Column(
              children: [
                for (final component in explanation.components)
                  _ComponentRow(component: component, locale: locale),
              ],
            ),
          ),
        _Block(
          title: 'Memory hook',
          child: Text(
            explanation.mnemonic,
            style: AppText.serif(size: 18, italic: true, height: 1.4),
          ),
        ),
        if (explanation.examples.isNotEmpty)
          _Block(
            title: 'Example words',
            child: Column(
              children: [
                for (final (i, example) in explanation.examples.indexed)
                  _ExampleRow(
                    example: example,
                    verified: result.checks[i] == ReadingCheck.verified,
                    locale: locale,
                  ),
              ],
            ),
          ),
        if (note != null)
          _Block(
            title: 'CN vs JP',
            child: Text(note, style: AppText.sans(size: 14, height: 1.45)),
          ),
        const _Foot(),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppText.sans(
              size: 11,
              weight: 600,
              color: AppColors.muted,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.component, required this.locale});

  final ExplanationComponent component;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            // Already large, so it does not grow with the text scale.
            child: Text(
              component.part,
              locale: locale,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: AppText.serif(size: 26, weight: 500, height: 1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              component.role,
              style: AppText.sans(size: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.example,
    required this.verified,
    required this.locale,
  });

  final ExplanationExample example;
  final bool verified;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              example.word,
              locale: locale,
              style: AppText.serif(size: 20, weight: 500, height: 1.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.reading,
                  style: AppText.sans(size: 14, weight: 600),
                ),
                Text(
                  example.meaning,
                  style: AppText.sans(size: 13, color: AppColors.muted),
                ),
                if (!verified) const _UnverifiedFlag(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnverifiedFlag extends StatelessWidget {
  const _UnverifiedFlag();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Tooltip(
        message: 'The dictionary does not confirm this reading',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.flagSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Unverified reading',
            style: AppText.sans(size: 11, weight: 600, color: AppColors.flag),
          ),
        ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        'Readings above come from the dictionary. Memory hooks can be '
        'plausible-sounding folk etymology.',
        style: AppText.sans(size: 12, color: AppColors.muted, height: 1.4),
      ),
    );
  }
}
