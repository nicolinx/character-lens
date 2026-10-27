import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/usecases/resolve_character.dart';
import '../../dictionary_provider.dart';

final resolveCharacterProvider = Provider<ResolveCharacter>(
  (ref) => ResolveCharacter(ref.watch(dictionaryProvider)),
);
