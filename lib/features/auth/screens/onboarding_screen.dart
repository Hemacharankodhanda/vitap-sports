/// VIT-AP Sports — Onboarding screen (Apple Design System).
///
/// First-login profile setup: name, branch, year, hostel block,
/// sports multi-select, and per-sport skill levels using AppSegmented.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/frosted_bar.dart';
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
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: FrostedAppBar(
        title: Text(
          'Complete Profile',
          style: AppTypography.title.copyWith(color: colors.textPrimary),
        ),
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
              // Welcome Header
              Text(
                'Tell us about yourself',
                style: AppTypography.largeTitle.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.68,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This helps other players on campus find and connect with you.',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Full Name
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Branch
              AppTextField(
                controller: _branchController,
                label: 'Branch',
                hint: 'e.g. CSE, ECE, ME',
                prefixIcon: Icons.school_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Branch is required' : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Year Selection
              Text(
                'Academic Year',
                style: AppTypography.callout.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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

              // Hostel Block
              Text(
                'Hostel Block',
                style: AppTypography.callout.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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
              const SizedBox(height: AppSpacing.xxl),

              // Sports Multi-Select
              Text(
                'Sports You Play',
                style: AppTypography.callout.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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

              // Skill Levels via AppSegmented per sport
              if (_selectedSports.isNotEmpty) ...[
                Text(
                  'Skill Levels',
                  style: AppTypography.callout.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < _selectedSports.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSports.elementAt(i),
                                style: AppTypography.headline.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppSegmented<String>(
                                options: _skillOptions,
                                selected: _skillLevels[_selectedSports.elementAt(i)] ?? 'Beginner',
                                height: 38,
                                labelBuilder: (lvl) => lvl,
                                onSelected: (lvl) {
                                  setState(() {
                                    _skillLevels[_selectedSports.elementAt(i)] = lvl;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (i < _selectedSports.length - 1)
                          Divider(height: 1, thickness: 0.5, color: colors.divider),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Complete Profile Button
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
