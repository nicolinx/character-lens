const _vowels = 'AIUEO';

final Map<String, String> _syllables = _buildSyllables();

Map<String, String> _buildSyllables() {
  final map = <String, String>{};
  void row(String kana, String consonant, [String vowels = 'AIUEO']) {
    for (var i = 0; i < kana.length; i++) {
      if (kana[i] == ' ') continue;
      map[kana[i]] = '$consonant${vowels[i]}'.replaceAll('--', '');
    }
  }

  row('あいうえお', '');
  row('かきくけこ', 'K');
  row('さ すせそ', 'S');
  row('た  てと', 'T');
  row('なにぬねの', 'N');
  row('はひ へほ', 'H');
  row('まみむめも', 'M');
  row('や ゆ よ', 'Y');
  row('らりるれろ', 'R');
  row('がぎぐげご', 'G');
  row('ざ ずぜぞ', 'Z');
  row('だ  でど', 'D');
  row('ばびぶべぼ', 'B');
  row('ぱぴぷぺぽ', 'P');
  map.addAll({
    'し': 'SHI',
    'ち': 'CHI',
    'つ': 'TSU',
    'ふ': 'FU',
    'じ': 'JI',
    'ぢ': 'JI',
    'づ': 'ZU',
    'わ': 'WA',
    'ゐ': 'I',
    'ゑ': 'E',
    'を': 'O',
    'ん': 'N',
  });
  return map;
}

/// The consonant part that a small ゃ, ゅ or ょ joins to.
const _youonStart = {
  'き': 'KY',
  'し': 'SH',
  'ち': 'CH',
  'に': 'NY',
  'ひ': 'HY',
  'み': 'MY',
  'り': 'RY',
  'ぎ': 'GY',
  'じ': 'J',
  'ぢ': 'J',
  'び': 'BY',
  'ぴ': 'PY',
};

const _smallYa = {'ゃ': 'A', 'ゅ': 'U', 'ょ': 'O'};

/// Spells a Japanese reading in kana the way Unihan spells its readings:
/// Hepburn (SHI, CHI, TSU, FU, JI), uppercase, with long vowels written out as
/// two vowels (JUU, SHOU).
///
/// Returns null when the text is not plain kana, so a caller can tell "cannot
/// check" from "checked and different". Katakana is read like hiragana.
String? romanizeKana(String reading) {
  final kana = _toHiragana(reading.replaceAll(RegExp(r'[\s・\-]'), ''))
      .split('');
  if (kana.isEmpty) return null;

  final out = StringBuffer();
  var doubleNext = false;

  bool add(String syllable) {
    if (doubleNext) {
      if (_vowels.contains(syllable[0]) || syllable == 'N') return false;
      out.write(syllable.startsWith('CH') ? 'T' : syllable[0]);
      doubleNext = false;
    }
    out.write(syllable);
    return true;
  }

  for (var i = 0; i < kana.length; i++) {
    final c = kana[i];
    if (c == 'っ') {
      if (doubleNext) return null;
      doubleNext = true;
      continue;
    }
    if (c == 'ー') {
      final text = out.toString();
      if (doubleNext ||
          text.isEmpty ||
          !_vowels.contains(text[text.length - 1])) {
        return null;
      }
      out.write(text[text.length - 1]);
      continue;
    }
    final next = i + 1 < kana.length ? kana[i + 1] : null;
    if (_youonStart.containsKey(c) && _smallYa.containsKey(next)) {
      if (!add('${_youonStart[c]}${_smallYa[next]}')) return null;
      i++;
      continue;
    }
    final syllable = _syllables[c];
    if (syllable == null || !add(syllable)) return null;
  }
  return doubleNext ? null : out.toString();
}

String _toHiragana(String text) => String.fromCharCodes(
  text.runes.map((r) => r >= 0x30A1 && r <= 0x30F6 ? r - 0x60 : r),
);
