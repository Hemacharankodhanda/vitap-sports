/// VIT-AP Sports — Action Dialogs and Bottom Sheets.
///
/// Collects supplementary event payloads (e.g. wicket types, goal kinds, player names)
/// with quick tap targets adhering to Apple HIG.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/player_option.dart';
import '../../engines/cricket/cricket_state.dart';

class ActionDialogs {
  ActionDialogs._();

  /// Prompt for Cricket Wicket details
  static Future<Map<String, dynamic>?> showWicketSheet({
    required BuildContext context,
    required String strikerId,
    required String nonStrikerId,
    required bool isFreeHit,
    List<PlayerOption> battingPlayers = const [],
    List<PlayerOption> bowlingPlayers = const [],
    Map<String, BatterRecord> battingStats = const {},
  }) async {
    String dismissalType = isFreeHit ? 'run_out' : 'bowled';
    String dismissedBatterId = strikerId;
    final fielderController = TextEditingController();
    final newBatterController = TextEditingController();
    int runOutRuns = 0;
    bool battersCrossed = false;

    // Next batters available: from battingPlayers who aren't striker/nonStriker and haven't gotten out
    final availableNextBatters = battingPlayers.where((p) {
      if (p.id == strikerId || p.name == strikerId) return false;
      if (p.id == nonStrikerId || p.name == nonStrikerId) return false;
      final stats = battingStats[p.id] ?? battingStats[p.name];
      return stats == null || !stats.isOut;
    }).toList();

    if (availableNextBatters.isNotEmpty && newBatterController.text.isEmpty) {
      newBatterController.text = availableNextBatters.first.name;
    }

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheetTop)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final allowedDismissals = isFreeHit
                ? ['run_out']
                : ['bowled', 'caught', 'lbw', 'run_out', 'stumped', 'hit_wicket'];

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sheetPadding,
                right: AppSpacing.sheetPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Text(
                      'Wicket Details',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Dismissal Type',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: allowedDismissals.map((type) {
                        return AppChip(
                          label: type.replaceAll('_', ' ').toUpperCase(),
                          isSelected: dismissalType == type,
                          onTap: () => setState(() => dismissalType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (dismissalType == 'run_out') ...[
                      Text(
                        'Dismissed Batter',
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Builder(builder: (context) {
                        final sName = battingPlayers.where((p) => p.id == strikerId || p.name == strikerId).firstOrNull?.name ?? strikerId;
                        final nsName = battingPlayers.where((p) => p.id == nonStrikerId || p.name == nonStrikerId).firstOrNull?.name ?? nonStrikerId;
                        return Row(
                          children: [
                            AppChip(
                              label: 'Striker ($sName)',
                              isSelected: dismissedBatterId == strikerId,
                              onTap: () => setState(() => dismissedBatterId = strikerId),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppChip(
                              label: 'Non-Striker ($nsName)',
                              isSelected: dismissedBatterId == nonStrikerId,
                              onTap: () => setState(() => dismissedBatterId = nonStrikerId),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Runs Completed on Ball',
                        style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [0, 1, 2].map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: AppChip(
                              label: '$r',
                              isSelected: runOutRuns == r,
                              onTap: () => setState(() => runOutRuns = r),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (dismissalType == 'caught') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Batters crossed before catch?',
                            style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                          ),
                          AppSwitch(
                            value: battersCrossed,
                            onChanged: (val) => setState(() => battersCrossed = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (dismissalType == 'caught' || dismissalType == 'stumped' || dismissalType == 'run_out') ...[
                      Text(
                        'Fielder',
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (bowlingPlayers.isNotEmpty) ...[
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: bowlingPlayers.map((p) {
                            return AppChip(
                              label: p.name,
                              isSelected: fielderController.text == p.name,
                              onTap: () => setState(() => fielderController.text = p.name),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      AppTextField(
                        controller: fielderController,
                        label: 'Fielder Name (Optional)',
                        hint: 'e.g. Ravindra Jadeja',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    Text(
                      'Next Batter',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (availableNextBatters.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: availableNextBatters.map((p) {
                          return AppChip(
                            label: p.name,
                            isSelected: newBatterController.text == p.name,
                            onTap: () => setState(() => newBatterController.text = p.name),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    AppTextField(
                      controller: newBatterController,
                      label: 'Next Batter Name',
                      hint: 'e.g. Rohit Sharma',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: 'Confirm Wicket',
                      variant: AppButtonVariant.destructive,
                      onPressed: () {
                        // Find IDs or use custom names
                        String? finalNewBatterId = newBatterController.text.trim().isEmpty ? null : newBatterController.text.trim();
                        String? finalFielderId = fielderController.text.trim().isEmpty ? null : fielderController.text.trim();
                        
                        // If they match a squad player exactly, use their ID
                        if (finalNewBatterId != null) {
                          final matchP = availableNextBatters.where((p) => p.name == finalNewBatterId).firstOrNull;
                          if (matchP != null) finalNewBatterId = matchP.id;
                        }
                        if (finalFielderId != null) {
                          final matchF = bowlingPlayers.where((p) => p.name == finalFielderId).firstOrNull;
                          if (matchF != null) finalFielderId = matchF.id;
                        }

                        Navigator.pop(ctx, {
                          'is_wicket': true,
                          'kind': 'normal',
                          'dismissal_type': dismissalType,
                          'out_batter_id': dismissedBatterId,
                          'dismissed_batter_id': dismissedBatterId,
                          'new_batter_id': finalNewBatterId,
                          'fielder_id': finalFielderId,
                          'runs': runOutRuns,
                          'runs_completed': runOutRuns,
                          'batters_crossed': battersCrossed,
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Prompt for extra runs produced on a Wide or No Ball delivery.
  ///
  /// Calculates the total runs on the ball (1 penalty run + extra runs)
  /// and confirms whether the runs were boundaries (e.g. 4 wides or No Ball hit for 4/6).
  static Future<Map<String, dynamic>?> showExtraRunsSheet({
    required BuildContext context,
    required String kind, // 'wide' or 'no_ball'
    String? strikerName,
    String? bowlerName,
  }) async {
    final isWide = kind == 'wide';
    int selectedExtraRuns = 0;
    bool isBoundary = false;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheetTop)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            const int basePenalty = 1;
            final int totalRunsOnBall = basePenalty + selectedExtraRuns;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sheetPadding,
                right: AppSpacing.sheetPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      isWide ? 'Wide Delivery (Wd)' : 'No Ball Delivery (Nb)',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWide
                          ? '1 penalty run is awarded. Select additional runs produced (byes or overthrows):'
                          : '1 penalty run is awarded + Free Hit. Select runs produced off bat or extras:',
                      style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Extra Runs Chip Selection
                    Text(
                      isWide ? 'Additional Extra Runs' : 'Runs off Bat / Extras',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [0, 1, 2, 3, 4, 5, 6].map((r) {
                        final isSelected = selectedExtraRuns == r;
                        return AppChip(
                          label: r == 0 ? '0 (None)' : '+$r',
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedExtraRuns = r;
                              isBoundary = (r == 4 || r == 6);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Realtime Calculation Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCardInner),
                        border: Border.all(
                          color: context.colors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isWide ? 'Wide Penalty:' : 'No Ball Penalty:',
                                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                                ),
                              ),
                              Text(
                                '1 run',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isWide ? 'Extra Runs (Byes/Overthrows):' : 'Runs off Bat / Extras:',
                                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                                ),
                              ),
                              Text(
                                '+$selectedExtraRuns ${selectedExtraRuns == 1 ? "run" : "runs"}',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: context.colors.divider,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Runs on this Delivery:',
                                  style: AppTypography.headline.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '$totalRunsOnBall ${totalRunsOnBall == 1 ? "run" : "runs"}',
                                style: AppTypography.headline.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primaryFill,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          if (!isWide && selectedExtraRuns > 0 && strikerName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '$selectedExtraRuns runs credited to $strikerName',
                              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Confirm Action Button
                    AppButton(
                      label: 'Confirm ($totalRunsOnBall ${totalRunsOnBall == 1 ? "Run" : "Runs"})',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        Navigator.pop(ctx, {
                          'runs': selectedExtraRuns,
                          'is_boundary': isBoundary,
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Prompt for selecting opening batters (e.g., at the start of an innings)
  static Future<Map<String, String>?> showBattersSheet({
    required BuildContext context,
    required String teamName,
    required List<PlayerOption> players,
    Map<String, BatterRecord> battingStats = const {},
  }) async {
    String? strikerId;
    String? nonStrikerId;
    
    // Auto-select if players available and not out
    final availableBatters = players.where((p) {
      final stats = battingStats[p.id] ?? battingStats[p.name];
      return stats == null || !stats.isOut;
    }).toList();

    if (availableBatters.isNotEmpty) {
      strikerId = availableBatters.first.id;
      if (availableBatters.length > 1) {
        nonStrikerId = availableBatters[1].id;
      }
    }

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheetTop)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sheetPadding,
                right: AppSpacing.sheetPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Text(
                      'Select Batters - $teamName',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Striker',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (availableBatters.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: availableBatters.map((p) {
                          return AppChip(
                            label: p.name,
                            isSelected: strikerId == p.id,
                            onTap: () => setState(() {
                              strikerId = p.id;
                              if (nonStrikerId == p.id) nonStrikerId = null;
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    Text(
                      'Non-Striker',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (availableBatters.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: availableBatters.map((p) {
                          if (p.id == strikerId) return const SizedBox.shrink();
                          return AppChip(
                            label: p.name,
                            isSelected: nonStrikerId == p.id,
                            onTap: () => setState(() => nonStrikerId = p.id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    AppButton(
                      label: 'Confirm Batters',
                      onPressed: strikerId != null && nonStrikerId != null
                          ? () {
                              Navigator.pop(ctx, {
                                'striker_id': strikerId!,
                                'non_striker_id': nonStrikerId!,
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Prompt for selecting new bowler from bowling team squad
  static Future<String?> showBowlerSheet({
    required BuildContext context,
    required List<String> previousBowlerIds,
    String? lastOverBowlerId,
    String? bowlingTeamName,
    List<PlayerOption> bowlingPlayers = const [],
    Map<String, BowlerRecord> bowlingStats = const {},
  }) async {
    String? selectedBowler;
    bool isCustomEntry = false;
    final customController = TextEditingController();

    final restrictedBowlerId = lastOverBowlerId ??
        (previousBowlerIds.isNotEmpty ? previousBowlerIds.last : null);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheetTop)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sheetPadding,
                right: AppSpacing.sheetPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.sports_baseball_rounded, color: context.colors.textPrimary, size: AppSpacing.iconNav),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Next Bowler',
                                style: AppTypography.headline.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              if (bowlingTeamName != null)
                                Text('Bowling Team: $bowlingTeamName', style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (bowlingPlayers.isNotEmpty) ...[
                      Text(
                        'Bowling Squad',
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: bowlingPlayers.map((player) {
                          final isRestricted = restrictedBowlerId != null &&
                              (player.id == restrictedBowlerId || player.name == restrictedBowlerId);
                          final isSelected = selectedBowler == player.id;
                          final stats = bowlingStats[player.id] ?? bowlingStats[player.name];

                          final labelText = stats != null
                              ? '${player.name} (${stats.oversString} ov • ${stats.wickets}/${stats.runsConceded})'
                              : player.name;

                          return Opacity(
                            opacity: isRestricted ? 0.45 : 1.0,
                            child: AppChip(
                              label: labelText,
                              isSelected: isSelected,
                              onTap: isRestricted
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('A bowler cannot bowl two consecutive overs.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  : () {
                                      setState(() {
                                        selectedBowler = player.id;
                                        isCustomEntry = false;
                                      });
                                    },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (!isCustomEntry)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: Icon(Icons.person_add_rounded, size: 18, color: context.colors.primaryFill),
                          label: Text(
                            '+ Enter Other / Custom Bowler Name',
                            style: AppTypography.callout.copyWith(
                              color: context.colors.primaryFill,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              isCustomEntry = true;
                              selectedBowler = null;
                            });
                          },
                        ),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Custom Bowler Name',
                            style: AppTypography.callout.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (bowlingPlayers.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isCustomEntry = false;
                                  selectedBowler = null;
                                });
                              },
                              child: Text(
                                '← Pick from Squad',
                                style: AppTypography.caption.copyWith(
                                  color: context.colors.primaryFill,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: customController,
                        label: 'Custom Bowler Name',
                        hint: 'e.g. Jasprit Bumrah',
                        onChanged: (val) {
                          setState(() => selectedBowler = val.trim());
                        },
                        onSubmitted: (val) {
                          final name = val.trim();
                          if (name.isNotEmpty) {
                            Navigator.pop(ctx, name);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: selectedBowler != null && selectedBowler!.isNotEmpty
                          ? 'Confirm Bowler ($selectedBowler)'
                          : 'Confirm Bowler',
                      onPressed: selectedBowler != null && selectedBowler!.isNotEmpty
                          ? () => Navigator.pop(ctx, selectedBowler)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Prompt for Football Goal details
  static Future<Map<String, dynamic>?> showGoalSheet({
    required BuildContext context,
    required String homeTeamId,
    required String awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
  }) async {
    String selectedTeam = homeTeamId;
    String goalKind = 'open_play';
    final scorerController = TextEditingController(text: 'Player');
    final assistController = TextEditingController();

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheetTop)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sheetPadding,
                right: AppSpacing.sheetPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Text(
                      'Record Goal',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Scoring Team',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        AppChip(
                          label: homeTeamName,
                          isSelected: selectedTeam == homeTeamId,
                          onTap: () => setState(() => selectedTeam = homeTeamId),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label: awayTeamName,
                          isSelected: selectedTeam == awayTeamId,
                          onTap: () => setState(() => selectedTeam = awayTeamId),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Kind of Goal',
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ['open_play', 'penalty', 'free_kick', 'header'].map((k) {
                        return AppChip(
                          label: k.replaceAll('_', ' ').toUpperCase(),
                          isSelected: goalKind == k,
                          onTap: () => setState(() => goalKind = k),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: scorerController,
                      label: 'Scorer Name/No.',
                      hint: 'e.g. Sunil Chhetri',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: assistController,
                      label: 'Assist Name/No. (Optional)',
                      hint: 'e.g. Sahal Abdul Samad',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: 'Confirm Goal',
                      onPressed: () {
                        Navigator.pop(ctx, {
                          'team': selectedTeam,
                          'scorer': scorerController.text.trim().isEmpty ? 'Player' : scorerController.text.trim(),
                          'assist': assistController.text.trim().isEmpty ? null : assistController.text.trim(),
                          'kind': goalKind,
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Confirmation dialog for destructive actions (Finish Match, Abandon)
  static Future<bool> confirmDestructive({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final result = await AppDialog.showConfirmation(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: true,
    );
    return result ?? false;
  }
}
