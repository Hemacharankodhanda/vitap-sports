/// VIT-AP Sports — Scorecard view screen (read-only, live updates).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_score.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../matches/data/models/match_model.dart';
import '../../matches/providers/match_providers.dart';
import '../data/models/cricket_scorecard_model.dart';
import '../providers/scorecard_providers.dart';

class ScorecardViewScreen extends ConsumerWidget {
  const ScorecardViewScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final scorecardAsync = ref.watch(scorecardDataProvider(matchId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Scorecard'),
        actions: [
          // Edit button — only visible to scorer
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/matches/$matchId/scorecard/edit'),
            tooltip: 'Edit Scorecard',
          ),
        ],
      ),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found'));
          
          return scorecardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (scorecardData) {
              if (match.sportName == 'Cricket') {
                return _buildCricketScorecard(context, isDark, match, scorecardData);
              }
              
              // Fallback for other sports
              return _buildBasicScorecard(isDark, match);
            },
          );
        },
      ),
    );
  }

  Widget _buildCricketScorecard(
      BuildContext context, bool isDark, MatchModel match, Map<String, dynamic>? data) {
    if (data == null) {
      return const EmptyState(
        icon: Icons.sports_cricket_outlined,
        title: 'Match hasn\'t started',
        subtitle: 'The scorer hasn\'t recorded any events yet.',
      );
    }
    
    final state = CricketScorecardState.fromJson(data);
    final active = state.activeInnings;

    if (active == null) {
      return const EmptyState(
        icon: Icons.sports_cricket_outlined,
        title: 'Match hasn\'t started',
        subtitle: 'The scorer hasn\'t started the 1st innings yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.lg,
      ),
      children: [
        const Center(child: StatusBadge(status: MatchStatus.live)),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            children: [
              Text('Cricket Scorecard', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${active.totalRuns}/${active.totalWickets}',
                style: AppTypography.headline.copyWith(fontSize: 36),
              ),
              Text(
                'Overs: ${active.totalOvers} ${active.totalOvers > 0 ? '' : '(${active.currentOver.length} balls)'}',
                style: AppTypography.title,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppCard(
          child: Center(child: Text('Detailed Batting & Bowling Stats\n(Work in Progress)')),
        ),
      ],
    );
  }

  Widget _buildBasicScorecard(bool isDark, MatchModel match) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.lg,
      ),
      children: [
        const Center(child: StatusBadge(status: MatchStatus.live)),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match.participants.isNotEmpty
                          ? match.participants.firstWhere((p) => p.side == 'home').teamName ?? 'Home'
                          : 'TBD',
                      style: AppTypography.headline,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedScore(value: match.homeScore ?? 0),
                  ],
                ),
              ),
              Text(
                '-',
                style: AppTypography.scoreDisplay.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match.participants.isNotEmpty
                          ? match.participants.firstWhere((p) => p.side == 'away').teamName ?? 'Away'
                          : 'TBD',
                      style: AppTypography.headline,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedScore(value: match.awayScore ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const EmptyState(
          icon: Icons.scoreboard_outlined,
          title: 'Scorecard is simple',
          subtitle: 'No detailed stats available for this sport.',
        ),
      ],
    );
  }
}
