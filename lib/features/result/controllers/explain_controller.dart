import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:character_lens/features/result/controllers/explain_character_provider.dart';
import 'package:character_lens/features/result/controllers/explain_state.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';

final explainControllerProvider =
    NotifierProvider<ExplainController, ExplainState>(ExplainController.new);

/// Starts when the lookup is loaded and resets when it closes or has nothing to
/// explain. It only reads the lookup.
class ExplainController extends Notifier<ExplainState> {
  /// Drops a stale answer.
  int _request = 0;

  @override
  ExplainState build() {
    ref.listen(lookupControllerProvider, (_, next) => _follow(next));
    // State cannot be set during build, so an already loaded sheet waits a tick.
    final current = ref.read(lookupControllerProvider);
    if (current is LookupLoaded) Future.microtask(() => _follow(current));
    return const ExplainIdle();
  }

  void _follow(LookupState lookup) {
    if (!ref.mounted) return;
    switch (lookup) {
      case LookupLoaded(:final view):
        _explain(view);
      case LookupLoading():
        // A switch skips Loading, so only a first load or a retry gets here.
        _reset();
      case LookupClosed() || LookupNotFound() || LookupFailed():
        _reset();
    }
  }

  Future<void> _explain(CharacterView view) async {
    final explain = ref.read(explainCharacterProvider);
    final request = ++_request;
    state = const ExplainLoading();

    ExplainState next;
    try {
      next = ExplainReady(await explain(view.entry, view.selected));
    } on ExplanationFailure catch (failure) {
      next = ExplainUnavailable(failure);
    } on Exception catch (e) {
      next = ExplainUnavailable(ExplainerFailure(cause: e));
    }

    if (!ref.mounted || request != _request) return;
    state = next;
  }

  void _reset() {
    _request++;
    if (state is! ExplainIdle) state = const ExplainIdle();
  }
}
