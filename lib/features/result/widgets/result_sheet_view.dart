import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/features/result/controllers/explain_state.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/speech_state.dart';
import 'package:character_lens/features/result/result_labels.dart';
import 'package:character_lens/features/result/widgets/across_languages_card.dart';
import 'package:character_lens/features/result/widgets/candidate_switcher.dart';
import 'package:character_lens/features/result/widgets/dictionary_card.dart';
import 'package:character_lens/features/result/widgets/explain_card.dart';
import 'package:character_lens/features/result/widgets/result_header.dart';

class ResultSheetView extends StatelessWidget {
  const ResultSheetView({
    super.key,
    required this.state,
    required this.candidates,
    required this.onCandidate,
    required this.onRetry,
    required this.onClose,
    this.speech = const SpeechIdle(),
    required this.onSpeak,
    this.explain = const ExplainIdle(),
  });

  final LookupOpen state;

  final List<String> candidates;
  final ValueChanged<String> onCandidate;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  final SpeechState speech;
  final ValueChanged<String> onSpeak;

  final ExplainState explain;

  @override
  Widget build(BuildContext context) {
    final language = state.language.han;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Grabber(),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close, color: AppColors.muted),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                switch (state) {
                  LookupLoaded(:final view) => ResultHeader(
                    character: view.form,
                    language: language,
                    variant: view.variantNote,
                    definition: view.entry.definition,
                    onSpeak: () => onSpeak(view.form),
                    speaking: speech is SpeechSpeaking,
                  ),
                  _ => ResultHeader(
                    character: state.character,
                    language: language,
                  ),
                },
                if (speechMessage(speech) case final message?)
                  _SpeechNote(message),
                CandidateSwitcher(
                  candidates: candidates,
                  current: state.character,
                  locale: language.locale,
                  onSelected: onCandidate,
                ),
                ...switch (state) {
                  LookupLoading() => [_Skeleton(state.character)],
                  LookupLoaded(:final view) => [
                    DictionaryCard(view: view),
                    AcrossLanguagesCard(view: view),
                    ExplainCard(state: explain, locale: language.locale),
                    const _Footer(),
                  ],
                  LookupNotFound() => [
                    _Message(
                      title: 'Not in the dictionary',
                      body:
                          'There is no entry for ${state.character}. Try '
                          'another match, or write it again.',
                    ),
                  ],
                  LookupFailed() => [
                    _Message(
                      title: 'The dictionary could not be opened',
                      body: 'If it keeps happening, restart the app.',
                      action: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.seal,
                          foregroundColor: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                },
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
String? speechMessage(SpeechState speech) => switch (speech) {
  SpeechNoVoice() => 'No voice installed for this language',
  SpeechFailed() => 'Could not play the sound',
  _ => null,
};

class _SpeechNote extends StatelessWidget {
  const _SpeechNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
          message,
          style: AppText.sans(size: 13, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFD6CCB6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton(this.character);

  final String character;

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
      label: 'Looking up $character',
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(spacing: 10, children: [bar(0.9), bar(0.7), bar(0.5)]),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.serif(size: 19, weight: 600)),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.sans(size: 14, color: AppColors.muted, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Data: Unicode Unihan · Handwriting stays on your device',
        textAlign: TextAlign.center,
        style: AppText.sans(size: 11.5, color: AppColors.muted),
      ),
    );
  }
}
