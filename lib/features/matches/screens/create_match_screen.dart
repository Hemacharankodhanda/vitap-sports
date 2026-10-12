/// VIT-AP Sports — Create match screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/providers/sport_filter_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_providers.dart';
import '../providers/match_providers.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _oversController = TextEditingController(text: '20'); // Default to T20
  final _player1CustomCtrl = TextEditingController();
  final _player2CustomCtrl = TextEditingController();
  String? _selectedSportId;
  String? _selectedFormat;
  String? _homeTeamId;
  String? _awayTeamId;
  final Set<String> _homeSelectedUserIds = {};
  final Set<String> _awaySelectedUserIds = {};
  bool _homeSquadConfigured = false;
  bool _awaySquadConfigured = false;

  // Badminton Singles / Doubles state
  String _badmintonType = 'singles'; // 'singles' or 'doubles'
  String? _selectedPlayer1Id;
  String? _selectedPlayer2Id;
  bool _isCustomP1 = false;
  bool _isCustomP2 = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isLoading = false;

  static const _formats = ['Friendly', 'Competitive', 'Pickup', 'Tournament'];

  @override
  void dispose() {
    _venueController.dispose();
    _oversController.dispose();
    _player1CustomCtrl.dispose();
    _player2CustomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _manageSquadForTeam({
    required String teamId,
    required String teamName,
    required bool isTeam1,
    bool isBadmintonDoubles = false,
  }) async {
    final team = await ref.read(teamDetailProvider(teamId).future);
    if (team == null || !mounted) return;

    final currentSelected = Set<String>.from(
      isTeam1 ? _homeSelectedUserIds : _awaySelectedUserIds,
    );
    final configured = isTeam1 ? _homeSquadConfigured : _awaySquadConfigured;
    if (!configured) {
      if (isBadmintonDoubles) {
        // For badminton doubles, take at most first 2 members initially
        for (final m in team.members.take(2)) {
          currentSelected.add(m.userId);
        }
      } else {
        for (final m in team.members) {
          currentSelected.add(m.userId);
        }
      }
    }

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) {
        final selected = Set<String>.from(currentSelected);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBadmintonDoubles
                              ? '$teamName Squad (${selected.length}/2)'
                              : '$teamName Squad (${selected.length})',
                          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!isBadmintonDoubles)
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (selected.length == team.members.length) {
                                  selected.clear();
                                } else {
                                  selected.clear();
                                  for (final m in team.members) {
                                    selected.add(m.userId);
                                  }
                                }
                              });
                            },
                            child: Text(
                              selected.length == team.members.length ? 'Deselect All' : 'Select All',
                            ),
                          ),
                      ],
                    ),
                    if (isBadmintonDoubles) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Doubles matches require exactly 2 players.',
                        style: AppTypography.caption.copyWith(
                          color: selected.length == 2
                              ? AppColors.success
                              : (selected.length > 2 ? AppColors.error : AppColors.warning),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Divider(),
                    if (team.members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('No members found in this team.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: team.members.length,
                          itemBuilder: (context, index) {
                            final member = team.members[index];
                            final isChecked = selected.contains(member.userId);
                            return CheckboxListTile(
                              title: Text(member.userName ?? 'Unknown Player'),
                              subtitle: Text(member.role.toUpperCase()),
                              value: isChecked,
                              onChanged: (val) {
                                if (isBadmintonDoubles && val == true && selected.length >= 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Badminton doubles allows only 2 players. Deselect another player first.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() {
                                  if (val == true) {
                                    selected.add(member.userId);
                                  } else {
                                    selected.remove(member.userId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: isBadmintonDoubles
                          ? 'Done (${selected.length}/2 players)'
                          : 'Done (${selected.length} players)',
                      onPressed: () {
                        if (isBadmintonDoubles && selected.length != 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                selected.length > 2
                                    ? 'More than 2 players selected. Please select only 2 players.'
                                    : 'Please select exactly 2 players for badminton doubles.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop(selected);
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

    if (result != null && mounted) {
      setState(() {
        if (isTeam1) {
          _homeSelectedUserIds
            ..clear()
            ..addAll(result);
          _homeSquadConfigured = true;
        } else {
          _awaySelectedUserIds
            ..clear()
            ..addAll(result);
          _awaySquadConfigured = true;
        }
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a sport')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      final sportsList = ref.read(sportsListProvider).valueOrNull ?? [];
      final selectedSport = sportsList.where((s) => s['id'] == _selectedSportId).firstOrNull;
      final sportName = (selectedSport?['name'] as String? ?? '').toLowerCase().trim();
      final isCricket = sportName.contains('cricket');
      final isBadminton = sportName.contains('badminton');

      String? finalFormat = _selectedFormat;
      if (isCricket && _oversController.text.isNotEmpty) {
        finalFormat = '${_oversController.text} Overs - ${finalFormat ?? "Match"}';
      }

      String? effectiveHomeTeamId = _homeTeamId;
      String? effectiveAwayTeamId = _awayTeamId;
      List<String> homePlayerIdsList = [];
      List<String> awayPlayerIdsList = [];

      if (isBadminton) {
        if (_badmintonType == 'singles') {
          final p1 = _isCustomP1 ? _player1CustomCtrl.text.trim() : _selectedPlayer1Id;
          final p2 = _isCustomP2 ? _player2CustomCtrl.text.trim() : _selectedPlayer2Id;

          if (p1 == null || p1.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select or enter Player 1')),
            );
            return;
          }
          if (p2 == null || p2.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select or enter Player 2')),
            );
            return;
          }
          if (p1.toLowerCase() == p2.toLowerCase()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Player 1 and Player 2 cannot be the same person')),
            );
            return;
          }

          effectiveHomeTeamId = null;
          effectiveAwayTeamId = null;
          homePlayerIdsList = [p1];
          awayPlayerIdsList = [p2];
          finalFormat = 'Singles - ${finalFormat ?? "Match"}';
        } else {
          // Doubles
          if (_homeTeamId == null || _awayTeamId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select both teams for doubles match')),
            );
            return;
          }
          if (_homeTeamId == _awayTeamId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Team 1 and Team 2 cannot be the same')),
            );
            return;
          }

          if (_homeSelectedUserIds.length != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _homeSelectedUserIds.length > 2
                      ? 'Team 1 has ${_homeSelectedUserIds.length} players selected. Doubles requires exactly 2 players.'
                      : 'Please select exactly 2 players for Team 1 before proceeding.',
                ),
              ),
            );
            return;
          }
          if (_awaySelectedUserIds.length != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _awaySelectedUserIds.length > 2
                      ? 'Team 2 has ${_awaySelectedUserIds.length} players selected. Doubles requires exactly 2 players.'
                      : 'Please select exactly 2 players for Team 2 before proceeding.',
                ),
              ),
            );
            return;
          }

          homePlayerIdsList = _homeSelectedUserIds.toList();
          awayPlayerIdsList = _awaySelectedUserIds.toList();
          finalFormat = 'Doubles - ${finalFormat ?? "Match"}';
        }
      } else {
        Set<String> homePlayerIds = Set<String>.from(_homeSelectedUserIds);
        if (!_homeSquadConfigured && _homeTeamId != null) {
          try {
            final t = await ref.read(teamDetailProvider(_homeTeamId!).future);
            if (t != null) {
              homePlayerIds = t.members.map((m) => m.userId).toSet();
            }
          } catch (_) {}
        }

        Set<String> awayPlayerIds = Set<String>.from(_awaySelectedUserIds);
        if (!_awaySquadConfigured && _awayTeamId != null) {
          try {
            final t = await ref.read(teamDetailProvider(_awayTeamId!).future);
            if (t != null) {
              awayPlayerIds = t.members.map((m) => m.userId).toSet();
            }
          } catch (_) {}
        }

        homePlayerIdsList = homePlayerIds.toList();
        awayPlayerIdsList = awayPlayerIds.toList();
      }

      await ref.read(matchServiceProvider).createMatch(
            sportId: _selectedSportId!,
            venue: _venueController.text.trim(),
            scheduledAt: scheduledAt,
            createdBy: userId,
            format: finalFormat,
            homeTeamId: effectiveHomeTeamId,
            awayTeamId: effectiveAwayTeamId,
            homePlayerIds: homePlayerIdsList,
            awayPlayerIds: awayPlayerIdsList,
          );

      ref.invalidate(matchesListProvider('upcoming'));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportsAsync = ref.watch(sportsListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Create Match')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
            vertical: AppSpacing.lg,
          ),
          children: [
            // Sport
            Text('Sport', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.sm),
            sportsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Failed to load sports'),
              data: (sports) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: sports
                    .map((s) => AppChip(
                          label: s['name'] as String,
                          isSelected: _selectedSportId == s['id'],
                          onTap: () {
                            if (_selectedSportId != s['id']) {
                              setState(() {
                                _selectedSportId = s['id'] as String;
                                _badmintonType = 'singles';
                                _selectedPlayer1Id = null;
                                _selectedPlayer2Id = null;
                                _player1CustomCtrl.clear();
                                _player2CustomCtrl.clear();
                                _isCustomP1 = false;
                                _isCustomP2 = false;
                                _homeTeamId = null;
                                _awayTeamId = null;
                                _homeSelectedUserIds.clear();
                                _awaySelectedUserIds.clear();
                                _homeSquadConfigured = false;
                                _awaySquadConfigured = false;
                              });
                            }
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Badminton Match Type: Singles or Doubles
            if (_isBadminton(sportsAsync.valueOrNull)) ...[
              Text('Match Type', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  AppChip(
                    label: 'Singles',
                    isSelected: _badmintonType == 'singles',
                    onTap: () {
                      setState(() {
                        _badmintonType = 'singles';
                        _homeTeamId = null;
                        _awayTeamId = null;
                        _homeSelectedUserIds.clear();
                        _awaySelectedUserIds.clear();
                      });
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Doubles',
                    isSelected: _badmintonType == 'doubles',
                    onTap: () {
                      setState(() {
                        _badmintonType = 'doubles';
                        _selectedPlayer1Id = null;
                        _selectedPlayer2Id = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // If Badminton Singles: Do not show option of teams, show option of players
            if (_isBadminton(sportsAsync.valueOrNull) && _badmintonType == 'singles') ...[
              Text('Players', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              _buildSinglesPlayersSection(),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              // Teams Selection (For cricket, football, or badminton doubles)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Teams', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
                  if (_isBadminton(sportsAsync.valueOrNull))
                    Text(
                      'Doubles: exactly 2 players per team',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ref.watch(teamsBySportProvider(_selectedSportId)).when(
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => const Text('Failed to load teams'),
                    data: (teams) {
                      final isBadmintonDoubles = _isBadminton(sportsAsync.valueOrNull) && _badmintonType == 'doubles';

                      final filteredTeams = teams
                          .where((t) => _selectedSportId == null || t.sportId == _selectedSportId)
                          .toList();
                      final items = filteredTeams
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList();

                      final homeTeamObj = filteredTeams
                          .where((t) => t.id == _homeTeamId)
                          .firstOrNull;
                      final awayTeamObj = filteredTeams
                          .where((t) => t.id == _awayTeamId)
                          .firstOrNull;

                      final sportObj = sportsAsync.valueOrNull
                          ?.where((s) => s['id'] == _selectedSportId)
                          .firstOrNull;
                      final sportName = sportObj?['name'] as String? ?? 'this sport';

                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'No teams found for $sportName.',
                                style: AppTypography.body,
                              ),
                              if (isBadmintonDoubles) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Tip: You can switch to Badminton Singles above to play immediately without teams.',
                                  style: AppTypography.caption.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: Text('Create a $sportName Team'),
                                onPressed: () => context.push('/teams/create'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('team1_${_selectedSportId}_${_homeTeamId}_${items.length}'),
                            initialValue: _homeTeamId,
                            decoration: const InputDecoration(
                              labelText: 'Team 1',
                              prefixIcon: Icon(Icons.shield_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: items,
                            onChanged: (v) {
                              setState(() {
                                _homeTeamId = v;
                                _homeSelectedUserIds.clear();
                                _homeSquadConfigured = false;
                              });
                            },
                            validator: (v) => v == null ? 'Select Team 1' : null,
                          ),
                          if (_homeTeamId != null && homeTeamObj != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.group_outlined, size: 18),
                                    label: Text(
                                      _homeSquadConfigured
                                          ? 'Manage ${homeTeamObj.name} Squad (${_homeSelectedUserIds.length}${isBadmintonDoubles ? '/2' : ''})'
                                          : 'Manage ${homeTeamObj.name} Squad',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => _manageSquadForTeam(
                                      teamId: _homeTeamId!,
                                      teamName: homeTeamObj.name,
                                      isTeam1: true,
                                      isBadmintonDoubles: isBadmintonDoubles,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isBadmintonDoubles) ...[
                              const SizedBox(height: 2),
                              Text(
                                _homeSelectedUserIds.length == 2
                                    ? '✓ 2 players selected for doubles'
                                    : (_homeSelectedUserIds.length > 2
                                        ? '⚠ ${_homeSelectedUserIds.length} players selected (must be exactly 2)'
                                        : '⚠ ${_homeSelectedUserIds.length}/2 players selected (please select 2)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _homeSelectedUserIds.length == 2
                                      ? AppColors.success
                                      : (_homeSelectedUserIds.length > 2 ? AppColors.error : AppColors.warning),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            key: ValueKey('team2_${_selectedSportId}_${_awayTeamId}_${items.length}'),
                            initialValue: _awayTeamId,
                            decoration: const InputDecoration(
                              labelText: 'Team 2',
                              prefixIcon: Icon(Icons.shield_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: items,
                            onChanged: (v) {
                              setState(() {
                                _awayTeamId = v;
                                _awaySelectedUserIds.clear();
                                _awaySquadConfigured = false;
                              });
                            },
                            validator: (v) => v == null ? 'Select Team 2' : null,
                          ),
                          if (_awayTeamId != null && awayTeamObj != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.group_outlined, size: 18),
                                    label: Text(
                                      _awaySquadConfigured
                                          ? 'Manage ${awayTeamObj.name} Squad (${_awaySelectedUserIds.length}${isBadmintonDoubles ? '/2' : ''})'
                                          : 'Manage ${awayTeamObj.name} Squad',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => _manageSquadForTeam(
                                      teamId: _awayTeamId!,
                                      teamName: awayTeamObj.name,
                                      isTeam1: false,
                                      isBadmintonDoubles: isBadmintonDoubles,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isBadmintonDoubles) ...[
                              const SizedBox(height: 2),
                              Text(
                                _awaySelectedUserIds.length == 2
                                    ? '✓ 2 players selected for doubles'
                                    : (_awaySelectedUserIds.length > 2
                                        ? '⚠ ${_awaySelectedUserIds.length} players selected (must be exactly 2)'
                                        : '⚠ ${_awaySelectedUserIds.length}/2 players selected (please select 2)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _awaySelectedUserIds.length == 2
                                      ? AppColors.success
                                      : (_awaySelectedUserIds.length > 2 ? AppColors.error : AppColors.warning),
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
              const SizedBox(height: AppSpacing.xl),
            ],
            
            // Check if Cricket is selected to show Overs input
            if (sportsAsync.valueOrNull?.any((s) => s['id'] == _selectedSportId && s['name'] == 'Cricket') ?? false) ...[
              AppTextField(
                controller: _oversController,
                label: 'Overs',
                hint: 'e.g., 20',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sports_cricket_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Overs are required for Cricket' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Venue
            AppTextField(
              controller: _venueController,
              label: 'Venue',
              hint: 'e.g., Ground A, Indoor Court',
              prefixIcon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Date',
                    hint: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    readOnly: true,
                    onTap: _pickDate,
                    prefixIcon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'Time',
                    hint: _selectedTime.format(context),
                    readOnly: true,
                    onTap: _pickTime,
                    prefixIcon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Format
            Text('Format', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _formats
                  .map((f) => AppChip(
                        label: f,
                        isSelected: _selectedFormat == f,
                        onTap: () => setState(() => _selectedFormat = f),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppButton(
              label: 'Create Match',
              onPressed: _handleCreate,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  bool _isBadminton(List<Map<String, dynamic>>? sports) {
    if (sports == null || _selectedSportId == null) return false;
    return sports.any((s) =>
        s['id'] == _selectedSportId &&
        (s['name'] as String? ?? '').toLowerCase().trim().contains('badminton'));
  }

  Widget _buildSinglesPlayersSection() {
    final playersAsync = ref.watch(playersForSportProvider(_selectedSportId));

    return playersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => _buildCustomPlayersFallback(),
      data: (players) {
        if (players.isEmpty) {
          return _buildCustomPlayersFallback(
            note: 'No registered players found in system. Enter player names manually below:',
          );
        }

        final playerItems = players
            .map((p) => DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(
                    p['name'] as String? ?? 'Player',
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList();

        final validP1 = players.any((p) => p['id'] == _selectedPlayer1Id) ? _selectedPlayer1Id : null;
        final validP2 = players.any((p) => p['id'] == _selectedPlayer2Id) ? _selectedPlayer2Id : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Player 1
            if (!_isCustomP1) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('p1_${_selectedSportId}_${validP1}_${playerItems.length}'),
                initialValue: validP1,
                decoration: InputDecoration(
                  labelText: 'Player 1',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomP1 = true;
                        _selectedPlayer1Id = null;
                      });
                    },
                    child: const Text('Custom', style: TextStyle(fontSize: 12)),
                  ),
                ),
                items: playerItems,
                onChanged: (v) => setState(() => _selectedPlayer1Id = v),
                validator: (v) => v == null ? 'Select Player 1' : null,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _player1CustomCtrl,
                      label: 'Player 1 Name',
                      hint: 'e.g., P.V. Sindhu',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter Player 1 name' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomP1 = false;
                        _player1CustomCtrl.clear();
                      });
                    },
                    child: const Text('From List', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Player 2
            if (!_isCustomP2) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('p2_${_selectedSportId}_${validP2}_${playerItems.length}'),
                initialValue: validP2,
                decoration: InputDecoration(
                  labelText: 'Player 2',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomP2 = true;
                        _selectedPlayer2Id = null;
                      });
                    },
                    child: const Text('Custom', style: TextStyle(fontSize: 12)),
                  ),
                ),
                items: playerItems,
                onChanged: (v) => setState(() => _selectedPlayer2Id = v),
                validator: (v) {
                  if (v == null) return 'Select Player 2';
                  if (v == _selectedPlayer1Id) return 'Player 2 must be different from Player 1';
                  return null;
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _player2CustomCtrl,
                      label: 'Player 2 Name',
                      hint: 'e.g., Saina Nehwal',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter Player 2 name' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomP2 = false;
                        _player2CustomCtrl.clear();
                      });
                    },
                    child: const Text('From List', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCustomPlayersFallback({String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Text(
              note,
              style: AppTypography.caption.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
        AppTextField(
          controller: _player1CustomCtrl,
          label: 'Player 1',
          hint: 'e.g., P.V. Sindhu',
          prefixIcon: Icons.person_outline,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Player 1 name' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _player2CustomCtrl,
          label: 'Player 2',
          hint: 'e.g., Saina Nehwal',
          prefixIcon: Icons.person_outline,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Player 2 name' : null,
        ),
      ],
    );
  }
}
