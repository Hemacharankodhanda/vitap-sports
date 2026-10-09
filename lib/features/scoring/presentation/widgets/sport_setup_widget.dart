/// VIT-AP Sports — Sport Setup Widget.
///
/// Pre-match configuration flow for Cricket, Badminton, and Football.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../providers/live_scorer_providers.dart';

class SportSetupWidget extends StatefulWidget {
  const SportSetupWidget({
    super.key,
    required this.state,
    required this.onStartMatch,
  });

  final ScorerState state;
  final Future<void> Function({
    required Map<String, dynamic> config,
    Map<String, dynamic>? extra,
  }) onStartMatch;

  @override
  State<SportSetupWidget> createState() => _SportSetupWidgetState();
}

class _SportSetupWidgetState extends State<SportSetupWidget> {
  // Cricket state
  late String _cricketTossWinner;
  String _cricketDecision = 'bat'; // 'bat' or 'bowl'
  int _cricketOvers = 6;
  final TextEditingController _strikerController = TextEditingController(text: 'Batter 1');
  final TextEditingController _nonStrikerController = TextEditingController(text: 'Batter 2');
  final TextEditingController _bowlerController = TextEditingController(text: 'Bowler 1');

  // Badminton state
  String _badmintonFormat = 'singles';
  late String _badmintonTossWinner;
  String _badmintonDecision = 'serve'; // 'serve' or 'receive'
  int _badmintonBestOf = 3;

