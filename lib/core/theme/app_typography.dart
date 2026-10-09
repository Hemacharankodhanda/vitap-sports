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

  // ─── Type Scale ───────────────────────────────────────────

  /// 28sp / bold — screen titles, hero numbers
  static TextStyle get largeTitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// 22sp / semibold — section titles, modal headers
  static TextStyle get title => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  /// 17sp / semibold — card titles, list item primary text
  static TextStyle get headline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// 15sp / regular — body text, descriptions, form labels
  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// 13sp / regular — secondary info, timestamps, metadata
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// 11sp / medium — tiny labels, badges, chips
  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.5,
      );

  // ─── Score Display ────────────────────────────────────────

  /// 40sp / bold — large score display on scorecards
  static TextStyle get scoreDisplay => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.0,
      );

  /// 24sp / bold — medium score display
  static TextStyle get scoreMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  // ─── Utility Modifiers ────────────────────────────────────

  /// Returns the full TextTheme for Material 3 theme data
  static TextTheme get textTheme => TextTheme(
        displayLarge: largeTitle,
        displayMedium: title,
        headlineMedium: headline,
        bodyLarge: body,
        bodyMedium: caption,
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelMedium: overline,
      );
}
