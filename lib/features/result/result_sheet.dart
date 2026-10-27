import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/domain/entities/han_language.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/speech_controller.dart';
import 'package:character_lens/features/result/widgets/result_sheet_view.dart';

/// Opens the result sheet for [character] and closes the lookup when the sheet
/// goes away, however it was dismissed.
///
/// [candidates] and [onSwitched] come from the caller, so this feature does not
/// depend on the canvas: "Not it?" lists the candidates and reports the one the
/// user picked.
Future<void> showResultSheet(
  BuildContext context,
  WidgetRef ref, {
  required String character,
  required InkLanguage language,
  required List<String> candidates,
  required ValueChanged<String> onSwitched,
}) {
  final lookup = ref.read(lookupControllerProvider.notifier);
  final speech = ref.read(speechControllerProvider.notifier);
  lookup.open(character, language);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.sheet,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) =>
        _ResultSheet(candidates: candidates, onSwitched: onSwitched),
  ).whenComplete(() {
    lookup.close();
    speech.stop();
  });
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.candidates, required this.onSwitched});

  final List<String> candidates;
  final ValueChanged<String> onSwitched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lookupControllerProvider);
    // Closed while the sheet slides away.
    if (state is! LookupOpen) return const SizedBox.shrink();
    final lookup = ref.read(lookupControllerProvider.notifier);
    final speech = ref.read(speechControllerProvider.notifier);

    return ResultSheetView(
      state: state,
      candidates: candidates,
      speech: ref.watch(speechControllerProvider),
      onSpeak: (text) => speech.speak(text, state.language.han),
      onCandidate: (character) {
        speech.stop();
        onSwitched(character);
        lookup.open(character, state.language);
      },
      onRetry: () => lookup.open(state.character, state.language),
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
