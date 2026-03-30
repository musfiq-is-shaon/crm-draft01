import 'package:flutter/material.dart';

/// Helpers for semantic UI colors that should follow the current [ColorScheme]
/// (seed / dynamic accent) instead of hardcoded palettes.
extension ColorSchemeSemantics on ColorScheme {
  /// Background tint for a colored foreground (badge, chip).
  Color tonalChipBackground(Color foreground) =>
      foreground.withValues(alpha: 0.12);
}
