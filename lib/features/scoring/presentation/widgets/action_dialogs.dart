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

class ActionDialogs {
  ActionDialogs._();

  /// Prompt for Cricket Wicket details
  static Future<Map<String, dynamic>?> showWicketSheet({
    required BuildContext context,
    required String strikerId,
    required String nonStrikerId,
    required bool isFreeHit,
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
        final newBatterController = TextEditingController(text: 'Batter');
        int runOutRuns = 0;
        bool battersCrossed = false;

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
                      TextField(
                        controller: fielderController,
                        decoration: const InputDecoration(
                          labelText: 'Fielder Name / Number (Optional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    TextField(
                      controller: newBatterController,
                      decoration: const InputDecoration(
                        labelText: 'Next Batter Name (Optional)',
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

  /// Prompt for selecting new bowler
  static Future<String?> showBowlerSheet({
    required BuildContext context,
    required List<String> previousBowlerIds,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        final controller = TextEditingController(text: 'Bowler');

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select Next Bowler', style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Bowler Name or Number',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Confirm Bowler',
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) Navigator.pop(ctx, text);
                },
              ),
            ],
          ),
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
