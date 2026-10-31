import 'dart:io';

import 'package:character_lens/data/cache/sqlite_lookup_history.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cn = InkLanguage.chinese;
const _jp = InkLanguage.japanese;

void main() {
  late Directory temp;
  late SqliteLookupHistory history;
  late DateTime now;

  SqliteLookupHistory make({String? directory, int? capacity}) =>
      SqliteLookupHistory(
        databaseFactory: databaseFactoryFfiNoIsolate,
        directory: directory ?? temp.path,
        capacity: capacity ?? SqliteLookupHistory.defaultCapacity,
        clock: () => now,
      );

  setUpAll(sqfliteFfiInit);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lookup_history_');
    now = DateTime.utc(2026, 10, 31, 12);
    history = make();
  });

  tearDown(() async {
    await history.close();
    temp.deleteSync(recursive: true);
  });

  File file() => File('${temp.path}/${SqliteLookupHistory.fileName}');

  Future<void> record(String character, InkLanguage language) async {
    await history.record(character, language);
    now = now.add(const Duration(minutes: 1));
  }

  Future<List<String>> characters() async => [
    for (final e in await history.recent()) e.character,
  ];

  group('record and recent', () {
    test('is empty at first', () async {
      expect(await history.recent(), isEmpty);
    });

    test('returns what was recorded, with the language and the time', () async {
      await history.record('木', _jp);

      final entry = (await history.recent()).single;

      expect(entry.character, '木');
      expect(entry.language, _jp);
      expect(entry.openedAt.isAtSameMomentAs(now), isTrue);
    });

    test('puts the newest first', () async {
      await record('木', _cn);
      await record('水', _cn);
      await record('日', _cn);

      expect(await characters(), ['日', '水', '木']);
    });

    test('a character looked up again moves to the top, once', () async {
      await record('木', _cn);
      await record('水', _cn);
      await record('日', _cn);

      await record('木', _cn);

      expect(await characters(), ['木', '日', '水']);
    });

    test('the time of a repeated lookup is the new one', () async {
      final first = now;
      await record('木', _cn);
      final second = now;
      await record('木', _cn);

      final entry = (await history.recent()).single;

      expect(entry.openedAt.isAtSameMomentAs(second), isTrue);
      expect(entry.openedAt.isAtSameMomentAs(first), isFalse);
    });

    test('the same character in the other language is its own entry', () async {
      await record('語', _cn);
      await record('語', _jp);

      final entries = await history.recent();

      expect(entries.map((e) => e.language), [_jp, _cn]);
    });

    test('keeps the order of lookups made in the same millisecond', () async {
      await history.record('木', _cn);
      await history.record('水', _cn);
      await history.record('日', _cn);

      expect(await characters(), ['日', '水', '木']);
    });

    test('keeps what was recorded after it is closed and reopened', () async {
      await record('木', _cn);
      await history.close();

      expect(await characters(), ['木']);
      expect(await make().recent(), hasLength(1));
    });
  });

  group('the limit', () {
    test('is 50 by default', () {
      expect(SqliteLookupHistory.defaultCapacity, 50);
    });

    test('keeps the newest ones and drops the oldest', () async {
      history = make(capacity: 3);
      for (final c in ['一', '二', '三', '四', '五']) {
        await record(c, _cn);
      }

      expect(await characters(), ['五', '四', '三']);
    });

    test('a repeated lookup does not push anything out', () async {
      history = make(capacity: 3);
      for (final c in ['一', '二', '三']) {
        await record(c, _cn);
      }

      await record('二', _cn);

      expect(await characters(), ['二', '三', '一']);
    });

    test('does not keep more than that on disk either', () async {
      history = make(capacity: 3);
      for (final c in ['一', '二', '三', '四', '五']) {
        await record(c, _cn);
      }

      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        file().path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final stored = (await db.query('lookup_history')).length;
      await db.close();

      expect(stored, 3);
    });

    test('holds exactly 50 after 60 different lookups', () async {
      for (var i = 0; i < 60; i++) {
        await record(String.fromCharCode(0x4E00 + i), _cn);
      }

      final entries = await history.recent();

      expect(entries, hasLength(50));
      expect(entries.first.character, String.fromCharCode(0x4E00 + 59));
      expect(entries.last.character, String.fromCharCode(0x4E00 + 10));
    });
  });

  group('a damaged row', () {
    test('with a language the app does not know is left out', () async {
      await record('木', _cn);
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        file().path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await db.insert('lookup_history', {
        'character': '水',
        'language': 'korean',
        'opened_at': now.millisecondsSinceEpoch,
      });
      await db.close();

      expect(await characters(), ['木']);
    });
  });

  group('a damaged file', () {
    test('is replaced, and the history works again', () async {
      file().writeAsBytesSync(List.filled(4096, 7));

      expect(await history.recent(), isEmpty);

      await record('木', _cn);
      expect(await characters(), ['木']);
    });
  });

  group('a history that cannot be opened', () {
    late String blocked;

    setUp(() {
      File('${temp.path}/blocker').writeAsStringSync('x');
      blocked = '${temp.path}/blocker';
      history = make(directory: blocked);
    });

    test('record and recent throw a failure, not a crash', () async {
      await expectLater(
        history.record('木', _cn),
        throwsA(isA<LookupHistoryUnavailableFailure>()),
      );
      await expectLater(
        history.recent(),
        throwsA(isA<LookupHistoryUnavailableFailure>()),
      );
    });

    test('the failure is not remembered, the next call tries again', () async {
      await expectLater(history.recent(), throwsA(anything));

      File(blocked).deleteSync();
      Directory(blocked).createSync();

      expect(await history.recent(), isEmpty);
    });
  });

  group('close', () {
    test('is safe before the history was used', () async {
      await expectLater(history.close(), completes);
    });

    test('lets a later call open it again', () async {
      await record('木', _cn);
      await history.close();

      expect(await characters(), ['木']);
    });
  });
}
