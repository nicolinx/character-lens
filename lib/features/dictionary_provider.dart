import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/dictionary.dart';

/// Overridden in main.dart with the SQLite dictionary, and in tests with a fake.
/// Shared by the canvas (candidate filter) and the result sheet (lookup), so it
/// sits at the top of features/ and not inside either one.
final dictionaryProvider = Provider<Dictionary>(
  (ref) => throw UnimplementedError(
    'dictionaryProvider must be overridden with a Dictionary.',
  ),
);
