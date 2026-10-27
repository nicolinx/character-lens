import 'dart:async';

import 'package:character_lens/domain/entities/character_entry.dart';
import 'package:character_lens/domain/repositories/dictionary.dart';

class FakeDictionary implements Dictionary {
  FakeDictionary(Iterable<CharacterEntry> entries)
    : _entries = {for (final e in entries) e.character: e};

  FakeDictionary.bare(String characters)
    : this([
        for (final rune in characters.runes)
          CharacterEntry(character: String.fromCharCode(rune)),
      ]);

  final Map<String, CharacterEntry> _entries;

  Object? error;

  final lookupErrors = <String, Object>{};

  /// A lookup of a character listed here waits for its completer, which keeps
  /// that lookup in flight.
  final gates = <String, Completer<void>>{};

  final lookups = <String>[];

  final checks = <String>[];

  @override
  Future<CharacterEntry?> lookup(String character) async {
    lookups.add(character);
    await gates[character]?.future;
    if (error != null) throw error!;
    if (lookupErrors.containsKey(character)) throw lookupErrors[character]!;
    return _entries[character];
  }

  @override
  Future<bool> contains(String character) async {
    checks.add(character);
    if (error != null) throw error!;
    return _entries.containsKey(character);
  }
}
