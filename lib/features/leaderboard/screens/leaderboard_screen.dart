/// VIT-AP Sports — Leaderboard screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/leaderboard/tournaments'),
            tooltip: 'Tournaments',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Sport filter (placeholder)
          SizedBox(
            height: AppSpacing.chipHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                AppChip(label: 'All', isSelected: true),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Cricket'),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Football'),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Basketball'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Top Players section
          const SectionHeader(title: 'Top Players'),
          const SizedBox(height: AppSpacing.md),
          const EmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'No leaderboard data yet',
            subtitle: 'Play matches to appear on the leaderboard!',
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Top Teams section
          const SectionHeader(title: 'Top Teams'),
          const SizedBox(height: AppSpacing.md),
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No team rankings yet',
            subtitle: 'Teams will be ranked after completing matches.',
          ),
        ],
      ),
    );
  }
}
