import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/ink/ml_kit_ink_recognizer.dart';
import 'features/canvas/ink_recognizer_provider.dart';

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
      ],
      child: const CharacterLensApp(),
    ),
  );
}
