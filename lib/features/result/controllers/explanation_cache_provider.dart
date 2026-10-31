import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/explainer/explanation_cache.dart';

final explanationCacheProvider = Provider<ExplanationCache>(
  (ref) => throw UnimplementedError(
    'explanationCacheProvider must be overridden with an ExplanationCache.',
  ),
);
