import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';

Future<void> showAboutSheet(BuildContext context) {
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
    builder: (_) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.close, color: AppColors.muted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            'About',
            style: AppText.serif(size: 26, weight: 500, height: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            'Draw a Chinese or Japanese character and look it up.',
            style: AppText.sans(size: 14, color: AppColors.muted, height: 1.4),
          ),
          const _Section(
            title: 'Data',
            body:
                'Readings, meanings and variant forms come from the Unicode '
                'Han Database (Unihan) 18.0.0, dated 2026-07-31. Unihan data '
                'is Copyright (c) 1991-2026 Unicode, Inc. and is used under '
                'the Unicode License v3. The dictionary keeps selected fields '
                'and reorganizes them, so it is not the official Unicode '
                'data, and Unicode does not endorse this app.',
          ),
          const _Section(
            title: 'AI explanation',
            body:
                'When it is turned on, the explanation card is written by a '
                'language model and labeled AI-generated. Only the '
                'recognized character and its dictionary entry are sent. '
                'Your strokes never leave the device.',
          ),
          const _Section(
            title: 'Fonts and code',
            body:
                'Instrument Sans and Newsreader are used under the SIL Open '
                'Font License 1.1. The code is MIT licensed.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.sans(
              size: 12,
              weight: 600,
              color: AppColors.muted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: AppText.sans(size: 14, height: 1.5)),
        ],
      ),
    );
  }
}
