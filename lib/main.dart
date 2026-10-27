import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'app.dart';
import 'data/dictionary/sqlite_dictionary.dart';
import 'data/ink/ml_kit_ink_recognizer.dart';
import 'features/canvas/controllers/ink_recognizer_provider.dart';
import 'features/dictionary_provider.dart';

void main() {
  EquatableConfig.stringify = kDebugMode;
  runApp(
    ProviderScope(
      overrides: [
        inkRecognizerProvider.overrideWith((ref) {
          final recognizer = MlKitInkRecognizer();
          ref.onDispose(recognizer.dispose);
          return recognizer;
        }),
        dictionaryProvider.overrideWith((ref) {
          final dictionary = SqliteDictionary(
            databaseFactory: sqflite.databaseFactory,
            loadAsset: () async {
              final data = await rootBundle.load('assets/db/dictionary.db');
              return data.buffer.asUint8List(
                data.offsetInBytes,
                data.lengthInBytes,
              );
            },
          );
          ref.onDispose(dictionary.close);
          return dictionary;
        }),
      ],
      child: const CharacterLensApp(),
    ),
  );
}
