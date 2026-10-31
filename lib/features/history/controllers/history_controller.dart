import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/features/history/controllers/history_state.dart';
import 'package:character_lens/features/history/controllers/list_history_provider.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

/// Notes each character the lookup loads, and keeps the list the history
/// screen shows. It only reads the lookup. Every character that loads counts,
/// also one the user then switches away from with "Not it?".
class HistoryController extends Notifier<HistoryState> {
  /// Drops a list that a newer one has replaced.
  int _request = 0;

  @override
  HistoryState build() {
    ref.listen(lookupControllerProvider, (_, next) {
      if (next is LookupLoaded) _record(next);
    });
    // State cannot be set during build, so the first load waits a tick.
    Future.microtask(refresh);
    return const HistoryLoading();
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    final list = ref.read(listHistoryProvider);
    final request = ++_request;

    HistoryState next;
    try {
      next = HistoryLoaded(await list());
    } on LookupHistoryFailure catch (failure) {
      next = HistoryUnavailable(failure);
    }

    if (!ref.mounted || request != _request) return;
    state = next;
  }

  Future<void> _record(LookupLoaded lookup) async {
    try {
      await ref
          .read(lookupHistoryProvider)
          .record(lookup.character, lookup.language);
    } on LookupHistoryFailure {
      // The lookup itself worked, so it just will not be listed.
    }
    await refresh();
  }
}
