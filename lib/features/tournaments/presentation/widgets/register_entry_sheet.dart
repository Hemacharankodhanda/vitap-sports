/// VIT-AP Sports — Register Tournament Entry BottomSheet.
///
/// Handles participant registration with scope eligibility validation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../teams/providers/team_providers.dart';
import '../../domain/models/tournament_models.dart';
import '../../providers/tournament_providers.dart';

class RegisterEntrySheet extends ConsumerStatefulWidget {
  const RegisterEntrySheet({
    required this.tournament,
    super.key,
  });

  final TournamentModel tournament;

  static Future<TournamentEntry?> show(BuildContext context, TournamentModel tournament) {
    return showModalBottomSheet<TournamentEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RegisterEntrySheet(tournament: tournament),
    );
  }

  @override
  ConsumerState<RegisterEntrySheet> createState() => _RegisterEntrySheetState();
}

class _RegisterEntrySheetState extends ConsumerState<RegisterEntrySheet> {
  final _displayNameController = TextEditingController();
  String? _selectedTeamId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  bool _isEligible(UserModel? user) {
    if (widget.tournament.scope == TournamentScope.open) return true;
    if (user == null) return false;

    if (widget.tournament.scope == TournamentScope.hostel) {
      final req = widget.tournament.eligibility['hostel_block'] as String?;
      if (req == null) return true;
      return user.hostelBlock?.toLowerCase() == req.toLowerCase();
    }
    if (widget.tournament.scope == TournamentScope.branch) {
      final req = widget.tournament.eligibility['branch'] as String?;
      if (req == null) return true;
      return user.branch?.toLowerCase() == req.toLowerCase();
    }
    if (widget.tournament.scope == TournamentScope.year) {
      final req = widget.tournament.eligibility['year']?.toString();
      if (req == null) return true;
      return user.year?.toLowerCase() == req.toLowerCase();
    }
    return true;
  }

  String _ineligibilityReason(UserModel? user) {
    if (user == null) return 'Please complete your profile to register';
    if (widget.tournament.scope == TournamentScope.hostel) {
      final hb = user.hostelBlock;
      return 'Restricted to hostel block ${widget.tournament.eligibility['hostel_block']}. Your profile: ${hb != null && hb.isNotEmpty ? hb : 'Not set'}';
    }
    if (widget.tournament.scope == TournamentScope.branch) {
      final b = user.branch;
      return 'Restricted to branch ${widget.tournament.eligibility['branch']}. Your profile: ${b != null && b.isNotEmpty ? b : 'Not set'}';
    }
    if (widget.tournament.scope == TournamentScope.year) {
      final y = user.year;
      return 'Restricted to batch ${widget.tournament.eligibility['year']}. Your profile: ${y != null && y.isNotEmpty ? y : 'Not set'}';
    }
    return 'Ineligible for this tournament scope';
  }

  Future<void> _submit(UserModel? user) async {
    if (!_isEligible(user)) return;

    final isTeam = widget.tournament.sport.toLowerCase() != 'badminton' || _selectedTeamId != null;
    if (isTeam && _selectedTeamId == null) {
      setState(() => _errorMessage = 'Please select a team to register');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(tournamentServiceProvider);
      final entry = await service.registerEntry(
        tournamentId: widget.tournament.id,
        kind: isTeam ? EntryKind.team : EntryKind.player,
        teamId: isTeam ? _selectedTeamId : null,
        userId: isTeam ? null : user?.id,
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
      );

      // Refresh entries
      ref.invalidate(tournamentEntriesProvider(widget.tournament.id));

      if (mounted) {
        Navigator.of(context).pop(entry);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.valueOrNull;
    final eligible = _isEligible(user);
    final teamsAsync = ref.watch(userTeamsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isTeamSport = widget.tournament.sport.toLowerCase() != 'badminton';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Register Entry',
                  style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ineligibility Banner
            if (!eligible) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.loss.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.loss, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, color: colors.loss, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ineligibilityReason(user),
                        style: AppTypography.caption.copyWith(color: colors.loss),
                      ),
                    ),
                  ],
                ),
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

            // Team Picker (for team sports or badminton team entry)
            if (isTeamSport) ...[
              Text(
                'Select Your Team',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              teamsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading teams: $e'),
                data: (teams) {
                  final filtered = teams.where((t) => t.sportId == widget.tournament.sportId || t.name.isNotEmpty).toList();
                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'You are not a captain or member of any team in ${widget.tournament.sport}. Create a team first to enter.',
                        style: AppTypography.caption.copyWith(color: colors.textSecondary),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedTeamId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: filtered.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTeamId = val;
                        final sel = filtered.firstWhere((t) => t.id == val);
                        _displayNameController.text = sel.name;
                      });
                    },
                    hint: const Text('Choose team'),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Display Name override
            AppTextField(
              controller: _displayNameController,
              label: 'Display Name (optional)',
              hint: isTeamSport ? 'Override team name' : (user?.name ?? 'Player Name'),
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'Confirm Registration',
              isLoading: _isLoading,
              onPressed: (!eligible || _isLoading) ? null : () => _submit(user),
            ),
          ],
        ),
      ),
    );
  }
}
