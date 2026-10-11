/// VIT-AP Sports — MatchCard widget.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/match_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap});
  final MatchModel match;
  final VoidCallback? onTap;

  MatchStatus get _status {
    switch (match.status) {
      case 'live': return MatchStatus.live;
      case 'completed': return MatchStatus.completed;
      case 'cancelled': return MatchStatus.cancelled;
      default: return MatchStatus.upcoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final home = match.participants.where((p) => p.side == 'home').toList();
    final away = match.participants.where((p) => p.side == 'away').toList();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: sport + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                match.sportName ?? 'Sport',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StatusBadge(status: _status, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Teams
          Row(
            children: [
              Expanded(
                child: Text(
                  home.isNotEmpty
                      ? (home.first.teamName ?? home.first.userName ?? match.homeTeamName ?? 'Team 1')
                      : (match.homeTeamName ?? 'TBD'),
                  style: AppTypography.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'vs',
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  away.isNotEmpty
                      ? (away.first.teamName ?? away.first.userName ?? match.awayTeamName ?? 'Team 2')
                      : (match.awayTeamName ?? 'TBD'),
                  style: AppTypography.headline,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Venue + Time
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: AppSpacing.iconInline,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  match.venue,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.schedule_rounded,
                size: AppSpacing.iconInline,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppDateUtils.formatSmartDateTime(match.scheduledAt),
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
