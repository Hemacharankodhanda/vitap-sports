/// VIT-AP Sports — Apple UI Responsive Breakpoints.
///
/// Breakpoint scale:
/// - Compact: < 600 dp (Phone portrait)
/// - Medium: 600 to 1023 dp (Tablets, phone landscape, foldable unfolded)
/// - Expanded: >= 1024 dp (Desktop, tablet landscape, wide web)
library;

import 'package:flutter/material.dart';

enum AppWindowSize { compact, medium, expanded }

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 599.9;
  static const double mediumMin = 600.0;
  static const double mediumMax = 1023.9;
  static const double expandedMin = 1024.0;

  // Maximum content reading constraints
  static const double maxContentWidth = 1120.0;
  static const double maxReadingWidth = 680.0;

  static AppWindowSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mediumMin) return AppWindowSize.compact;
    if (width < expandedMin) return AppWindowSize.medium;
    return AppWindowSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mediumMin;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mediumMin && width < expandedMin;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedMin;

  static double screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mediumMin) return 24.0;
    if (width < expandedMin) return 32.0;
    return 40.0;
  }
}
