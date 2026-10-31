import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/explainer/explainer.dart';

final explainerProvider = Provider<Explainer>(
  (ref) => throw UnimplementedError(
    'explainerProvider must be overridden with an Explainer.',
  ),
);
