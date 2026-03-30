import 'package:flutter/material.dart';

/// 8px grid spacing scale.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}

/// Consistent corner radii (modern, slightly rounded).
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double full = 9999;
}

/// Layered, soft shadows — light mode (lighter touch than before).
abstract final class AppElevation {
  static const List<BoxShadow> cardLight = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 20,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> navLight = [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 16,
      offset: Offset(0, -4),
      spreadRadius: -4,
    ),
  ];

  /// Dark mode: subtle lift + optional accent glow.
  static List<BoxShadow> cardDark(Color accent) => [
        BoxShadow(
          color: accent.withOpacity(0.14),
          blurRadius: 22,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.55),
          blurRadius: 16,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
      ];

  static const List<BoxShadow> navDark = [
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 18,
      offset: Offset(0, -4),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> fabGlow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

/// Soft gradient overlays for hero / premium surfaces.
abstract final class AppGradients {
  static LinearGradient heroLight(Color accent) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.08),
          colorSchemeLightSurface.withOpacity(0.0),
        ],
      );

  static LinearGradient heroDark(Color accent) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.12),
          const Color(0x00000000),
        ],
      );

  static const Color colorSchemeLightSurface = Color(0xFFFFFFFF);
}
