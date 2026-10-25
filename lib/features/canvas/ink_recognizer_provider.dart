import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ink_recognizer.dart';

/// Overridden in main.dart with the real recognizer, and in tests with a fake.
/// Declared here, not in data/, so features depend on the domain interface only.
final inkRecognizerProvider = Provider<InkRecognizer>(
  (ref) => throw UnimplementedError(
    'inkRecognizerProvider must be overridden with an InkRecognizer.',
  ),
);
