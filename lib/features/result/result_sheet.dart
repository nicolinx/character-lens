import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/features/result/controllers/explain_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_controller.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/speech_controller.dart';
import 'package:character_lens/features/result/widgets/result_sheet_view.dart';

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
      explain: ref.watch(explainControllerProvider),
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
