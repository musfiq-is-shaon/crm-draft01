import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color accent) => _build(
        accent: accent,
        brightness: Brightness.light,
      );

  static ThemeData dark(Color accent) => _build(
        accent: accent,
        brightness: Brightness.dark,
      );

  static TextStyle _w600(double size, Color color) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle _w500(double size, Color color) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static ThemeData _build({
    required Color accent,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    // Harmonious surfaces: light = cool gray-white; dark = subtle blue-gray lift on black.
    final cs = scheme.copyWith(
      primary: accent,
      onPrimary: AppColors.onAccent(accent),
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      surface: isDark ? const Color(0xFF101018) : Colors.white,
      surfaceContainerLowest: isDark
          ? AppColors.pitchBlack
          : const Color(0xFFF8FAFC),
      surfaceContainerLow:
          isDark ? const Color(0xFF12121C) : const Color(0xFFF1F5F9),
      surfaceContainer:
          isDark ? const Color(0xFF161622) : const Color(0xFFEEF2F7),
      surfaceContainerHigh:
          isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE8EDF4),
      surfaceContainerHighest:
          isDark ? const Color(0xFF262632) : const Color(0xFFE2E8F0),
      onSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      onSurfaceVariant:
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      outline: isDark ? const Color(0xFF343448) : const Color(0xFFCBD5E1),
      outlineVariant:
          isDark ? const Color(0xFF282836) : const Color(0xFFE2E8F0),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor:
          isDark ? AppColors.pitchBlack : const Color(0xFFF8FAFC),
      splashFactory: InkSparkle.splashFactory,
      splashColor: accent.withOpacity(isDark ? 0.12 : 0.08),
      highlightColor: accent.withOpacity(isDark ? 0.06 : 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = base.textTheme.apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: cs.onPrimary,
        displayColor: cs.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _w600(18, cs.onSurface),
        iconTheme: IconThemeData(color: cs.onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.pitchBlack,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: cs.surface,
              ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: cs.outlineVariant.withOpacity(isDark ? 0.5 : 0.85),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.primary.withOpacity(0.35);
            }
            return cs.primary;
          }),
          foregroundColor: WidgetStateProperty.all(cs.onPrimary),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            _w600(14, cs.onPrimary),
          ),
          overlayColor: WidgetStateProperty.all(
            cs.onPrimary.withOpacity(0.08),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(cs.primary),
          side: WidgetStateProperty.all(
            BorderSide(color: cs.primary.withOpacity(0.4)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            _w600(14, cs.primary),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(cs.primary),
          textStyle: WidgetStateProperty.all(
            _w600(14, cs.primary),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cs.surfaceContainer : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: _w500(14, cs.onSurfaceVariant),
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.72),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: _w500(14, cs.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outline.withOpacity(0.32),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.45)),
        ),
        titleTextStyle: _w600(20, cs.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        dragHandleColor: cs.onSurfaceVariant.withOpacity(0.35),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(
          color: cs.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary.withOpacity(0.35);
          }
          return cs.surfaceContainerHighest;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        circularTrackColor: cs.primary.withOpacity(0.2),
      ),
    );
  }
}
