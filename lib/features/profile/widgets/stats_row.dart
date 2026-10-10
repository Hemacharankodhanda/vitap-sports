/// VIT-AP Sports — StatsRow widget.
///
/// Horizontal stats display with consistent layout.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class StatItem {
  const StatItem({required this.label, required this.value});
  final String label;
  final String value;
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});

  final List<StatItem> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Row(
        children: stats
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final stat = entry.value;
              return Expanded(
                child: Container(
                  decoration: index < stats.length - 1
                      ? BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider,
                              width: 1,
                            ),
                          ),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.value,
                        style: AppTypography.title.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        stat.label,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}
