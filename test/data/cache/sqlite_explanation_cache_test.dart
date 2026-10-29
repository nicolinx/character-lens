import 'dart:io';

import 'package:character_lens/data/cache/sqlite_explanation_cache.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_cache.dart';
import 'package:character_lens/domain/explainer/explanation_cache_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _key = ExplanationKey(
  character: '木',
  language: HanLanguage.chinese,
  promptVersion: 'prompt_v1',
);

const _explanation = Explanation(
  components: [ExplanationComponent(part: '木', role: 'tree')],
  mnemonic: 'A tree with branches and roots.',
  examples: [
    ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood'),
    ExplanationExample(word: '树木', reading: 'shùmù', meaning: 'trees'),
  ],
  usageNote: 'Used for trees in both languages.',
);

void main() {
  late Directory temp;
  late SqliteExplanationCache cache;
  late DateTime now;

  SqliteExplanationCache make({String? directory}) => SqliteExplanationCache(
    databaseFactory: databaseFactoryFfiNoIsolate,
    directory: directory ?? temp.path,
    clock: () => now,
  );

  setUpAll(sqfliteFfiInit);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('explanation_cache_');
    now = DateTime.utc(2026, 10, 29, 12);
    cache = make();
  });

  tearDown(() async {
    await cache.close();
    temp.deleteSync(recursive: true);
  });

  File file() => File('${temp.path}/${SqliteExplanationCache.fileName}');

  /// Reads or changes the table without going through the cache.
  Future<T> raw<T>(Future<T> Function(Database db) action) async {
    // Not the shared instance: closing it must not close the cache's own.
    final db = await databaseFactoryFfiNoIsolate.openDatabase(
      file().path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      return await action(db);
    } finally {
      await db.close();
    }
  }

  group('get and put', () {
    test('returns nothing for a key that was never stored', () async {
      expect(await cache.get(_key), isNull);
    });

    test('returns what was stored, with every field', () async {
      await cache.put(_key, _explanation);

      expect(await cache.get(_key), _explanation);
    });

    test('keeps an explanation with no components or usage note', () async {
      const plain = Explanation(
        components: [],
        mnemonic: 'A tree.',
        examples: [],
      );

      await cache.put(_key, plain);

      expect(await cache.get(_key), plain);
    });

    test('a second put for the same key replaces the first', () async {
      const newer = Explanation(
        components: [],
        mnemonic: 'A newer one.',
        examples: [],
      );
      await cache.put(_key, _explanation);

      await cache.put(_key, newer);

      expect(await cache.get(_key), newer);
      expect(
        await raw((db) async => (await db.query('explanation')).length),
        1,
      );
    });

    test(
      'keeps what was stored after the cache is closed and reopened',
      () async {
        await cache.put(_key, _explanation);
        await cache.close();

        expect(await make().get(_key), _explanation);
      },
    );

    test('records when the entry was stored', () async {
      await cache.put(_key, _explanation);

      final rows = await raw((db) => db.query('explanation'));

      expect(rows.single['created_at'], now.millisecondsSinceEpoch);
    });
  });

  group('the key', () {
    setUp(() => cache.put(_key, _explanation));

    test('a different language is a different entry', () async {
      const other = ExplanationKey(
        character: '木',
        language: HanLanguage.japanese,
        promptVersion: 'prompt_v1',
      );

      expect(await cache.get(other), isNull);
    });

    test(
      'a new prompt version misses, so an old answer is not reused',
      () async {
        const other = ExplanationKey(
          character: '木',
          language: HanLanguage.chinese,
          promptVersion: 'prompt_v2',
        );

        expect(await cache.get(other), isNull);
      },
    );

    test('a different character is a different entry', () async {
      const other = ExplanationKey(
        character: '水',
        language: HanLanguage.chinese,
        promptVersion: 'prompt_v1',
      );

      expect(await cache.get(other), isNull);
    });

    test('entries of different keys live side by side', () async {
      const japanese = ExplanationKey(
        character: '木',
        language: HanLanguage.japanese,
        promptVersion: 'prompt_v1',
      );
      const other = Explanation(
        components: [],
        mnemonic: 'For Japanese.',
        examples: [],
      );

      await cache.put(japanese, other);

      expect(await cache.get(_key), _explanation);
      expect(await cache.get(japanese), other);
    });
  });

  group('a damaged entry', () {
    setUp(() => cache.put(_key, _explanation));

    Future<void> overwrite(String text) =>
        raw((db) => db.update('explanation', {'explanation': text}));

    test('with text that is not JSON is a miss, and is removed', () async {
      await overwrite('not json at all');

      expect(await cache.get(_key), isNull);
      expect(await raw((db) => db.query('explanation')), isEmpty);
    });

    test('with JSON that does not fit the schema is a miss too', () async {
      await overwrite('{"mnemonic": "", "components": [], "examples": []}');

      expect(await cache.get(_key), isNull);
      expect(await raw((db) => db.query('explanation')), isEmpty);
    });

    test('can be stored again afterwards', () async {
      await overwrite('garbage');
      await cache.get(_key);

      await cache.put(_key, _explanation);

      expect(await cache.get(_key), _explanation);
    });
  });

  group('a damaged file', () {
    test('is replaced, and the cache works again', () async {
      file().writeAsBytesSync(List.filled(4096, 7));

      expect(await cache.get(_key), isNull);

      await cache.put(_key, _explanation);
      expect(await cache.get(_key), _explanation);
    });

    test('is also replaced when the first call is a put', () async {
      file().writeAsBytesSync(List.filled(4096, 7));

      await cache.put(_key, _explanation);

      expect(await cache.get(_key), _explanation);
    });
  });

  group('a cache that cannot be opened', () {
    late String blocked;

    setUp(() {
      // A file where the folder should be, so nothing can be created in it.
      File('${temp.path}/blocker').writeAsStringSync('x');
      blocked = '${temp.path}/blocker';
      cache = make(directory: blocked);
    });

    test('get throws a failure, not a crash', () async {
      await expectLater(
        cache.get(_key),
        throwsA(isA<ExplanationCacheUnavailableFailure>()),
      );
    });

    test('put throws a failure too', () async {
      await expectLater(
        cache.put(_key, _explanation),
        throwsA(isA<ExplanationCacheUnavailableFailure>()),
      );
    });

    test('the failure is not remembered, the next call tries again', () async {
      await expectLater(cache.get(_key), throwsA(anything));

      File(blocked).deleteSync();
      Directory(blocked).createSync();

      expect(await cache.get(_key), isNull);
    });
  });

  group('close', () {
    test('is safe before the cache was used', () async {
      await expectLater(cache.close(), completes);
    });

    test('lets a later call open the cache again', () async {
      await cache.put(_key, _explanation);
      await cache.close();

      expect(await cache.get(_key), _explanation);
    });
  });
}
