import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/dictionary/dictionary.dart';
import 'package:character_lens/domain/dictionary/dictionary_failure.dart';
import 'package:character_lens/domain/dictionary/resolve_character.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/history_item.dart';
import 'package:character_lens/domain/history/lookup_history.dart';

/// The history, each entry shown as the dictionary shows it now. An entry whose
/// dictionary data cannot be read is still listed, without it.
class ListHistory {
  ListHistory({
    required this._history,
    required this._dictionary,
    required this._resolve,
  });

  final LookupHistory _history;
  final Dictionary _dictionary;
  final ResolveCharacter _resolve;

  /// Throws a `LookupHistoryFailure` when the history cannot be read.
  Future<List<HistoryItem>> call() async {
    final items = <HistoryItem>[];
    for (final entry in await _history.recent()) {
      items.add(HistoryItem(entry: entry, view: await _view(entry)));
    }
    return items;
  }

  Future<CharacterView?> _view(HistoryEntry entry) async {
    try {
      final found = await _dictionary.lookup(entry.character);
      if (found == null) return null;
      return await _resolve(found, entry.language.han);
    } on DictionaryFailure {
      return null;
    }
  }
}
