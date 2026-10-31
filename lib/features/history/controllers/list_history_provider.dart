import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/history/list_history.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:character_lens/features/result/controllers/resolve_character_provider.dart';

final listHistoryProvider = Provider<ListHistory>(
  (ref) => ListHistory(
    history: ref.watch(lookupHistoryProvider),
    dictionary: ref.watch(dictionaryProvider),
    resolve: ref.watch(resolveCharacterProvider),
  ),
);
