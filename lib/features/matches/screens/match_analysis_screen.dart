/// VIT-AP Sports — Match Analysis Screen.
/// Displays comprehensive individual player performance stats (Runs, Balls, SR, 4s, 6s,
/// Wickets, Overs, Economy, Maidens) and complete match scorecards.
library;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/match_providers.dart';
import '../widgets/professional_scorecard.dart';

class MatchAnalysisScreen extends ConsumerStatefulWidget {
  const MatchAnalysisScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends ConsumerState<MatchAnalysisScreen> {
  int _selectedTabIndex = 0; // 0 = Player Stats, 1 = Scorecard

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(matchAnalysisProvider(widget.matchId));
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Match Analysis'),
      ),
      body: matchAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(matchDetailProvider(widget.matchId)),
        ),
        data: (match) {
          if (match == null) return const ErrorView(message: 'Match not found');

          return analysisAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(matchAnalysisProvider(widget.matchId)),
            ),
            data: (statsData) {
              // 1. Resolve player stats (from player_match_stats DB table or match.score JSON)
              List<Map<String, dynamic>> resolvedPlayerStats = List.from(statsData);

              if (resolvedPlayerStats.isEmpty && match.score != null) {
                final scoreMap = match.score!;
                final pStatsRaw = scoreMap['player_stats'];
                if (pStatsRaw is Map) {
                  for (final entry in pStatsRaw.entries) {
                    final pId = entry.key.toString();
                    final counters = entry.value is Map
                        ? Map<String, dynamic>.from(entry.value as Map)
                        : <String, dynamic>{};
                    final participant = match.participants
                        .firstWhereOrNull((p) => p.userId == pId || p.userName == pId);

                    resolvedPlayerStats.add({
                      'player_id': pId,
                      'team_id': participant?.teamId,
                      'users': {
                        'name': participant?.userName ?? pId,
                        'avatar_url': participant?.userAvatar,
                      },
                      'counters': counters,
                    });
                  }
                }
              }

              // Group by team_id
              final Map<String, List<Map<String, dynamic>>> byTeam = {};
              final Map<String, String> teamNames = {};

              for (final p in match.participants) {
                if (p.teamId != null) {
                  teamNames[p.teamId!] = p.teamName ?? 'Team';
                }
              }
              if (match.homeTeamId != null) teamNames[match.homeTeamId!] = match.homeTeamName ?? 'Home Team';
              if (match.awayTeamId != null) teamNames[match.awayTeamId!] = match.awayTeamName ?? 'Away Team';

              for (final row in resolvedPlayerStats) {
                final teamId = row['team_id'] as String?;
                final key = teamId ?? 'unassigned';
                if (!byTeam.containsKey(key)) byTeam[key] = [];
                byTeam[key]!.add(row);
              }

              return Column(
                children: [
                  // Tab selector: Player Stats vs Full Scorecard
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        AppChip(
                          label: 'Player Performance',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label: 'Full Scorecard',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _selectedTabIndex == 0
                        ? (resolvedPlayerStats.isEmpty
                            ? const Center(
                                child: Text('No player stats available for this match.'),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                                children: [
                                  for (final entry in byTeam.entries) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                        top: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        teamNames[entry.key] ?? 'Players',
                                        style: AppTypography.title.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    for (final playerStats in entry.value)
                                      _PlayerStatCard(
                                        data: playerStats,
                                        sport: match.sportName ?? 'Cricket',
                                      ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ))
                        : ListView(
                            padding: const EdgeInsets.all(AppSpacing.screenMargin),
                            children: [
                              ProfessionalScorecard(match: match),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PlayerStatCard extends StatelessWidget {
  const _PlayerStatCard({required this.data, required this.sport});
  final Map<String, dynamic> data;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final users = data['users'] as Map<String, dynamic>?;
    final name = users?['name'] as String? ?? 'Unknown Player';
    final avatar = users?['avatar_url'] as String?;
    final counters = data['counters'] as Map<String, dynamic>? ?? {};

    final sportLower = sport.toLowerCase();
    final isMvp = (counters['mvps'] as num?)?.toInt() == 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Player Name & MVP ─────────────────────────
          Row(
            children: [
              AppAvatar(
                imageUrl: avatar,
                name: name,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (isMvp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'MVP',
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

          // ─── Stats by Sport ────────────────────────────
          if (sportLower.contains('cricket'))
            _buildCricketPlayerStats(context, counters, isDark)
          else if (sportLower.contains('football'))
            _buildFootballPlayerStats(context, counters, isDark)
          else if (sportLower.contains('badminton'))
            _buildBadmintonPlayerStats(context, counters, isDark)
          else
            _buildGenericStats(context, counters, isDark),
        ],
      ),
    );
  }

  Widget _buildCricketPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    bool isDark,
  ) {
    final runs = (counters['runs_scored'] as num?)?.toInt() ?? 0;
    final balls = (counters['balls_faced'] as num?)?.toInt() ?? 0;
    final fours = (counters['fours'] as num?)?.toInt() ?? 0;
    final sixes = (counters['sixes'] as num?)?.toInt() ?? 0;
    final sr = balls > 0 ? ((runs / balls) * 100).toStringAsFixed(1) : '0.0';

    final wickets = (counters['wickets_taken'] as num?)?.toInt() ?? 0;
    final ballsBowled = (counters['balls_bowled'] as num?)?.toInt() ?? 0;
    final oversBowled = '${ballsBowled ~/ 6}.${ballsBowled % 6}';
    final runsConceded = (counters['runs_conceded'] as num?)?.toInt() ?? 0;
    final econ = ballsBowled > 0 ? (runsConceded / (ballsBowled / 6.0)).toStringAsFixed(2) : '0.00';
    final maidens = (counters['maidens'] as num?)?.toInt() ?? 0;

    final catches = (counters['catches'] as num?)?.toInt() ?? 0;
    final runOuts = (counters['run_outs'] as num?)?.toInt() ?? 0;
    final stumpings = (counters['stumpings'] as num?)?.toInt() ?? 0;

    final hasBat = balls > 0 || runs > 0;
    final hasBowl = ballsBowled > 0;
    final hasField = catches > 0 || runOuts > 0 || stumpings > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBat) ...[
          Text('Batting', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _metricChip('Runs', runs.toString(), isDark, highlight: true),
              _metricChip('Balls', balls.toString(), isDark),
              _metricChip('SR', sr, isDark, color: Colors.teal),
              _metricChip('4s', fours.toString(), isDark),
              _metricChip('6s', sixes.toString(), isDark, color: Colors.deepPurpleAccent),
            ],
          ),
        ],
        if (hasBowl) ...[
          if (hasBat) const SizedBox(height: AppSpacing.sm),
          Text('Bowling', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _metricChip('Wkts', wickets.toString(), isDark, color: Colors.deepOrange, highlight: true),
              _metricChip('Overs', oversBowled, isDark),
              _metricChip('Runs', runsConceded.toString(), isDark),
              _metricChip('Econ', econ, isDark, color: Colors.teal),
              if (maidens > 0) _metricChip('Maidens', maidens.toString(), isDark),
            ],
          ),
        ],
        if (hasField) ...[
          if (hasBat || hasBowl) const SizedBox(height: AppSpacing.sm),
          Text('Fielding', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (catches > 0) _metricChip('Catches', catches.toString(), isDark),
              if (stumpings > 0) _metricChip('Stumpings', stumpings.toString(), isDark),
              if (runOuts > 0) _metricChip('Run Outs', runOuts.toString(), isDark),
            ],
          ),
        ],
        if (!hasBat && !hasBowl && !hasField)
          Text('Did not bat or bowl', style: AppTypography.caption),
      ],
    );
  }

  Widget _buildFootballPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    bool isDark,
  ) {
    final goals = (counters['goals'] as num?)?.toInt() ?? 0;
    final assists = (counters['assists'] as num?)?.toInt() ?? 0;
    final saves = (counters['saves'] as num?)?.toInt() ?? 0;
    final yellow = (counters['yellow_cards'] as num?)?.toInt() ?? 0;
    final red = (counters['red_cards'] as num?)?.toInt() ?? 0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _metricChip('Goals', goals.toString(), isDark, highlight: true),
        _metricChip('Assists', assists.toString(), isDark),
        if (saves > 0) _metricChip('Saves', saves.toString(), isDark),
        if (yellow > 0) _metricChip('Yellow', yellow.toString(), isDark, color: Colors.amber),
        if (red > 0) _metricChip('Red', red.toString(), isDark, color: Colors.redAccent),
      ],
    );
  }

  Widget _buildBadmintonPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    bool isDark,
  ) {
    final points = (counters['points_won'] as num?)?.toInt() ?? 0;
    final servePts = (counters['service_points_won'] as num?)?.toInt() ?? 0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _metricChip('Points', points.toString(), isDark, highlight: true),
        _metricChip('Serve Pts', servePts.toString(), isDark),
      ],
    );
  }

  Widget _buildGenericStats(
    BuildContext context,
    Map<String, dynamic> counters,
    bool isDark,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: counters.entries
          .where((e) => !e.key.startsWith('matches_') && e.key != 'mvps')
          .map((e) => _metricChip(e.key.replaceAll('_', ' '), e.value.toString(), isDark))
          .toList(),
    );
  }

  Widget _metricChip(String label, String value, bool isDark, {Color? color, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
