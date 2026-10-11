/// VIT-AP Sports — EmptyState widget.
///
/// Component specification:
/// Centred column (max width 280): optional 40 px outline icon in textSecondary,
/// Headline title, one to two lines of Body text in textSecondary,
/// at most one button (tonal or outlined).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 40,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                title,
                style: AppTypography.headline.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ] else if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
