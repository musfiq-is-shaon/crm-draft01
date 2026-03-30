import 'package:flutter/material.dart';

/// Theme-aware colors — always derived from [ThemeData] / [ColorScheme].
///
/// Prefer [tonalForAccent] for icon chips / quick actions so primary, secondary,
/// and tertiary map to Material 3 tonal containers from the seed palette.
class AppThemeColors {
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// App bars, sheets — matches scaffold (including AMOLED black).
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color cardColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerLow;
  }

  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color textTertiaryColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Color.alphaBlend(
      cs.onSurface.withOpacity(0.38),
      Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline.withOpacity(0.35);
  }

  /// Unpaid expense — secondary tonal (accent-aware).
  static Color expenseUnpaidColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// Paid expense — tertiary tonal (accent-aware).
  static Color expensePaidColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  static Color expenseUnpaidBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer;
  }

  static Color expensePaidBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiaryContainer;
  }

  /// Maps a saturated accent ([ColorScheme.primary] / [secondary] / [tertiary])
  /// to the matching **tonal container** pair for icons, chips, and pills.
  static ({Color background, Color foreground}) tonalForAccent(
    BuildContext context,
    Color accent,
  ) {
    final cs = Theme.of(context).colorScheme;
    final key = accent.toARGB32();
    if (key == cs.primary.toARGB32()) {
      return (
        background: cs.primaryContainer,
        foreground: cs.onPrimaryContainer,
      );
    }
    if (key == cs.secondary.toARGB32()) {
      return (
        background: cs.secondaryContainer,
        foreground: cs.onSecondaryContainer,
      );
    }
    if (key == cs.tertiary.toARGB32()) {
      return (
        background: cs.tertiaryContainer,
        foreground: cs.onTertiaryContainer,
      );
    }
    return (
      background: Color.alphaBlend(
        accent.withValues(alpha: 0.14),
        cs.surface,
      ),
      foreground: accent,
    );
  }

  static Color surfaceContainerLow(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  static Color surfaceContainerHigh(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHigh;
  }
}
