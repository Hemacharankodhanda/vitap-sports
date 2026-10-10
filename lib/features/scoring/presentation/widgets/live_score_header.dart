/// VIT-AP Sports — Live Score Header.
///
/// Responsive scoreboard card displaying real-time match figures
/// for Cricket, Badminton, and Football.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../engines/badminton/badminton_state.dart';
import '../../engines/cricket/cricket_state.dart';
import '../../engines/football/football_state.dart';
import '../../providers/live_scorer_providers.dart';

class LiveScoreHeader extends StatelessWidget {
  const LiveScoreHeader({
    super.key,
    required this.state,
  });

  final ScorerState state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sport = state.sport.toLowerCase();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Title & Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${state.homeName} vs ${state.awayName}',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStatusBadge(isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Sport-specific Scoreboard View
          if (sport == 'cricket' && state.scoringState is CricketState)
            _buildCricketScore(context, state.scoringState as CricketState, isDark)
          else if (sport == 'badminton' && state.scoringState is BadmintonState)
            _buildBadmintonScore(context, state.scoringState as BadmintonState, isDark)
          else if (sport == 'football' && state.scoringState is FootballState)
            _buildFootballScore(context, state.scoringState as FootballState, isDark)
          else
            _buildFallbackScore(isDark),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final status = state.status.toUpperCase();
    Color bg;
    Color fg;

