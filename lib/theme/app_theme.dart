import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// Builds Inkwell's complete Material 3 theme system.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: AppColors.lightBackground,
    ).copyWith(
      surface: AppColors.lightBackground,
      surfaceContainerHighest: AppColors.lightSurfaceHigh,
      outline: AppColors.lightBorder,
    );

    return _build(
      scheme: scheme,
      accent: accent,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      borderColor: AppColors.lightBorder,
      textColor: AppColors.lightText,
      mutedText: AppColors.lightTextMuted,
      glassWhite: 0.75,
    );
  }

  static ThemeData dark(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: AppColors.darkBackground,
    ).copyWith(
      surface: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      outline: AppColors.darkBorder,
      onSurface: AppColors.darkText,
    );

    return _build(
      scheme: scheme,
      accent: accent,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurfaceHigh,
      borderColor: AppColors.darkBorder,
      textColor: AppColors.darkText,
      mutedText: AppColors.darkTextMuted,
      glassWhite: 0.08,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color accent,
    required Color background,
    required Color surface,
    required Color borderColor,
    required Color textColor,
    required Color mutedText,
    required double glassWhite,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      canvasColor: background,
    );

    const radiusSm = 14.0;
    const radiusMd = 20.0;
    const radiusLg = 28.0;

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, textColor, mutedText),
      dividerTheme: DividerThemeData(color: borderColor.withValues(alpha: 0.6)),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: borderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: accent.withValues(alpha: 0.4),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceHigh,
        hintStyle: TextStyle(color: mutedText.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : surface,
        contentTextStyle: TextStyle(color: textColor),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: borderColor),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        showDragHandle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: isDark ? 0.18 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? accent
                : mutedText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.12),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.1),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return accent.withValues(alpha: 0.15);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return borderColor;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : Colors.transparent,
        ),
        side: BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accent.withValues(alpha: isDark ? 0.22 : 0.14);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? accent : mutedText;
          }),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(color: borderColor),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurface : surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(color: textColor, fontSize: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      dividerColor: borderColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color text, Color muted) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            color: text,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            color: text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            color: text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.titleLarge?.copyWith(
            color: text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.titleMedium?.copyWith(
            color: text,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.bodyLarge?.copyWith(color: text, height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(color: text, height: 1.5),
          bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.4),
          labelLarge: base.labelLarge?.copyWith(
            color: text,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: text, displayColor: text);
  }
}

/// A Material 3 style page transition builder that works on all platforms.
class FadeForwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeForwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
