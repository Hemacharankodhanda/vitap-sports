/// VIT-AP Sports — Match Analysis Screen.
/// Displays comprehensive individual player performance stats (Runs, Balls, SR, 4s, 6s,
/// Wickets, Overs, Economy, Maidens) and complete match scorecards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/frosted_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../scoring/domain/match_event.dart';
import '../../scoring/domain/sport_registry.dart';
import '../../scoring/providers/live_scorer_providers.dart';
import '../data/models/match_model.dart';
import '../providers/match_providers.dart';
import '../widgets/professional_scorecard.dart';

class MatchAnalysisScreen extends ConsumerStatefulWidget {
  const MatchAnalysisScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends ConsumerState<MatchAnalysisScreen> {
  int _selectedTabIndex = 0; // 0 = Scorecard, 1 = Player Performance

  @override
  Widget build(BuildContext context) {
    final initialMatchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final liveStreamAsync = ref.watch(liveMatchStreamProvider(widget.matchId));
    final eventsAsync = ref.watch(liveEventsNotifierProvider(widget.matchId));
    final analysisAsync = ref.watch(matchAnalysisProvider(widget.matchId));
    final horizontalPadding = AppBreakpoints.screenPadding(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: FrostedAppBar(
        title: Text(
          'Scorecard',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: AppSpacing.iconNav, color: context.colors.textPrimary),
            onPressed: () {
              ref.invalidate(matchDetailProvider(widget.matchId));
              ref.invalidate(matchAnalysisProvider(widget.matchId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: initialMatchAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () {
            ref.invalidate(matchDetailProvider(widget.matchId));
            ref.invalidate(matchAnalysisProvider(widget.matchId));
          },
        ),
        data: (initialMatch) {
          if (initialMatch == null) return const ErrorView(message: 'Match not found');

          final match = initialMatch.updateFromRealtime(liveStreamAsync.valueOrNull);
          final statsData = analysisAsync.valueOrNull ?? const <Map<String, dynamic>>[];
          final playerNames = ref.watch(matchPlayerNamesProvider(widget.matchId)).valueOrNull ?? const <String, String>{};

          // Compute pure engine derived state if available for live reactive scorecard
          final sport = (match.sportName ?? 'cricket').toLowerCase().trim();
          final config = match.config ?? {};
          final engine = SportRegistry.getEngine(sport);
          final scoreSnapshot = match.score;

          dynamic derivedState;
          if (scoreSnapshot != null && engine != null) {
            try {
              derivedState = engine.fromSnapshot(
                Map<String, dynamic>.from(scoreSnapshot),
                SportRegistry.parseConfig(sport, config),
              );
            } catch (e) {
              debugPrint('Error parsing score snapshot: $e');
            }
          }

          if (derivedState == null && engine != null) {
            final events = eventsAsync.valueOrNull ?? const <MatchEvent>[];
            if (events.isNotEmpty) {
              String homeId = match.homeTeamId ?? 'home';
              String awayId = match.awayTeamId ?? 'away';
              try {
                derivedState = SportRegistry.fold(
                  sportName: sport,
                  configJson: config,
                  events: events,
                  homeId: homeId,
                  awayId: awayId,
                );
              } catch (_) {}
            }
          }

          String resolveDisplayName(String pId, MatchParticipant? participant) {
            if (participant?.userName != null && participant!.userName!.isNotEmpty) {
              return participant.userName!;
            }
            if (playerNames.containsKey(pId) && playerNames[pId]!.isNotEmpty) {
              return playerNames[pId]!;
            }
            if (match.score != null) {
              final pNames = match.score!['player_names'];
              if (pNames is Map && pNames[pId] != null && pNames[pId].toString().isNotEmpty) {
                return pNames[pId].toString();
              }
              final pStats = match.score!['player_stats'];
              if (pStats is Map && pStats[pId] is Map && pStats[pId]['name'] != null) {
                final n = pStats[pId]['name'].toString();
                if (n.isNotEmpty) return n;
              }
            }
            if (pId.startsWith('home_p_')) {
              final t = match.homeTeamName ?? 'Team 1';
              return '$t Player ${pId.replaceFirst('home_p_', '')}';
            }
            if (pId.startsWith('away_p_')) {
              final t = match.awayTeamName ?? 'Team 2';
              return '$t Player ${pId.replaceFirst('away_p_', '')}';
            }
            if (pId.length == 36 && pId.contains('-')) {
              return 'Player';
            }
            return pId;
          }

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
                MatchParticipant? participant;
                for (final p in match.participants) {
                  if (p.userId == pId || p.userName == pId) {
                    participant = p;
                    break;
                  }
                }

                resolvedPlayerStats.add({
                  'player_id': pId,
                  'team_id': participant?.teamId,
                  'users': {
                    'name': resolveDisplayName(pId, participant),
                    'avatar_url': participant?.userAvatar,
                  },
                  'counters': counters,
                });
              }
            }
          }

          // Ensure any rows from DB missing user names are resolved
          for (final row in resolvedPlayerStats) {
            final pId = row['player_id']?.toString() ?? '';
            final usersMap = row['users'] as Map<String, dynamic>?;
            final curName = usersMap?['name'] as String?;
            if (curName == null || curName.isEmpty || (curName.length == 36 && curName.contains('-'))) {
              row['users'] = {
                'name': resolveDisplayName(pId, null),
                'avatar_url': usersMap?['avatar_url'],
              };
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
          if (match.homeTeamId != null) teamNames[match.homeTeamId!] = match.homeTeamName ?? 'Team 1';
          if (match.awayTeamId != null) teamNames[match.awayTeamId!] = match.awayTeamName ?? 'Team 2';

          for (final row in resolvedPlayerStats) {
            final teamId = row['team_id'] as String?;
            final key = teamId ?? 'unassigned';
            if (!byTeam.containsKey(key)) byTeam[key] = [];
            byTeam[key]!.add(row);
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReadingWidth),
              child: Column(
                children: [
                  // Tab selector: Scorecard vs Player Performance (AppSegmented)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: AppSegmented<int>(
                      options: const [0, 1],
                      selected: _selectedTabIndex,
                      onSelected: (val) => setState(() => _selectedTabIndex = val),
                      labelBuilder: (idx) => idx == 0 ? 'Scorecard' : 'Player Performance',
                    ),
                  ),

                  Expanded(
                    child: _selectedTabIndex == 0
                        ? ListView(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: AppSpacing.sm,
                            ),
                            children: [
                              ProfessionalScorecard(
                                match: match,
                                scoringState: derivedState,
                                playerNames: playerNames,
                              ),
                            ],
                          )
                        : (resolvedPlayerStats.isEmpty
                            ? const EmptyState(
                                icon: Icons.sports_score_rounded,
                                title: 'No Player Stats',
                                subtitle: 'Individual performance records will appear once scoring begins.',
                              )
                            : ListView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: AppSpacing.sm,
                                ),
                                children: [
                                  for (final entry in byTeam.entries) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                        top: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        teamNames[entry.key] ?? 'Players',
                                        style: AppTypography.headline.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: context.colors.textPrimary,
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
                              )),
                  ),
                ],
              ),
            ),
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
    final colors = context.colors;
    final users = data['users'] as Map<String, dynamic>?;
    final name = users?['name'] as String? ?? 'Unknown Player';
    final avatar = users?['avatar_url'] as String?;
    final counters = data['counters'] as Map<String, dynamic>? ?? {};

    final sportLower = sport.toLowerCase();
    final isMvp = (counters['mvps'] as num?)?.toInt() == 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isMvp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.warningContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 14, color: colors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'MVP',
                        style: AppTypography.caption.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w700,
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
            _buildCricketPlayerStats(context, counters, colors)
          else if (sportLower.contains('football'))
            _buildFootballPlayerStats(context, counters, colors)
          else if (sportLower.contains('badminton'))
            _buildBadmintonPlayerStats(context, counters, colors)
          else
            _buildGenericStats(context, counters, colors),
        ],
      ),
    );
  }

  Widget _buildCricketPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    AppColorsExtension colors,
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
          Text(
            'Batting',
            style: AppTypography.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _metricChip('Runs', runs.toString(), colors, highlight: true),
              _metricChip('Balls', balls.toString(), colors),
              _metricChip('SR', sr, colors),
              _metricChip('4s', fours.toString(), colors),
              _metricChip('6s', sixes.toString(), colors),
            ],
          ),
        ],
        if (hasBowl) ...[
          if (hasBat) const SizedBox(height: AppSpacing.sm),
          Text(
            'Bowling',
            style: AppTypography.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _metricChip('Wkts', wickets.toString(), colors, color: colors.loss, highlight: true),
              _metricChip('Overs', oversBowled, colors),
              _metricChip('Runs', runsConceded.toString(), colors),
              _metricChip('Econ', econ, colors),
              if (maidens > 0) _metricChip('Maidens', maidens.toString(), colors),
            ],
          ),
        ],
        if (hasField) ...[
          if (hasBat || hasBowl) const SizedBox(height: AppSpacing.sm),
          Text(
            'Fielding',
            style: AppTypography.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (catches > 0) _metricChip('Catches', catches.toString(), colors),
              if (stumpings > 0) _metricChip('Stumpings', stumpings.toString(), colors),
              if (runOuts > 0) _metricChip('Run Outs', runOuts.toString(), colors),
            ],
          ),
        ],
        if (!hasBat && !hasBowl && !hasField)
          Text('Did not bat or bowl', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
      ],
    );
  }

  Widget _buildFootballPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    AppColorsExtension colors,
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
        _metricChip('Goals', goals.toString(), colors, highlight: true),
        _metricChip('Assists', assists.toString(), colors),
        if (saves > 0) _metricChip('Saves', saves.toString(), colors),
        if (yellow > 0) _metricChip('Yellow', yellow.toString(), colors, color: colors.warning),
        if (red > 0) _metricChip('Red', red.toString(), colors, color: colors.loss),
      ],
    );
  }

  Widget _buildBadmintonPlayerStats(
    BuildContext context,
    Map<String, dynamic> counters,
    AppColorsExtension colors,
  ) {
    final points = (counters['points_won'] as num?)?.toInt() ?? 0;
    final servePts = (counters['service_points_won'] as num?)?.toInt() ?? 0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _metricChip('Points', points.toString(), colors, highlight: true),
        _metricChip('Serve Pts', servePts.toString(), colors),
      ],
    );
  }

  Widget _buildGenericStats(
    BuildContext context,
    Map<String, dynamic> counters,
    AppColorsExtension colors,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: counters.entries
          .where((e) => !e.key.startsWith('matches_') && e.key != 'mvps')
          .map((e) => _metricChip(e.key.replaceAll('_', ' '), e.value.toString(), colors))
          .toList(),
    );
  }

  Widget _metricChip(String label, String value, AppColorsExtension colors, {Color? color, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colors.fillSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCardInner),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (highlight ? colors.win : colors.textPrimary),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
