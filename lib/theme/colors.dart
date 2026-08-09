import 'package:flutter/material.dart';

/// Central color system for Inkwell.
class AppColors {
  // ---- Accent palette -------------------------------------------------
  static const Color indigo = Color(0xFF6366F1);
  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color emerald = Color(0xFF10B981);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color teal = Color(0xFF14B8A6);
  static const Color orange = Color(0xFFF97316);

  /// Colors a user may pick as an accent.
  static const List<Color> accentOptions = [
    indigo,
    violet,
    rose,
    pink,
    amber,
    orange,
    emerald,
    teal,
    sky,
  ];

  /// Accent colors grouped per note type.
  static const Color markdownAccent = indigo;
  static const Color chatAccent = emerald;
  static const Color importedAccent = amber;

  // ---- Dark surfaces ---------------------------------------------------
  static const Color darkBackground = Color(0xFF070A13);
  static const Color darkSurface = Color(0xFF10141F);
  static const Color darkSurfaceHigh = Color(0xFF1B2233);
  static const Color darkBorder = Color(0xFF2A3245);
  static const Color darkText = Color(0xFFEDF1F8);
  static const Color darkTextMuted = Color(0xFF7B869E);

  // ---- Light surfaces --------------------------------------------------
  static const Color lightBackground = Color(0xFFF5F7FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF1F4FB);
  static const Color lightBorder = Color(0xFFE3E8F4);
  static const Color lightText = Color(0xFF101425);
  static const Color lightTextMuted = Color(0xFF6B7690);

  // ---- Gradient presets ------------------------------------------------
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient forestGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<LinearGradient> allGradients = [
    sunsetGradient,
    oceanGradient,
    forestGradient,
    cosmicGradient,
  ];

  /// A brand gradient derived from a base accent color.
  static LinearGradient accentGradient(Color accent) {
    return LinearGradient(
      colors: [
        accent,
        Color.lerp(accent, const Color(0xFF8B5CF6), 0.55)!,
        Color.lerp(accent, const Color(0xFFEC4899), 0.35)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// A soft, translucent tint used behind gradient blobs.
  static Color soft(Color accent) => accent.withValues(alpha: 0.14);

  static Color hexToColor(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }
}
