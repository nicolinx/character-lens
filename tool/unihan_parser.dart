library;

const unihanFields = {
  'kDefinition',
  'kMandarin',
  'kJapaneseOn',
  'kJapaneseKun',
  'kJapanese',
  'kHangul',
  'kSimplifiedVariant',
  'kTraditionalVariant',
  'kTotalStrokes',
};

final _codePoint = RegExp(r'^U\+([0-9A-F]{4,6})$');
final _version = RegExp(r'^# Unicode Version (\S+)');
final _date = RegExp(r'^# Date: (\d{4}-\d{2}-\d{2})');

class DictionaryRow {
  const DictionaryRow({
    required this.codepoint,
    required this.character,
    required this.definition,
    required this.mandarin,
    required this.japaneseOn,
    required this.japaneseKun,
    required this.japaneseKana,
    required this.hangul,
    required this.simplified,
    required this.traditional,
    required this.strokes,
  });

  final int codepoint;
  final String character;
  final String? definition;
  final List<String> mandarin;
  final List<String> japaneseOn;
  final List<String> japaneseKun;
  final List<String> japaneseKana;
  final List<String> hangul;
  final List<String> simplified;
  final List<String> traditional;
  final int? strokes;
}

({String? version, String? date}) parseHeader(Iterable<String> lines) {
  String? version;
  String? date;
  for (final line in lines) {
    if (!line.startsWith('#')) break;
    version ??= _version.firstMatch(line)?.group(1);
    date ??= _date.firstMatch(line)?.group(1);
  }
  return (version: version, date: date);
}

void parseUnihanLines(
  Iterable<String> lines,
  Map<int, Map<String, String>> into,
) {
  for (final line in lines) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final first = line.indexOf('\t');
    if (first < 0) continue;
    final second = line.indexOf('\t', first + 1);
    if (second < 0) continue;

    final field = line.substring(first + 1, second);
    if (!unihanFields.contains(field)) continue;
    final match = _codePoint.firstMatch(line.substring(0, first));
    if (match == null) continue;

    final codepoint = int.parse(match.group(1)!, radix: 16);
    into.putIfAbsent(codepoint, () => {})[field] = line.substring(second + 1);
  }
}

List<String> splitValues(String value) => [
  for (final item in value.split(' '))
    if (item.isNotEmpty) item,
];

/// `목:0E 온:N` becomes `[목, 온]`: the source code after the colon is
/// dropped and a syllable that repeats is kept once.
List<String> parseHangul(String value) =>
    {for (final item in splitValues(value)) item.split(':').first}.toList();

/// `U+6C14 U+6C23` becomes `[气, 氣]`, in the order Unihan lists them. A
/// source suffix (`U+6C35<kMatthews`) is dropped; a value that is not a code
/// point is skipped.
List<String> parseVariants(String value) {
  final variants = <String>[];
  for (final item in splitValues(value)) {
    final match = _codePoint.firstMatch(item.split('<').first);
    if (match == null) continue;
    final codepoint = int.parse(match.group(1)!, radix: 16);
    if (!_isCharacter(codepoint)) continue;
    variants.add(String.fromCharCode(codepoint));
  }
  return variants;
}

int? parseStrokes(String value) =>
    int.tryParse(splitValues(value).firstOrNull ?? '');

/// Builds a row from the fields collected for one code point. Returns null for
/// a character with no reading and no definition: variants or a stroke count
/// alone give the sheet nothing to show.
DictionaryRow? toRow(int codepoint, Map<String, String> fields) {
  List<String> list(String field) => splitValues(fields[field] ?? '');

  final definition = fields['kDefinition']?.trim();
  final row = DictionaryRow(
    codepoint: codepoint,
    character: String.fromCharCode(codepoint),
    definition: definition == null || definition.isEmpty ? null : definition,
    mandarin: list('kMandarin'),
    japaneseOn: list('kJapaneseOn'),
    japaneseKun: list('kJapaneseKun'),
    japaneseKana: list('kJapanese'),
    hangul: parseHangul(fields['kHangul'] ?? ''),
    simplified: parseVariants(fields['kSimplifiedVariant'] ?? ''),
    traditional: parseVariants(fields['kTraditionalVariant'] ?? ''),
    strokes: parseStrokes(fields['kTotalStrokes'] ?? ''),
  );

  final hasContent =
      row.definition != null ||
      row.mandarin.isNotEmpty ||
      row.japaneseOn.isNotEmpty ||
      row.japaneseKun.isNotEmpty ||
      row.japaneseKana.isNotEmpty ||
      row.hangul.isNotEmpty;
  return hasContent ? row : null;
}

bool _isCharacter(int codepoint) =>
    codepoint <= 0x10FFFF && (codepoint < 0xD800 || codepoint > 0xDFFF);
