/// VIT-AP Sports — Create team screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_providers.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedSportId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
      
      final hasTeam = await ref.read(teamServiceProvider).hasTeamForSport(userId, _selectedSportId!);
      if (hasTeam) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only create one team per sport.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      
      await ref.read(teamServiceProvider).createTeam(
            name: _nameController.text.trim(),
            sportId: _selectedSportId!,
            captainId: userId,
            description: _descController.text.trim(),
          );

      ref.invalidate(teamsListProvider);
      ref.invalidate(userTeamsProvider);
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
      appBar: AppBar(title: const Text('Create Team')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
            vertical: AppSpacing.lg,
          ),
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Team Name',
              hint: 'e.g., Thunder Strikers',
              prefixIcon: Icons.groups_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Sport',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            sportsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load sports'),
              data: (sports) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: sports
                    .map((sport) => AppChip(
                          label: sport['name'] as String,
                          isSelected: _selectedSportId == sport['id'],
                          onTap: () => setState(
                            () => _selectedSportId = sport['id'] as String,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppTextField(
              controller: _descController,
              label: 'Description',
              hint: 'Tell others about your team...',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppButton(
              label: 'Create Team',
              onPressed: _handleCreate,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
