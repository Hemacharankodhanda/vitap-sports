/// VIT-AP Sports — Scorecard edit screen (scorer-only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../matches/data/models/match_model.dart';
import '../../matches/providers/match_providers.dart';
import '../data/models/cricket_scorecard_model.dart';
import '../providers/scorecard_providers.dart';
import 'cricket_scoring_dashboard.dart';

class ScorecardEditScreen extends ConsumerStatefulWidget {
  const ScorecardEditScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<ScorecardEditScreen> createState() =>
      _ScorecardEditScreenState();
}

class _ScorecardEditScreenState extends ConsumerState<ScorecardEditScreen> {
  int _homeScore = 0;
  int _awayScore = 0;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final scorecardAsync = ref.watch(scorecardDataProvider(widget.matchId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Edit Scorecard')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found'));
          
          return scorecardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading scorecard: $err')),
            data: (scorecardData) {
              
              if (match.sportName == 'Cricket') {
                final state = scorecardData != null 
                    ? CricketScorecardState.fromJson(scorecardData)
                    : null;
                return CricketScoringDashboard(
                  match: match,
                  initialState: state,
                );
              }
              
              // Fallback to basic scoring for other sports
              return _buildBasicScoring(match);
            },
          );
        },
      ),
    );
  }

  Widget _buildBasicScoring(MatchModel match) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.lg,
      ),
      children: [
        AppCard(
          child: Column(
            children: [
              Text('Update Score', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Home', style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_homeScore > 0) {
                                  setState(() => _homeScore--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                            ),
                            Text(
                              '$_homeScore',
                              style: AppTypography.scoreMedium,
                            ),
                            IconButton(
                              onPressed: () => setState(() => _homeScore++),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-',
                    style: AppTypography.title.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Away', style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_awayScore > 0) {
                                  setState(() => _awayScore--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                            ),
                            Text(
                              '$_awayScore',
                              style: AppTypography.scoreMedium,
                            ),
                            IconButton(
                              onPressed: () => setState(() => _awayScore++),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Update Score',
          onPressed: () {
            // TODO: Write to Supabase matches table
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Score updated!')),
            );
          },
        ),
      ],
    );
  }
}
