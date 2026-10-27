import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/usecases/recognize_characters.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';

final recognizeCharactersProvider = Provider<RecognizeCharacters>(
  (ref) => RecognizeCharacters(
    ref.watch(inkRecognizerProvider),
    ref.watch(dictionaryProvider),
  ),
);
