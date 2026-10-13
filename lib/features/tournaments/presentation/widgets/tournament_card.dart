/// VIT-AP Sports — Tournament Card.
///
/// Overview card for tournament listings adhering strictly to the design system.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/tournament_models.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    required this.tournament,
    this.onTap,
    super.key,
  });

  final TournamentModel tournament;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dateFormat = DateFormat('MMM d');
    String dateText = 'TBD';
    if (tournament.startDate != null) {
      dateText = dateFormat.format(tournament.startDate!);
      if (tournament.endDate != null) {
        dateText += ' - ${dateFormat.format(tournament.endDate!)}';
      }
    }

    final formatLabel = switch (tournament.format) {
      TournamentFormat.knockout => 'Knockout',
      TournamentFormat.league => 'League Table',
      TournamentFormat.groupsKnockout => 'Groups + KO',
    };

    final scopeLabel = switch (tournament.scope) {
      TournamentScope.open => 'Open',
      TournamentScope.hostel => 'Hostel: ${tournament.eligibility['hostel_block'] ?? 'Block'}',
      TournamentScope.branch => 'Branch: ${tournament.eligibility['branch'] ?? 'Dept'}',
      TournamentScope.year => 'Batch: ${tournament.eligibility['year'] ?? ''}',
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Sport + Format + Status
          Row(
            children: [
              AppChip(
                label: tournament.sport.toUpperCase(),
                isSelected: true,
              ),
              const SizedBox(width: 8),
              Text(
                formatLabel,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(context, tournament.status),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            tournament.name,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Footer details: Dates + Scope + Official Badge
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                scopeLabel,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (tournament.isOfficial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent, width: 0.8),
                  ),
                  child: Text(
                    'OFFICIAL',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TournamentStatus status) {
    final colors = context.appColors;

    switch (status) {
      case TournamentStatus.live:
        return const StatusBadge(
          status: MatchStatus.live,
        );
      case TournamentStatus.registrationOpen:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.win.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'REGISTRATION OPEN',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.win,
            ),
          ),
        );
      case TournamentStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.completedSurface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'COMPLETED',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.completed,
            ),
          ),
        );
      case TournamentStatus.registrationClosed:
      case TournamentStatus.ready:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'UPCOMING',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.name.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
            ),
          ),
        );
    }
  }
}
