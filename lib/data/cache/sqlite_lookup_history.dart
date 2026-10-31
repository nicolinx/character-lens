import 'dart:io';

import 'package:sqflite/sqlite_api.dart';

import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/lookup_history.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/domain/ink/ink_language.dart';

/// The last characters looked up, in a database file of their own. It is not
/// the explanation cache, whose file is deleted and made again when damaged:
/// that must never take the history with it.
class SqliteLookupHistory implements LookupHistory {
  SqliteLookupHistory({
    required this._databaseFactory,
    this._directory,
    this.capacity = defaultCapacity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const fileName = 'history.db';
  static const defaultCapacity = 50;

  final DatabaseFactory _databaseFactory;
  final String? _directory;
  final int capacity;
  final DateTime Function() _clock;

  Future<Database>? _opening;

  @override
  Future<void> record(String character, InkLanguage language) async {
    final db = await _database();
    try {
      await db.transaction((txn) async {
        await txn.insert('lookup_history', {
          'character': character,
          'language': language.name,
          'opened_at': _clock().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.execute(
          'DELETE FROM lookup_history WHERE rowid NOT IN ('
          'SELECT rowid FROM lookup_history '
          'ORDER BY opened_at DESC, rowid DESC LIMIT ?)',
          [capacity],
        );
      });
    } on Exception catch (e) {
      throw LookupHistoryUnavailableFailure(cause: e);
    }
  }

  @override
  Future<List<HistoryEntry>> recent() async {
    final db = await _database();
    try {
      final rows = await db.query(
        'lookup_history',
        orderBy: 'opened_at DESC, rowid DESC',
        limit: capacity,
      );
      return [
        for (final row in rows)
          if (_languageOf(row['language']! as String) case final language?)
            HistoryEntry(
              character: row['character']! as String,
              language: language,
              openedAt: DateTime.fromMillisecondsSinceEpoch(
                row['opened_at']! as int,
              ),
            ),
      ];
    } on Exception catch (e) {
      throw LookupHistoryUnavailableFailure(cause: e);
    }
  }

  /// Closes the database. A later call opens it again.
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

  InkLanguage? _languageOf(String name) {
    for (final language in InkLanguage.values) {
      if (language.name == name) return language;
    }
    return null;
  }

  /// A failed open is not kept, so the next call tries again.
  Future<Database> _database() async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } on Exception catch (e) {
      if (identical(_opening, opening)) _opening = null;
      throw LookupHistoryUnavailableFailure(cause: e);
    }
  }

  Future<Database> _open() async {
    final directory = _directory ?? await _databaseFactory.getDatabasesPath();
    final path = '$directory/$fileName';
    try {
      return await _openAt(path);
    } on Exception {
      // A file that cannot be read is no use, so start again.
      await _delete(path);
      return _openAt(path);
    }
  }

  Future<Database> _openAt(String path) async {
    final db = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
    try {
      await db.rawQuery('SELECT 1 FROM lookup_history LIMIT 1');
    } catch (_) {
      await db.close();
      rethrow;
    }
    return db;
  }

  Future<void> _create(Database db, int version) => db.execute('''
    CREATE TABLE lookup_history (
      character TEXT NOT NULL,
      language TEXT NOT NULL,
      opened_at INTEGER NOT NULL,
      PRIMARY KEY (character, language)
    )
  ''');

  Future<void> _delete(String path) async {
    for (final suffix in ['', '-journal', '-wal', '-shm']) {
      try {
        final file = File('$path$suffix');
        if (file.existsSync()) await file.delete();
      } on FileSystemException {
        // Nothing more can be done here; the next open reports the problem.
      }
    }
  }
}
