import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/dictionary/resolve_character.dart';
import 'package:character_lens/features/dictionary_provider.dart';

final resolveCharacterProvider = Provider<ResolveCharacter>(
  (ref) => ResolveCharacter(ref.watch(dictionaryProvider)),
);
