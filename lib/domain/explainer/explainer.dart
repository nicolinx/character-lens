import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';

abstract interface class Explainer {
  /// Part of the cache key, so a new prompt never reuses an old answer.
  String get promptVersion;

  /// Explains [entry] for a reader of [language]. Throws an
  /// `ExplanationFailure` when it cannot.
  Future<Explanation> explain(CharacterEntry entry, HanLanguage language);
}
