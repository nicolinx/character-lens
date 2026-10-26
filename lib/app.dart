import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/canvas/canvas_screen.dart';

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
