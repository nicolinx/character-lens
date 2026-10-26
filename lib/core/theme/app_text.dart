import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Type styles for the two families in the design: Instrument Sans for the UI
/// and Newsreader for characters, titles and prompts.
///
/// Both fonts are variable, so the weight is also set as an axis value.
abstract final class AppText {
  static const sansFamily = 'InstrumentSans';
  static const serifFamily = 'Newsreader';

  static TextStyle sans({
    required double size,
    int weight = 400,
    Color color = AppColors.text,
    double? height,
    double? letterSpacing,
  }) => _style(
    sansFamily,
    size: size,
    weight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle serif({
    required double size,
    int weight = 400,
    Color color = AppColors.text,
    double? height,
    bool italic = false,
  }) => _style(
    serifFamily,
    size: size,
    weight: weight,
    color: color,
    height: height,
    italic: italic,
  );

  static TextStyle _style(
    String family, {
    required double size,
    required int weight,
    required Color color,
    double? height,
    double? letterSpacing,
    bool italic = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation.weight(weight.toDouble())],
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
