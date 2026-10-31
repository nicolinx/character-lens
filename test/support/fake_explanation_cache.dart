import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';

class FakeExplanationCache implements ExplanationCache {
  final entries = <ExplanationKey, Explanation>{};

  Object? getError;
  Object? putError;

  final gets = <ExplanationKey>[];
  final puts = <ExplanationKey>[];

  @override
  Future<Explanation?> get(ExplanationKey key) async {
    gets.add(key);
    if (getError != null) throw getError!;
    return entries[key];
  }

  @override
  Future<void> put(ExplanationKey key, Explanation explanation) async {
    puts.add(key);
    if (putError != null) throw putError!;
    entries[key] = explanation;
  }
}
