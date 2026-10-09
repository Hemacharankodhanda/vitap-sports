/// VIT-AP Sports — AppButton widget.
///
/// The ONLY button widget used across the entire app.
/// Variants: primary (filled accent), secondary (outlined), destructive, text.
/// AnimatedScale on press (0.96) per design.md motion guidelines.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

enum AppButtonSize { large, medium, small }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.large:
        return AppSpacing.buttonHeightPrimary;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightSecondary;
      case AppButtonSize.small:
        return 32.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            isDisabled ? null : () => setState(() => _isPressed = false),
        child: SizedBox(
          width: widget.isExpanded ? double.infinity : null,
          height: _height,
          child: _buildButton(isDark, isDisabled),
        ),
      ),
    );
  }

  Widget _buildButton(bool isDark, bool isDisabled) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withAlpha(77),
            disabledForegroundColor: Colors.white.withAlpha(128),
            elevation: 0,
            minimumSize: Size(0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            textStyle:
                AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          child: _buildChild(Colors.white),
        );

      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            elevation: 0,
            minimumSize: Size(0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            side: BorderSide(
              color:
                  isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            textStyle:
                AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          child: _buildChild(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        );

      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size(0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            textStyle:
                AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          child: _buildChild(Colors.white),
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            minimumSize: Size(0, _height),
            textStyle:
                AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          child: _buildChild(AppColors.accent),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: AppSpacing.iconInline),
          const SizedBox(width: AppSpacing.sm),
          Text(widget.label),
        ],
      );
    }

    return Text(widget.label);
  }
}
