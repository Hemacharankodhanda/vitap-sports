/// VIT-AP Sports — AppChip and ResultChip widgets (Apple Design System).
///
/// Component specification:
/// - Pill shape (StadiumBorder / radius 999).
/// - Unselected: fillSecondary background + textPrimary text, no border.
/// - Selected: primaryFill background + onPrimary text, no checkmark.
/// - Result chip (W / D / L): 24 x 24, radius 8, container tints (win/loss/warning).
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

    final bgColor = isSelected ? colors.primaryFill : colors.fillSecondary;
    final textColor = isSelected ? colors.onPrimary : colors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget, minWidth: AppSpacing.minTouchTarget),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          splashColor: Colors.transparent,
          highlightColor: textColor.withAlpha(20),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
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
      bgColor = colors.warningContainer;
      textColor = colors.warning;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        clean,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
