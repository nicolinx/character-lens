import 'dart:convert';

import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Turns the model's JSON text into an [Explanation].
///
/// Strict about the shape: the text must be one JSON object with the fields of
/// the schema, and every text field must be non-empty. Unknown fields are
/// ignored. Lists may be empty. A problem is an
/// [ExplainerInvalidOutputFailure] whose detail names the field, never the
/// model's text.
Explanation parseExplanation(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const ExplainerInvalidOutputFailure(detail: 'not JSON');
  }
  if (json is! Map<String, Object?>) {
    throw const ExplainerInvalidOutputFailure(detail: 'not an object');
  }

  return Explanation(
    components: [
      for (final (i, item) in _list(json, 'components').indexed)
        _component(item, 'components[$i]'),
    ],
    mnemonic: _text(json, 'mnemonic', ''),
    examples: [
      for (final (i, item) in _list(json, 'examples').indexed)
        _example(item, 'examples[$i]'),
    ],
    usageNote: _optionalText(json, 'usage_note'),
  );
}

ExplanationComponent _component(Object? item, String path) {
  final map = _object(item, path);
  return ExplanationComponent(
    part: _text(map, 'part', path),
    role: _text(map, 'role', path),
  );
}

ExplanationExample _example(Object? item, String path) {
  final map = _object(item, path);
  return ExplanationExample(
    word: _text(map, 'word', path),
    reading: _text(map, 'reading', path),
    meaning: _text(map, 'meaning', path),
  );
}

Map<String, Object?> _object(Object? item, String path) => switch (item) {
  final Map<String, Object?> map => map,
  _ => throw ExplainerInvalidOutputFailure(detail: '$path is not an object'),
};

List<Object?> _list(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      final List<Object?> list => list,
      _ => throw ExplainerInvalidOutputFailure(detail: '$key is not a list'),
    };

String _text(Map<String, Object?> json, String key, String path) =>
    switch (json[key]) {
      final String text when text.trim().isNotEmpty => text.trim(),
      _ => throw ExplainerInvalidOutputFailure(
        detail: '${path.isEmpty ? key : '$path.$key'} is missing or empty',
      ),
    };

String? _optionalText(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      null => null,
      final String text => text.trim().isEmpty ? null : text.trim(),
      _ => throw ExplainerInvalidOutputFailure(detail: '$key is not a string'),
    };
