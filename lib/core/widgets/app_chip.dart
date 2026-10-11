/// VIT-AP Sports — AppChip and ResultChip widgets.
///
/// Component specification:
/// - Filter chip: height 32 (48 touch target), radius 8.
///   Unselected: 1 px borderStrong, textPrimary.
///   Selected: accentContainer, accent text, no checkmark.
/// - Result chip (W / D / L): 24 x 24, radius 8, letter inside, container tints.
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
    final colors = context.appColors;

    final bgColor = isSelected ? colors.accentContainer : Colors.transparent;
    final textColor = isSelected ? colors.accent : colors.textPrimary;
    final borderColor = isSelected ? Colors.transparent : colors.borderStrong;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (avatar != null) ...[
                  avatar!,
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 16, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.callout.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 24x24 result chip (W / D / L) per component specification.
class ResultChip extends StatelessWidget {
  const ResultChip({
    super.key,
    required this.result,
  });

  final String result; // 'W', 'D', 'L'

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final clean = result.trim().toUpperCase();

    Color bgColor;
    Color textColor;

    if (clean == 'W') {
      bgColor = colors.winContainer;
      textColor = colors.win;
    } else if (clean == 'L') {
      bgColor = colors.lossContainer;
      textColor = colors.loss;
    } else {
      bgColor = colors.textPrimary.withAlpha(15);
      textColor = colors.textSecondary;
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        clean,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
