/// VIT-AP Sports — AppSnack widget.
///
/// Component specification:
/// - Bottom aligned, radius 8.
/// - Dark inverse surface, white text.
/// - One text action maximum, 4 second duration.
/// - Used for confirmations and undo.
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.callout.copyWith(color: Colors.white),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.accentLight,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
