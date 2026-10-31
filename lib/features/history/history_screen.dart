import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/history/controllers/history_controller.dart';
import 'package:character_lens/features/history/controllers/history_state.dart';
import 'package:character_lens/features/history/widgets/history_tile.dart';
import 'package:character_lens/features/result/result_sheet.dart';

class HistoryScreen extends ConsumerWidget {
  /// [now] is what "5 min ago" is counted from. The tab stays built while it is
  /// hidden, so the owner passes a new one each time it is shown.
  const HistoryScreen({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final now = this.now ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'History',
                  style: AppText.serif(size: 28, weight: 500),
                ),
              ),
              switch (state) {
                HistoryLoading() => const SizedBox.shrink(),
                HistoryUnavailable() => _Quiet(
                  'History is not available right now.',
                ),
                HistoryLoaded(:final items) when items.isEmpty => const _Quiet(
                  'Characters you look up appear here, and open instantly '
                  'offline.',
                ),
                HistoryLoaded(:final items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
                      child: Text(
                        '${items.length} '
                        '${items.length == 1 ? 'character' : 'characters'}'
                        ' · saved on this device',
                        style: AppText.sans(size: 13, color: AppColors.muted),
                      ),
                    ),
                    for (final item in items)
                      HistoryTile(
                        item: item,
                        now: now,
                        onTap: () => showResultSheet(
                          context,
                          ref,
                          character: item.entry.character,
                          language: item.entry.language,
                          candidates: [item.entry.character],
                          onSwitched: (_) {},
                        ),
                      ),
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.serif(size: 16, italic: true, color: AppColors.muted),
      ),
    );
  }
}
