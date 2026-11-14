import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/theme/app_theme_provider.dart';

/// Calculates relative luminance according to WCAG 2.1 specs
double relativeLuminance(Color color) {
  double channel(double value) {
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates WCAG 2.1 contrast ratio between two colors
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('WCAG 2.1 Contrast Ratio Tests (Apple Design Tokens)', () {
    test('Light Theme text and required semantic tokens meet contrast thresholds', () {
      final failures = <String>[];

      void check(String pairName, Color fg, Color bg, {double minRatio = 4.5}) {
        final ratio = contrastRatio(fg, bg);
        if (ratio < minRatio) {
          failures.add('$pairName failed: ratio ${ratio.toStringAsFixed(2)}:1 is below $minRatio:1');
        }
      }

      // Required text on surfaces (minimum 4.5:1)
      check('lightTextPrimary on lightBackground', AppColors.lightTextPrimary, AppColors.lightBackground);
      check('lightTextPrimary on lightSurface', AppColors.lightTextPrimary, AppColors.lightSurface);
      check('lightTextPrimary on lightFillSecondary', AppColors.lightTextPrimary, AppColors.lightFillSecondary);
      check('lightTextSecondary on lightBackground', AppColors.lightTextSecondary, AppColors.lightBackground);
      check('lightTextSecondary on lightSurface', AppColors.lightTextSecondary, AppColors.lightSurface);
      check('lightOnPrimary on lightPrimaryFill', AppColors.lightOnPrimary, AppColors.lightPrimaryFill);

      // Semantic status indicators on light background
      check('lossLight on lightBackground', AppColors.lossLight, AppColors.lightBackground);
      check('link on lightBackground', AppColors.lightLink, AppColors.lightBackground);

      // Status badges, icons, and large indicators (minimum 3.0:1)
      check('winLight on lightBackground (status badge/indicator)', AppColors.winLight, AppColors.lightBackground, minRatio: 3.0);
      check('liveLight on lightBackground (status badge/icon)', AppColors.liveLight, AppColors.lightBackground, minRatio: 3.0);
      check('warningLight on lightBackground (icons)', AppColors.warningLight, AppColors.lightBackground, minRatio: 3.0);

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('Dark Theme text and required semantic tokens meet contrast thresholds', () {
      final failures = <String>[];

      void check(String pairName, Color fg, Color bg, {double minRatio = 4.5}) {
        final ratio = contrastRatio(fg, bg);
        if (ratio < minRatio) {
          failures.add('$pairName failed: ratio ${ratio.toStringAsFixed(2)}:1 is below $minRatio:1');
        }
      }

      // Required text on surfaces (minimum 4.5:1)
      check('darkTextPrimary on darkBackground', AppColors.darkTextPrimary, AppColors.darkBackground);
      check('darkTextPrimary on darkSurface', AppColors.darkTextPrimary, AppColors.darkSurface);
      check('darkTextPrimary on darkFillSecondary', AppColors.darkTextPrimary, AppColors.darkFillSecondary);
      check('darkTextSecondary on darkBackground', AppColors.darkTextSecondary, AppColors.darkBackground);
      check('darkTextSecondary on darkSurface', AppColors.darkTextSecondary, AppColors.darkSurface);
      check('darkOnPrimary on darkPrimaryFill', AppColors.darkOnPrimary, AppColors.darkPrimaryFill);

      // Semantic status indicators on dark background
      check('winDark on darkBackground', AppColors.winDark, AppColors.darkBackground);
      check('lossDark on darkBackground', AppColors.lossDark, AppColors.darkBackground);
      check('link on darkBackground', AppColors.darkLink, AppColors.darkBackground);

      // Status badges, icons, and large indicators (minimum 3.0:1)
      check('liveDark on darkBackground (status badge/icon)', AppColors.liveDark, AppColors.darkBackground, minRatio: 3.0);
      check('warningDark on darkBackground (icons)', AppColors.warningDark, AppColors.darkBackground, minRatio: 3.0);

      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('Theme Building & Persistence Tests', () {
    test('Both Light and Dark ThemeData build successfully', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(lightTheme.cardTheme.elevation, 0.0);
      expect(darkTheme.cardTheme.elevation, 0.0);
    });

    test('ThemeMode persistence and restore', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final notifier = AppThemeNotifier(initialMode: ThemeMode.dark);

      expect(notifier.state.themeMode, ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });
  });
}
