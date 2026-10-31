import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/history/lookup_history.dart';

final lookupHistoryProvider = Provider<LookupHistory>(
  (ref) => throw UnimplementedError(
    'lookupHistoryProvider must be overridden with a LookupHistory.',
  ),
);
