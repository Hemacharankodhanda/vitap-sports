/// VIT-AP Sports — Feed screen (Home tab).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sport_filter_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'VIT-AP Sports',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/home/free-agents'),
            tooltip: 'Free Agents',
          ),
        ],
        bottom: const SportFilterBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.lg,
        ),
        children: [
          // ─── Quick Actions ────────────────────────────
          SectionHeader(
            title: 'Quick Actions',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.groups_rounded,
                  label: 'Create Team',
                  onTap: () => context.go('/teams/create'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.sports_rounded,
                  label: 'New Match',
                  onTap: () => context.go('/matches/create'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // ─── Activity Feed ────────────────────────────
          const SectionHeader(title: 'Recent Activity'),
          const SizedBox(height: AppSpacing.md),
          const EmptyState(
            icon: Icons.dynamic_feed_rounded,
            title: 'No recent activity',
            subtitle: 'Match results, new teams, and achievements will appear here.',
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: AppSpacing.iconNav),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
