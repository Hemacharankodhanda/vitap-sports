/// VIT-AP Sports — Match Analysis Screen.
/// Displays player stats for a completed match.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/match_providers.dart';
import '../widgets/professional_scorecard.dart';

class MatchAnalysisScreen extends ConsumerWidget {
  const MatchAnalysisScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(matchAnalysisProvider(matchId));
    final matchAsync = ref.watch(matchDetailProvider(matchId));
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
          onRetry: () => ref.invalidate(matchDetailProvider(matchId)),
        ),
        data: (match) {
          if (match == null) return const ErrorView(message: 'Match not found');

          return analysisAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(matchAnalysisProvider(matchId)),
            ),
            data: (statsData) {
              if (match.score != null) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  children: [
                    ProfessionalScorecard(match: match),
                  ],
                );
              }

              if (statsData.isEmpty) {
                return const Center(child: Text('No stats available for this match.'));
              }

              // Group by team_id
              final Map<String, List<Map<String, dynamic>>> byTeam = {};
              final Map<String, String> teamNames = {};

              // Populate team names from match participants
              for (final p in match.participants) {
                if (p.teamId != null) {
                  teamNames[p.teamId!] = p.teamName ?? 'Team';
                }
              }

              for (final row in statsData) {
                final teamId = row['team_id'] as String?;
                final key = teamId ?? 'unassigned';
                if (!byTeam.containsKey(key)) byTeam[key] = [];
                byTeam[key]!.add(row);
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                children: [
                  for (final entry in byTeam.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
                      child: Text(
                        teamNames[entry.key] ?? 'Unassigned Players',
                        style: AppTypography.headline,
                      ),
                    ),
                    for (final playerStats in entry.value)
                      _PlayerStatCard(
                        data: playerStats,
                        sport: match.sportName ?? 'SPORT',
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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

    String val(String key) => (counters[key] ?? 0).toString();

    // Map the stats beautifully based on the sport
    final sportLower = sport.toLowerCase();
    List<Widget> statWidgets = [];

    if (sportLower == 'cricket') {
      statWidgets = [
        _buildStat('Runs', val('runs_scored'), isDark),
        _buildStat('Balls', val('balls_faced'), isDark),
        _buildStat('4s/6s', '${val('fours')}/${val('sixes')}', isDark),
        _buildStat('Wickets', val('wickets_taken'), isDark),
        _buildStat('Econ', val('runs_conceded'), isDark, label2: 'given'),
      ];
    } else if (sportLower == 'football') {
      statWidgets = [
        _buildStat('Goals', val('goals'), isDark),
        _buildStat('Assists', val('assists'), isDark),
        _buildStat('Own Goals', val('own_goals'), isDark),
        _buildStat('Cards', '${val('yellow_cards')}Y ${val('red_cards')}R', isDark),
      ];
    } else if (sportLower == 'badminton') {
      statWidgets = [
        _buildStat('Points', val('points_won'), isDark),
        _buildStat('Serve Pts', val('service_points_won'), isDark),
      ];
    } else {
      counters.forEach((key, value) {
        if (!key.startsWith('matches_') && key != 'mvps') {
          statWidgets.add(_buildStat(key, value.toString(), isDark));
        }
      });
    }

    final isMvp = (counters['mvps'] as num?)?.toInt() == 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MVP',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (statWidgets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: statWidgets,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDark, {String? label2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label2 != null ? '$label $label2' : label,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
