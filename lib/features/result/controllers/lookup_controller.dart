import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/failures/dictionary_failure.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/resolve_character_provider.dart';

final lookupControllerProvider =
    NotifierProvider<LookupController, LookupState>(LookupController.new);

class LookupController extends Notifier<LookupState> {
  /// Drops an answer when a newer request or a close came first.
  int _request = 0;

  @override
  LookupState build() => const LookupClosed();

  /// Also used to switch candidate. A sheet that already shows a result keeps it
  /// until the new answer arrives, so it does not shrink to a skeleton and blink.
  Future<void> open(String character, InkLanguage language) async {
    final dictionary = ref.read(dictionaryProvider);
    final resolve = ref.read(resolveCharacterProvider);
    final request = ++_request;
    if (state is! LookupLoaded) {
      state = LookupLoading(character: character, language: language);
    }

    LookupState next;
    try {
      final entry = await dictionary.lookup(character);
      next = entry == null
          ? LookupNotFound(character: character, language: language)
          : LookupLoaded(
              character: character,
              language: language,
              view: await resolve(entry, language.han),
            );
    } on DictionaryFailure catch (failure) {
      next = LookupFailed(
        character: character,
        language: language,
        failure: failure,
      );
    } on Exception catch (e) {
      next = LookupFailed(
        character: character,
        language: language,
        failure: DictionaryUnavailableFailure(cause: e),
      );
    }

    if (!ref.mounted || request != _request) return;
    state = next;
  }

  void close() {
    _request++;
    if (state is! LookupClosed) state = const LookupClosed();
  }
}
