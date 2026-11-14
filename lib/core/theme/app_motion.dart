/// VIT-AP Sports — Motion & Animation Tokens.
///
/// Restrained, fluid Apple-inspired curves and timing.
library;

import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  /// Apple-style standard ease curve: Cubic(0.28, 0.11, 0.32, 1.0)
  static const Curve curve = Cubic(0.28, 0.11, 0.32, 1.0);

  /// Quick feedback for tap/press states (120 ms)
  static const Duration press = Duration(milliseconds: 120);

  /// Fluid transitions for state changes, theme crossfades, segmented controls (250 ms)
  static const Duration stateChange = Duration(milliseconds: 250);

  /// Navigation, modal sheets, and page transitions (350 ms)
  static const Duration pageOrSheet = Duration(milliseconds: 350);

  /// Checks if reduce-motion is enabled in system settings
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}
