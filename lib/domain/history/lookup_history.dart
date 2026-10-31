import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/ink/ink_language.dart';

abstract interface class LookupHistory {
  /// Notes that [character] was looked up now. A character already there moves
  /// to the top. Throws a `LookupHistoryFailure`.
  Future<void> record(String character, InkLanguage language);

  /// Newest first, at most as many as the history keeps. Throws a
  /// `LookupHistoryFailure`.
  Future<List<HistoryEntry>> recent();
}