  // Football state
  int _footballHalfLength = 20;
  late String _footballKickoffTeam;
  bool _footballExtraTime = false;
  bool _footballShootout = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cricketTossWinner = widget.state.homeId;
    _badmintonTossWinner = widget.state.homeId;
    _footballKickoffTeam = widget.state.homeId;
  }

  @override
  void dispose() {
    _strikerController.dispose();
    _nonStrikerController.dispose();
    _bowlerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sport = widget.state.sport.toLowerCase();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: AppSpacing.iconNav, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pre-Match Setup',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (sport == 'cricket')
            _buildCricketSetup()
          else if (sport == 'badminton')
            _buildBadmintonSetup()
          else if (sport == 'football')
            _buildFootballSetup()
          else
            const Text('Configure rules to begin.'),

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Start Live Match',
            icon: Icons.play_arrow_rounded,
            isLoading: _isSubmitting,
            onPressed: _handleStart,
          ),
        ],
      ),
    );
  }

  Widget _buildCricketSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Toss Winner', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: widget.state.homeName,
              isSelected: _cricketTossWinner == widget.state.homeId,
              onTap: () => setState(() => _cricketTossWinner = widget.state.homeId),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: widget.state.awayName,
              isSelected: _cricketTossWinner == widget.state.awayId,
              onTap: () => setState(() => _cricketTossWinner = widget.state.awayId),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Elected To', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: 'Bat First',
              isSelected: _cricketDecision == 'bat',
              onTap: () => setState(() => _cricketDecision = 'bat'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Bowl First',
              isSelected: _cricketDecision == 'bowl',
              onTap: () => setState(() => _cricketDecision = 'bowl'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Overs Per Innings', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [4, 6, 10, 20].map((ov) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: '$ov Ov',
                isSelected: _cricketOvers == ov,
                onTap: () => setState(() => _cricketOvers = ov),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // Lineup inputs
        Text('Opening Striker', style: AppTypography.caption),
        TextField(
          controller: _strikerController,
          decoration: const InputDecoration(isDense: true),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Opening Non-Striker', style: AppTypography.caption),
        TextField(
          controller: _nonStrikerController,
          decoration: const InputDecoration(isDense: true),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Opening Bowler', style: AppTypography.caption),
        TextField(
          controller: _bowlerController,
          decoration: const InputDecoration(isDense: true),
        ),
      ],
    );
  }

  Widget _buildBadmintonSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match Format', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: 'Singles',
              isSelected: _badmintonFormat == 'singles',
              onTap: () => setState(() => _badmintonFormat = 'singles'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Doubles',
              isSelected: _badmintonFormat == 'doubles',
              onTap: () => setState(() => _badmintonFormat = 'doubles'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Toss Winner', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: widget.state.homeName,
              isSelected: _badmintonTossWinner == widget.state.homeId,
              onTap: () => setState(() => _badmintonTossWinner = widget.state.homeId),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: widget.state.awayName,
              isSelected: _badmintonTossWinner == widget.state.awayId,
              onTap: () => setState(() => _badmintonTossWinner = widget.state.awayId),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Elected To', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: 'Serve',
              isSelected: _badmintonDecision == 'serve',
              onTap: () => setState(() => _badmintonDecision = 'serve'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Receive',
              isSelected: _badmintonDecision == 'receive',
              onTap: () => setState(() => _badmintonDecision = 'receive'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Games Count', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: 'Best of 3',
              isSelected: _badmintonBestOf == 3,
              onTap: () => setState(() => _badmintonBestOf = 3),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Single Game',
              isSelected: _badmintonBestOf == 1,
              onTap: () => setState(() => _badmintonBestOf = 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFootballSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Half Length', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [15, 20, 25, 45].map((mins) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: '$mins mins',
                isSelected: _footballHalfLength == mins,
                onTap: () => setState(() => _footballHalfLength = mins),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Kickoff Team', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            AppChip(
              label: widget.state.homeName,
              isSelected: _footballKickoffTeam == widget.state.homeId,
              onTap: () => setState(() => _footballKickoffTeam = widget.state.homeId),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: widget.state.awayName,
              isSelected: _footballKickoffTeam == widget.state.awayId,
              onTap: () => setState(() => _footballKickoffTeam = widget.state.awayId),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Extra Time if Drawn', style: AppTypography.body),
          value: _footballExtraTime,
          onChanged: (val) => setState(() => _footballExtraTime = val),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Penalty Shootout', style: AppTypography.body),
          value: _footballShootout,
          onChanged: (val) => setState(() => _footballShootout = val),
        ),
      ],
    );
  }

  Future<void> _handleStart() async {
    setState(() => _isSubmitting = true);
    final sport = widget.state.sport.toLowerCase();

    try {
      if (sport == 'cricket') {
        final config = {
          'overs_per_innings': _cricketOvers,
          'players_per_side': 11,
          'wides_add_run': true,
          'no_balls_add_run': true,
        };
        final extra = {
          'toss_winner': _cricketTossWinner,
          'toss_decision': _cricketDecision,
          'opening_striker': _strikerController.text.trim().isEmpty ? 'Batter 1' : _strikerController.text.trim(),
          'opening_non_striker': _nonStrikerController.text.trim().isEmpty ? 'Batter 2' : _nonStrikerController.text.trim(),
          'opening_bowler': _bowlerController.text.trim().isEmpty ? 'Bowler 1' : _bowlerController.text.trim(),
        };
        await widget.onStartMatch(config: config, extra: extra);
      } else if (sport == 'badminton') {
        final config = {
          'format': _badmintonFormat,
          'best_of_games': _badmintonBestOf,
          'points_per_game': 21,
          'cap': 30,
        };
        final serverSide = _badmintonDecision == 'serve'
            ? _badmintonTossWinner
            : (_badmintonTossWinner == widget.state.homeId ? widget.state.awayId : widget.state.homeId);
        final extra = {
          'first_server_id': serverSide,
        };
        await widget.onStartMatch(config: config, extra: extra);
      } else if (sport == 'football') {
        final config = {
          'players_per_side': 7,
          'half_length_minutes': _footballHalfLength,
          'halves': 2,
          'extra_time': _footballExtraTime,
          'shootout': _footballShootout,
        };
        await widget.onStartMatch(config: config);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
