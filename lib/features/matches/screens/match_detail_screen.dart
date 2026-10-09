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
                        color: AppColors.accent,
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
                                  ? (homeTeam.first.teamName ?? 'Home')
                                  : 'TBD',
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
                                  ? (awayTeam.first.teamName ?? 'Away')
                                  : 'TBD',
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

              // Scorecard buttons
              if (match.status == 'live' || match.status == 'completed') ...[
                AppButton(
                  label: 'View Scorecard',
                  onPressed: () => context.go('/matches/$matchId/scorecard'),
                  icon: Icons.scoreboard_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              
              Consumer(
                builder: (context, ref, _) {
                  final currentUserId = ref.watch(currentUserIdProvider);
                  // Show edit button if user created the match, or is the scorer
                  if (currentUserId != null && 
                     (match.createdBy == currentUserId || match.scorerId == currentUserId)) {
                    return Column(
                      children: [
                        if (homeTeam.isNotEmpty && homeTeam.first.teamId != null) ...[
                          AppButton(
                            label: 'Manage Home Squad',
                            onPressed: () => context.go('/matches/$matchId/squad/${homeTeam.first.teamId}/home'),
                            icon: Icons.group_add_rounded,
                            variant: AppButtonVariant.secondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (awayTeam.isNotEmpty && awayTeam.first.teamId != null) ...[
                          AppButton(
                            label: 'Manage Away Squad',
                            onPressed: () => context.go('/matches/$matchId/squad/${awayTeam.first.teamId}/away'),
                            icon: Icons.group_add_rounded,
                            variant: AppButtonVariant.secondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        AppButton(
                          label: 'Edit Scorecard',
                          onPressed: () => context.go('/matches/$matchId/scorecard/edit'),
                          icon: Icons.edit_note_rounded,
                          variant: match.status == 'live' ? AppButtonVariant.primary : AppButtonVariant.secondary,
                        ),
                        if (match.createdBy == currentUserId) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: 'Delete Match',
                            onPressed: () async {
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
                            },
                            icon: Icons.delete_outline_rounded,
                            variant: AppButtonVariant.secondary,
                          ),
                        ],
                      ],
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
}
