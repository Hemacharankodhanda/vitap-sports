/// VIT-AP Sports — Typography scale.
///
/// Single typeface: Inter (via Google Fonts).
/// Limited type scale: largeTitle / title / headline / body / caption.
/// No ad hoc font sizes outside this scale.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // ─── Type Scale (Design Rules) ─────────────────────────────

  /// 48sp / 56lh / 700 bold — Display (scores)
  static TextStyle get scoreDisplay => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 28sp / 36lh / 700 bold — Title large
  static TextStyle get largeTitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get titleLarge => largeTitle;

  /// 20sp / 28lh / 600 semibold — Title
  static TextStyle get title => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 16sp / 24lh / 600 semibold — Headline
  static TextStyle get headline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 15sp / 24lh / 400 regular — Body
  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 24 / 15,
      );

  /// 14sp / 20lh / 500 medium — Callout
  static TextStyle get callout => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 12sp / 16lh / 500 medium — Caption
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 12sp / 16lh / 500 medium — Overline / Tiny label (sentence or uppercase)
  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 24sp / 32lh / 700 bold — Medium score display
  static TextStyle get scoreMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─── Utility Modifiers ────────────────────────────────────

  /// Appends tabular figures to any TextStyle
  static TextStyle tabular(TextStyle base) => base.copyWith(
        fontFeatures: [
          ...?base.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      );

  /// Returns the full TextTheme for Material 3 theme data
  static TextTheme get textTheme => TextTheme(
        displayLarge: scoreDisplay,
        displayMedium: largeTitle,
        headlineMedium: headline,
        titleMedium: title,
        bodyLarge: body,
        bodyMedium: caption,
        labelLarge: callout,
        labelMedium: overline,
      );
}
