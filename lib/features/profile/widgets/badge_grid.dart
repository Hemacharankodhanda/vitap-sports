/// VIT-AP Sports — BadgeGrid widget.
///
/// Grid of achievement badges, greyed-out for unearned.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';

class BadgeGrid extends ConsumerWidget {
  const BadgeGrid({super.key});

  // Placeholder badges — will be populated from achievements table
  static const _badges = [
    _Badge('First Match', Icons.sports_rounded, true),
    _Badge('5 Wins', Icons.emoji_events_rounded, false),
    _Badge('Team Captain', Icons.star_rounded, false),
    _Badge('Hat-trick', Icons.local_fire_department_rounded, false),
    _Badge('MVP', Icons.workspace_premium_rounded, false),
    _Badge('10 Matches', Icons.sports_score_rounded, false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_badges.isEmpty) {
      return const EmptyState(
        icon: Icons.workspace_premium_outlined,
        title: 'No badges yet',
        subtitle: 'Play matches to earn achievements!',
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: _badges.length,
      itemBuilder: (_, index) {
        final badge = _badges[index];
        return Container(
          decoration: BoxDecoration(
            color: badge.earned
                ? AppColors.accentSurface
                : (isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                size: AppSpacing.iconLarge,
                color: badge.earned
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                badge.name,
                style: AppTypography.caption.copyWith(
                  color: badge.earned
                      ? AppColors.accent
                      : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary),
                  fontWeight:
                      badge.earned ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge {
  const _Badge(this.name, this.icon, this.earned);
  final String name;
  final IconData icon;
  final bool earned;
}
