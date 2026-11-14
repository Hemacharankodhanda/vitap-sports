/// VIT-AP Sports — Apple Design System Color Palette.
///
/// Clean, minimal, content-first monochrome tokens with subtle grays
/// and semantic-only accent colors. Supports Light, Dark, and System theme.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Apple Design Monochrome Tokens ─────────────────────────

  // Light Mode
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F7);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightFillSecondary = Color(0xFFE8E8ED);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightTextTertiary = Color(0xFF86868B);
  static const Color lightDivider = Color(0xFFD2D2D7);
  static const Color lightPrimaryFill = Color(0xFF1D1D1F);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightLink = Color(0xFF0066CC);

  // Dark Mode
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkFillSecondary = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1A6);
  static const Color darkTextTertiary = Color(0xFF86868B);
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkPrimaryFill = Color(0xFFF5F5F7);
  static const Color darkOnPrimary = Color(0xFF1D1D1F);
  static const Color darkLink = Color(0xFF2997FF);

  // Common Overlays
  static const Color scrim = Color(0x66000000); // 40% black
  static const double scrimOpacity = 0.40;
  static const Color focusRing = Color(0xFF1D1D1F);
  static const Color darkFocusRing = Color(0xFFF5F5F7);

  // ─── Semantic Tokens (Used sparingly for status/meaning) ────
  // Live
  static const Color liveLight = Color(0xFFFF3B30);
  static const Color liveDark = Color(0xFFFF453A);
  static const Color liveContainerLight = Color(0x1AFF3B30); // 10%
  static const Color liveContainerDark = Color(0x29FF453A); // 16%

  // Win / Positive
  static const Color winLight = Color(0xFF248A3D);
  static const Color winDark = Color(0xFF30D158);
  static const Color winContainerLight = Color(0x1A248A3D); // 10%
  static const Color winContainerDark = Color(0x2930D158); // 16%

  // Loss / Negative
  static const Color lossLight = Color(0xFFD70015);
  static const Color lossDark = Color(0xFFFF453A);
  static const Color lossContainerLight = Color(0x1AD70015); // 10%
  static const Color lossContainerDark = Color(0x29FF453A); // 16%

  // Warning / Paused
  static const Color warningLight = Color(0xFFB25000);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color warningContainerLight = Color(0x1AB25000); // 10%
  static const Color warningContainerDark = Color(0x29FF9F0A); // 16%

  // Backwards-compatible static aliases
  static const Color live = liveLight;
  static const Color win = winLight;
  static const Color loss = lossLight;
  static const Color warning = warningLight;
  static const Color success = winLight;
  static const Color error = lossLight;
  static const Color accent = lightPrimaryFill;
  static const Color accentLight = darkPrimaryFill;
  static const Color accentDark = lightPrimaryFill;
  static const Color accentSurface = lightFillSecondary;

  static const Color upcoming = lightPrimaryFill;
  static const Color upcomingSurface = lightFillSecondary;
  static const Color completed = lightTextSecondary;
  static const Color completedSurface = lightSurface;
  static const Color cancelled = lossLight;
  static const Color cancelledSurface = lossContainerLight;

  static const Color borderStrongLight = lightDivider;
  static const Color borderStrongDark = darkDivider;
  static const Color lightSurfaceVariant = lightFillSecondary;
  static const Color darkSurfaceVariant = darkFillSecondary;

  // State Overlays
  static const double overlayHover = 0.06;
  static const double overlayFocus = 0.08;
  static const double overlayPressed = 0.08;
  static const double overlayDisabledContent = 0.38;
  static const double overlayDisabledContainer = 0.12;

  // Badges
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
    required this.surfaceElevated,
    required this.surfaceVariant,
    required this.fillSecondary,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primaryFill,
    required this.onPrimary,
    required this.link,
    required this.scrim,
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
  final Color surfaceElevated;
  final Color surfaceVariant;
  final Color fillSecondary;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primaryFill;
  final Color onPrimary;
  final Color link;
  final Color scrim;

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
  Color get divider => border;

  static const light = AppColorsExtension(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceVariant: AppColors.lightFillSecondary,
    fillSecondary: AppColors.lightFillSecondary,
    border: AppColors.lightDivider,
    borderStrong: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    primaryFill: AppColors.lightPrimaryFill,
    onPrimary: AppColors.lightOnPrimary,
    link: AppColors.lightLink,
    scrim: AppColors.scrim,
    accent: AppColors.lightPrimaryFill,
    onAccent: AppColors.lightOnPrimary,
    accentContainer: AppColors.lightFillSecondary,
    live: AppColors.liveLight,
    liveContainer: AppColors.liveContainerLight,
    win: AppColors.winLight,
    winContainer: AppColors.winContainerLight,
    loss: AppColors.lossLight,
    lossContainer: AppColors.lossContainerLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
  );

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    surfaceVariant: AppColors.darkFillSecondary,
    fillSecondary: AppColors.darkFillSecondary,
    border: AppColors.darkDivider,
    borderStrong: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    primaryFill: AppColors.darkPrimaryFill,
    onPrimary: AppColors.darkOnPrimary,
    link: AppColors.darkLink,
    scrim: AppColors.scrim,
    accent: AppColors.darkPrimaryFill,
    onAccent: AppColors.darkOnPrimary,
    accentContainer: AppColors.darkFillSecondary,
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
    Color? surfaceElevated,
    Color? surfaceVariant,
    Color? fillSecondary,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primaryFill,
    Color? onPrimary,
    Color? link,
    Color? scrim,
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
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      fillSecondary: fillSecondary ?? this.fillSecondary,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primaryFill: primaryFill ?? this.primaryFill,
      onPrimary: onPrimary ?? this.onPrimary,
      link: link ?? this.link,
      scrim: scrim ?? this.scrim,
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
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      fillSecondary: Color.lerp(fillSecondary, other.fillSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      link: Color.lerp(link, other.link, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
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
