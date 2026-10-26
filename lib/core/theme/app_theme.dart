import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Ink & Paper. Light mode only, by design.
abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.seal,
      onPrimary: Color(0xFFFFFFFF),
      secondary: AppColors.moss,
      surface: AppColors.bg,
      onSurface: AppColors.text,
      outline: AppColors.line,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: AppText.sansFamily,
      textTheme: Typography.blackMountainView.apply(
        fontFamily: AppText.sansFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      focusColor: AppColors.seal,
    );
  }
}
