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
  String? _selectedSportId;
  String? _selectedFormat;
  String? _homeTeamId;
  String? _awayTeamId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isLoading = false;

  static const _formats = ['Friendly', 'Competitive', 'Pickup', 'Tournament'];

  @override
  void dispose() {
    _venueController.dispose();
    _oversController.dispose();
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
      
      // Determine if cricket is selected to include overs
      final sportsList = ref.read(sportsListProvider).valueOrNull ?? [];
      final isCricket = sportsList.any((s) => s['id'] == _selectedSportId && s['name'] == 'Cricket');
      
      String? finalFormat = _selectedFormat;
      if (isCricket && _oversController.text.isNotEmpty) {
        finalFormat = '${_oversController.text} Overs - ${finalFormat ?? "Match"}';
      }

      await ref.read(matchServiceProvider).createMatch(
            sportId: _selectedSportId!,
            venue: _venueController.text.trim(),
            scheduledAt: scheduledAt,
            createdBy: userId,
            format: finalFormat,
            homeTeamId: _homeTeamId,
            awayTeamId: _awayTeamId,
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
              error: (_, __) => const Text('Failed to load sports'),
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
                                _homeTeamId = null;
                                _awayTeamId = null;
                              });
                            }
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Teams Selection
            Text('Teams', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.sm),
            ref.watch(teamsListProvider).when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Failed to load teams'),
                  data: (teams) {
                    final items = teams
                        .where((t) => t.sportId == _selectedSportId)
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ))
                        .toList();

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _homeTeamId,
                          decoration: const InputDecoration(
                            labelText: 'Team 1',
                            prefixIcon: Icon(Icons.shield_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: items,
                          onChanged: (v) => setState(() => _homeTeamId = v),
                          validator: (v) => v == null ? 'Select Team 1' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          value: _awayTeamId,
                          decoration: const InputDecoration(
                            labelText: 'Team 2',
                            prefixIcon: Icon(Icons.shield_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: items,
                          onChanged: (v) => setState(() => _awayTeamId = v),
                          validator: (v) => v == null ? 'Select Team 2' : null,
                        ),
                      ],
                    );
                  },
                ),
            const SizedBox(height: AppSpacing.xl),
            
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
}
