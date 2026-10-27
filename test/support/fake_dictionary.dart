import 'dart:async';

import 'package:character_lens/domain/entities/character_entry.dart';
import 'package:character_lens/domain/repositories/dictionary.dart';

/// Answers from memory, so no test touches SQLite.
class FakeDictionary implements Dictionary {
  FakeDictionary(Iterable<CharacterEntry> entries)
    : _entries = {for (final e in entries) e.character: e};

  /// One bare entry (no readings) for each character of [characters], for
  /// tests that only ask whether a character exists.
  FakeDictionary.bare(String characters)
    : this([
        for (final rune in characters.runes)
          CharacterEntry(character: String.fromCharCode(rune)),
      ]);

  final Map<String, CharacterEntry> _entries;

  /// When set, every call throws it.
  Object? error;

  /// Errors for single characters, thrown by [lookup] only.
  final lookupErrors = <String, Object>{};

  /// A lookup of a character listed here waits for its completer, which keeps
  /// that lookup in flight.
  final gates = <String, Completer<void>>{};

  /// The characters looked up, in order.
  final lookups = <String>[];

  /// The texts asked about with [contains], in order.
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
