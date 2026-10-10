/// VIT-AP Sports — AppChip widget.
///
/// Consistent 40px-height chip for filter/selection.
/// Selected state uses accent color per design guidelines.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.avatar,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected
        ? Theme.of(context).colorScheme.primary.withAlpha(20)
        : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant);
    final textColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary.withAlpha(77)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: AppSpacing.chipHeight,
        padding: EdgeInsets.symmetric(
          horizontal: avatar != null ? AppSpacing.xs : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: AppSpacing.sm),
            ],
            if (icon != null) ...[
              Icon(icon, size: AppSpacing.iconInline, color: textColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
