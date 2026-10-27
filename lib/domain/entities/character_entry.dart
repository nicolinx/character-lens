import 'package:equatable/equatable.dart';

/// One character as the dictionary stores it. Readings are kept as the source
/// gives them; the entry does not decide how they are shown.
class CharacterEntry extends Equatable {
  CharacterEntry({
    required this.character,
    this.definition,
    this.mandarin = const [],
    this.japaneseOn = const [],
    this.japaneseKun = const [],
    this.hangul = const [],
    this.simplified = const [],
    this.traditional = const [],
    this.totalStrokes,
  }) : assert(
         character.runes.length == 1,
         'an entry is exactly one character, got "$character"',
       );

  /// A single code point.
  final String character;

  /// English gloss, as one string. Many characters have none.
  final String? definition;

  /// Pinyin with tone marks.
  final List<String> mandarin;
  final List<String> japaneseOn;
  final List<String> japaneseKun;
  final List<String> hangul;

  /// Simplified forms of this character. May include the character itself.
  final List<String> simplified;

  /// Traditional forms of this character. May include the character itself,
  /// and may list more than one.
  final List<String> traditional;

  final int? totalStrokes;

  int get codePoint => character.runes.first;

  @override
  List<Object?> get props => [
    character,
    definition,
    mandarin,
    japaneseOn,
    japaneseKun,
    hangul,
    simplified,
    traditional,
    totalStrokes,
  ];
}
