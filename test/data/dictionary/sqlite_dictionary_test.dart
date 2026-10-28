import 'dart:io';
import 'dart:typed_data';

import 'package:character_lens/data/dictionary/sqlite_dictionary.dart';
import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/dictionary_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../tool/build_dictionary.dart';

void main() {
  late Uint8List bundled;
  late Directory temp;
  late SqliteDictionary dictionary;
  late int loads;
  Object? assetError;
  late Uint8List Function() assetBytes;

  setUpAll(() {
    sqfliteFfiInit();
    final built = Directory.systemTemp.createTempSync('dictionary_asset_');
    buildDictionary(
      unihanDir: Directory('test/fixtures/unihan'),
      outputPath: '${built.path}/dictionary.db',
    );
    bundled = File('${built.path}/dictionary.db').readAsBytesSync();
    built.deleteSync(recursive: true);
  });

  setUp(() {
    temp = Directory.systemTemp.createTempSync('sqlite_dictionary_');
    loads = 0;
    assetError = null;
    assetBytes = () => bundled;
    dictionary = SqliteDictionary(
      databaseFactory: databaseFactoryFfiNoIsolate,
      directory: temp.path,
      loadAsset: () async {
        loads++;
        if (assetError != null) throw assetError!;
        return assetBytes();
      },
    );
  });

  tearDown(() async {
    await dictionary.close();
    temp.deleteSync(recursive: true);
  });

  File installed() => File('${temp.path}/dictionary.db');

  group('lookup', () {
    test('returns every field of an entry', () async {
      final entry = await dictionary.lookup('語');

      expect(
        entry,
        CharacterEntry(
          character: '語',
          definition: 'language, words; saying, expression',
          mandarin: const ['yǔ'],
          japaneseOn: const ['GO', 'GYO'],
          japaneseKun: const ['KATARU', 'KOTOBA', 'TSUGERU'],
          hangul: const ['어'],
          simplified: const ['语'],
          totalStrokes: 14,
        ),
      );
    });

    test('returns empty lists for fields the entry does not have', () async {
      final entry = (await dictionary.lookup('语'))!;

      expect(entry.japaneseOn, isEmpty);
      expect(entry.japaneseKun, isEmpty);
      expect(entry.hangul, isEmpty);
      expect(entry.simplified, isEmpty);
    });

    test('returns several variants in the stored order', () async {
      final entry = (await dictionary.lookup('气'))!;

      expect(entry.traditional, ['气', '氣']);
      expect(entry.simplified, ['气']);
    });

    test('finds a character above the BMP', () async {
      final entry = (await dictionary.lookup(String.fromCharCode(0x20000)))!;

      expect(entry.character, String.fromCharCode(0x20000));
      expect(entry.mandarin, ['hē']);
    });

    test(
      'returns null for a character that is not in the dictionary',
      () async {
        expect(await dictionary.lookup('水'), isNull);
      },
    );

    test(
      'returns null for a character that had no reading or definition',
      () async {
        expect(await dictionary.lookup(String.fromCharCode(0x20002)), isNull);
      },
    );

    test('returns null for text that is not exactly one character', () async {
      expect(await dictionary.lookup(''), isNull);
      expect(await dictionary.lookup('木木'), isNull);
      expect(await dictionary.lookup('1日'), isNull);
    });
  });

  group('contains', () {
    test('is true for a character in the dictionary', () async {
      expect(await dictionary.contains('木'), isTrue);
    });

    test('is false for a character that is not', () async {
      expect(await dictionary.contains('水'), isFalse);
    });

    test('is false for text that is not exactly one character', () async {
      expect(await dictionary.contains(''), isFalse);
      expect(await dictionary.contains('木木'), isFalse);
    });
  });

  group('opening', () {
    test('copies the bundled database on first use', () async {
      expect(installed().existsSync(), isFalse);

      await dictionary.lookup('木');

      expect(installed().readAsBytesSync(), bundled);
    });

    test('opens once for several lookups', () async {
      await dictionary.lookup('木');
      await dictionary.contains('語');
      await dictionary.lookup('学');

      expect(loads, 1);
    });

    test('opens once when lookups start at the same time', () async {
      await Future.wait([
        dictionary.lookup('木'),
        dictionary.contains('語'),
        dictionary.lookup('学'),
      ]);

      expect(loads, 1);
    });

    test(
      'replaces an installed copy that differs from the bundled one',
      () async {
        installed().writeAsBytesSync([1, 2, 3]);

        final entry = await dictionary.lookup('木');

        expect(entry, isNotNull);
        expect(installed().readAsBytesSync(), bundled);
      },
    );

    test('leaves no temporary file behind', () async {
      await dictionary.lookup('木');

      expect(temp.listSync().map((e) => e.uri.pathSegments.last), [
        'dictionary.db',
      ]);
    });

    test('does not write the file again when it is already current', () async {
      await dictionary.lookup('木');
      await dictionary.close();
      final marker = DateTime(2020);
      installed().setLastModifiedSync(marker);

      final again = SqliteDictionary(
        databaseFactory: databaseFactoryFfiNoIsolate,
        directory: temp.path,
        loadAsset: () async => bundled,
      );
      addTearDown(again.close);
      await again.lookup('木');

      expect(installed().statSync().modified, marker);
    });
  });

  group('failures', () {
    test(
      'a missing asset makes lookup throw DictionaryUnavailableFailure',
      () async {
        final error = Exception('asset not found');
        assetError = error;

        await expectLater(
          dictionary.lookup('木'),
          throwsA(DictionaryUnavailableFailure(cause: error)),
        );
      },
    );

    test('an Error from the asset loader is also a failure', () async {
      final error = StateError('Unable to load asset');
      assetError = error;

      await expectLater(
        dictionary.lookup('木'),
        throwsA(DictionaryUnavailableFailure(cause: error)),
      );
    });

    test('a missing asset makes contains throw too', () async {
      assetError = Exception('asset not found');

      await expectLater(
        dictionary.contains('木'),
        throwsA(isA<DictionaryUnavailableFailure>()),
      );
    });

    test(
      'a corrupt bundled file throws DictionaryUnavailableFailure',
      () async {
        assetBytes = () => Uint8List.fromList(List.filled(4096, 7));

        await expectLater(
          dictionary.lookup('木'),
          throwsA(isA<DictionaryUnavailableFailure>()),
        );
      },
    );

    test('a bundled file with the wrong tables throws', () async {
      final other = Directory.systemTemp.createTempSync('wrong_tables_');
      addTearDown(() => other.deleteSync(recursive: true));
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        '${other.path}/other.db',
      );
      await db.execute('CREATE TABLE unrelated (id INTEGER)');
      await db.close();
      final wrong = File('${other.path}/other.db').readAsBytesSync();
      assetBytes = () => wrong;

      await expectLater(
        dictionary.lookup('木'),
        throwsA(isA<DictionaryUnavailableFailure>()),
      );
    });

    test('a failure is not remembered, the next call tries again', () async {
      assetError = Exception('asset not found');
      await expectLater(
        dictionary.lookup('木'),
        throwsA(isA<DictionaryUnavailableFailure>()),
      );

      assetError = null;

      expect(await dictionary.contains('木'), isTrue);
      expect(loads, 2);
    });

    test(
      'a failure reaches every caller that was waiting for the open',
      () async {
        assetError = Exception('asset not found');

        final results = await Future.wait([
          dictionary
              .lookup('木')
              .then<Object?>((_) => 'ok')
              .onError<Object>((e, _) => e),
          dictionary
              .contains('木')
              .then<Object?>((_) => 'ok')
              .onError<Object>((e, _) => e),
        ]);

        expect(results, everyElement(isA<DictionaryUnavailableFailure>()));
      },
    );
  });

  group('close', () {
    test('is safe before the dictionary was used', () async {
      await dictionary.close();
    });

    test('lets a later lookup open the dictionary again', () async {
      await dictionary.lookup('木');
      await dictionary.close();

      expect(await dictionary.contains('木'), isTrue);
    });
  });
}
