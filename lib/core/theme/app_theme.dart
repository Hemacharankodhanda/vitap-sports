/// VIT-AP Sports — Apple Design System Theme Configuration.
///
/// Clean, minimal, content-first monochrome themes.
/// Elevation 0 everywhere. Separate with surface contrast and hairlines.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData light([Color? _]) {
    final colorScheme = const ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.lightPrimaryFill,
      onPrimary: AppColors.lightOnPrimary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightFillSecondary,
      error: AppColors.lossLight,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData dark([Color? _]) {
    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimaryFill,
      onPrimary: AppColors.darkOnPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkFillSecondary,
      error: AppColors.lossDark,
      onError: Colors.black,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ─── Build Theme ──────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceElevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final fillSecondary =
        isDark ? AppColors.darkFillSecondary : AppColors.lightFillSecondary;
    final primaryFill =
        isDark ? AppColors.darkPrimaryFill : AppColors.lightPrimaryFill;
    final onPrimary =
        isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary;

    final systemOverlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      extensions: [
        isDark ? AppColorsExtension.dark : AppColorsExtension.light,
      ],
      textTheme: AppTypography.textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 0,
      ),

      // ─── AppBar ─────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: AppTypography.title.copyWith(color: textColor),
      ),

      // ─── Bottom Navigation ──────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryFill,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.caption,
      ),

      // ─── Card ───────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),

      // ─── Switch ─────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return secondaryTextColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryFill;
          return fillSecondary;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ─── Buttons ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeightPrimary),
          textStyle: AppTypography.headline,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: onPrimary,
          shape: const StadiumBorder(),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeightPrimary),
          textStyle: AppTypography.headline,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: dividerColor, width: 0.5),
          shape: const StadiumBorder(),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeightPrimary),
          textStyle: AppTypography.headline,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.darkLink : AppColors.lightLink,
          shape: const StadiumBorder(),
          textStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w500),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeightCompact),
        ),
      ),

      // ─── Input Decoration ──────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: textColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: const BorderSide(color: AppColors.loss, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: const BorderSide(color: AppColors.loss, width: 1.5),
        ),
        labelStyle: AppTypography.callout.copyWith(color: secondaryTextColor),
        hintStyle: AppTypography.body.copyWith(color: AppColors.lightTextTertiary),
        errorStyle: AppTypography.footnote.copyWith(color: AppColors.loss),
      ),

      // ─── Chip ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: fillSecondary,
        selectedColor: primaryFill,
        labelStyle: AppTypography.callout,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),

      // ─── Bottom Sheet ──────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
        dragHandleColor: dividerColor,
        showDragHandle: true,
      ),

      // ─── Dialog ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDialog),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: textColor),
        contentTextStyle: AppTypography.body.copyWith(color: secondaryTextColor),
      ),

      // ─── Snackbar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFF1D1D1F),
        contentTextStyle: AppTypography.callout.copyWith(
          color: isDark ? AppColors.darkTextPrimary : Colors.white,
        ),
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ─── Tab Bar ───────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: textColor,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: primaryFill,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: dividerColor,
        labelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w400),
      ),

      // ─── Page Transitions ─────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
