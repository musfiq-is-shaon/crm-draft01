import 'package:flutter/material.dart';

/// Helper class to get theme-aware colors
class AppThemeColors {
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);
  }

  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }

  static Color textTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);
  }

  // Expense Status Colors - Theme Aware
  // Using darker, more vibrant colors that work well with white text
  static Color expenseUnpaidColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD97706) // Darker amber for dark mode - more saturated
        : const Color(0xFFF59E0B); // Standard amber for light mode
  }

  static Color expensePaidColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF059669) // Darker green for dark mode - more saturated
        : const Color(0xFF10B981); // Standard green for light mode
  }

  static Color expenseUnpaidBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF451A03) // Dark amber background
        : const Color(0xFFFEF3C7); // Light amber background
  }

  static Color expensePaidBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF064E3B) // Dark green background
        : const Color(0xFFD1FAE5); // Light green background
  }
}
