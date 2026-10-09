/// VIT-AP Sports — Onboarding screen.
///
/// First-login profile creation: name, branch, year, hostel block,
/// sports multi-select with skill level per sport.
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
import '../../profile/providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();

  String _selectedYear = '1st Year';
  String _selectedHostel = '';
  final Set<String> _selectedSports = {};
  final Map<String, String> _skillLevels = {};
  bool _isLoading = false;

  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  static const _hostels = [
    'MH-1', 'MH-2', 'MH-3', 'MH-4', 'MH-5', 'MH-6',
    'LH-1', 'LH-2', 'LH-3',
  ];
  static const _sports = [
    'Cricket', 'Football', 'Badminton', 'Basketball',
    'Tennis', 'Table Tennis', 'Volleyball', 'Athletics',
  ];
  static const _skillOptions = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one sport')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(createProfileProvider({
        'name': _nameController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _selectedYear,
        'hostel_block': _selectedHostel,
        'sports': _selectedSports.toList(),
        'skill_levels': _skillLevels,
      }).future);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.lg,
            ),
            children: [
              // Welcome text
              Text(
                'Tell us about yourself',
                style: AppTypography.title.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This helps other players find and connect with you.',
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ─── Name ─────────────────────────────────
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Branch ───────────────────────────────
              AppTextField(
                controller: _branchController,
                label: 'Branch',
                hint: 'e.g., CSE, ECE, ME',
                prefixIcon: Icons.school_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Branch is required' : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Year ─────────────────────────────────
              Text(
                'Year',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _years
                    .map((year) => AppChip(
                          label: year,
                          isSelected: _selectedYear == year,
                          onTap: () => setState(() => _selectedYear = year),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Hostel Block ─────────────────────────
              Text(
                'Hostel Block',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _hostels
                    .map((hostel) => AppChip(
                          label: hostel,
                          isSelected: _selectedHostel == hostel,
                          onTap: () =>
                              setState(() => _selectedHostel = hostel),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Sports ───────────────────────────────
              Text(
                'Sports You Play',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _sports
                    .map((sport) => AppChip(
                          label: sport,
                          isSelected: _selectedSports.contains(sport),
                          onTap: () {
                            setState(() {
                              if (_selectedSports.contains(sport)) {
                                _selectedSports.remove(sport);
                                _skillLevels.remove(sport);
                              } else {
                                _selectedSports.add(sport);
                                _skillLevels[sport] = 'Beginner';
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Skill Levels ─────────────────────────
              if (_selectedSports.isNotEmpty) ...[
                Text(
                  'Skill Level',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._selectedSports.map((sport) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              sport,
                              style: AppTypography.body.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: _skillOptions
                                  .map((level) => Expanded(
                                        child: AppChip(
                                          label: level,
                                          isSelected:
                                              _skillLevels[sport] == level,
                                          onTap: () => setState(() =>
                                              _skillLevels[sport] = level),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.lg),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // ─── Submit ───────────────────────────────
              AppButton(
                label: 'Complete Profile',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
