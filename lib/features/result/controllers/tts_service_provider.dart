import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/repositories/tts_service.dart';

/// Overridden in main.dart with the real service, and in tests with a fake.
final ttsServiceProvider = Provider<TtsService>(
  (ref) => throw UnimplementedError(
    'ttsServiceProvider must be overridden with a TtsService.',
  ),
);
