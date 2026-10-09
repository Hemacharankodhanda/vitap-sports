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
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
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

        return StatefulBuilder(
          builder: (context, setState) {
            final allowedDismissals = isFreeHit
                ? ['run_out']
                : ['bowled', 'caught', 'lbw', 'run_out', 'stumped', 'hit_wicket'];

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Wicket Details', style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.md),

                    Text('Dismissal Type', style: AppTypography.body),
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
                      Text('Dismissed Batter', style: AppTypography.body),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          AppChip(
                            label: 'Striker ($strikerId)',
                            isSelected: dismissedBatterId == strikerId,
                            onTap: () => setState(() => dismissedBatterId = strikerId),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppChip(
                            label: 'Non-Striker ($nonStrikerId)',
                            isSelected: dismissedBatterId == nonStrikerId,
                            onTap: () => setState(() => dismissedBatterId = nonStrikerId),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Runs Completed on Ball', style: AppTypography.caption),
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Batters crossed before catch?', style: AppTypography.body),
                        value: battersCrossed,
                        onChanged: (val) => setState(() => battersCrossed = val),
                      ),
                    ],

                    if (dismissalType == 'caught' || dismissalType == 'stumped' || dismissalType == 'run_out') ...[
                      Text('Fielder', style: AppTypography.body),
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
                      TextField(
                        controller: fielderController,
                        decoration: const InputDecoration(
                          labelText: 'Fielder Name (Optional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    Text('Next Batter', style: AppTypography.body),
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
                    TextField(
                      controller: newBatterController,
                      decoration: const InputDecoration(
                        labelText: 'Next Batter Name',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: 'Confirm Wicket',
                      variant: AppButtonVariant.destructive,
                      onPressed: () {
                        Navigator.pop(ctx, {
                          'dismissal_type': dismissalType,
                          'dismissed_batter_id': dismissedBatterId,
                          'new_batter_id': newBatterController.text.trim().isEmpty
                              ? null
                              : newBatterController.text.trim(),
                          'fielder_id': fielderController.text.trim().isEmpty
                              ? null
                              : fielderController.text.trim(),
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

  /// Prompt for selecting new bowler from bowling team squad
  static Future<String?> showBowlerSheet({
    required BuildContext context,
    required List<String> previousBowlerIds,
    String? lastOverBowlerId,
    String? bowlingTeamName,
    List<PlayerOption> bowlingPlayers = const [],
    Map<String, BowlerRecord> bowlingStats = const {},
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        String? selectedBowler;
        bool isCustomEntry = false;
        final customController = TextEditingController();

        final restrictedBowlerId = lastOverBowlerId ??
            (previousBowlerIds.isNotEmpty ? previousBowlerIds.last : null);

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_baseball_rounded, color: AppColors.accent, size: AppSpacing.iconNav),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Next Bowler',
                                  style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
                              if (bowlingTeamName != null)
                                Text('Bowling Team: $bowlingTeamName', style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (bowlingPlayers.isNotEmpty) ...[
                      Text('Bowling Squad', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: bowlingPlayers.map((player) {
                          final isRestricted = restrictedBowlerId != null &&
                              (player.id == restrictedBowlerId || player.name == restrictedBowlerId);
                          final isSelected = selectedBowler == player.name;
                          final stats = bowlingStats[player.id] ?? bowlingStats[player.name];

                          final labelText = stats != null
                              ? '${player.name} (${stats.oversString} ov • ${stats.wickets}/${stats.runsConceded})'
                              : player.name;

                          return Opacity(
                            opacity: isRestricted ? 0.45 : 1.0,
                            child: ActionChip(
                              avatar: isRestricted
                                  ? const Icon(Icons.block_rounded, size: 14, color: AppColors.error)
                                  : (isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                              label: Text(labelText),
                              backgroundColor: isSelected ? AppColors.accent : null,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onPressed: isRestricted
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
                                        selectedBowler = player.name;
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
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('+ Enter Other / Custom Bowler Name'),
                        onPressed: () {
                          setState(() {
                            isCustomEntry = true;
                            selectedBowler = null;
                          });
                        },
                      )
                    else ...[
                      TextField(
                        controller: customController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Custom Bowler Name',
                          hintText: 'e.g. Jasprit Bumrah',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() => selectedBowler = val.trim());
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
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        String selectedTeam = homeTeamId;
        String goalKind = 'open_play';
        final scorerController = TextEditingController(text: 'Player');
        final assistController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Record Goal', style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),

                  Text('Scoring Team', style: AppTypography.body),
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

                  Text('Kind of Goal', style: AppTypography.body),
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

                  TextField(
                    controller: scorerController,
                    decoration: const InputDecoration(labelText: 'Scorer Name/No.', isDense: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: assistController,
                    decoration: const InputDecoration(labelText: 'Assist Name/No. (Optional)', isDense: true),
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
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
          content: Text(message, style: AppTypography.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
