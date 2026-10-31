import 'package:character_lens/data/ai/prompt_v1.dart' as prompt;
import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Used when the app was built without Firebase settings.
class UnavailableExplainer implements Explainer {
  // The real version, so answers cached by an earlier run are found.
  @override
  String get promptVersion => prompt.promptVersion;

  @override
  Future<Explanation> explain(CharacterEntry entry, HanLanguage language) =>
      Future.error(const ExplainerNotConfiguredFailure());
}
