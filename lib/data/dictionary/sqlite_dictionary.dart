import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqlite_api.dart';

import 'package:character_lens/domain/entities/character_entry.dart';
import 'package:character_lens/domain/failures/dictionary_failure.dart';
import 'package:character_lens/domain/repositories/dictionary.dart';

typedef AssetLoader = Future<Uint8List> Function();

/// The bundled Unihan database, copied to the databases folder on first use and
/// again whenever the installed file differs from the bundled one. Opened
/// read-only.
class SqliteDictionary implements Dictionary {
  SqliteDictionary({
    required this._databaseFactory,
    required this._loadAsset,
    this._directory,
  });

  static const fileName = 'dictionary.db';

  final DatabaseFactory _databaseFactory;
  final AssetLoader _loadAsset;
  final String? _directory;

  Future<Database>? _opening;

  @override
  Future<CharacterEntry?> lookup(String character) async {
    final codepoint = _codepointOf(character);
    if (codepoint == null) return null;
    final rows = await _query('SELECT * FROM entry WHERE codepoint = ?', [
      codepoint,
    ]);
    return rows.isEmpty ? null : _toEntry(rows.first);
  }

  @override
  Future<bool> contains(String character) async {
    final codepoint = _codepointOf(character);
    if (codepoint == null) return false;
    final rows = await _query(
      'SELECT 1 FROM entry WHERE codepoint = ? LIMIT 1',
      [codepoint],
    );
    return rows.isNotEmpty;
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening == null) return;
    try {
      await (await opening).close();
    } on Exception {
      // The open had failed, so there is nothing to close.
    }
  }

  Future<List<Map<String, Object?>>> _query(
    String sql,
    List<Object?> arguments,
  ) async {
    final db = await _database();
    try {
      return await db.rawQuery(sql, arguments);
    } on Exception catch (e) {
      throw DictionaryUnavailableFailure(cause: e);
    }
  }

  /// A failed open is not kept, so the next call tries again.
  Future<Database> _database() async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } catch (_) {
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    try {
      final directory = _directory ?? await _databaseFactory.getDatabasesPath();
      final path = '$directory/$fileName';
      await _install(directory, path);

      final db = await _databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      try {
        await db.rawQuery('SELECT 1 FROM entry LIMIT 1');
      } catch (_) {
        await db.close();
        rethrow;
      }
      return db;
    } on DictionaryFailure {
      rethrow;
    } on Exception catch (e) {
      throw DictionaryUnavailableFailure(cause: e);
    }
  }

  Future<void> _install(String directory, String path) async {
    final Uint8List bundled;
    try {
      bundled = await _loadAsset();
    } catch (e) {
      // rootBundle reports a missing asset with a FlutterError, which is an
      // Error and not an Exception.
      throw DictionaryUnavailableFailure(cause: e);
    }

    final file = File(path);
    if (file.existsSync() && _sameBytes(await file.readAsBytes(), bundled)) {
      return;
    }
    await Directory(directory).create(recursive: true);
    final copy = File('$path.tmp');
    await copy.writeAsBytes(bundled, flush: true);
    await copy.rename(path);
  }

  bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int? _codepointOf(String character) {
    final runes = character.runes;
    return runes.length == 1 ? runes.first : null;
  }

  CharacterEntry _toEntry(Map<String, Object?> row) {
    List<String> list(String column) {
      final value = row[column] as String?;
      return value == null ? const <String>[] : value.split(' ');
    }

    return CharacterEntry(
      character: row['character'] as String,
      definition: row['definition'] as String?,
      mandarin: list('mandarin'),
      japaneseOn: list('ja_on'),
      japaneseKun: list('ja_kun'),
      hangul: list('hangul'),
      simplified: list('simplified'),
      traditional: list('traditional'),
      totalStrokes: row['strokes'] as int?,
    );
  }
}
