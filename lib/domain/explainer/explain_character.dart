import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/explainer/explanation_cache_failure.dart';
import 'package:character_lens/domain/explainer/explanation_validator.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';

/// Cache first, then the explainer, then each example is checked against the
/// entry. A broken cache is a miss, and a failed explainer is not cached.
class ExplainCharacter {
  ExplainCharacter({
    required this._explainer,
    required this._cache,
    ExplanationValidator? validator,
  }) : _validator = validator ?? ExplanationValidator();

  final Explainer _explainer;
  final ExplanationCache _cache;
  final ExplanationValidator _validator;

  Future<ValidatedExplanation> call(
    CharacterEntry entry,
    HanLanguage language,
  ) async {
    final key = ExplanationKey(
      character: entry.character,
      language: language,
      promptVersion: _explainer.promptVersion,
    );

    var explanation = await _cached(key);
    if (explanation == null) {
      explanation = await _explainer.explain(entry, language);
      await _store(key, explanation);
    }
    return _validator.validate(explanation, entry, language);
  }

  Future<Explanation?> _cached(ExplanationKey key) async {
    try {
      return await _cache.get(key);
    } on ExplanationCacheFailure {
      return null;
    }
  }

  Future<void> _store(ExplanationKey key, Explanation explanation) async {
    try {
      await _cache.put(key, explanation);
    } on ExplanationCacheFailure {
      // The answer is still good.
    }
  }
}
