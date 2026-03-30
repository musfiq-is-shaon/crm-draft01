import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get appText => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary brand / accent from ColorScheme (user-configurable).
  Color get primaryColor => colors.primary;

  /// Soft surface for cards on pitch-black scaffold.
  Color get surfaceElevated => colors.surfaceContainerHighest;
}
