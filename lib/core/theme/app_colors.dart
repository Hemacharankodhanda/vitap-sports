/// VIT-AP Sports — Color palette.
///
/// Single accent color used sparingly for CTAs, active states, live indicators.
/// Neutral grayscale for everything else. Supports light and dark mode.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Accent ───────────────────────────────────────────────
  static const Color accent = Color(0xFF2563EB); // Modern professional blue (or orange if chosen)
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF1D4ED8);
  static const Color accentSurface = Color(0x142563EB);

  // ─── Semantic / Status ────────────────────────────────────
  static const Color live = Color(0xFFDC2626); // Live broadcast red
  static const Color liveDark = Color(0xFFF87171);
  static const Color liveSurface = Color(0x14DC2626);

  static const Color win = Color(0xFF15803D); // Win / Positive green
  static const Color winDark = Color(0xFF4ADE80);

  static const Color loss = Color(0xFFB91C1C); // Loss / Negative red
  static const Color lossDark = Color(0xFFF87171);

  static const Color upcoming = Color(0xFF2563EB);
  static const Color upcomingSurface = Color(0x142563EB);
  static const Color completed = Color(0xFF64748B);
  static const Color completedSurface = Color(0x1464748B);
  static const Color cancelled = Color(0xFFB91C1C);
  static const Color cancelledSurface = Color(0x14B91C1C);

  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // ─── Light Mode ───────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // ─── Dark Mode ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0F14);
  static const Color darkSurface = Color(0xFF131A22);
  static const Color darkSurfaceVariant = Color(0xFF1E2633);
  static const Color darkDivider = Color(0xFF243040);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // ─── Badge Colors ─────────────────────────────────────────
  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF94A3B8);
  static const Color bronze = Color(0xFFB45309);
}

/// Semantic ThemeExtension for theme-aware tokens: surface, textSecondary, live, win, etc.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.live,
    required this.win,
    required this.loss,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color live;
  final Color win;
  final Color loss;

  static const light = AppColorsExtension(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    border: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    accent: Color(0xFF2563EB),
    live: AppColors.live,
    win: AppColors.win,
    loss: AppColors.loss,
  );

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    border: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    accent: Color(0xFF60A5FA),
    live: AppColors.liveDark,
    win: AppColors.winDark,
    loss: AppColors.lossDark,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? live,
    Color? win,
    Color? loss,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      live: live ?? this.live,
      win: win ?? this.win,
      loss: loss ?? this.loss,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      live: Color.lerp(live, other.live, t)!,
      win: Color.lerp(win, other.win, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
    );
  }
}

extension AppThemeColors on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColorsExtension.dark
          : AppColorsExtension.light);
}
