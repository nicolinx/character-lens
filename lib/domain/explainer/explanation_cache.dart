import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation.dart';

/// One explanation per character, language and prompt version, so a new prompt
/// never serves an answer made by an older one.
class ExplanationKey extends Equatable {
  const ExplanationKey({
    required this.character,
    required this.language,
    required this.promptVersion,
  });

  final String character;
  final HanLanguage language;
  final String promptVersion;

  @override
  List<Object?> get props => [character, language, promptVersion];
}

abstract interface class ExplanationCache {
  /// Null when there is no usable entry. Throws an
  /// `ExplanationCacheFailure` when the cache cannot be read.
  Future<Explanation?> get(ExplanationKey key);

  /// Replaces any entry for [key]. Throws an `ExplanationCacheFailure`.
  Future<void> put(ExplanationKey key, Explanation explanation);
}
