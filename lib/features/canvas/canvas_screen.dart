import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'widgets/language_selector.dart';
import 'widgets/model_status_line.dart';
import 'widgets/writing_pad.dart';

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
              SizedBox(height: 18),
              LanguageSelector(),
              SizedBox(height: 4),
              ModelStatusLine(),
              SizedBox(height: 10),
              WritingPad(),
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
        Flexible(
          child: Text(
            'Character Lens',
            style: AppText.serif(size: 22, weight: 500, height: 1.1),
          ),
        ),
      ],
    );
  }
}
