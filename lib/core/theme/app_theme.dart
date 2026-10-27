import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';

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
