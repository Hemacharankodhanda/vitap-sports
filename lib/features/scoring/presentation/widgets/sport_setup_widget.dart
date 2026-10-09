/// VIT-AP Sports — Sport Setup Widget.
///
/// Pre-match configuration flow for Cricket, Badminton, and Football.
/// Provides selectable squad lists for opening batsmen and bowlers.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/player_option.dart';
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
  String? _selectedStriker;
  String? _selectedNonStriker;
  String? _selectedBowler;

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
    _syncDefaultPlayers();
  }

  String get _battingTeamId {
    return _cricketDecision == 'bat'
        ? _cricketTossWinner
        : (_cricketTossWinner == widget.state.homeId ? widget.state.awayId : widget.state.homeId);
  }

  String get _bowlingTeamId {
    return _battingTeamId == widget.state.homeId ? widget.state.awayId : widget.state.homeId;
  }

  String get _battingTeamName {
    return _battingTeamId == widget.state.homeId ? widget.state.homeName : widget.state.awayName;
  }

  String get _bowlingTeamName {
    return _bowlingTeamId == widget.state.homeId ? widget.state.homeName : widget.state.awayName;
  }

  List<PlayerOption> get _battingPlayers => widget.state.playersForTeam(_battingTeamId);
  List<PlayerOption> get _bowlingPlayers => widget.state.playersForTeam(_bowlingTeamId);

  void _syncDefaultPlayers() {
    final batting = _battingPlayers;
    final bowling = _bowlingPlayers;

    if (batting.isNotEmpty) {
      _selectedStriker = batting.first.name;
      _selectedNonStriker = batting.length > 1 ? batting[1].name : '${batting.first.name} (2)';
    } else {
      _selectedStriker = 'Batter 1';
      _selectedNonStriker = 'Batter 2';
    }

    if (bowling.isNotEmpty) {
      _selectedBowler = bowling.first.name;
    } else {
      _selectedBowler = 'Bowler 1';
    }
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
              onTap: () {
                setState(() {
                  _cricketTossWinner = widget.state.homeId;
                  _syncDefaultPlayers();
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: widget.state.awayName,
              isSelected: _cricketTossWinner == widget.state.awayId,
              onTap: () {
                setState(() {
                  _cricketTossWinner = widget.state.awayId;
                  _syncDefaultPlayers();
                });
              },
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
              onTap: () {
                setState(() {
                  _cricketDecision = 'bat';
                  _syncDefaultPlayers();
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Bowl First',
              isSelected: _cricketDecision == 'bowl',
              onTap: () {
                setState(() {
                  _cricketDecision = 'bowl';
                  _syncDefaultPlayers();
                });
              },
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
        const SizedBox(height: AppSpacing.lg),

        // ─── Selectable Lineup Pickers ───
        Text(
          'Opening Batters ($_battingTeamName)',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildPlayerSelectorTile(
          label: 'Striker',
          playerName: _selectedStriker,
          teamName: _battingTeamName,
          onTap: () => _openPlayerPicker(
            title: 'Select Opening Striker',
            teamName: _battingTeamName,
            players: _battingPlayers,
            currentSelection: _selectedStriker,
            excludePlayerName: _selectedNonStriker,
            onSelected: (val) => setState(() => _selectedStriker = val),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPlayerSelectorTile(
          label: 'Non-Striker',
          playerName: _selectedNonStriker,
          teamName: _battingTeamName,
          onTap: () => _openPlayerPicker(
            title: 'Select Opening Non-Striker',
            teamName: _battingTeamName,
            players: _battingPlayers,
            currentSelection: _selectedNonStriker,
            excludePlayerName: _selectedStriker,
            onSelected: (val) => setState(() => _selectedNonStriker = val),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          'Opening Bowler ($_bowlingTeamName)',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildPlayerSelectorTile(
          label: 'Opening Bowler',
          playerName: _selectedBowler,
          teamName: _bowlingTeamName,
          onTap: () => _openPlayerPicker(
            title: 'Select Opening Bowler',
            teamName: _bowlingTeamName,
            players: _bowlingPlayers,
            currentSelection: _selectedBowler,
            onSelected: (val) => setState(() => _selectedBowler = val),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSelectorTile({
    required String label,
    required String? playerName,
    required String teamName,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 22, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.caption),
                  Text(
                    playerName != null && playerName.isNotEmpty ? playerName : 'Tap to select player',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayerPicker({
    required String title,
    required String teamName,
    required List<PlayerOption> players,
    required String? currentSelection,
    required ValueChanged<String> onSelected,
    String? excludePlayerName,
  }) async {
    final available = players.where((p) => p.name != excludePlayerName).toList();
    final customCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        bool showCustom = false;
        return StatefulBuilder(
          builder: (c, setSheetState) {
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
                        const Icon(Icons.group_rounded, color: AppColors.accent, size: AppSpacing.iconNav),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
                              Text('Team: $teamName', style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (available.isNotEmpty) ...[
                      Text('Squad Players', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: available.map((p) {
                          final isSelected = p.name == currentSelection;
                          return ActionChip(
                            avatar: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                            label: Text(p.name),
                            backgroundColor: isSelected ? AppColors.accent : null,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onPressed: () {
                              onSelected(p.name);
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (!showCustom)
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('+ Enter Custom Player Name'),
                        onPressed: () => setSheetState(() => showCustom = true),
                      )
                    else ...[
                      TextField(
                        controller: customCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Custom Player Name',
                          hintText: 'e.g. Virat Kohli',
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            onSelected(val.trim());
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Use This Name',
                        onPressed: () {
                          if (customCtrl.text.trim().isNotEmpty) {
                            onSelected(customCtrl.text.trim());
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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
              label: 'Serve First',
              isSelected: _badmintonDecision == 'serve',
              onTap: () => setState(() => _badmintonDecision = 'serve'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Receive First',
              isSelected: _badmintonDecision == 'receive',
              onTap: () => setState(() => _badmintonDecision = 'receive'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Best Of', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [1, 3, 5].map((g) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: '$g Games',
                isSelected: _badmintonBestOf == g,
                onTap: () => setState(() => _badmintonBestOf = g),
              ),
            );
          }).toList(),
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
          children: [10, 15, 20, 45].map((m) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: '$m Min',
                isSelected: _footballHalfLength == m,
                onTap: () => setState(() => _footballHalfLength = m),
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
          title: Text('Extra Time (if drawn)', style: AppTypography.body),
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
          'batting_first_team_id': _battingTeamId,
          'striker_id': _selectedStriker ?? 'Batter 1',
          'non_striker_id': _selectedNonStriker ?? 'Batter 2',
          'opening_bowler_id': _selectedBowler ?? 'Bowler 1',
          'opening_striker': _selectedStriker ?? 'Batter 1',
          'opening_non_striker': _selectedNonStriker ?? 'Batter 2',
          'opening_bowler': _selectedBowler ?? 'Bowler 1',
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
