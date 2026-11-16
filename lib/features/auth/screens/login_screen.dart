/// VIT-AP Sports — Login screen (Apple Design System).
///
/// Clean, minimal auth screen: calm surfaces, large confident typography,
/// pill button, generous whitespace, zero emojis.
/// Scrollable viewport ensures clean rendering even at 200% text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _LoginScreenState extends ConsumerState<LoginScreen> with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoading) {
      // If user returned to the app without completing auth,
      // allow a brief moment for the OAuth deep link to arrive.
      // If no session exists after 2s, restore button state.
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _isLoading && ref.read(authServiceProvider).currentSession == null) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final launched = await service.signInWithGoogle();
      if (!launched && mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull?.session != null && mounted) {
        setState(() => _isLoading = false);
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      const SizedBox(height: AppSpacing.xl),

                      // Logo container
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        ),
                        child: Icon(
                          Icons.sports_rounded,
                          size: 44,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Title
                      Text(
                        'VIT-AP Sports',
                        style: AppTypography.largeTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.68,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Tagline
                      Text(
                        'Your campus sports community.\nForm teams, play matches, track stats.',
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 4),
                      const SizedBox(height: AppSpacing.xxl),

                      // Sign In Button
                      AppButton(
                        label: 'Continue with Google',
                        onPressed: _handleSignIn,
                        isLoading: _isLoading,
                        icon: Icons.g_mobiledata_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Domain notice
                      Text(
                        'Sign in with your @vitap.ac.in email',
                        style: AppTypography.footnote.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
