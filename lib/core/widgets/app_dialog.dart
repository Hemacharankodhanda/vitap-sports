/// VIT-AP Sports — AppDialog widget.
///
/// Component specification:
/// - Radius 16, max width 400, padding 24.
/// - Title heading, Body text in textSecondary.
/// - Right-aligned text-button actions. No header icons.
/// - Used for destructive confirmation and critical decisions. Scrim 40%.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlpha((0.40 * 255).round()), // 40% scrim
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.medium,
                    isExpanded: false,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: confirmLabel,
                    variant: isDestructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    isExpanded: false,
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
