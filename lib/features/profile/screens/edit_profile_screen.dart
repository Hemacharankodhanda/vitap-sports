/// VIT-AP Sports — Edit profile screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_service.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();

  String _selectedYear = '1st Year';
  String _selectedHostel = '';
  final Set<String> _selectedSports = {};
  final Map<String, String> _skillLevels = {};
  bool _isLoading = false;
  bool _initialized = false;

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

  void _initFromProfile() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile != null && !_initialized) {
      _nameController.text = profile.name;
      _branchController.text = profile.branch ?? '';
      _selectedYear = profile.year ?? '1st Year';
      _selectedHostel = profile.hostelBlock ?? '';
      for (final sport in profile.sports) {
        _selectedSports.add(sport.sportName);
        _skillLevels[sport.sportName] = sport.skillLevel;
      }
      _initialized = true;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      final service = ref.read(profileServiceProvider);

      await service.updateProfile(userId, {
        'name': _nameController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _selectedYear,
        'hostel_block': _selectedHostel,
      });

      await service.updateUserSports(
        userId,
        _selectedSports.toList(),
        _skillLevels,
      );

      ref.invalidate(currentProfileProvider);
      if (mounted) context.pop();
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

  Future<void> _handleAvatarChange() async {
    final imageData = await ImageUtils.pickAndCompressImage();
    if (imageData == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      final service = ref.read(profileServiceProvider);
      final url = await service.uploadAvatar(userId, imageData);
      await service.updateProfile(userId, {'avatar_url': url});
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const ErrorView(message: 'Profile not found');
          }

          _initFromProfile();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.lg,
              ),
              children: [
                // ─── Avatar ─────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _handleAvatarChange,
                    child: Stack(
                      children: [
                        AppAvatar(
                          imageUrl: profile.avatarUrl,
                          name: profile.name,
                          size: AppAvatarSize.xlarge,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ─── Name ───────────────────────────────
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Branch ─────────────────────────────
                AppTextField(
                  controller: _branchController,
                  label: 'Branch',
                  hint: 'e.g., CSE, ECE',
                  prefixIcon: Icons.school_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Year ───────────────────────────────
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

                // ─── Hostel ─────────────────────────────
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

                // ─── Sports ─────────────────────────────
                Text(
                  'Sports',
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

                // ─── Skill Levels ───────────────────────
                if (_selectedSports.isNotEmpty) ...[
                  Text(
                    'Skill Levels',
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
                              child: Text(sport, style: AppTypography.body),
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
                ],
                const SizedBox(height: AppSpacing.xxl),

                // ─── Save ───────────────────────────────
                AppButton(
                  label: 'Save Changes',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
