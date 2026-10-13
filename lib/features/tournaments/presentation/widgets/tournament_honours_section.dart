/// VIT-AP Sports — Tournament Honours Section.
///
/// Displays a player's official tournament podium honours:
/// Champions (Gold), Runner-up (Silver), and 3rd Place (Bronze).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/models/tournament_models.dart';

class TournamentHonoursSection extends StatelessWidget {
  const TournamentHonoursSection({
    required this.honours,
    super.key,
  });

  final List<TournamentHonour> honours;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Tournament Honours',
        ),
        const SizedBox(height: 12),
        if (honours.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 24,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No tournament honours yet • Participate in campus tournaments to earn podium trophies',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: honours.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final honour = honours[index];
              return _HonourCard(honour: honour);
            },
          ),
      ],
    );
  }
}

class _HonourCard extends StatelessWidget {
  const _HonourCard({required this.honour});

  final TournamentHonour honour;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final (badgeColor, badgeSurface, badgeIcon, titleLabel) = switch (honour.rank) {
      HonourRank.champion => (
          AppColors.gold,
          AppColors.gold.withValues(alpha: 0.12),
          Icons.emoji_events,
          'CHAMPION',
        ),
      HonourRank.runnerUp => (
          AppColors.silver,
          AppColors.silver.withValues(alpha: 0.12),
          Icons.military_tech,
          'RUNNER-UP',
        ),
      HonourRank.thirdPlace => (
          AppColors.bronze,
          AppColors.bronze.withValues(alpha: 0.12),
          Icons.workspace_premium,
          '3RD PLACE',
        ),
    };

    return AppCard(
      onTap: honour.tournamentId.isNotEmpty
          ? () => context.push('/tournaments/${honour.tournamentId}')
          : null,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Medal / Trophy Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor, width: 1.0),
            ),
            child: Icon(
              badgeIcon,
              color: badgeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        titleLabel,
                        style: AppTypography.caption.copyWith(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      honour.year,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (honour.isOfficial) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• Official',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  honour.tournamentName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${honour.sport.toUpperCase()} • ${honour.teamOrEntryName}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
