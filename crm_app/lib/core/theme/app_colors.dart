import 'package:flutter/material.dart';

/// Semantic palette — status / category colors stay stable; primary comes from [ColorScheme] (accent).
class AppColors {
  AppColors._();

  // Default accent (overridden by user accent picker at runtime).
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  static const Color secondary = Color(0xFF34A37C);
  static const Color accent = Color(0xFF7C6CF0);

  static const Color warning = Color(0xFFD9A23A);
  static const Color error = Color(0xFFE85D5D);
  static const Color success = Color(0xFF34A37C);
  static const Color info = Color(0xFF4F8FD9);

  // Light — slate scale (matches system look)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Dark — pitch-black scaffold; surfaces tinted for cohesion with blue accent
  static const Color pitchBlack = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF101018);
  static const Color darkSurfaceHigh = Color(0xFF1E1E2A);
  static const Color darkCard = Color(0xFF161622);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkTextOnPrimary = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFF2A2A32);
  static const Color darkDivider = Color(0xFF22222A);

  // Sales / task (unchanged semantics, slightly softer)
  static const Color hot = Color(0xFFE85D5D);
  static const Color warm = Color(0xFFD9A23A);
  static const Color cold = Color(0xFF4F8FD9);

  static const Color lead = Color(0xFF6B6FE8);
  static const Color prospect = Color(0xFF7C6CF0);
  static const Color proposal = Color(0xFF2EB8D4);
  static const Color negotiation = Color(0xFFD9A23A);
  static const Color closed = Color(0xFF34A37C);
  static const Color closedWon = Color(0xFF34A37C);
  static const Color closedLost = Color(0xFFE85D5D);
  static const Color disqualified = Color(0xFF6B7280);

  static const Color taskPending = Color(0xFFD9A23A);
  static const Color taskInProgress = Color(0xFF4F8FD9);
  static const Color taskCompleted = Color(0xFF34A37C);
  static const Color taskCancelled = Color(0xFF6B7280);

  static Color onAccent(Color accent) {
    final l = accent.computeLuminance();
    return l > 0.45 ? const Color(0xFF0A0A0C) : const Color(0xFFFFFFFF);
  }
}
