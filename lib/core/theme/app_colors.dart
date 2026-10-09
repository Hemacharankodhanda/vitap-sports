/// VIT-AP Sports — Color palette.
///
/// Single accent color used sparingly for CTAs, active states, live indicators.
/// Neutral grayscale for everything else. Supports light and dark mode.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Accent ───────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6D00); // Vivid orange
  static const Color accentLight = Color(0xFFFF9E40);
  static const Color accentDark = Color(0xFFE65100);
  static const Color accentSurface = Color(0x14FF6D00); // 8% opacity

  // ─── Semantic / Status ────────────────────────────────────
  static const Color live = Color(0xFF00C853); // Green — live match
  static const Color liveSurface = Color(0x1400C853);
  static const Color upcoming = Color(0xFF2979FF); // Blue — upcoming
  static const Color upcomingSurface = Color(0x142979FF);
  static const Color completed = Color(0xFF78909C); // Grey — completed
  static const Color completedSurface = Color(0x1478909C);
  static const Color cancelled = Color(0xFFEF5350); // Red — cancelled
  static const Color cancelledSurface = Color(0x14EF5350);

  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  // ─── Light Mode ───────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightDivider = Color(0xFFE9ECEF);
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextTertiary = Color(0xFFADB5BD);

  // ─── Dark Mode ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  static const Color darkDivider = Color(0xFF30363D);
  
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextTertiary = Color(0xFF484F58);

  // ─── Badge Colors (achievement backgrounds) ───────────────
  static const Color gold = Color(0xFFFFD54F);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color bronze = Color(0xFFBCAAA4);
}
