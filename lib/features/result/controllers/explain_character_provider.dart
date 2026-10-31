import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/explainer/explain_character.dart';
import 'package:character_lens/features/result/controllers/explainer_provider.dart';
import 'package:character_lens/features/result/controllers/explanation_cache_provider.dart';

final explainCharacterProvider = Provider<ExplainCharacter>(
  (ref) => ExplainCharacter(
    explainer: ref.watch(explainerProvider),
    cache: ref.watch(explanationCacheProvider),
  ),
);
