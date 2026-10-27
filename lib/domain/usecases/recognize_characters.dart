import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/repositories/dictionary.dart';
import 'package:character_lens/domain/repositories/ink_recognizer.dart';

/// Recognizes strokes and keeps only candidates the dictionary can look up.
///
/// The recognizer also returns multi-character strings (`十木`), symbols and
/// kana. A candidate stays when it is exactly one character and has an entry.
/// The cap comes after the filter, so noise does not use up the places.
class RecognizeCharacters {
  RecognizeCharacters(this._recognizer, this._dictionary);

  static const maxCandidates = 5;

  final InkRecognizer _recognizer;
  final Dictionary _dictionary;

  /// Best first, at most [maxCandidates]. Empty when nothing was recognized or
  /// nothing is in the dictionary. Throws what the recognizer or the
  /// dictionary throws.
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
