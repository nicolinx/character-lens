import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Used when the app was built without Firebase settings.
class UnavailableExplainer implements Explainer {
  @override
  Future<Explanation> explain(CharacterEntry entry, HanLanguage language) =>
      Future.error(const ExplainerNotConfiguredFailure());
}
