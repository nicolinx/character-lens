import 'package:character_lens/data/ai/explanation_model.dart';
import 'package:character_lens/data/ai/explanation_prompt_builder.dart';

/// Plays back a script, one item for each call: a String is returned, a
/// Future is awaited (use a Completer's future to keep a call in flight), and
/// anything else is thrown.
class FakeExplanationModel implements ExplanationModel {
  FakeExplanationModel(this.script);

  final List<Object> script;

  /// The prompts received, in order.
  final prompts = <ExplanationPrompt>[];

  int get calls => prompts.length;

  @override
  Future<String> generate(ExplanationPrompt prompt) async {
    prompts.add(prompt);
    if (script.length < prompts.length) {
      throw StateError('no scripted answer for call ${prompts.length}');
    }
    return switch (script[prompts.length - 1]) {
      final String text => text,
      final Future<String> future => future,
      final Object error => throw error,
    };
  }
}
