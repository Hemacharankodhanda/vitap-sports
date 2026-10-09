/// VIT-AP Sports — Login screen.
///
/// Minimal auth screen: logo, tagline, single "Continue with Google" button.
/// Clean, premium design per design.md guidelines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      await service.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ─── Logo / Brand ─────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: const Icon(
                  Icons.sports_rounded,
                  size: 44,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Title ────────────────────────────────
              Text(
                'VIT-AP Sports',
                style: AppTypography.largeTitle.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── Tagline ──────────────────────────────
              Text(
                'Your campus sports community.\nForm teams, play matches, track stats.',
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 4),

              // ─── Sign In Button ───────────────────────
              AppButton(
                label: 'Continue with Google',
                onPressed: _handleSignIn,
                isLoading: _isLoading,
                icon: Icons.g_mobiledata_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),

              const SizedBox(height: AppSpacing.sm),

              // ─── Domain notice ────────────────────────
              Text(
                'Sign in with your @vitap.ac.in email',
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
