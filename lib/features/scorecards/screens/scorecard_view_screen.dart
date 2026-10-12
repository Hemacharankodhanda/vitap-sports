/// VIT-AP Sports — Realtime Scorecard View Screen.
///
/// Live spectator screen updated via Supabase Realtime streams.
/// Features animated score count-up, live chronological event timeline,
/// app resume re-fetch, and shimmer loading.
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
import '../../../core/widgets/loading_indicator.dart';
import '../../matches/providers/match_providers.dart';
import '../../matches/widgets/professional_scorecard.dart';
import '../../scoring/domain/match_event.dart';
import '../../scoring/domain/sport_registry.dart';
import '../../scoring/engines/badminton/badminton_state.dart';
import '../../scoring/engines/cricket/cricket_state.dart';
import '../../scoring/engines/football/football_state.dart';
import '../../scoring/providers/live_scorer_providers.dart';

class ScorecardViewScreen extends ConsumerStatefulWidget {
  const ScorecardViewScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  ConsumerState<ScorecardViewScreen> createState() => _ScorecardViewScreenState();
}

class _ScorecardViewScreenState extends ConsumerState<ScorecardViewScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Refetch and re-sync on app resume
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(liveEventsNotifierProvider(widget.matchId).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchDetailAsync = ref.watch(matchDetailProvider(widget.matchId));
    final matchStreamAsync = ref.watch(liveMatchStreamProvider(widget.matchId));
    final eventsAsync = ref.watch(liveEventsNotifierProvider(widget.matchId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          matchDetailAsync.valueOrNull?.status == 'completed'
              ? 'Match Scorecard'
              : 'Live Match Scorecard',
        ),
        actions: [
          if (matchDetailAsync.valueOrNull?.status != 'completed')
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: AppSpacing.iconNav),
              tooltip: 'Scorer Screen',
              onPressed: () => context.go('/matches/${widget.matchId}/scorecard/edit'),
            ),
        ],
      ),
      body: matchDetailAsync.when(
        loading: () => const Center(child: ShimmerList()),
        error: (err, _) => _buildErrorView(context, err.toString()),
        data: (matchDetail) {
          if (matchDetail == null) {
            return const EmptyState(
              icon: Icons.sports_score_outlined,
              title: 'Match Not Found',
              subtitle: 'The requested fixture does not exist.',
            );
          }

          final rawStreamMatch = matchStreamAsync.valueOrNull;
          final events = eventsAsync.valueOrNull ?? const <MatchEvent>[];
          final hasScore = (rawStreamMatch?['score'] != null) || (matchDetail.score != null);

          if (eventsAsync.isLoading && events.isEmpty && !hasScore) {
            return const Center(child: ShimmerList());
          }

          if (eventsAsync.hasError && events.isEmpty && !hasScore) {
            return _buildErrorView(context, eventsAsync.error.toString());
          }

          String homeName = matchDetail.homeTeamName ?? 'Team 1';
          String awayName = matchDetail.awayTeamName ?? 'Team 2';
          String homeId = 'home';
          String awayId = 'away';

          for (final p in matchDetail.participants) {
            final name = p.teamName ?? p.userName;
            final id = p.teamId ?? p.userId;
            if (p.side == 'home') {
              if (name != null) homeName = name;
              if (id != null) homeId = id;
            } else if (p.side == 'away') {
              if (name != null) awayName = name;
              if (id != null) awayId = id;
            }
          }

          final sport = (matchDetail.sportName ?? 'cricket').toLowerCase();
          final config = (rawStreamMatch?['config'] as Map<String, dynamic>?) ??
              matchDetail.config ??
              {};

          dynamic derivedState;
          final engine = SportRegistry.getEngine(sport);
          final scoreSnapshot = (rawStreamMatch?['score'] as Map?) ?? matchDetail.score;

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
            try {
              derivedState = SportRegistry.fold(
                sportName: sport,
                configJson: config,
                events: events,
                homeId: homeId,
                awayId: awayId,
              );
            } catch (_) {
              try {
                derivedState = SportRegistry.initialState(
                  sportName: sport,
                  configJson: config,
                  homeId: homeId,
                  awayId: awayId,
                );
              } catch (_) {}
            }
          }

          final matchStatus = rawStreamMatch?['status'] as String? ?? matchDetail.status;
          final playerNames = ref.watch(matchPlayerNamesProvider(widget.matchId)).valueOrNull ?? const <String, String>{};

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(liveEventsNotifierProvider(widget.matchId).notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.lg,
              ),
              children: [
                // 1. Live Animated Score Header
                _buildAnimatedHeader(
                  context: context,
                  sport: sport,
                  derivedState: derivedState,
                  rawStreamMatch: rawStreamMatch,
                  matchDetail: matchDetail,
                  homeName: homeName,
                  awayName: awayName,
                  status: matchStatus,
                  isDark: isDark,
                  playerNames: playerNames,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Full Professional Scorecard (Batting, Bowling, Sets, Goals)
                ProfessionalScorecard(
                  match: matchDetail,
                  scoringState: derivedState,
                  playerNames: playerNames,
                ),
                const SizedBox(height: AppSpacing.xl),

                // 3. Timeline Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Timeline',
                      style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: Text(
                        '${events.length} Events',
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Chronological Event Feed (newest first)
                if (events.isEmpty)
                  const EmptyState(
                    icon: Icons.timeline_outlined,
                    title: 'No Events Yet',
                    subtitle: 'Scoring actions will appear here in real time.',
                  )
                else
                  ...events.reversed.map((event) => _buildTimelineTile(
                        context: context,
                        event: event,
                        homeId: homeId,
                        homeName: homeName,
                        awayName: awayName,
                        sport: sport,
                        isDark: isDark,
                        playerNames: playerNames,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Connection Error', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Retry Connection',
                onPressed: () {
                  ref.read(liveEventsNotifierProvider(widget.matchId).notifier).refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader({
    required BuildContext context,
    required String sport,
    required dynamic derivedState,
    required Map<String, dynamic>? rawStreamMatch,
    required dynamic matchDetail,
    required String homeName,
    required String awayName,
    required String status,
    required bool isDark,
    required Map<String, String> playerNames,
  }) {
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    String resolvePlayer(String? id) {
      if (id == null || id.isEmpty) return 'Player';
      if (playerNames.containsKey(id) && playerNames[id]!.isNotEmpty) {
        return playerNames[id]!;
      }
      if (matchDetail.score != null) {
        final pNames = matchDetail.score['player_names'];
        if (pNames is Map && pNames[id] != null && pNames[id].toString().isNotEmpty) {
          return pNames[id].toString();
        }
        final pStats = matchDetail.score['player_stats'];
        if (pStats is Map && pStats[id] is Map && pStats[id]['name'] != null) {
          final n = pStats[id]['name'].toString();
          if (n.isNotEmpty) return n;
        }
      }
      final p = matchDetail.participants.where((e) => e.userId == id || e.teamId == id).firstOrNull;
      if (p?.userName != null && p!.userName!.isNotEmpty) return p.userName!;

      final idLower = id.toLowerCase().trim();
      if (idLower == 'batter 1' ||
          idLower == 'batter 2' ||
          idLower == 'bowler 1' ||
          idLower == 'striker 1' ||
          idLower == 'non-striker 2' ||
          idLower == 'opening bowler') {
        final isCricket = derivedState is CricketState && (derivedState as CricketState).innings.isNotEmpty;
        final battingTeamId = isCricket
            ? (derivedState as CricketState).innings.first.battingTeamId
            : matchDetail.homeTeamId;
        final isHomeBatting = battingTeamId == matchDetail.homeTeamId || battingTeamId == 'home';
        final battingTeamName = isHomeBatting ? homeName : awayName;
        final bowlingTeamName = isHomeBatting ? awayName : homeName;

        final battingParticipants = matchDetail.participants
            .where((e) => (isHomeBatting ? (e.teamId == matchDetail.homeTeamId || e.teamId == 'home') : (e.teamId == matchDetail.awayTeamId || e.teamId == 'away')) && e.userName != null && e.userName!.isNotEmpty)
            .toList();
        final bowlingParticipants = matchDetail.participants
            .where((e) => (isHomeBatting ? (e.teamId == matchDetail.awayTeamId || e.teamId == 'away') : (e.teamId == matchDetail.homeTeamId || e.teamId == 'home')) && e.userName != null && e.userName!.isNotEmpty)
            .toList();

        if (idLower == 'batter 1' || idLower == 'striker 1') {
          if (battingParticipants.isNotEmpty) return battingParticipants[0].userName!;
          return '$battingTeamName Player 1';
        }
        if (idLower == 'batter 2' || idLower == 'striker 2' || idLower == 'non-striker 2') {
          if (battingParticipants.length > 1) return battingParticipants[1].userName!;
          return '$battingTeamName Player 2';
        }
        if (idLower == 'bowler 1' || idLower == 'opening bowler') {
          if (bowlingParticipants.isNotEmpty) return bowlingParticipants[0].userName!;
          return '$bowlingTeamName Bowler 1';
        }
      }

      if (id.startsWith('home_p_')) {
        final num = int.tryParse(id.replaceFirst('home_p_', '')) ?? 1;
        final homeParts = matchDetail.participants
            .where((e) => (e.teamId == matchDetail.homeTeamId || e.teamId == 'home') && e.userName != null && e.userName!.isNotEmpty)
            .toList();
        if (num > 0 && num <= homeParts.length) return homeParts[num - 1].userName!;
        return '$homeName Player $num';
      }
      if (id.startsWith('away_p_')) {
        final num = int.tryParse(id.replaceFirst('away_p_', '')) ?? 1;
        final awayParts = matchDetail.participants
            .where((e) => (e.teamId == matchDetail.awayTeamId || e.teamId == 'away') && e.userName != null && e.userName!.isNotEmpty)
            .toList();
        if (num > 0 && num <= awayParts.length) return awayParts[num - 1].userName!;
        return '$awayName Player $num';
      }
      if (id.length == 36 && id.contains('-')) return 'Player';
      return id;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Title & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$homeName vs $awayName',
                  style: AppTypography.headline.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildLiveBadge(status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Count-up Animated Score per Sport
          if (sport == 'football' && derivedState is FootballState) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(homeName, style: AppTypography.body.copyWith(color: secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedScore(value: derivedState.homeScore),
                  ],
                ),
                Text(
                  '-',
                  style: AppTypography.title.copyWith(color: secondaryText),
                ),
                Column(
                  children: [
                    Text(awayName, style: AppTypography.body.copyWith(color: secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedScore(value: derivedState.awayScore),
                  ],
                ),
              ],
            ),
            if (derivedState.shootoutKicks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Shootout: ${derivedState.shootoutHomeScore} - ${derivedState.shootoutAwayScore} pens',
                style: AppTypography.caption.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ] else if (sport == 'badminton' && derivedState is BadmintonState) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(homeName, style: AppTypography.body.copyWith(color: secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedScore(value: derivedState.currentGame.homePoints),
                    Text('Games: ${derivedState.homeGamesWon}', style: AppTypography.caption),
                  ],
                ),
                Text(
                  'G${derivedState.currentGameIndex + 1}',
                  style: AppTypography.headline.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                Column(
                  children: [
                    Text(awayName, style: AppTypography.body.copyWith(color: secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedScore(value: derivedState.currentGame.awayPoints),
                    Text('Games: ${derivedState.awayGamesWon}', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ] else if (sport == 'cricket' && derivedState is CricketState) ...[
            if (derivedState.activeInnings != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedScore(value: derivedState.activeInnings!.totalRuns),
                      Text(
                        '/',
                        style: AppTypography.scoreDisplay,
                      ),
                      AnimatedScore(value: derivedState.activeInnings!.totalWickets),
                    ],
                  ),
                  Text(
                    '${derivedState.activeInnings!.overs.toStringAsFixed(1)} ov',
                    style: AppTypography.headline.copyWith(color: secondaryText),
                  ),
                ],
              ),
              if (derivedState.target != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  derivedState.resultMarginText ?? 'Target: ${derivedState.target}',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              // Active Batters & Bowler
              if (derivedState.activeInnings!.strikerId != null ||
                  derivedState.activeInnings!.currentBowlerId != null) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (derivedState.activeInnings!.strikerId != null)
                      Text(
                        '${resolvePlayer(derivedState.activeInnings!.strikerId)}*',
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    if (derivedState.activeInnings!.nonStrikerId != null)
                      Text(
                        resolvePlayer(derivedState.activeInnings!.nonStrikerId),
                        style: AppTypography.caption.copyWith(color: secondaryText),
                      ),
                  ],
                ),
                if (derivedState.activeInnings!.currentBowlerId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bowler: ${resolvePlayer(derivedState.activeInnings!.currentBowlerId)}',
                    style: AppTypography.caption.copyWith(color: secondaryText),
                  ),
                ],
              ],
            ] else
              const Center(child: Text('Innings setup in progress')),
          ] else ...[
            // Generic Fallback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedScore(value: (rawStreamMatch?['home_score'] as int?) ?? matchDetail.homeScore ?? 0),
                const Text('-'),
                AnimatedScore(value: (rawStreamMatch?['away_score'] as int?) ?? matchDetail.awayScore ?? 0),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveBadge(String status) {
    final isLive = status.toLowerCase() == 'live';
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isLive ? colors.live.withAlpha(20) : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLive ? colors.live.withAlpha(60) : colors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: colors.live,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            isLive ? 'LIVE' : (status.toLowerCase() == 'completed' ? 'FT' : status.toUpperCase()),
            style: AppTypography.overline.copyWith(
              color: isLive ? colors.live : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required BuildContext context,
    required MatchEvent event,
    required String homeId,
    required String homeName,
    required String awayName,
    required String sport,
    required bool isDark,
    required Map<String, String> playerNames,
  }) {
    final teamName = event.teamId == homeId ? homeName : awayName;
    final iconData = _getEventIcon(event);
    final iconColor = _getEventColor(event);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventTitle(event, teamName),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatEventSubtitle(event, playerNames),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#${event.seq}',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(MatchEvent event) {
    if (event.payload['is_wicket'] == true) return Icons.sports_cricket_rounded;
    switch (event.type) {
      case 'goal':
      case 'own_goal':
        return Icons.sports_soccer_rounded;
      case 'yellow_card':
      case 'red_card':
        return Icons.warning_rounded;
      case 'rally_won':
        return Icons.sports_tennis_rounded;
      case 'wicket':
        return Icons.sports_cricket_rounded;
      case 'delivery':
        return Icons.circle;
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _getEventColor(MatchEvent event) {
    if (event.payload['is_wicket'] == true) return AppColors.error;
    switch (event.type) {
      case 'goal':
      case 'rally_won':
        return AppColors.success;
      case 'own_goal':
      case 'wicket':
      case 'red_card':
        return AppColors.error;
      case 'yellow_card':
        return AppColors.warning;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatEventTitle(MatchEvent event, String teamName) {
    switch (event.type) {
      case 'goal':
        return 'GOAL! $teamName';
      case 'own_goal':
        return 'OWN GOAL conceded by $teamName';
      case 'yellow_card':
        return 'Yellow Card: $teamName';
      case 'red_card':
        return 'RED CARD: $teamName';
      case 'rally_won':
        return 'Point to $teamName';
      case 'wicket':
        return 'WICKET! ($teamName)';
      case 'delivery':
        if (event.payload['is_wicket'] == true) {
          final dismissal = event.payload['dismissal_type'] as String?;
          final dismissalText = dismissal != null ? ' (${dismissal.replaceAll('_', ' ')})' : '';
          return 'WICKET!$dismissalText ($teamName)';
        }
        final runs = event.payload['runs'] ?? event.payload['runs_completed'] ?? 0;
        return '$runs Run${runs == 1 ? "" : "s"} ($teamName)';
      default:
        return event.type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatEventSubtitle(MatchEvent event, Map<String, String> playerNames) {
    String resolvePlayer(String? id) {
      if (id == null || id.isEmpty) return 'Player';
      if (playerNames.containsKey(id) && playerNames[id]!.isNotEmpty) {
        return playerNames[id]!;
      }
      if (id.startsWith('home_p_') || id.startsWith('away_p_')) return 'Player';
      if (id.length == 36 && id.contains('-')) return 'Player';
      return id;
    }

    if (event.payload.containsKey('scorer')) {
      final rawScorer = event.payload['scorer']?.toString();
      final scorer = resolvePlayer(rawScorer);
      return 'Scorer: $scorer (${event.payload['kind'] ?? "open play"})';
    }
    if (event.payload.containsKey('dismissal_type') || event.payload['is_wicket'] == true) {
      final dismissal = event.payload['dismissal_type'] ?? 'out';
      final rawBatter = event.payload['out_batter_id'] ?? event.payload['dismissed_batter_id'] ?? "Striker";
      final batter = resolvePlayer(rawBatter.toString());
      final runs = event.payload['runs'] ?? event.payload['runs_completed'];
      final runsNum = (runs is num) ? runs.toInt() : (int.tryParse(runs?.toString() ?? '') ?? 0);
      final runsText = runsNum > 0 ? ' • $runsNum runs completed' : '';
      return '$dismissal • Batter: $batter$runsText';
    }
    if (event.payload.containsKey('reason')) {
      return 'Reason: ${event.payload['reason']}';
    }
    return 'Action recorded';
  }
}
