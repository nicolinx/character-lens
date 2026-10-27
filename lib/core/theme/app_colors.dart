import 'dart:ui';

/// Ink & Paper palette, copied from the `:root` tokens in docs/design/index.html.
abstract final class AppColors {
  static const bg = Color(0xFFF6F1E7);
  static const sheet = Color(0xFFFAF6EE);
  static const card = Color(0xFFFFFDF8);
  static const text = Color(0xFF1D1A15);
  static const muted = Color(0xFF6F685A);
  static const line = Color(0xFFE0D7C4);
  static const seal = Color(0xFFB3321F);
  static const sealDark = Color(0xFF8F2616);
  static const sealSoft = Color(0xFFF6E3DD);
  static const moss = Color(0xFF2F6A4F);
  static const mossSoft = Color(0xFFE3EFE7);
  static const idleDot = Color(0xFFB9B09B);

  /// Placeholder bars while the dictionary is read.
  static const skeleton = Color(0xFFEBE3D1);

  /// Writing practice sheet: the ring, the cross and the diagonals.
  static const padRing = Color(0xFFE8C9C1);
  static const padCross = Color(0xFFE5B9AE);
  static const padDiagonal = Color(0xFFEFD5CD);

  /// The italic "Write one character" prompt.
  static const hint = Color(0xFF7B705C);
}
