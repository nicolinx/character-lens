import 'package:character_lens/domain/dictionary/character_entry.dart';

abstract interface class Dictionary {
  /// Null when the character is not in the dictionary. Throws a
  /// `DictionaryFailure` when the dictionary cannot be read.
  Future<CharacterEntry?> lookup(String character);

  Future<bool> contains(String character);
}
