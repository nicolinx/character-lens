import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';

abstract interface class Explainer {
  /// Explains [entry] for a reader of [language]. Throws an
  /// `ExplanationFailure` when it cannot.
  Future<Explanation> explain(CharacterEntry entry, HanLanguage language);
}
