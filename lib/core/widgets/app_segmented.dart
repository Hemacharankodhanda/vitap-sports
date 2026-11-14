/// VIT-AP Sports — AppSegmented widget (Apple Design System).
///
/// Component specification:
/// - Pill track in fillSecondary (#E8E8ED light / #2C2C2E dark).
/// - White (light) / #636366-ish elevated (dark) thumb that slides with 250 ms animation
///   using curve Cubic(0.28, 0.11, 0.32, 1.0).
/// - 2 to 4 options.
/// - Used for view toggles and for theme switches.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.iconBuilder,
    this.height = 40.0,
  }) : assert(options.length >= 2 && options.length <= 4,
            'AppSegmented requires between 2 and 4 options');

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final Widget Function(T)? iconBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = options.indexOf(selected);
    final count = options.length;

    // Thumb background: pure white with subtle elevation on light; #636366 elevated on dark
    final thumbColor = isDark ? const Color(0xFF636366) : Colors.white;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.fillSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSegmented),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final segmentWidth = totalWidth / count;
          final activeIndex = selectedIndex >= 0 ? selectedIndex : 0;

          return Stack(
            children: [
              // Sliding Animated Thumb
              AnimatedPositioned(
                duration: AppMotion.stateChangeDuration,
                curve: AppMotion.curve,
                left: activeIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSegmented),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 50 : 25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Clickable Segment Options
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < count; i++) ...[
                    Expanded(
                      child: InkWell(
                        onTap: () => onSelected(options[i]),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSegmented),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (iconBuilder != null) ...[
                                  iconBuilder!(options[i]),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Flexible(
                                  child: Text(
                                    labelBuilder(options[i]),
                                    style: AppTypography.callout.copyWith(
                                      fontWeight: i == activeIndex
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: i == activeIndex
                                          ? (isDark ? Colors.white : colors.textPrimary)
                                          : colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
