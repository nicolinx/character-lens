import 'dart:io';

import 'package:sqflite/sqlite_api.dart';

import 'package:character_lens/data/ai/explanation_encoder.dart';
import 'package:character_lens/data/ai/explanation_parser.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/explainer/explanation_cache_failure.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Explanations kept in a database of their own, separate from the dictionary.
///
/// It is only a cache, so a damaged entry is dropped and a damaged file is
/// deleted and created again.
class SqliteExplanationCache implements ExplanationCache {
  SqliteExplanationCache({
    required this._databaseFactory,
    this._directory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const fileName = 'explanation_cache.db';

  final DatabaseFactory _databaseFactory;
  final String? _directory;
  final DateTime Function() _clock;

  Future<Database>? _opening;

  @override
  Future<Explanation?> get(ExplanationKey key) async {
    final db = await _database();
    try {
      final rows = await db.query(
        'explanation',
        columns: ['explanation'],
        where: _where,
        whereArgs: _args(key),
        limit: 1,
      );
      if (rows.isEmpty) return null;
      try {
        return parseExplanation(rows.first['explanation']! as String);
      } on ExplainerInvalidOutputFailure {
        await db.delete('explanation', where: _where, whereArgs: _args(key));
        return null;
      }
    } on Exception catch (e) {
      throw ExplanationCacheUnavailableFailure(cause: e);
    }
  }

  @override
  Future<void> put(ExplanationKey key, Explanation explanation) async {
    final db = await _database();
    try {
      await db.insert('explanation', {
        'character': key.character,
        'language': key.language.name,
        'prompt_version': key.promptVersion,
        'explanation': encodeExplanation(explanation),
        'created_at': _clock().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Exception catch (e) {
      throw ExplanationCacheUnavailableFailure(cause: e);
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

  static const _where = 'character = ? AND language = ? AND prompt_version = ?';

  List<Object?> _args(ExplanationKey key) => [
    key.character,
    key.language.name,
    key.promptVersion,
  ];

  /// A failed open is not kept, so the next call tries again.
  Future<Database> _database() async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } on Exception catch (e) {
      if (identical(_opening, opening)) _opening = null;
      throw ExplanationCacheUnavailableFailure(cause: e);
    }
  }

  Future<Database> _open() async {
    final directory = _directory ?? await _databaseFactory.getDatabasesPath();
    final path = '$directory/$fileName';
    try {
      return await _openAt(path);
    } on Exception {
      // Damaged file: it only holds copies of answers, so start again.
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
      await db.rawQuery('SELECT 1 FROM explanation LIMIT 1');
    } catch (_) {
      await db.close();
      rethrow;
    }
    return db;
  }

  Future<void> _create(Database db, int version) => db.execute('''
    CREATE TABLE explanation (
      character TEXT NOT NULL,
      language TEXT NOT NULL,
      prompt_version TEXT NOT NULL,
      explanation TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (character, language, prompt_version)
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
