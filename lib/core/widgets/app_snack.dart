/// VIT-AP Sports — AppSnack widget (Apple Design System).
///
/// Component specification:
/// - Floating capsule pill shape (StadiumBorder).
/// - Restrained soft shadow (the only place shadow is allowed).
/// - High contrast inverted surface (primaryFill) with onPrimary text.
/// - One text action maximum, 4 second duration.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppSnack {
  AppSnack._();

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.callout.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        backgroundColor: colors.primaryFill,
        shape: const StadiumBorder(),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: colors.onPrimary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
