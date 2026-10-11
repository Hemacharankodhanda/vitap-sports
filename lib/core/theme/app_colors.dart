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
  static const Color liveLight = live;
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

  static const Color success = win;
  static const Color error = loss;

  // ─── Status / Additional Tokens (Component Spec) ─────────
  static const Color borderStrongLight = Color(0xFFCBD5E1);
  static const Color borderStrongDark = Color(0xFF334155);

  static const Color warningLight = Color(0xFFB45309);
  static const Color warningDark = Color(0xFFFBBF24);

  static const Color warning = warningLight;

  // ─── Container Tints (10% on light, 16% on dark) ──────────
  static const Color accentContainerLight = Color(0x1A2563EB); // 10%
  static const Color accentContainerDark = Color(0x2960A5FA); // 16%

  static const Color liveContainerLight = Color(0x1ADC2626);
  static const Color liveContainerDark = Color(0x29F87171);

  static const Color winContainerLight = Color(0x1A15803D);
  static const Color winContainerDark = Color(0x294ADE80);

  static const Color lossContainerLight = Color(0x1AB91C1C);
  static const Color lossContainerDark = Color(0x29F87171);

  static const Color warningContainerLight = Color(0x1AB45309);
  static const Color warningContainerDark = Color(0x29FBBF24);

  // ─── State Overlays ───────────────────────────────────────
  static const double overlayHover = 0.08;
  static const double overlayFocus = 0.12;
  static const double overlayPressed = 0.12;
  static const double overlayDisabledContent = 0.38;
  static const double overlayDisabledContainer = 0.12;

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
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.live,
    required this.liveContainer,
    required this.win,
    required this.winContainer,
    required this.loss,
    required this.lossContainer,
    required this.warning,
    required this.warningContainer,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color live;
  final Color liveContainer;
  final Color win;
  final Color winContainer;
  final Color loss;
  final Color lossContainer;
  final Color warning;
  final Color warningContainer;

  Color get negative => loss;
  Color get negativeContainer => lossContainer;

  static const light = AppColorsExtension(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    border: AppColors.lightDivider,
    borderStrong: AppColors.borderStrongLight,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    accent: Color(0xFF2563EB),
    onAccent: Colors.white,
    accentContainer: AppColors.accentContainerLight,
    live: AppColors.live,
    liveContainer: AppColors.liveContainerLight,
    win: AppColors.win,
    winContainer: AppColors.winContainerLight,
    loss: AppColors.loss,
    lossContainer: AppColors.lossContainerLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
  );

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    border: AppColors.darkDivider,
    borderStrong: AppColors.borderStrongDark,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    accent: Color(0xFF60A5FA),
    onAccent: AppColors.darkBackground,
    accentContainer: AppColors.accentContainerDark,
    live: AppColors.liveDark,
    liveContainer: AppColors.liveContainerDark,
    win: AppColors.winDark,
    winContainer: AppColors.winContainerDark,
    loss: AppColors.lossDark,
    lossContainer: AppColors.lossContainerDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? live,
    Color? liveContainer,
    Color? win,
    Color? winContainer,
    Color? loss,
    Color? lossContainer,
    Color? warning,
    Color? warningContainer,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      live: live ?? this.live,
      liveContainer: liveContainer ?? this.liveContainer,
      win: win ?? this.win,
      winContainer: winContainer ?? this.winContainer,
      loss: loss ?? this.loss,
      lossContainer: lossContainer ?? this.lossContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
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
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      live: Color.lerp(live, other.live, t)!,
      liveContainer: Color.lerp(liveContainer, other.liveContainer, t)!,
      win: Color.lerp(win, other.win, t)!,
      winContainer: Color.lerp(winContainer, other.winContainer, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      lossContainer: Color.lerp(lossContainer, other.lossContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
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
