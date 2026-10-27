import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_theme.dart';
import 'package:character_lens/features/canvas/canvas_screen.dart';

class CharacterLensApp extends StatelessWidget {
  const CharacterLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character Lens',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const CanvasScreen(),
    );
  }
}
