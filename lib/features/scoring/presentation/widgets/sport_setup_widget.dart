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
  String? _badmintonPlayer1;
  String? _badmintonPlayer2;
  final Set<String> _badmintonHomeDoubles = {};
  final Set<String> _badmintonAwayDoubles = {};

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

    final formatStr = widget.state.matchData?['format'] as String?;
    final configFormat = widget.state.config['format'] as String?;
    if (configFormat != null && configFormat.toLowerCase() == 'doubles') {
      _badmintonFormat = 'doubles';
    } else if (formatStr != null && formatStr.toLowerCase().contains('doubles')) {
      _badmintonFormat = 'doubles';
    } else if (configFormat != null && configFormat.toLowerCase() == 'singles') {
      _badmintonFormat = 'singles';
    } else if (formatStr != null && formatStr.toLowerCase().contains('singles')) {
      _badmintonFormat = 'singles';
    }

    if (formatStr != null && formatStr.contains('Overs')) {
      final oversStr = formatStr.split('Overs')[0].trim();
      final parsed = int.tryParse(oversStr);
      if (parsed != null) {
        _cricketOvers = parsed;
      }
    }

    _syncDefaultPlayers();
    _syncBadmintonPlayers();
  }

  @override
  void didUpdateWidget(covariant SportSetupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final homeChanged = widget.state.homePlayers != oldWidget.state.homePlayers;
    final awayChanged = widget.state.awayPlayers != oldWidget.state.awayPlayers;
    if (homeChanged || awayChanged) {
      if (_selectedStriker == null ||
          _selectedStriker == 'Batter 1' ||
          _selectedStriker!.contains('Player 1') ||
          !_battingPlayers.any((p) => p.id == _selectedStriker)) {
        _syncDefaultPlayers();
      }
      _syncBadmintonPlayers();
    }
  }

  void _syncBadmintonPlayers() {
    final homeList = widget.state.homePlayers;
    final awayList = widget.state.awayPlayers;

    if (homeList.isNotEmpty) {
      _badmintonPlayer1 = homeList.first.id;
    } else {
      _badmintonPlayer1 = widget.state.homeName;
    }

    if (awayList.isNotEmpty) {
      _badmintonPlayer2 = awayList.first.id;
    } else {
      _badmintonPlayer2 = widget.state.awayName;
    }

    _badmintonHomeDoubles.clear();
    for (final p in homeList.take(2)) {
      _badmintonHomeDoubles.add(p.id);
    }

    _badmintonAwayDoubles.clear();
    for (final p in awayList.take(2)) {
      _badmintonAwayDoubles.add(p.id);
    }

    if (_badmintonFormat == 'singles') {
      _badmintonTossWinner = widget.state.homeId;
    } else {
      _badmintonTossWinner = widget.state.homeId;
    }
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
      _selectedStriker = batting.first.id;
      _selectedNonStriker = batting.length > 1 ? batting[1].id : null;
    } else {
      _selectedStriker = '$_battingTeamName Player 1';
      _selectedNonStriker = '$_battingTeamName Player 2';
    }

    if (bowling.isNotEmpty) {
      _selectedBowler = bowling.first.id;
    } else {
      _selectedBowler = '$_bowlingTeamName Bowler 1';
    }
  }

  String _playerDisplayName(String? id, List<PlayerOption> list, String fallback) {
    if (id == null || id.isEmpty) return fallback;
    final match = list.where((p) => p.id == id || p.name == id).firstOrNull;
    if (match != null) return match.name;
    if (id == 'Batter 1' || id == 'Striker 1') {
      return list.isNotEmpty ? list.first.name : '$_battingTeamName Player 1';
    }
    if (id == 'Batter 2' || id == 'Non-Striker 2') {
      return list.length > 1 ? list[1].name : '$_battingTeamName Player 2';
    }
    if (id == 'Bowler 1' || id == 'Opening Bowler') {
      return _bowlingPlayers.isNotEmpty ? _bowlingPlayers.first.name : '$_bowlingTeamName Bowler 1';
    }
    return id;
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
              Icon(Icons.tune_rounded, size: AppSpacing.iconNav, color: Theme.of(context).colorScheme.primary),
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

          if (sport == 'badminton' &&
              _badmintonFormat == 'doubles' &&
              (_badmintonHomeDoubles.length != 2 || _badmintonAwayDoubles.length != 2)) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Doubles matches require exactly 2 players per team before proceeding.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

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

        // ─── Selectable Lineup Pickers ───
        Text(
          'Opening Batters ($_battingTeamName)',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildPlayerSelectorTile(
          label: 'Striker',
          playerName: _playerDisplayName(_selectedStriker, _battingPlayers, 'Striker 1'),
          teamName: _battingTeamName,
          onTap: () => _openPlayerPicker(
            title: 'Select Opening Striker',
            teamName: _battingTeamName,
            players: _battingPlayers,
            currentSelection: _selectedStriker,
            excludePlayerId: _selectedNonStriker,
            onSelected: (val) => setState(() => _selectedStriker = val),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPlayerSelectorTile(
          label: 'Non-Striker',
          playerName: _playerDisplayName(_selectedNonStriker, _battingPlayers, 'Non-Striker 2'),
          teamName: _battingTeamName,
          onTap: () => _openPlayerPicker(
            title: 'Select Opening Non-Striker',
            teamName: _battingTeamName,
            players: _battingPlayers,
            currentSelection: _selectedNonStriker,
            excludePlayerId: _selectedStriker,
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
          playerName: _playerDisplayName(_selectedBowler, _bowlingPlayers, 'Opening Bowler'),
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
            Icon(Icons.person_outline_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
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
    String? excludePlayerId,
  }) async {
    final available = players.where((p) => p.id != excludePlayerId && p.name != excludePlayerId).toList();
    final customCtrl = TextEditingController();
    bool showCustom = false;

    if (currentSelection != null &&
        currentSelection.isNotEmpty &&
        !available.any((p) => p.id == currentSelection || p.name == currentSelection)) {
      customCtrl.text = currentSelection;
      showCustom = true;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
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
                        Icon(Icons.group_rounded, color: Theme.of(context).colorScheme.primary, size: AppSpacing.iconNav),
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

                    if (!showCustom) ...[
                      if (available.isNotEmpty) ...[
                        Text('Squad Players', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: available.map((p) {
                            final isSelected = p.id == currentSelection || p.name == currentSelection;
                            return ActionChip(
                              avatar: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                              label: Text(p.name),
                              backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onPressed: () {
                                onSelected(p.id);
                                Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      TextButton.icon(
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('+ Enter Custom Player Name'),
                        onPressed: () => setSheetState(() => showCustom = true),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Custom Player Name', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          TextButton(
                            onPressed: () => setSheetState(() => showCustom = false),
                            child: const Text('← Pick from Squad'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: customCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Player Name',
                          hintText: 'e.g. Virat Kohli',
                          isDense: true,
                        ),
                        onChanged: (val) => setSheetState(() {}),
                        onSubmitted: (val) {
                          final name = val.trim();
                          if (name.isNotEmpty) {
                            final matchP = players.where((p) => p.name.toLowerCase() == name.toLowerCase()).firstOrNull;
                            onSelected(matchP?.id ?? name);
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: customCtrl.text.trim().isNotEmpty
                            ? 'Use "${customCtrl.text.trim()}"'
                            : 'Confirm Player',
                        onPressed: customCtrl.text.trim().isNotEmpty
                            ? () {
                                final name = customCtrl.text.trim();
                                final matchP = players.where((p) => p.name.toLowerCase() == name.toLowerCase()).firstOrNull;
                                onSelected(matchP?.id ?? name);
                                Navigator.pop(ctx);
                              }
                            : null,
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
    final p1Name = _playerDisplayName(_badmintonPlayer1, widget.state.homePlayers, widget.state.homeName);
    final p2Name = _playerDisplayName(_badmintonPlayer2, widget.state.awayPlayers, widget.state.awayName);

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
              onTap: () {
                setState(() {
                  _badmintonFormat = 'singles';
                  _badmintonTossWinner = widget.state.homeId;
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Doubles',
              isSelected: _badmintonFormat == 'doubles',
              onTap: () {
                setState(() {
                  _badmintonFormat = 'doubles';
                  _badmintonTossWinner = widget.state.homeId;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // If Singles: Show option of PLAYERS, not teams!
        if (_badmintonFormat == 'singles') ...[
          Text('Players', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          _buildPlayerSelectorTile(
            label: 'Player 1 (Home)',
            playerName: p1Name,
            teamName: widget.state.homeName,
            onTap: () => _openPlayerPicker(
              title: 'Select Player 1',
              teamName: widget.state.homeName,
              players: widget.state.homePlayers,
              currentSelection: _badmintonPlayer1,
              excludePlayerId: _badmintonPlayer2,
              onSelected: (val) {
                setState(() {
                  _badmintonPlayer1 = val;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPlayerSelectorTile(
            label: 'Player 2 (Away)',
            playerName: p2Name,
            teamName: widget.state.awayName,
            onTap: () => _openPlayerPicker(
              title: 'Select Player 2',
              teamName: widget.state.awayName,
              players: widget.state.awayPlayers,
              currentSelection: _badmintonPlayer2,
              excludePlayerId: _badmintonPlayer1,
              onSelected: (val) {
                setState(() {
                  _badmintonPlayer2 = val;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Toss Winner', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              AppChip(
                label: p1Name,
                isSelected: _badmintonTossWinner == widget.state.homeId || _badmintonTossWinner == _badmintonPlayer1,
                onTap: () => setState(() => _badmintonTossWinner = widget.state.homeId),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: p2Name,
                isSelected: _badmintonTossWinner == widget.state.awayId || _badmintonTossWinner == _badmintonPlayer2,
                onTap: () => setState(() => _badmintonTossWinner = widget.state.awayId),
              ),
            ],
          ),
        ] else ...[
          // If Doubles: Show Teams and require exactly 2 players per team!
          Text(
            '${widget.state.homeName} Pair (${_badmintonHomeDoubles.length}/2)',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildDoublesPairCard(
            teamName: widget.state.homeName,
            isHome: true,
            selectedPlayerIds: _badmintonHomeDoubles,
            availablePlayers: widget.state.homePlayers,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            '${widget.state.awayName} Pair (${_badmintonAwayDoubles.length}/2)',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildDoublesPairCard(
            teamName: widget.state.awayName,
            isHome: false,
            selectedPlayerIds: _badmintonAwayDoubles,
            availablePlayers: widget.state.awayPlayers,
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
        ],

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

  Widget _buildDoublesPairCard({
    required String teamName,
    required bool isHome,
    required Set<String> selectedPlayerIds,
    required List<PlayerOption> availablePlayers,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = selectedPlayerIds.length == 2;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isReady
              ? AppColors.success.withAlpha(120)
              : (selectedPlayerIds.length > 2 ? AppColors.error : AppColors.warning),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isReady
                    ? '✓ 2 players selected'
                    : (selectedPlayerIds.length > 2
                        ? '⚠ ${selectedPlayerIds.length} players (must be 2)'
                        : '⚠ ${selectedPlayerIds.length}/2 players selected'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isReady
                      ? AppColors.success
                      : (selectedPlayerIds.length > 2 ? AppColors.error : AppColors.warning),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Manage Pair', style: TextStyle(fontSize: 12)),
                onPressed: () => _openDoublesSquadPicker(
                  teamName: teamName,
                  availablePlayers: availablePlayers,
                  currentSelected: selectedPlayerIds,
                  onConfirm: (res) {
                    setState(() {
                      if (isHome) {
                        _badmintonHomeDoubles
                          ..clear()
                          ..addAll(res);
                      } else {
                        _badmintonAwayDoubles
                          ..clear()
                          ..addAll(res);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          if (selectedPlayerIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: selectedPlayerIds.map((id) {
                final match = availablePlayers.where((p) => p.id == id).firstOrNull;
                return Chip(
                  avatar: const Icon(Icons.person, size: 14),
                  label: Text(match?.name ?? id, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDoublesSquadPicker({
    required String teamName,
    required List<PlayerOption> availablePlayers,
    required Set<String> currentSelected,
    required ValueChanged<Set<String>> onConfirm,
  }) async {
    final customCtrl = TextEditingController();
    bool showCustom = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        final selected = Set<String>.from(currentSelected);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$teamName Pair (${selected.length}/2)', style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          selected.length == 2 ? 'Ready' : 'Must be exactly 2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected.length == 2 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (!showCustom) ...[
                      if (availablePlayers.isNotEmpty) ...[
                        Text('Select 2 players for this pair:', style: AppTypography.caption),
                        const SizedBox(height: AppSpacing.xs),
                        ...availablePlayers.map((p) {
                          final isChecked = selected.contains(p.id) || selected.contains(p.name);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(p.name),
                            value: isChecked,
                            onChanged: (val) {
                              if (val == true && selected.length >= 2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Doubles pair can only have 2 players. Deselect another player first.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() {
                                if (val == true) {
                                  selected.add(p.id);
                                } else {
                                  selected.remove(p.id);
                                  selected.remove(p.name);
                                }
                              });
                            },
                          );
                        }),
                      ],
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('+ Enter Custom Player Name'),
                        onPressed: () => setSheetState(() => showCustom = true),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Custom Player Name', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          TextButton(
                            onPressed: () => setSheetState(() => showCustom = false),
                            child: const Text('← Pick from Squad'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: customCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Player Name',
                          hintText: 'e.g. Lakshya Sen',
                          isDense: true,
                        ),
                        onChanged: (val) => setSheetState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Add to Pair',
                        onPressed: customCtrl.text.trim().isNotEmpty && selected.length < 2
                            ? () {
                                setSheetState(() {
                                  selected.add(customCtrl.text.trim());
                                  customCtrl.clear();
                                  showCustom = false;
                                });
                              }
                            : null,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Confirm Pair (${selected.length}/2)',
                      onPressed: selected.length == 2
                          ? () {
                              onConfirm(selected);
                              Navigator.pop(ctx);
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
        final batting = _battingPlayers;
        final bowling = _bowlingPlayers;

        String strikerId = _selectedStriker ?? '';
        if (strikerId.isEmpty || strikerId == 'Batter 1' || strikerId == 'Striker 1') {
          strikerId = batting.isNotEmpty ? batting.first.id : '$_battingTeamName Player 1';
        }
        String nonStrikerId = _selectedNonStriker ?? '';
        if (nonStrikerId.isEmpty || nonStrikerId == 'Batter 2' || nonStrikerId == 'Non-Striker 2') {
          nonStrikerId = batting.length > 1 ? batting[1].id : '$_battingTeamName Player 2';
        }
        String bowlerId = _selectedBowler ?? '';
        if (bowlerId.isEmpty || bowlerId == 'Bowler 1' || bowlerId == 'Opening Bowler') {
          bowlerId = bowling.isNotEmpty ? bowling.first.id : '$_bowlingTeamName Bowler 1';
        }

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
          'striker_id': strikerId,
          'non_striker_id': nonStrikerId,
          'opening_bowler_id': bowlerId,
          'opening_striker': strikerId,
          'opening_non_striker': nonStrikerId,
          'opening_bowler': bowlerId,
        };
        await widget.onStartMatch(config: config, extra: extra);
      } else if (sport == 'badminton') {
        if (_badmintonFormat == 'doubles') {
          if (_badmintonHomeDoubles.length != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _badmintonHomeDoubles.length > 2
                      ? '${widget.state.homeName} has ${_badmintonHomeDoubles.length} players. Doubles requires exactly 2 players.'
                      : 'Please select exactly 2 players for ${widget.state.homeName} before proceeding.',
                ),
              ),
            );
            return;
          }
          if (_badmintonAwayDoubles.length != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _badmintonAwayDoubles.length > 2
                      ? '${widget.state.awayName} has ${_badmintonAwayDoubles.length} players. Doubles requires exactly 2 players.'
                      : 'Please select exactly 2 players for ${widget.state.awayName} before proceeding.',
                ),
              ),
            );
            return;
          }
        }

        final config = {
          'format': _badmintonFormat,
          'best_of_games': _badmintonBestOf,
          'points_per_game': 21,
          'cap': 30,
        };

        final homeList = _badmintonFormat == 'doubles'
            ? _badmintonHomeDoubles.toList()
            : [_badmintonPlayer1 ?? widget.state.homeId];
        final awayList = _badmintonFormat == 'doubles'
            ? _badmintonAwayDoubles.toList()
            : [_badmintonPlayer2 ?? widget.state.awayId];

        final bool isHomeTossWinner = _badmintonFormat == 'singles'
            ? (_badmintonTossWinner == widget.state.homeId || _badmintonTossWinner == _badmintonPlayer1)
            : (_badmintonTossWinner == widget.state.homeId);

        final tossWinnerTeamId = isHomeTossWinner ? widget.state.homeId : widget.state.awayId;
        final tossLoserTeamId = isHomeTossWinner ? widget.state.awayId : widget.state.homeId;

        final serverSide = _badmintonDecision == 'serve' ? tossWinnerTeamId : tossLoserTeamId;

        final firstServerId = serverSide == widget.state.homeId
            ? homeList.first
            : awayList.first;

        final extra = {
          'first_server_id': firstServerId,
          'first_server_team_id': serverSide,
          'home_players': homeList,
          'away_players': awayList,
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
