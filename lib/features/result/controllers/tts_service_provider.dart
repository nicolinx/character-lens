import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/tts/tts_service.dart';

final ttsServiceProvider = Provider<TtsService>(
  (ref) => throw UnimplementedError(
    'ttsServiceProvider must be overridden with a TtsService.',
  ),
);
