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
        title: const Text('Live Match Scorecard'),
        actions: [
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

          String homeName = 'Home';
          String awayName = 'Away';
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

          return eventsAsync.when(
            loading: () => const Center(child: ShimmerList()),
            error: (err, _) => _buildErrorView(context, err.toString()),
            data: (events) {
              // Derive pure state snapshot from events or stored match snapshot
              final rawStreamMatch = matchStreamAsync.valueOrNull;
              final config = (rawStreamMatch?['config'] as Map<String, dynamic>?) ??
                  matchDetail.config ??
                  {};

              dynamic derivedState;
              final engine = SportRegistry.getEngine(sport);
              if (events.isEmpty && matchDetail.score != null && engine != null) {
                try {
                  derivedState = engine.fromSnapshot(
                    matchDetail.score!,
                    SportRegistry.parseConfig(sport, config),
                  );
                } catch (_) {}
              }

              derivedState ??= SportRegistry.fold(
                sportName: sport,
                configJson: config,
                events: events,
                homeId: homeId,
                awayId: awayId,
              );

              final matchStatus = rawStreamMatch?['status'] as String? ?? matchDetail.status;

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
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 2. Timeline Section Header
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
                            color: AppColors.accent.withAlpha(25),
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Text(
                            '${events.length} Events',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Chronological Event Feed (newest first)
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
                          )),
                  ],
                ),
              );
            },
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
  }) {
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                style: AppTypography.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
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
                  style: AppTypography.headline.copyWith(color: AppColors.accent),
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
                    color: AppColors.accent,
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
                        '🏏 ${derivedState.activeInnings!.strikerId}*',
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    if (derivedState.activeInnings!.nonStrikerId != null)
                      Text(
                        '${derivedState.activeInnings!.nonStrikerId}',
                        style: AppTypography.body.copyWith(color: secondaryText),
                      ),
                  ],
                ),
                if (derivedState.activeInnings!.currentBowlerId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '⚾ Bowler: ${derivedState.activeInnings!.currentBowlerId}',
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
    final isLive = status == 'live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isLive ? AppColors.error.withAlpha(30) : AppColors.success.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: isLive ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
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
  }) {
    final teamName = event.teamId == homeId ? homeName : awayName;
    final iconData = _getEventIcon(event.type);
    final iconColor = _getEventColor(event.type);

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
                  _formatEventSubtitle(event),
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

  IconData _getEventIcon(String type) {
    switch (type) {
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

  Color _getEventColor(String type) {
    switch (type) {
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
        return AppColors.accent;
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
        final runs = event.payload['runs'] ?? 0;
        return '$runs Run${runs == 1 ? "" : "s"} ($teamName)';
      default:
        return event.type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatEventSubtitle(MatchEvent event) {
    if (event.payload.containsKey('scorer')) {
      return 'Scorer: ${event.payload['scorer']} (${event.payload['kind'] ?? "open play"})';
    }
    if (event.payload.containsKey('dismissal_type')) {
      return '${event.payload['dismissal_type']} • Batter: ${event.payload['dismissed_batter_id'] ?? "Striker"}';
    }
    if (event.payload.containsKey('reason')) {
      return 'Reason: ${event.payload['reason']}';
    }
    return 'Action recorded';
  }
}
