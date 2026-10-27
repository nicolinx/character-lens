import 'package:character_lens/domain/entities/character_entry.dart';

abstract interface class Dictionary {
  /// The entry for a single character, or null when it is not in the
  /// dictionary. Throws a `DictionaryFailure` when the dictionary cannot be
  /// read.
  Future<CharacterEntry?> lookup(String character);

  /// Whether [character] has an entry. Same failure behavior as [lookup].
  Future<bool> contains(String character);
}
