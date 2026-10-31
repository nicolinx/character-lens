import 'dart:async';

import 'package:character_lens/data/ai/explanation_model.dart';
import 'package:character_lens/data/ai/explanation_parser.dart';
import 'package:character_lens/data/ai/explanation_prompt_builder.dart';
import 'package:character_lens/data/ai/prompt_v1.dart' as prompt;
import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Explains a character with a language model, grounded on its dictionary
/// entry. Works with any [ExplanationModel]; the Gemini call is in
/// `FirebaseExplanationModel`.
///
/// An invalid answer is asked for once more, then dropped. Other failures are
/// not retried.
class LlmExplainer implements Explainer {
  LlmExplainer(
    this._model, {
    ExplanationPromptBuilder? promptBuilder,
    this.timeout = defaultTimeout,
  }) : _promptBuilder = promptBuilder ?? ExplanationPromptBuilder();

  /// Per attempt. In 20 calls the slowest took 8.7 s and the median was 3.2 to
  /// 3.9 s, so this leaves room without a long skeleton. Not tuned further.
  static const defaultTimeout = Duration(seconds: 15);

  /// One answer, plus one retry when the first is invalid.
  static const attempts = 2;

  final ExplanationModel _model;
  final ExplanationPromptBuilder _promptBuilder;
  final Duration timeout;

  @override
  String get promptVersion => prompt.promptVersion;

  @override
  Future<Explanation> explain(
    CharacterEntry entry,
    HanLanguage language,
  ) async {
    final prompt = _promptBuilder.build(entry, language);
    ExplainerInvalidOutputFailure? invalid;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      final String text;
      try {
        text = await _model.generate(prompt).timeout(timeout);
      } on TimeoutException {
        throw const ExplainerTimeoutFailure();
      } on ExplanationFailure {
        rethrow;
      } on Exception catch (error) {
        throw ExplainerFailure(cause: error);
      }

      try {
        return parseExplanation(text);
      } on ExplainerInvalidOutputFailure catch (failure) {
        invalid = failure;
      }
    }
    throw invalid!;
  }
}
