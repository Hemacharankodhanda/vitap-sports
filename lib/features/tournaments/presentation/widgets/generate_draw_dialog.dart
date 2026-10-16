/// VIT-AP Sports — Generate Draw Dialog.
///
/// Organiser wizard for previewing and committing tournament draws using
/// pure-Dart generator engines.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/tournament_models.dart';
import '../../engines/group_stage_engine.dart';
import '../../engines/knockout_bracket_engine.dart';
import '../../engines/round_robin_engine.dart';
import '../../providers/tournament_providers.dart';

class GenerateDrawDialog extends ConsumerStatefulWidget {
  const GenerateDrawDialog({
    required this.tournament,
    required this.entries,
    super.key,
  });

  final TournamentModel tournament;
  final List<TournamentEntry> entries;

  static Future<bool?> show(
    BuildContext context, {
    required TournamentModel tournament,
    required List<TournamentEntry> entries,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => GenerateDrawDialog(
        tournament: tournament,
        entries: entries,
      ),
    );
  }

  @override
  ConsumerState<GenerateDrawDialog> createState() => _GenerateDrawDialogState();
}

class _GenerateDrawDialogState extends ConsumerState<GenerateDrawDialog> {
  bool _useRandomSeeds = false;
  int? _randomSeed;
  bool _includeThirdPlace = true;
  int _groupsCount = 2;
  int _qualifiersPerGroup = 2;

  bool _isCommitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _randomSeed = Random().nextInt(100000);
  }

  Future<void> _commit() async {
    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    try {
      final tId = widget.tournament.id;
      List<TournamentFixture> fixtures = [];
      List<TournamentGroup> groups = [];

      switch (widget.tournament.format) {
        case TournamentFormat.knockout:
          const engine = KnockoutBracketEngine();
          fixtures = engine.generateBracket(
            tournamentId: tId,
            entries: widget.entries,
            includeThirdPlace: _includeThirdPlace,
            randomSeed: _useRandomSeeds ? _randomSeed : null,
          );
          break;

        case TournamentFormat.league:
          const engine = RoundRobinEngine();
          fixtures = engine.generateSchedule(
            tournamentId: tId,
            entries: widget.entries,
            doubleRoundRobin: false,
          );
          break;

        case TournamentFormat.groupsKnockout:
          const engine = GroupStageEngine();
          final res = engine.setupGroupStage(
            tournamentId: tId,
            entries: widget.entries,
            groupsCount: _groupsCount,
            qualifiersPerGroup: _qualifiersPerGroup,
            includeThirdPlace: _includeThirdPlace,
          );
          fixtures = [...res.groupFixtures, ...res.knockoutFixtures];
          groups = res.groups;
          break;
      }

      final service = ref.read(tournamentServiceProvider);
      await service.generateDraw(
        tournamentId: tId,
        fixtures: fixtures,
        groups: groups,
      );

      // Invalidate providers
      ref.invalidate(tournamentDetailProvider(tId));
      ref.invalidate(tournamentFixturesProvider(tId));
      ref.invalidate(tournamentGroupsProvider(tId));
      ref.invalidate(tournamentStandingsProvider(tId));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isCommitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entryCount = widget.entries.length;
    final canGenerate = entryCount >= 2;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Generate Tournament Draw',
        style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrants: $entryCount registered',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: canGenerate ? AppColors.win : colors.loss,
                ),
              ),
              const SizedBox(height: 12),

              if (!canGenerate) ...[
                Text(
                  'At least 2 approved entries are required to generate the draw.',
                  style: AppTypography.caption.copyWith(color: colors.loss),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.loss.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.loss, width: 0.8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.caption.copyWith(color: colors.loss),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Format-specific options
              if (widget.tournament.format == TournamentFormat.knockout) ...[
                SwitchListTile.adaptive(
                  title: Text('Random Seeding', style: AppTypography.body),
                  subtitle: Text(
                    _useRandomSeeds ? 'Shuffled with seed $_randomSeed' : 'Seeded by entrant seed ranking',
                    style: AppTypography.caption,
                  ),
                  value: _useRandomSeeds,
                  onChanged: (val) => setState(() => _useRandomSeeds = val),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  title: Text('Third-place Playoff', style: AppTypography.body),
                  subtitle: Text('Add match for semi-final losers', style: AppTypography.caption),
                  value: _includeThirdPlace,
                  onChanged: (val) => setState(() => _includeThirdPlace = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ] else if (widget.tournament.format == TournamentFormat.groupsKnockout) ...[
                Text('Number of Groups', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [2, 4].map((g) {
                    final isSel = _groupsCount == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$g Groups'),
                        selected: isSel,
                        onSelected: (_) => setState(() => _groupsCount = g),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Qualifiers per Group', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2].map((q) {
                    final isSel = _qualifiersPerGroup == q;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Top $q'),
                        selected: isSel,
                        onSelected: (_) => setState(() => _qualifiersPerGroup = q),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCommitting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        AppButton(
          label: 'Commit Draw',
          isLoading: _isCommitting,
          onPressed: (!canGenerate || _isCommitting) ? null : _commit,
        ),
      ],
    );
  }
}
