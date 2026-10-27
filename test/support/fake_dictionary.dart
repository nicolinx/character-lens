import 'package:character_lens/domain/entities/character_entry.dart';
import 'package:character_lens/domain/repositories/dictionary.dart';

/// Answers from memory, so no test touches SQLite.
class FakeDictionary implements Dictionary {
  FakeDictionary(Iterable<CharacterEntry> entries)
    : _entries = {for (final e in entries) e.character: e};

  final Map<String, CharacterEntry> _entries;

  /// When set, every call throws it.
  Object? error;

  /// The characters looked up, in order.
  final lookups = <String>[];

  @override
  Future<CharacterEntry?> lookup(String character) async {
    lookups.add(character);
    if (error != null) throw error!;
    return _entries[character];
  }

  @override
  Future<bool> contains(String character) async {
    if (error != null) throw error!;
    return _entries.containsKey(character);
  }
}
