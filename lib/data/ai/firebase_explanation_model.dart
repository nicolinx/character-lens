import 'package:firebase_ai/firebase_ai.dart';

import 'package:character_lens/data/ai/explanation_model.dart';
import 'package:character_lens/data/ai/explanation_prompt_builder.dart';
import 'package:character_lens/data/ai/explanation_schema.dart';
import 'package:character_lens/data/ai/firebase_failure_mapper.dart';

/// Chosen from the models page of Firebase AI Logic (2026-10-27): stable, no
/// shutdown announced before 2027-05-07, and no paid plan needed. Change
/// `promptVersion` along with it when old cached answers should not be reused.
const geminiModelName = 'gemini-3.1-flash-lite';

/// Asks Gemini through Firebase AI Logic for JSON that follows the schema.
/// Call it only after Firebase has started.
class FirebaseExplanationModel implements ExplanationModel {
  FirebaseExplanationModel({FirebaseAI? firebaseAI})
    : _ai = firebaseAI ?? FirebaseAI.googleAI();

  final FirebaseAI _ai;

  @override
  Future<String> generate(ExplanationPrompt prompt) async {
    final model = _ai.generativeModel(
      model: geminiModelName,
      systemInstruction: Content.system(prompt.system),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseJsonSchema: explanationSchemaV1,
      ),
    );
    try {
      final response = await model.generateContent([Content.text(prompt.user)]);
      return response.text ?? '';
    } on Exception catch (error) {
      throw explanationFailureFor(error);
    }
  }
}
