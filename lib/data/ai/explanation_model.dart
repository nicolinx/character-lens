import 'package:character_lens/data/ai/explanation_prompt_builder.dart';

/// One call to the language model, returning the text of its answer. A thin
/// seam over the Firebase plugin, so [LlmExplainer] can be tested with a
/// fake. Implementations throw an `ExplanationFailure`, never a plugin error.
abstract interface class ExplanationModel {
  Future<String> generate(ExplanationPrompt prompt);
}
