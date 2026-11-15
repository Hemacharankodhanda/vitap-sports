/// VIT-AP Sports — Typography Scale (Apple Design System).
///
/// Single typeface: Inter (Google Fonts).
/// Tabular figures for ALL numbers via FontFeature.tabularFigures.
/// Sentence case, tight tracking on large display sizes.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static const String fontName = 'Inter';

  static String get _fontFamily {
    // In test bindings or when allowRuntimeFetching is disabled, avoid triggering
    // asynchronous HTTP font fetches that fail under Flutter test harness.
    if (kIsWeb || !GoogleFonts.config.allowRuntimeFetching) {
      return fontName;
    }
    try {
      return GoogleFonts.inter().fontFamily ?? fontName;
    } catch (_) {
      return fontName;
    }
  }

  // ─── Apple Typography Scale ──────────────────────────────────

  /// Display XL 48/52 w700 (scores, hero numbers) — Letter spacing -2% (-0.96)
  static TextStyle get displayXL => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 52 / 48,
        letterSpacing: -0.96,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Large Title 34/40 w700 — Letter spacing -2% (-0.68)
  static TextStyle get largeTitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 40 / 34,
        letterSpacing: -0.68,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Title 24/30 w600 — Letter spacing -2% (-0.48)
  static TextStyle get title => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 30 / 24,
        letterSpacing: -0.48,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Headline 17/24 w600 — Letter spacing -1% (-0.17)
  static TextStyle get headline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 24 / 17,
        letterSpacing: -0.17,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Body 16/24 w400 — Letter spacing 0.0
  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Callout 15/22 w400 — Letter spacing -1% (-0.15)
  static TextStyle get callout => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
        letterSpacing: -0.15,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Footnote 13/18 w400 — Letter spacing -1% (-0.13)
  static TextStyle get footnote => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        letterSpacing: -0.13,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Caption 12/16 w500 — Letter spacing -1% (-0.12)
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: -0.12,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─── Backwards-Compatible Aliases ───────────────────────────
  static TextStyle get scoreDisplay => displayXL;
  static TextStyle get scoreMedium => title.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get titleLarge => largeTitle;
  static TextStyle get overline => footnote.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // ─── Material TextTheme ────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayXL,
        displayMedium: largeTitle,
        displaySmall: title,
        headlineMedium: headline,
        titleLarge: title,
        titleMedium: headline,
        titleSmall: callout.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: body,
        bodyMedium: callout,
        bodySmall: footnote,
        labelLarge: callout.copyWith(fontWeight: FontWeight.w600),
        labelMedium: footnote,
        labelSmall: caption,
      );
}
