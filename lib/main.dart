import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:character_lens/app.dart';
import 'package:character_lens/data/ai/firebase_bootstrap.dart';
import 'package:character_lens/data/ai/firebase_config.dart';
import 'package:character_lens/data/ai/firebase_explanation_model.dart';
import 'package:character_lens/data/ai/llm_explainer.dart';
import 'package:character_lens/data/ai/unavailable_explainer.dart';
import 'package:character_lens/data/cache/sqlite_explanation_cache.dart';
import 'package:character_lens/data/dictionary/sqlite_dictionary.dart';
import 'package:character_lens/data/ink/ml_kit_ink_recognizer.dart';
import 'package:character_lens/data/tts/flutter_tts_service.dart';
import 'package:character_lens/domain/explainer/explainer.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/result/controllers/explainer_provider.dart';
import 'package:character_lens/features/result/controllers/explanation_cache_provider.dart';
import 'package:character_lens/features/result/controllers/tts_service_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EquatableConfig.stringify = kDebugMode;
  final firebaseReady = await startFirebase(FirebaseConfig.fromEnvironment());
  final Explainer explainer = firebaseReady
      ? LlmExplainer(FirebaseExplanationModel())
      : UnavailableExplainer();
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
        explainerProvider.overrideWithValue(explainer),
        explanationCacheProvider.overrideWith((ref) {
          final cache = SqliteExplanationCache(
            databaseFactory: sqflite.databaseFactory,
          );
          ref.onDispose(cache.close);
          return cache;
        }),
        ttsServiceProvider.overrideWith((ref) {
          final service = FlutterTtsService(FlutterTts());
          ref.onDispose(service.stop);
          return service;
        }),
      ],
      child: const CharacterLensApp(),
    ),
  );
}
