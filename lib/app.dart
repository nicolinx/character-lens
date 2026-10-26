import 'package:flutter/material.dart';

import 'features/canvas/canvas_screen.dart';

class CharacterLensApp extends StatelessWidget {
  const CharacterLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Character Lens', home: CanvasScreen());
  }
}
