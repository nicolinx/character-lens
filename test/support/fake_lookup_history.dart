import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/lookup_history.dart';
import 'package:character_lens/domain/ink/ink_language.dart';

/// Keeps the history in memory, so no test touches SQLite.
class FakeLookupHistory implements LookupHistory {
  FakeLookupHistory({List<HistoryEntry>? entries}) : entries = entries ?? [];

  /// Newest first.
  final List<HistoryEntry> entries;

  /// When set, [record] or [recent] throws it.
  Object? recordError;
  Object? recentError;

  /// What [record] was asked to note, in order.
  final recorded = <(String, InkLanguage)>[];

  DateTime now = DateTime.utc(2026, 10, 31, 12);

  @override
  Future<void> record(String character, InkLanguage language) async {
    recorded.add((character, language));
    if (recordError != null) throw recordError!;
    entries.removeWhere(
      (e) => e.character == character && e.language == language,
    );
    entries.insert(
      0,
      HistoryEntry(character: character, language: language, openedAt: now),
    );
  }

  @override
  Future<List<HistoryEntry>> recent() async {
    if (recentError != null) throw recentError!;
    return List.of(entries);
  }
}
