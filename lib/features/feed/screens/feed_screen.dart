/// VIT-AP Sports — Feed screen (Home tab) (Apple Design System).
///
/// Content-first Apple look: generous whitespace, calm monochrome surfaces,
/// frosted navigation bar, live status indicators, zero emojis.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/frosted_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sport_filter_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../matches/providers/match_providers.dart';
import '../../matches/widgets/match_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final liveMatchesAsync = ref.watch(liveMatchesStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: FrostedAppBar(
        title: Text(
          'VIT-AP Sports',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/home/free-agents'),
            tooltip: 'Free Agents',
            color: colors.textPrimary,
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
          // ─── Live Matches (Realtime Stream) ───────────
          ...liveMatchesAsync.when(
            loading: () => const [SizedBox.shrink()],
            error: (_, __) => const [SizedBox.shrink()],
            data: (liveMatches) {
              if (liveMatches.isEmpty) return const <Widget>[];

              return [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const StatusLabel.live(),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Live Matches',
                          style: AppTypography.headline.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/matches'),
                      child: Text(
                        'View All',
                        style: AppTypography.callout.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final match in liveMatches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: MatchCard(
                      match: match,
                      onTap: () => context.go('/matches/${match.id}'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sectionGap),
              ];
            },
          ),

          // ─── Quick Actions ────────────────────────────
          const SectionHeader(
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
          const SizedBox(height: AppSpacing.md),
          _WideQuickActionCard(
            icon: Icons.emoji_events_rounded,
            label: 'Tournaments',
            subtitle: 'Browse campus tournaments, fixtures, tables & brackets',
            onTap: () => context.push('/tournaments'),
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

class _WideQuickActionCard extends StatelessWidget {
  const _WideQuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.fillSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.footnote.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: colors.textSecondary,
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
    final colors = context.appColors;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.fillSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.textPrimary, size: AppSpacing.iconNav),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTypography.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
