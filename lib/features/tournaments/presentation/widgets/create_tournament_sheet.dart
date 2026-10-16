/// VIT-AP Sports — Create Tournament BottomSheet.
///
/// Multi-field dialog allowing organisers to configure tournaments, rules, and scopes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/tournament_models.dart';
import '../../providers/tournament_providers.dart';

class CreateTournamentSheet extends ConsumerStatefulWidget {
  const CreateTournamentSheet({super.key});

  static Future<TournamentModel?> show(BuildContext context) async {
    final created = await showModalBottomSheet<TournamentModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CreateTournamentSheet(),
    );

    return created;
  }

  @override
  ConsumerState<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends ConsumerState<CreateTournamentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scopeValueController = TextEditingController();

  String _selectedSport = 'cricket';
  TournamentFormat _selectedFormat = TournamentFormat.knockout;
  TournamentScope _selectedScope = TournamentScope.open;
  int _maxEntries = 8;
  bool _openRegistrationImmediately = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _scopeValueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eligibility = <String, dynamic>{};
      if (_selectedScope == TournamentScope.hostel && _scopeValueController.text.isNotEmpty) {
        eligibility['hostel_block'] = _scopeValueController.text.trim();
      } else if (_selectedScope == TournamentScope.branch && _scopeValueController.text.isNotEmpty) {
        eligibility['branch'] = _scopeValueController.text.trim();
      } else if (_selectedScope == TournamentScope.year && _scopeValueController.text.isNotEmpty) {
        eligibility['year'] = _scopeValueController.text.trim();
      }

      final service = ref.read(tournamentServiceProvider);
      var created = await service.createTournament(
        name: _nameController.text.trim(),
        sport: _selectedSport,
        format: _selectedFormat,
        scope: _selectedScope,
        maxEntries: _maxEntries,
        eligibility: eligibility,
      );

      if (_openRegistrationImmediately) {
        try {
          created = await service.updateTournamentStatus(
            tournamentId: created.id,
            status: TournamentStatus.registrationOpen,
          );
        } catch (_) {
          // If status update RPC fails, keep initial created tournament
        }
      }

      // Refresh list
      ref.invalidate(tournamentsListProvider);

      if (mounted) {
        Navigator.of(context).pop(created);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Create Tournament',
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

              // Tournament Name
              AppTextField(
                controller: _nameController,
                label: 'Tournament Name',
                hint: 'e.g. Inter-Block Premier Cup 2026',
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Sport Selection
              Text('Sport', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _sportOption('cricket', 'Cricket', Icons.sports_cricket),
                  const SizedBox(width: 8),
                  _sportOption('football', 'Football', Icons.sports_soccer),
                  const SizedBox(width: 8),
                  _sportOption('badminton', 'Badminton', Icons.sports_tennis),
                ],
              ),
              const SizedBox(height: 16),

              // Format Selection
              Text('Format', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _formatOption(TournamentFormat.knockout, 'Knockout'),
                  const SizedBox(width: 8),
                  _formatOption(TournamentFormat.league, 'League'),
                  const SizedBox(width: 8),
                  _formatOption(TournamentFormat.groupsKnockout, 'Groups + KO'),
                ],
              ),
              const SizedBox(height: 16),

              // Scope Selection
              Text('Eligibility Scope', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _scopeOption(TournamentScope.open, 'Open'),
                  const SizedBox(width: 8),
                  _scopeOption(TournamentScope.hostel, 'Hostel'),
                  const SizedBox(width: 8),
                  _scopeOption(TournamentScope.branch, 'Branch'),
                  const SizedBox(width: 8),
                  _scopeOption(TournamentScope.year, 'Year'),
                ],
              ),

              if (_selectedScope != TournamentScope.open) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _scopeValueController,
                  label: _selectedScope == TournamentScope.hostel
                      ? 'Hostel Block'
                      : (_selectedScope == TournamentScope.branch ? 'Branch Code' : 'Batch Year'),
                  hint: _selectedScope == TournamentScope.hostel
                      ? 'e.g. MH-1, LH-2'
                      : (_selectedScope == TournamentScope.branch ? 'e.g. CSE, ECE' : 'e.g. 2024'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Value required for restricted scope' : null,
                ),
              ],
              const SizedBox(height: 16),

              // Max Entries
              Text('Max Entrants', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [4, 8, 16, 32].map((size) {
                  final isSel = _maxEntries == size;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _maxEntries = size),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.accentSurface : colors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSel ? AppColors.accent : colors.border,
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '$size',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? AppColors.accent : colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Open registration immediately toggle
              SwitchListTile.adaptive(
                title: Text('Open Registration Immediately', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Allow players and teams to apply right away', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                value: _openRegistrationImmediately,
                onChanged: (val) => setState(() => _openRegistrationImmediately = val),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
              ),
              const SizedBox(height: 16),

              // Submit Button
              AppButton(
                label: 'Create Tournament',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sportOption(String key, String label, IconData icon) {
    final colors = context.appColors;
    final isSel = _selectedSport == key;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSport = key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.accentSurface : colors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSel ? AppColors.accent : colors.border,
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSel ? AppColors.accent : colors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AppColors.accent : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatOption(TournamentFormat fmt, String label) {
    final colors = context.appColors;
    final isSel = _selectedFormat == fmt;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFormat = fmt),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? AppColors.accentSurface : colors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSel ? AppColors.accent : colors.border,
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppColors.accent : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _scopeOption(TournamentScope scope, String label) {
    final colors = context.appColors;
    final isSel = _selectedScope == scope;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedScope = scope),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.accentSurface : colors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSel ? AppColors.accent : colors.border,
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppColors.accent : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
