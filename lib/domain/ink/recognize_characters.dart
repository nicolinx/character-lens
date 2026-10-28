import 'package:character_lens/domain/ink/candidate.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/stroke.dart';
import 'package:character_lens/domain/ink/writing_area.dart';
import 'package:character_lens/domain/dictionary/dictionary.dart';
import 'package:character_lens/domain/ink/ink_recognizer.dart';

/// The recognizer also returns strings like `十木`, symbols and kana. A candidate
/// stays when it is one character with an entry. The cap comes after the
/// filter, so noise does not use up the places.
class RecognizeCharacters {
  RecognizeCharacters(this._recognizer, this._dictionary);

  static const maxCandidates = 5;

  final InkRecognizer _recognizer;
  final Dictionary _dictionary;

  Future<List<Candidate>> call(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  }) async {
    final recognized = await _recognizer.recognize(
      strokes,
      language,
      writingArea: writingArea,
    );

    final kept = <Candidate>[];
    for (final candidate in recognized) {
      if (candidate.character.runes.length != 1) continue;
      if (!await _dictionary.contains(candidate.character)) continue;
      kept.add(candidate);
      if (kept.length == maxCandidates) break;
    }
    return kept;
  }
}
