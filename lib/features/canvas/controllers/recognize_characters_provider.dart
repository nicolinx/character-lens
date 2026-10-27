import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/usecases/recognize_characters.dart';
import '../../dictionary_provider.dart';
import 'ink_recognizer_provider.dart';

final recognizeCharactersProvider = Provider<RecognizeCharacters>(
  (ref) => RecognizeCharacters(
    ref.watch(inkRecognizerProvider),
    ref.watch(dictionaryProvider),
  ),
);
