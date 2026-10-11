/// VIT-AP Sports — AppButton widget.
///
/// Component specification:
/// - Primary: filled accent
/// - Secondary: tonal accentContainer
/// - Outlined: transparent with 1px borderStrong
/// - Text: none, accent label
/// - Destructive: negative fill, white text
/// - DestructiveInline: outlined in negative, negative text
///
/// Heights: 48 (default), 40 (compact). Radius 8.
/// Ripple: ink ripple with pressed overlay, no bouncy motion.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
  destructiveInline,
}

enum AppButtonSize {
  large,
  medium,
  small;

  bool get isCompact => this != AppButtonSize.large;
}

class AppButton extends StatelessWidget {
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

  double get _height => size.isCompact ? 40.0 : 48.0;

  EdgeInsetsGeometry get _padding => EdgeInsets.symmetric(
        horizontal: size.isCompact ? 12.0 : 16.0,
      );

  TextStyle get _textStyle =>
      size.isCompact ? AppTypography.callout.copyWith(fontWeight: FontWeight.w600) : AppTypography.headline;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: _height,
      child: _buildButton(context, colors, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, AppColorsExtension colors, bool isDisabled) {
    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            disabledBackgroundColor: colors.accent.withAlpha((AppColors.overlayDisabledContainer * 255).round()),
            disabledForegroundColor: colors.onAccent.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            elevation: 0,
            minimumSize: Size(64, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: _textStyle,
          ),
          child: _buildContent(colors.onAccent),
        );

      case AppButtonVariant.secondary:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accentContainer,
            foregroundColor: colors.accent,
            disabledBackgroundColor: colors.accentContainer.withAlpha((AppColors.overlayDisabledContainer * 255).round()),
            disabledForegroundColor: colors.accent.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            elevation: 0,
            minimumSize: Size(64, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: _textStyle,
          ),
          child: _buildContent(colors.accent),
        );

      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            disabledForegroundColor: colors.textPrimary.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            elevation: 0,
            minimumSize: Size(64, _height),
            padding: _padding,
            side: BorderSide(color: colors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: _textStyle,
          ),
          child: _buildContent(colors.textPrimary),
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.accent,
            disabledForegroundColor: colors.accent.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            minimumSize: Size(64, _height),
            padding: _padding,
            textStyle: _textStyle,
          ),
          child: _buildContent(colors.accent),
        );

      case AppButtonVariant.destructive:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.loss,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.loss.withAlpha((AppColors.overlayDisabledContainer * 255).round()),
            disabledForegroundColor: Colors.white.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            elevation: 0,
            minimumSize: Size(64, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: _textStyle,
          ),
          child: _buildContent(Colors.white),
        );

      case AppButtonVariant.destructiveInline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.loss,
            disabledForegroundColor: colors.loss.withAlpha((AppColors.overlayDisabledContent * 255).round()),
            elevation: 0,
            minimumSize: Size(64, _height),
            padding: _padding,
            side: BorderSide(color: colors.loss),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: _textStyle,
          ),
          child: _buildContent(colors.loss),
        );
    }
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