    switch (state.status) {
      case 'live':
        bg = AppColors.error.withAlpha(30);
        fg = AppColors.error;
        break;
      case 'completed':
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        break;
      case 'paused':
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        break;
      default:
        bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.status == 'live') ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            status,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCricketScore(BuildContext context, CricketState cricket, bool isDark) {
    final currentInnings = cricket.activeInnings;
    if (currentInnings == null) return _buildFallbackScore(isDark);

    final battingTeam = currentInnings.battingTeamId == state.homeId
        ? state.homeName
        : state.awayName;

    final striker = currentInnings.battingStats[currentInnings.strikerId];
    final nonStriker = currentInnings.battingStats[currentInnings.nonStrikerId];
    final bowler = currentInnings.bowlingStats[currentInnings.currentBowlerId];

    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Innings & Score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$battingTeam (Inn ${cricket.currentInningsIndex + 1})',
                  style: AppTypography.caption.copyWith(color: secondaryText),
                ),
                Text(
                  '${currentInnings.totalRuns}/${currentInnings.totalWickets}',
                  style: AppTypography.scoreDisplay.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${currentInnings.overs.toStringAsFixed(1)} ov',
                  style: AppTypography.headline.copyWith(color: secondaryText),
                ),
                Text(
                  'CRR: ${currentInnings.runRate.toStringAsFixed(2)}',
                  style: AppTypography.caption.copyWith(color: secondaryText),
                ),
              ],
            ),
          ],
        ),

        // Target / Chase details
        if (cricket.target != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              cricket.resultMarginText != null
                  ? cricket.resultMarginText!
                  : 'Target: ${cricket.target}',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],

        const Divider(height: AppSpacing.xl),

        // Active Batters
        Row(
          children: [
            Expanded(
              child: Text(
                '🏏 ${currentInnings.strikerId ?? "Striker"}* '
                '${striker != null ? "${striker.runs} (${striker.ballsFaced})" : ""}',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${currentInnings.nonStrikerId ?? "Non-Striker"} '
                '${nonStriker != null ? "${nonStriker.runs} (${nonStriker.ballsFaced})" : ""}',
                style: AppTypography.body.copyWith(color: secondaryText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Active Bowler
        Text(
          '⚾ ${currentInnings.currentBowlerId ?? "Bowler"}: '
          '${bowler != null ? "${bowler.wickets}/${bowler.runsConceded} (${bowler.oversDecimal.toStringAsFixed(1)} ov)" : "Not selected"}',
          style: AppTypography.caption.copyWith(color: secondaryText),
        ),

        // Free Hit Banner
        if (currentInnings.isFreeHit) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              'FREE HIT NEXT BALL (Run out only)',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        // This Over Ball Chips
        if (currentInnings.thisOverChips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: currentInnings.thisOverChips.map((b) {
              final isWicket = b.contains('W');
              final isBoundary = b == '4' || b == '6';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isWicket
                      ? AppColors.error
                      : isBoundary
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  b,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (isWicket || isBoundary)
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBadmintonScore(BuildContext context, BadmintonState badminton, bool isDark) {
    final currentGame = badminton.currentGame;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final servingScore = badminton.servingTeamId == state.homeId
        ? currentGame.homePoints
        : currentGame.awayPoints;
    final courtSide = servingScore % 2 == 0 ? 'Right' : 'Left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Big Game Points Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(state.homeName, style: AppTypography.body.copyWith(color: secondaryText)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${currentGame.homePoints}',
                  style: AppTypography.scoreDisplay.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Games: ${badminton.homeGamesWon}',
                  style: AppTypography.caption.copyWith(color: secondaryText),
                ),
              ],
            ),
            Text(
              'G${badminton.currentGameIndex + 1}',
              style: AppTypography.headline.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            Column(
              children: [
                Text(state.awayName, style: AppTypography.body.copyWith(color: secondaryText)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${currentGame.awayPoints}',
                  style: AppTypography.scoreDisplay.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Games: ${badminton.awayGamesWon}',
                  style: AppTypography.caption.copyWith(color: secondaryText),
                ),
              ],
            ),
          ],
        ),

        // Game History Breakdown
        if (badminton.games.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Games: ${badminton.games.map((g) => "${g.homePoints}-${g.awayPoints}").join(", ")}',
            style: AppTypography.caption.copyWith(color: secondaryText),
            textAlign: TextAlign.center,
          ),
        ],

        const Divider(height: AppSpacing.lg),

        // Serving Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis_rounded, size: AppSpacing.iconInline),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Server: ${badminton.currentServerId == state.homeId ? state.homeName : state.awayName} '
              '($courtSide court)',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),

        // Interval Prompt Banner
        if (badminton.intervalPrompt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              '🔔 ${badminton.intervalPrompt!}',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFootballScore(BuildContext context, FootballState football, bool isDark) {
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Goals Score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    state.homeName,
                    style: AppTypography.body.copyWith(color: secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${football.homeScore}',
                    style: AppTypography.scoreDisplay.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  _formatFootballPeriod(football.currentPeriod),
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-',
                  style: AppTypography.title.copyWith(color: secondaryText),
                ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    state.awayName,
                    style: AppTypography.body.copyWith(color: secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${football.awayScore}',
                    style: AppTypography.scoreDisplay.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Shootout Breakdown if active
        if (football.shootoutKicks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              'Pens: ${football.shootoutHomeScore} - ${football.shootoutAwayScore}'
              '${football.shootoutCompleted ? " (Finished)" : ""}',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Recent Goals Timeline
        if (football.goals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            children: football.goals.map((g) {
              return Text(
                '⚽ ${g.scorerId} ${g.minute}\'${g.isOwnGoal ? " (OG)" : ""}',
                style: AppTypography.caption.copyWith(color: secondaryText),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackScore(bool isDark) {
    return Center(
      child: Text(
        'Match Setup Pending',
        style: AppTypography.body.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  String _formatFootballPeriod(String period) {
    switch (period) {
      case 'first_half':
        return '1st Half';
      case 'half_time':
        return 'Half Time';
      case 'second_half':
        return '2nd Half';
      case 'full_time':
        return 'Full Time';
      case 'extra_time_1':
        return 'ET 1st';
      case 'extra_time_2':
        return 'ET 2nd';
      case 'shootout':
        return 'Penalties';
      default:
        return 'Scheduled';
    }
  }
}
