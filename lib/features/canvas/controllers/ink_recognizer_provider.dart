import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/repositories/ink_recognizer.dart';

final inkRecognizerProvider = Provider<InkRecognizer>(
  (ref) => throw UnimplementedError(
    'inkRecognizerProvider must be overridden with an InkRecognizer.',
  ),
);
