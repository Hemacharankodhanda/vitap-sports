/// VIT-AP Sports — Material 3 Theme Configuration.
///
/// Light and dark themes built from the design system constants.
/// useMaterial3: true, ColorScheme.fromSeed with accent orange.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData light(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      error: AppColors.error,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData dark(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      error: AppColors.error,
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
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      extensions: [
        isDark ? AppColorsExtension.dark : AppColorsExtension.light,
      ],
      textTheme: GoogleFonts.interTextTheme(
        AppTypography.textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 0,
      ),

      // ─── AppBar ─────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: textColor),
      ),

      // ─── Bottom Navigation ──────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.overline.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.overline,
      ),

      // ─── Navigation Bar (Material 3) ───────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primary.withAlpha(isDark ? 41 : 26),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: AppSpacing.iconNav,
              color: colorScheme.primary,
            );
          }
          return IconThemeData(
            size: AppSpacing.iconNav,
            color: secondaryTextColor,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.overline.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.overline.copyWith(color: secondaryTextColor);
        }),
      ),

      // ─── Cards ──────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),

      // ─── Filled Button (Primary) ───────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.headline,
        ),
      ),

      // ─── Elevated Button (Primary Fallback) ────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.headline,
        ),
      ),

      // ─── Outlined Button (Secondary) ───────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight,
          ),
          textStyle: AppTypography.headline,
        ),
      ),

      // ─── Text Button ───────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 48),
        ),
      ),

      // ─── Input Decoration ──────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.loss, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.loss, width: 2),
        ),
        labelStyle: AppTypography.callout.copyWith(color: secondaryTextColor),
        hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.loss),
      ),

      // ─── Chip ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        selectedColor: colorScheme.primary.withAlpha(isDark ? 41 : 26),
        labelStyle: AppTypography.caption,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight,
          ),
        ),
      ),

      // ─── Bottom Sheet ──────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        dragHandleColor: isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight,
        showDragHandle: true,
      ),

      // ─── Dialog ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dividerColor),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: textColor),
        contentTextStyle: AppTypography.body.copyWith(color: secondaryTextColor),
      ),

      // ─── Snackbar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFF1E293B),
        contentTextStyle: AppTypography.body.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Tab Bar ───────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w400),
      ),

      // ─── Page transitions ─────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
