import 'package:flutter/material.dart';

/// Theme-aware colors — always derived from [ThemeData] / [ColorScheme].
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
        : cs.surface;
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
}
