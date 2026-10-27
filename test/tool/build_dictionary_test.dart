import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../tool/build_dictionary.dart';

const _fixture = 'test/fixtures/unihan';

void main() {
  late Directory temp;
  late String output;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('dictionary_build_');
    output = '${temp.path}/dictionary.db';
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Database open() => sqlite3.open(output, mode: OpenMode.readOnly);

  Row entry(Database db, String character) => db.select(
    'SELECT * FROM entry WHERE codepoint = ?',
    [character.runes.first],
  ).single;

  BuildReport build({DateTime? now}) => buildDictionary(
    unihanDir: Directory(_fixture),
    outputPath: output,
    now: now ?? DateTime.utc(2026, 10, 27, 1, 2, 3),
  );

  test('keeps the characters that have a reading or a definition', () {
    final report = build();
    final db = open();
    addTearDown(db.close);

    final characters = db
        .select('SELECT character FROM entry ORDER BY codepoint')
        .map((r) => r['character'] as String)
        .toList();

    expect(characters, [
      '丂',
      '学',
      '學',
      '木',
      '气',
      '気',
      '氣',
      '語',
      '语',
      String.fromCharCode(0x20000),
    ]);
    expect(report.rows, 10);
  });

  test('leaves out a character that has only a stroke count', () {
    build();
    final db = open();
    addTearDown(db.close);

    final rows = db.select('SELECT 1 FROM entry WHERE codepoint = ?', [
      0x20002,
    ]);

    expect(rows, isEmpty);
  });

  test('writes every field of a full entry', () {
    build();
    final db = open();
    addTearDown(db.close);

    final row = entry(db, '語');

    expect(row['character'], '語');
    expect(row['definition'], 'language, words; saying, expression');
    expect(row['mandarin'], 'yǔ');
    expect(row['ja_on'], 'GO GYO');
    expect(row['ja_kun'], 'KATARU KOTOBA TSUGERU');
    expect(row['ja_kana'], 'ゴ ギョ かたる かたらう ことば つげる');
    expect(row['hangul'], '어');
    expect(row['simplified'], '语');
    expect(row['traditional'], isNull);
    expect(row['strokes'], 14);
  });

  test('stores a missing field as NULL', () {
    build();
    final db = open();
    addTearDown(db.close);

    final row = entry(db, '语');

    expect(row['definition'], isNotNull);
    expect(row['ja_on'], isNull);
    expect(row['hangul'], isNull);
  });

  test('stores several variants in the order Unihan lists them', () {
    build();
    final db = open();
    addTearDown(db.close);

    expect(entry(db, '气')['traditional'], '气 氣');
  });

  test('stores a code point above the BMP as one character', () {
    build();
    final db = open();
    addTearDown(db.close);

    final row = entry(db, String.fromCharCode(0x20000));

    expect(row['mandarin'], 'hē');
    expect(row['strokes'], 2);
  });

  test('records where the data came from', () {
    build(now: DateTime.utc(2026, 10, 27, 1, 2, 3));
    final db = open();
    addTearDown(db.close);

    final meta = {
      for (final r in db.select('SELECT key, value FROM meta'))
        r['key'] as String: r['value'] as String,
    };

    expect(meta, {
      'unihan_version': '18.0.0',
      'unihan_date': '2026-07-31',
      'built_at': '2026-10-27T01:02:03.000Z',
    });
  });

  test('reports the size of the file it wrote', () {
    final report = build();

    expect(report.bytes, File(output).lengthSync());
    expect(report.bytes, greaterThan(0));
    expect(report.version, '18.0.0');
  });

  test('replaces a database that is already there', () {
    File(output).writeAsStringSync('not a database');

    final report = build();

    expect(report.rows, 10);
  });

  test('creates the output folder when it is missing', () {
    output = '${temp.path}/assets/db/dictionary.db';

    build();

    expect(File(output).existsSync(), isTrue);
  });

  test('says which file is missing', () {
    final empty = Directory('${temp.path}/empty')..createSync();

    expect(
      () => buildDictionary(unihanDir: empty, outputPath: output),
      throwsA(
        isA<BuildFailure>().having(
          (e) => e.message,
          'message',
          contains('Unihan_Readings.txt'),
        ),
      ),
    );
  });
}
