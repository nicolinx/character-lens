import 'dart:convert';

import 'package:character_lens/domain/explainer/explanation.dart';

/// The text form of an [Explanation], in the shape of the answer schema, so
/// `parseExplanation` reads it back.
String encodeExplanation(Explanation explanation) => jsonEncode({
  'components': [
    for (final component in explanation.components)
      {'part': component.part, 'role': component.role},
  ],
  'mnemonic': explanation.mnemonic,
  'examples': [
    for (final example in explanation.examples)
      {
        'word': example.word,
        'reading': example.reading,
        'meaning': example.meaning,
      },
  ],
  'usage_note': ?explanation.usageNote,
});
