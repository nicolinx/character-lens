import 'dart:async';

import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/domain/explainer/explanation.dart';

class FakeExplainer implements Explainer {
  FakeExplainer({this.promptVersion = 'prompt_test'});

  @override
  final String promptVersion;

  Explanation result = const Explanation(
    components: [],
    mnemonic: 'A memory aid.',
    examples: [
      ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood'),
    ],
  );
  final results = <String, Explanation>{};

  Object? error;

  /// A call for a character listed here waits for its completer.
  final gates = <String, Completer<void>>{};

  final calls = <(String, HanLanguage)>[];

  @override
  Future<Explanation> explain(
    CharacterEntry entry,
    HanLanguage language,
  ) async {
    calls.add((entry.character, language));
    await gates[entry.character]?.future;
    if (error != null) throw error!;
    return results[entry.character] ?? result;
  }
}
