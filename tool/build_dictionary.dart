/// Builds `assets/db/dictionary.db` from the Unihan text files.
///
///     dart run tool/build_dictionary.dart <unihan folder> [output path]
///
/// The folder is the extracted Unihan.zip. It is not part of the repo.
library;

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'unihan_parser.dart';

const _readings = 'Unihan_Readings.txt';
const _sourceFiles = [
  _readings,
  'Unihan_Variants.txt',
  'Unihan_IRGSources.txt',
];
const _defaultOutput = 'assets/db/dictionary.db';

class BuildFailure implements Exception {
  const BuildFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class BuildReport {
  const BuildReport({
    required this.rows,
    required this.bytes,
    required this.version,
    required this.date,
  });

  final int rows;
  final int bytes;
  final String version;
  final String date;
}

BuildReport buildDictionary({
  required Directory unihanDir,
  required String outputPath,
  DateTime? now,
}) {
  final fields = <int, Map<String, String>>{};
  var header = (version: null as String?, date: null as String?);

  for (final name in _sourceFiles) {
    final file = File('${unihanDir.path}/$name');
    if (!file.existsSync()) {
      throw BuildFailure('Missing $name in ${unihanDir.path}');
    }
    final lines = file.readAsLinesSync();
    if (name == _readings) header = parseHeader(lines);
    parseUnihanLines(lines, fields);
  }

  final version = header.version;
  final date = header.date;
  if (version == null || date == null) {
    throw const BuildFailure(
      'Could not read the Unicode version and date from $_readings',
    );
  }

  final rows = [
    for (final codepoint in fields.keys.toList()..sort())
      ?toRow(codepoint, fields[codepoint]!),
  ];

  _write(
    outputPath,
    rows,
    meta: {
      'unihan_version': version,
      'unihan_date': date,
      'built_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
    },
  );

  return BuildReport(
    rows: rows.length,
    bytes: File(outputPath).lengthSync(),
    version: version,
    date: date,
  );
}

void _write(
  String path,
  List<DictionaryRow> rows, {
  required Map<String, String> meta,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(path);
  try {
    db.execute('''
      CREATE TABLE entry (
        codepoint INTEGER PRIMARY KEY,
        character TEXT NOT NULL,
        definition TEXT,
        mandarin TEXT,
        ja_on TEXT,
        ja_kun TEXT,
        ja_kana TEXT,
        hangul TEXT,
        simplified TEXT,
        traditional TEXT,
        strokes INTEGER
      )
    ''');
    db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');

    db.execute('BEGIN');
    final insert = db.prepare(
      'INSERT INTO entry VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    for (final row in rows) {
      insert.execute([
        row.codepoint,
        row.character,
        row.definition,
        _join(row.mandarin),
        _join(row.japaneseOn),
        _join(row.japaneseKun),
        _join(row.japaneseKana),
        _join(row.hangul),
        _join(row.simplified),
        _join(row.traditional),
        row.strokes,
      ]);
    }
    insert.close();
    for (final item in meta.entries) {
      db.execute('INSERT INTO meta VALUES (?, ?)', [item.key, item.value]);
    }
    db.execute('COMMIT');
  } finally {
    db.close();
  }
}

/// Lists are stored as space separated text, NULL when empty. No stored value
/// contains a space.
String? _join(List<String> values) => values.isEmpty ? null : values.join(' ');

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'usage: dart run tool/build_dictionary.dart <unihan folder> [output]',
    );
    exitCode = 64;
    return;
  }

  try {
    final report = buildDictionary(
      unihanDir: Directory(args[0]),
      outputPath: args.length == 2 ? args[1] : _defaultOutput,
    );
    final mb = (report.bytes / (1024 * 1024)).toStringAsFixed(2);
    stdout
      ..writeln('Unihan ${report.version} (${report.date})')
      ..writeln('rows:  ${report.rows}')
      ..writeln('size:  ${report.bytes} bytes ($mb MB)');
  } on BuildFailure catch (e) {
    stderr.writeln('build failed: $e');
    exitCode = 1;
  }
}
