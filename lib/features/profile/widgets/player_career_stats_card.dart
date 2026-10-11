/// VIT-AP Sports — Comprehensive Player Career Stats Card.
/// Displays detailed real-world statistics for Cricket, Football, and Badminton.
/// Designed according to Apple HIG 8pt grid with rich contrast and scannability.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class PlayerCareerStatsCard extends StatelessWidget {
  const PlayerCareerStatsCard({
    super.key,
    required this.sportRow,
  });

  final Map<String, dynamic> sportRow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportRaw = ((sportRow['sport'] as String?) ?? 'cricket').toLowerCase();
    final sportDisplayName = (sportRow['sport_display_name'] as String?) ??
        (sportRaw.isNotEmpty ? '${sportRaw[0].toUpperCase()}${sportRaw.substring(1)}' : 'Cricket');
    
    final matchesPlayed = (sportRow['matches_played'] as num?)?.toInt() ?? 0;
    var rawCounters = sportRow['career_counters'];
    if (rawCounters is String) {
      try {
        rawCounters = jsonDecode(rawCounters);
      } catch (_) {}
    }
    final counters = (rawCounters as Map<String, dynamic>?) ?? {};

    final wins = (counters['matches_won'] as num?)?.toInt() ?? 0;
    final losses = (counters['matches_lost'] as num?)?.toInt() ?? 0;
    final mvps = (counters['mvps'] as num?)?.toInt() ?? 0;

    final winRate = matchesPlayed > 0 ? ((wins / matchesPlayed) * 100).toStringAsFixed(0) : '0';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Sport Name & Record ───────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _sportIcon(sportRaw),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sportDisplayName,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '$matchesPlayed Matches • $wins W - $losses L ($winRate% Win Rate)',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (mvps > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha(120), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$mvps MVP',
                        style: AppTypography.caption.copyWith(
                          color: Colors.amber[800] ?? Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Sport-Specific Detailed Stats ─────────────
          if (sportRaw.contains('cricket'))
            _buildCricketStats(context, counters, matchesPlayed, isDark)
          else if (sportRaw.contains('football'))
            _buildFootballStats(context, counters, matchesPlayed, isDark)
          else if (sportRaw.contains('badminton'))
            _buildBadmintonStats(context, counters, matchesPlayed, isDark)
          else
            _buildGenericStats(context, counters, isDark),
        ],
      ),
    );
  }

  IconData _sportIcon(String sport) {
    if (sport.contains('cricket')) return Icons.sports_cricket_rounded;
    if (sport.contains('football')) return Icons.sports_soccer_rounded;
    if (sport.contains('badminton')) return Icons.sports_tennis_rounded;
    return Icons.emoji_events_outlined;
  }

  Widget _buildCricketStats(
    BuildContext context,
    Map<String, dynamic> counters,
    int matches,
    bool isDark,
  ) {
    // Batting counters
    final runs = (counters['runs_scored'] as num?)?.toInt() ?? 0;
    final ballsFaced = (counters['balls_faced'] as num?)?.toInt() ?? 0;
    final fours = (counters['fours'] as num?)?.toInt() ?? 0;
    final sixes = (counters['sixes'] as num?)?.toInt() ?? 0;
    final outs = (counters['outs'] as num?)?.toInt() ?? 0;
    final strikeRate = ballsFaced > 0 ? ((runs / ballsFaced) * 100).toStringAsFixed(1) : '0.0';
    final battingAvg = outs > 0 ? (runs / outs).toStringAsFixed(1) : (runs > 0 ? '$runs*' : '-');
    final notOuts = matches > outs ? (matches - outs) : 0;
    final ducks = (counters['ducks'] as num?)?.toInt() ?? 0;
    final goldenDucks = (counters['golden_ducks'] as num?)?.toInt() ?? 0;
    final totalDucks = ducks + goldenDucks;

    // Bowling counters
    final wickets = (counters['wickets_taken'] as num?)?.toInt() ?? 0;
    final ballsBowled = (counters['balls_bowled'] as num?)?.toInt() ?? 0;
    final oversBowled = '${ballsBowled ~/ 6}.${ballsBowled % 6}';
    final runsConceded = (counters['runs_conceded'] as num?)?.toInt() ?? 0;
    final oversDecimal = ballsBowled / 6.0;
    final economy = oversDecimal > 0 ? (runsConceded / oversDecimal).toStringAsFixed(2) : '0.00';
    final maidens = (counters['maidens'] as num?)?.toInt() ?? 0;
    final bowlingAvg = wickets > 0 ? (runsConceded / wickets).toStringAsFixed(1) : '-';

    // Fielding counters
    final catches = (counters['catches'] as num?)?.toInt() ?? 0;
    final runOuts = (counters['run_outs'] as num?)?.toInt() ?? 0;
    final stumpings = (counters['stumpings'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Batting Section ─────────────────────────────
        _buildSectionTitle('BATTING RECORD', Icons.sports_cricket_outlined, isDark),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Highlight row: Runs, SR, 4s, 6s
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'RUNS',
                      value: runs.toString(),
                      isDark: isDark,
                      accentColor: Theme.of(context).colorScheme.primary,
                      isHero: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'STRIKE RATE',
                      value: strikeRate,
                      isDark: isDark,
                      accentColor: Colors.teal,
                      isHero: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'FOURS (4s)',
                      value: fours.toString(),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'SIXES (6s)',
                      value: sixes.toString(),
                      isDark: isDark,
                      accentColor: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Secondary row: Balls, Avg, Outs, Ducks
              Row(
                children: [
                  Expanded(child: _buildMetricTile(label: 'BALLS', value: ballsFaced.toString(), isDark: isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _buildMetricTile(label: 'AVG', value: battingAvg, isDark: isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _buildMetricTile(label: 'NOT OUTS', value: notOuts.toString(), isDark: isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'DUCKS',
                      value: totalDucks.toString(),
                      subtitle: goldenDucks > 0 ? '($goldenDucks gold)' : null,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Bowling Section ─────────────────────────────
        _buildSectionTitle('BOWLING RECORD', Icons.sports_baseball_outlined, isDark),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Highlight row: Wickets, Overs, Economy, Runs Conceded
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'WICKETS',
                      value: wickets.toString(),
                      isDark: isDark,
                      accentColor: Colors.deepOrange,
                      isHero: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'ECONOMY',
                      value: economy,
                      isDark: isDark,
                      accentColor: Colors.teal,
                      isHero: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'OVERS',
                      value: oversBowled,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'RUNS GIVEN',
                      value: runsConceded.toString(),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Secondary row: Maidens, Bowling Avg
              Row(
                children: [
                  Expanded(child: _buildMetricTile(label: 'MAIDENS', value: maidens.toString(), isDark: isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _buildMetricTile(label: 'BOWL AVG', value: bowlingAvg, isDark: isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'EXTRAS',
                      value: '${counters['wides_bowled'] ?? 0}w/${counters['no_balls_bowled'] ?? 0}nb',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'BALLS',
                      value: ballsBowled.toString(),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Fielding Section ─────────────────────────────
        _buildSectionTitle('FIELDING', Icons.pan_tool_outlined, isDark),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMetricTile(label: 'CATCHES', value: catches.toString(), isDark: isDark)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _buildMetricTile(label: 'STUMPINGS', value: stumpings.toString(), isDark: isDark)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _buildMetricTile(label: 'RUN OUTS', value: runOuts.toString(), isDark: isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFootballStats(
    BuildContext context,
    Map<String, dynamic> counters,
    int matches,
    bool isDark,
  ) {
    final goals = (counters['goals'] as num?)?.toInt() ?? 0;
    final assists = (counters['assists'] as num?)?.toInt() ?? 0;
    final saves = (counters['saves'] as num?)?.toInt() ?? 0;
    final cleanSheets = (counters['clean_sheets'] as num?)?.toInt() ?? 0;
    final yellowCards = (counters['yellow_cards'] as num?)?.toInt() ?? 0;
    final redCards = (counters['red_cards'] as num?)?.toInt() ?? 0;
    final goalContributions = goals + assists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('ATTACKING & PLAYMAKING', Icons.sports_soccer_outlined, isDark),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'GOALS',
                  value: goals.toString(),
                  isDark: isDark,
                  accentColor: Theme.of(context).colorScheme.primary,
                  isHero: true,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: 'ASSISTS',
                  value: assists.toString(),
                  isDark: isDark,
                  accentColor: Colors.teal,
                  isHero: true,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: 'G + A',
                  value: goalContributions.toString(),
                  isDark: isDark,
                  accentColor: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionTitle('DEFENSE & DISCIPLINE', Icons.shield_outlined, isDark),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMetricTile(label: 'SAVES', value: saves.toString(), isDark: isDark)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _buildMetricTile(label: 'CLEAN SHEETS', value: cleanSheets.toString(), isDark: isDark)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: 'YELLOW',
                  value: yellowCards.toString(),
                  isDark: isDark,
                  accentColor: Colors.amber,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: 'RED',
                  value: redCards.toString(),
                  isDark: isDark,
                  accentColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadmintonStats(
    BuildContext context,
    Map<String, dynamic> counters,
    int matches,
    bool isDark,
  ) {
    final points = (counters['points_won'] as num?)?.toInt() ?? 0;
    final servePts = (counters['service_points_won'] as num?)?.toInt() ?? 0;
    final gamesWon = (counters['games_won'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'POINTS WON',
              value: points.toString(),
              isDark: isDark,
              accentColor: Theme.of(context).colorScheme.primary,
              isHero: true,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildMetricTile(
              label: 'SERVE POINTS',
              value: servePts.toString(),
              isDark: isDark,
              accentColor: Colors.teal,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildMetricTile(
              label: 'GAMES WON',
              value: gamesWon.toString(),
              isDark: isDark,
              accentColor: Colors.deepPurpleAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericStats(
    BuildContext context,
    Map<String, dynamic> counters,
    bool isDark,
  ) {
    final entries = counters.entries
        .where((e) => !e.key.startsWith('matches_') && e.key != 'mvps')
        .toList();

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'No additional match stats recorded yet.',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: entries.map((e) {
        final label = e.key.replaceAll('_', ' ').toUpperCase();
        return SizedBox(
          width: 100,
          child: _buildMetricTile(
            label: label,
            value: e.value.toString(),
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
    Color? accentColor,
    String? subtitle,
    bool isHero = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isHero ? 18 : 15,
              color: accentColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? AppColors.darkTextSecondary.withAlpha(160) : AppColors.lightTextSecondary.withAlpha(160),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
