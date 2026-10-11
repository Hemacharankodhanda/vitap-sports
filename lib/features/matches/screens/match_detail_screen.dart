/// VIT-AP Sports — Match detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/match_model.dart';
import '../providers/match_providers.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  MatchStatus _parseStatus(String s) {
    switch (s) {
      case 'live': return MatchStatus.live;
      case 'completed': return MatchStatus.completed;
      case 'cancelled': return MatchStatus.cancelled;
      default: return MatchStatus.upcoming;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Match Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: AppSpacing.iconNav),
            onPressed: () => ref.invalidate(matchDetailProvider(matchId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: matchAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(matchDetailProvider(matchId)),
        ),
        data: (match) {
          if (match == null) {
            return const ErrorView(message: 'Match not found');
          }

          final homeTeam = match.participants
              .where((p) => p.side == 'home')
              .toList();
          final awayTeam = match.participants
              .where((p) => p.side == 'away')
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
            ),
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Status badge
              Center(child: StatusBadge(status: _parseStatus(match.status))),
              const SizedBox(height: AppSpacing.xl),

              // Sport + Venue + Time
              AppCard(
                child: Column(
                  children: [
                    Text(
                      match.sportName ?? 'Sport',
                      style: AppTypography.headline.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _infoRow(Icons.location_on_outlined, match.venue, isDark),
                    const SizedBox(height: AppSpacing.sm),
                    _infoRow(
                      Icons.schedule_rounded,
                      AppDateUtils.formatSmartDateTime(match.scheduledAt),
                      isDark,
                    ),
                    if (match.format != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _infoRow(
                          Icons.sports_rounded, match.format!, isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Teams
              if (homeTeam.isNotEmpty || awayTeam.isNotEmpty) ...[
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              homeTeam.isNotEmpty
                                  ? (homeTeam.first.teamName ?? match.homeTeamName ?? 'Team 1')
                                  : (match.homeTeamName ?? 'TBD'),
                              style: AppTypography.headline,
                              textAlign: TextAlign.center,
                            ),
                            if (match.homeScore != null)
                              Text(
                                match.homeScore.toString(),
                                style: AppTypography.scoreMedium,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'VS',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              awayTeam.isNotEmpty
                                  ? (awayTeam.first.teamName ?? match.awayTeamName ?? 'Team 2')
                                  : (match.awayTeamName ?? 'TBD'),
                              style: AppTypography.headline,
                              textAlign: TextAlign.center,
                            ),
                            if (match.awayScore != null)
                              Text(
                                match.awayScore.toString(),
                                style: AppTypography.scoreMedium,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Winner Banner for completed matches
              if (match.status == 'completed') ...[
                _buildWinnerCard(context, match, homeTeam, awayTeam, isDark),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Scorecard and Analysis buttons
              if (match.status == 'live' || match.status == 'completed') ...[
                AppButton(
                  label: 'View Scorecard',
                  onPressed: () => context.go('/matches/$matchId/scorecard'),
                  icon: Icons.scoreboard_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (match.status == 'completed') ...[
                AppButton(
                  label: 'View Match Analysis',
                  onPressed: () => context.go('/matches/$matchId/analysis'),
                  icon: Icons.analytics_outlined,
                  variant: AppButtonVariant.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              
              Consumer(
                builder: (context, ref, _) {
                  final currentUserId = ref.watch(currentUserIdProvider);
                  // Show scoring/action button if user created the match, is the scorer, or if match is unassigned
                  final isAuthorizedToScore = currentUserId != null &&
                      (match.createdBy == currentUserId ||
                       match.scorerId == currentUserId ||
                       match.scorerId == null);

                  // Only show live scorer / start match if NOT completed
                  if (isAuthorizedToScore && match.status != 'completed') {
                    final isScheduled = match.status == 'scheduled' || (match.status != 'live');
                    final isLive = match.status == 'live';
                    final buttonLabel = isScheduled ? 'Start Match' : 'Live Scorer';
                    final buttonIcon = isScheduled
                        ? Icons.play_arrow_rounded
                        : Icons.sports_score_rounded;

                    return Column(
                      children: [
                        AppButton(
                          label: buttonLabel,
                          onPressed: () => context.go('/matches/$matchId/scorecard/edit'),
                          icon: buttonIcon,
                          variant: AppButtonVariant.primary,
                        ),
                        if (match.createdBy == currentUserId) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: 'Delete Match',
                            onPressed: () async => _deleteMatch(context, ref, matchId),
                            icon: Icons.delete_outline_rounded,
                            variant: AppButtonVariant.destructive,
                          ),
                        ],
                      ],
                    );
                  }

                  if (match.createdBy == currentUserId) {
                    return AppButton(
                      label: 'Delete Match',
                      onPressed: () async => _deleteMatch(context, ref, matchId),
                      icon: Icons.delete_outline_rounded,
                      variant: AppButtonVariant.destructive,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: AppSpacing.iconInline,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard(
    BuildContext context,
    MatchModel match,
    List<MatchParticipant> homeTeam,
    List<MatchParticipant> awayTeam,
    bool isDark,
  ) {
    final homeName = homeTeam.isNotEmpty
        ? (homeTeam.first.teamName ?? homeTeam.first.userName ?? match.resolvedHomeTeamName ?? 'Team 1')
        : (match.resolvedHomeTeamName ?? 'Team 1');
    final awayName = awayTeam.isNotEmpty
        ? (awayTeam.first.teamName ?? awayTeam.first.userName ?? match.resolvedAwayTeamName ?? 'Team 2')
        : (match.resolvedAwayTeamName ?? 'Team 2');

    if (match.isDraw) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handshake_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Drawn / Tied',
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (match.resultMargin != null && match.resultMargin!.isNotEmpty)
                    Text(
                      match.resultMargin!,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final winningTeam = match.winningTeamName ??
        (homeTeam.isNotEmpty ? (homeTeam.first.teamName ?? homeTeam.first.userName) : null) ??
        homeName;
    final margin = match.resultMargin?.trim();

    String titleText = '$winningTeam Won';
    String? subtitleText;

    if (margin != null && margin.isNotEmpty) {
      final lowerMargin = margin.toLowerCase();
      if (lowerMargin != 'winner won' &&
          lowerMargin != 'winner wins' &&
          lowerMargin != 'winner') {
        if (lowerMargin.startsWith('won by ')) {
          subtitleText = margin;
        } else if (lowerMargin.startsWith('by ')) {
          subtitleText = 'Won $margin';
        } else if (lowerMargin.contains('won by ')) {
          final idx = lowerMargin.indexOf('won by ');
          subtitleText = margin.substring(idx);
        } else {
          subtitleText = margin;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 28,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                  ),
                ),
                if (subtitleText != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitleText,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMatch(BuildContext context, WidgetRef ref, String matchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(matchServiceProvider).deleteMatch(matchId);
        ref.invalidate(matchesListProvider('upcoming'));
        ref.invalidate(matchesListProvider('live'));
        ref.invalidate(matchesListProvider('completed'));
        
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}
