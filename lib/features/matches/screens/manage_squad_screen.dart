/// VIT-AP Sports — Manage squad screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../teams/providers/team_providers.dart';
import '../providers/match_providers.dart';

class ManageSquadScreen extends ConsumerStatefulWidget {
  const ManageSquadScreen({
    super.key,
    required this.matchId,
    required this.teamId,
    required this.side,
  });

  final String matchId;
  final String teamId;
  final String side; // 'home' or 'away'

  @override
  ConsumerState<ManageSquadScreen> createState() => _ManageSquadScreenState();
}

class _ManageSquadScreenState extends ConsumerState<ManageSquadScreen> {
  final Set<String> _selectedUserIds = {};
  bool _isSaving = false;
  bool _isInitialized = false;

  void _initializeSelection(List<dynamic> matchParticipants) {
    if (_isInitialized) return;
    for (final p in matchParticipants) {
      if (p.teamId == widget.teamId && p.userId != null) {
        _selectedUserIds.add(p.userId!);
      }
    }
    _isInitialized = true;
  }

  Future<void> _saveSquad() async {
    final match = ref.read(matchDetailProvider(widget.matchId)).valueOrNull;
    final isBadminton = match?.sportName?.toLowerCase() == 'badminton';
    final isDoubles = (match?.format?.toLowerCase().contains('doubles') ?? false) ||
        (match?.config?['format'] == 'doubles');

    if (isBadminton && isDoubles && _selectedUserIds.length != 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedUserIds.length > 2
                  ? 'Badminton doubles teams cannot have more than two players. Please select only two.'
                  : 'Badminton doubles requires exactly 2 players (currently ${_selectedUserIds.length}).',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(matchServiceProvider).setPlayingSquad(
            matchId: widget.matchId,
            teamId: widget.teamId,
            side: widget.side,
            userIds: _selectedUserIds.toList(),
          );
      ref.invalidate(matchDetailProvider(widget.matchId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving squad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    if (teamAsync.isLoading || matchAsync.isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }
    
    if (teamAsync.hasError || matchAsync.hasError) {
      return const Scaffold(body: ErrorView(message: 'Failed to load data'));
    }
    
    final team = teamAsync.valueOrNull;
    final match = matchAsync.valueOrNull;
    
    if (team == null || match == null) {
      return const Scaffold(body: ErrorView(message: 'Not found'));
    }

    final isBadminton = match.sportName?.toLowerCase() == 'badminton';
    final isDoubles = (match.format?.toLowerCase().contains('doubles') ?? false) ||
        (match.config?['format'] == 'doubles');

    _initializeSelection(match.participants);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBadminton && isDoubles
              ? '${team.name} Squad (${_selectedUserIds.length}/2)'
              : '${team.name} Squad (${_selectedUserIds.length})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveSquad,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: team.members.length,
        itemBuilder: (context, index) {
          final member = team.members[index];
          final isSelected = _selectedUserIds.contains(member.userId);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: CheckboxListTile(
                title: Text(member.userName ?? 'Unknown User'),
                subtitle: Text(member.role.toUpperCase()),
                value: isSelected,
                onChanged: (checked) {
                  if (isBadminton && isDoubles && checked == true && _selectedUserIds.length >= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Doubles pair can only have 2 players. Deselect another player first.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    if (checked == true) {
                      _selectedUserIds.add(member.userId);
                    } else {
                      _selectedUserIds.remove(member.userId);
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: isBadminton && isDoubles
                ? 'Save Squad (${_selectedUserIds.length}/2 players)'
                : 'Save Squad',
            onPressed: _saveSquad,
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }
}
