import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/dictionary/dictionary.dart';

final dictionaryProvider = Provider<Dictionary>(
  (ref) => throw UnimplementedError(
    'dictionaryProvider must be overridden with a Dictionary.',
  ),
);
