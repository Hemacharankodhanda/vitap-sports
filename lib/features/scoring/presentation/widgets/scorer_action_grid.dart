/// VIT-AP Sports — Scorer Action Grid.
///
/// Dynamic grid driven by pure engine availableActions.
/// Features large touch targets (>= 48dp), haptic feedback,
/// and contextual prompt dialogs.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/scoring_engine.dart';
import '../../engines/cricket/cricket_state.dart';
import '../../engines/badminton/badminton_state.dart';
import '../../providers/live_scorer_providers.dart';
import 'action_dialogs.dart';

class ScorerActionGrid extends StatelessWidget {
  const ScorerActionGrid({
    super.key,
    required this.state,
    required this.onRecordAction,
  });

  final ScorerState state;
  final Future<void> Function({
    required String type,
    String? teamId,
    String? playerId,
    Map<String, dynamic> payload,
  }) onRecordAction;

  @override
  Widget build(BuildContext context) {
    final actions = state.availableActions;
    if (actions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No scoring actions available. Match may be completed or awaiting setup.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Separate primary scoring buttons (runs, rally points, goals) from secondary actions
    final primaryActions = actions.where((a) => a.isPrimary).toList();
    final otherActions = actions.where((a) => !a.isPrimary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryActions.isNotEmpty) ...[
          _buildPrimaryGrid(context, primaryActions),
          const SizedBox(height: AppSpacing.md),
        ],
        if (otherActions.isNotEmpty) ...[
          _buildSecondaryWrap(context, otherActions),
        ],
      ],
    );
  }

  Widget _buildPrimaryGrid(BuildContext context, List<ScoringAction> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = actions.length <= 4 ? actions.length : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionButton(context, action, isLarge: true);
          },
        );
      },
    );
  }

  Widget _buildSecondaryWrap(BuildContext context, List<ScoringAction> actions) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((action) {
        return _buildActionButton(context, action, isLarge: false);
      }).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, ScoringAction action, {required bool isLarge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (action.isDestructive) {
      bg = AppColors.error;
      fg = Colors.white;
    } else if (action.isPrimary) {
      bg = Theme.of(context).colorScheme.primary;
      fg = Colors.white;
    } else {
      bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
      fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () async {
          // Haptic feedback per HIG
          HapticFeedback.lightImpact();
          await _handleActionTap(context, action);
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.buttonHeightPrimary, // 48dp >= 44pt touch target
            minWidth: 48,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  action.label,
                  style: isLarge
                      ? AppTypography.title.copyWith(
                          color: fg,
                          fontWeight: FontWeight.bold,
                        )
                      : AppTypography.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                  textAlign: TextAlign.center,
                ),
                if (action.subLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    action.subLabel!,
                    style: AppTypography.caption.copyWith(
                      color: fg.withAlpha(200),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleActionTap(BuildContext context, ScoringAction action) async {
    // 1. Cricket Wicket Sheet
    if (action.type == 'wicket' || action.id == 'wicket') {
      final cricket = state.scoringState as CricketState?;
      final active = cricket?.activeInnings;
      final strikerId = active?.strikerId ?? 'Striker';
      final nonStrikerId = active?.nonStrikerId ?? 'Non-Striker';
      final isFreeHit = active?.isFreeHit ?? false;
      final battingTeamId = active?.battingTeamId ?? state.homeId;
      final bowlingTeamId = active?.bowlingTeamId ?? state.awayId;

      final result = await ActionDialogs.showWicketSheet(
        context: context,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        isFreeHit: isFreeHit,
        battingPlayers: state.playersForTeam(battingTeamId),
        bowlingPlayers: state.playersForTeam(bowlingTeamId),
        battingStats: active?.battingStats ?? {},
      );

      if (result != null) {
        await onRecordAction(
          type: 'delivery',
          payload: {
            ...result,
            'striker_id': strikerId,
            'non_striker_id': nonStrikerId,
            'bowler_id': active?.currentBowlerId,
          },
        );
      }
      return;
    }

    // 2. Cricket Bowler Selection
    if (action.type == 'select_bowler' ||
        action.type == 'set_bowler' ||
        action.type == 'select_bowler_prompt' ||
        action.id == 'select_bowler') {
      final cricket = state.scoringState as CricketState?;
      final active = cricket?.activeInnings;
      final bowlingTeamId = active?.bowlingTeamId ??
          (active?.battingTeamId == state.homeId ? state.awayId : state.homeId);
      final bowlingPlayers = state.playersForTeam(bowlingTeamId);
      final lastBowlerId = active?.lastOverBowlerId ?? active?.currentBowlerId;

      final selectedBowler = await ActionDialogs.showBowlerSheet(
        context: context,
        previousBowlerIds: lastBowlerId != null ? [lastBowlerId] : [],
        lastOverBowlerId: lastBowlerId,
        bowlingTeamName: bowlingTeamId == state.homeId ? state.homeName : state.awayName,
        bowlingPlayers: bowlingPlayers,
        bowlingStats: active?.bowlingStats ?? {},
      );

      if (selectedBowler != null) {
        await onRecordAction(
          type: 'set_bowler',
          payload: {'bowler_id': selectedBowler},
        );
      }
      return;
    }

    // 3. Cricket Batters Selection
    if (action.type == 'set_batters' || action.id == 'set_batters') {
      final cricket = state.scoringState as CricketState?;
      final active = cricket?.activeInnings;
      final battingTeamId = active?.battingTeamId ?? state.homeId;
      final battingPlayers = state.playersForTeam(battingTeamId);

      final result = await ActionDialogs.showBattersSheet(
        context: context,
        teamName: battingTeamId == state.homeId ? state.homeName : state.awayName,
        players: battingPlayers,
        battingStats: active?.battingStats ?? {},
      );

      if (result != null) {
        await onRecordAction(
          type: 'set_batters',
          payload: result,
        );
      }
      return;
    }

    // 4. Football Goal Prompt
    if (action.type == 'goal') {
      final goalData = await ActionDialogs.showGoalSheet(
        context: context,
        homeTeamId: state.homeId,
        awayTeamId: state.awayId,
        homeTeamName: state.homeName,
        awayTeamName: state.awayName,
      );

      if (goalData != null) {
        await onRecordAction(
          type: 'goal',
          teamId: goalData['team'] as String?,
          playerId: goalData['scorer'] as String?,
          payload: goalData,
        );
      }
      return;
    }

    // 4. Inject explicit IDs into Cricket delivery events
    if (action.type == 'delivery') {
      final cricket = state.scoringState as CricketState?;
      final active = cricket?.activeInnings;
      final payload = Map<String, dynamic>.from(action.payload ?? {});
      payload['striker_id'] = active?.strikerId;
      payload['non_striker_id'] = active?.nonStrikerId;
      payload['bowler_id'] = active?.currentBowlerId;
      
      await onRecordAction(
        type: action.type,
        teamId: action.teamId,
        playerId: action.playerId,
        payload: payload,
      );
      return;
    }

    // 5. Inject explicit IDs into Badminton rally_won events
    if (action.type == 'rally_won') {
      final badminton = state.scoringState as BadmintonState?;
      final payload = Map<String, dynamic>.from(action.payload ?? {});
      payload['server_id'] = badminton?.currentServerId;
      payload['receiver_id'] = badminton?.currentReceiverId;
      
      await onRecordAction(
        type: action.type,
        teamId: action.teamId,
        playerId: action.playerId,
        payload: payload,
      );
      return;
    }

    // Default: Dispatch event directly
    await onRecordAction(
      type: action.type,
      teamId: action.teamId,
      playerId: action.playerId,
      payload: action.payload,
    );
  }
}
