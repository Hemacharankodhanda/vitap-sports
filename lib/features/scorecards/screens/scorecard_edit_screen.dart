/// VIT-AP Sports — Live Scorecard Edit Screen (Scorer Shell).
///
/// Single shell screen driven by pure Dart scoring engines (Football, Badminton, Cricket).
/// Features large tap targets (>= 44pt), haptic feedback, optimistic local apply,
/// offline retry queue, and always-visible Undo.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../scoring/presentation/widgets/action_dialogs.dart';
import '../../scoring/presentation/widgets/live_score_header.dart';
import '../../matches/providers/match_providers.dart';
import '../../scoring/presentation/widgets/scorer_action_grid.dart';
import '../../scoring/presentation/widgets/sport_setup_widget.dart';
import '../../scoring/providers/live_scorer_providers.dart';

class ScorecardEditScreen extends ConsumerWidget {
  const ScorecardEditScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveScorerNotifierProvider(matchId));
    final notifier = ref.read(liveScorerNotifierProvider(matchId).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.sport.isEmpty ? 'Live Scorer' : '${state.sport.toUpperCase()} Scorer',
              style: AppTypography.headline.copyWith(fontSize: 16),
            ),
            if (state.homeName.isNotEmpty && state.awayName.isNotEmpty)
              Text(
                '${state.homeName} vs ${state.awayName}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // Offline / Sync Status Indicator
          if (state.isSyncing) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ] else if (state.hasPendingWrites || state.syncError != null) ...[
            IconButton(
              tooltip: state.syncError ?? 'Pending writes queued',
              icon: const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
              onPressed: () => notifier.retryPendingQueue(),
            ),
          ],

          // Take Over Scoring Action
          if (state.isAuthorized &&
              state.currentScorerId != null &&
              state.status != 'completed') ...[
            TextButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final confirm = await ActionDialogs.confirmDestructive(
                  context: context,
                  title: 'Take Over Scoring?',
                  message: 'You will become the active scorer for this live match.',
                  confirmLabel: 'Take Over',
                );
                if (confirm) {
                  await notifier.takeOverScoring();
                }
              },
              child: const Text('Take Over'),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !state.isAuthorized
                ? _buildUnauthorizedView(context, isDark, notifier, state)
                : _buildScorerBody(context, state, notifier, ref),
      ),
      bottomNavigationBar: state.isAuthorized && state.isMatchLive
          ? _buildBottomBar(context, state, notifier, ref)
          : null,
    );
  }

  Widget _buildUnauthorizedView(
    BuildContext context,
    bool isDark,
    LiveScorerNotifier notifier,
    ScorerState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.warning),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Scoring Restricted',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Only the match creator, participating team captains, or designated scorers can record live events.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              if (state.syncError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.syncError!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Claim / Take Over Scoring',
                icon: Icons.sports_score_rounded,
                variant: AppButtonVariant.primary,
                isLoading: state.isSyncing,
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await notifier.takeOverScoring();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Back to Match Details',
                icon: Icons.arrow_back_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/matches/${state.matchId}');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScorerBody(
    BuildContext context,
    ScorerState state,
    LiveScorerNotifier notifier,
    WidgetRef ref,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.lg,
      ),
      children: [
        // Offline / Sync Banner
        if (state.syncError != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    state.syncError!,
                    style: AppTypography.caption.copyWith(color: AppColors.warning),
                  ),
                ),
                TextButton(
                  onPressed: () => notifier.retryPendingQueue(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],

        // 1. Live Score Header
        LiveScoreHeader(state: state),
        const SizedBox(height: AppSpacing.lg),

        // 2. Pre-Match Setup (if match scheduled)
        if (state.status == 'scheduled' || state.status == 'upcoming') ...[
          SportSetupWidget(
            state: state,
            onStartMatch: ({required config, extra}) async {
              HapticFeedback.mediumImpact();
              await notifier.startMatch(config: config, extra: extra);
              ref.invalidate(matchDetailProvider(matchId));
              ref.invalidate(matchesListProvider);
            },
          ),
        ] else if (state.status == 'live') ...[
          // 3. Dynamic Action Grid
          ScorerActionGrid(
            state: state,
            onRecordAction: ({required type, teamId, playerId, payload = const {}}) async {
              await notifier.recordAction(
                type: type,
                teamId: teamId,
                playerId: playerId,
                payload: payload,
              );
            },
          ),
        ] else if (state.status == 'completed') ...[
          // 4. Completed Match State
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Match Completed',
                  style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'All results, team win/loss records, and player statistics have been finalized atomically.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ScorerState state,
    LiveScorerNotifier notifier,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Always-Visible Undo Button
          Expanded(
            flex: 1,
            child: AppButton(
              label: 'Undo',
              icon: Icons.undo_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: state.events.isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      notifier.undo();
                    },
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Finish Match Button (Destructive Confirmation)
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Finish Match',
              icon: Icons.check_circle_outline_rounded,
              variant: AppButtonVariant.destructive,
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final confirm = await ActionDialogs.confirmDestructive(
                  context: context,
                  title: 'Complete Match?',
                  message:
                      'Are you sure you want to finish this match? Results will be permanently written to team standings and player statistics.',
                  confirmLabel: 'Finish Match',
                );

                if (confirm) {
                  await notifier.finishMatch();
                  ref.invalidate(matchDetailProvider(matchId));
                  ref.invalidate(matchesListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match finished successfully'),
                      ),
                    );
                    context.pop();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
