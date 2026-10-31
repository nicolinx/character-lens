import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/about/about_sheet.dart';
import 'package:character_lens/features/canvas/widgets/candidate_chips.dart';
import 'package:character_lens/features/canvas/widgets/canvas_status_line.dart';
import 'package:character_lens/features/canvas/widgets/language_selector.dart';
import 'package:character_lens/features/canvas/widgets/model_status_line.dart';
import 'package:character_lens/features/canvas/widgets/primary_action_button.dart';
import 'package:character_lens/features/canvas/widgets/writing_pad.dart';

class CanvasScreen extends StatelessWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Brand(),
              LanguageSelector(),
              SizedBox(height: 4),
              ModelStatusLine(),
              SizedBox(height: 10),
              WritingPad(),
              SizedBox(height: 12),
              CanvasStatusLine(),
              SizedBox(height: 6),
              CandidateChips(),
              SizedBox(height: 8),
              PrimaryActionButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  static final _stampStyle = AppText.serif(
    size: 18,
    weight: 600,
    height: 1,
    color: const Color(0xFFFFFFFF),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.rotate(
          angle: -0.07,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.seal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '字',
              locale: const Locale('zh', 'Hans'),
              style: _stampStyle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Character Lens',
            style: AppText.serif(size: 22, weight: 500, height: 1.1),
          ),
        ),
        IconButton(
          tooltip: 'About',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.info_outline, color: AppColors.muted),
          onPressed: () => showAboutSheet(context),
        ),
      ],
    );
  }
}
