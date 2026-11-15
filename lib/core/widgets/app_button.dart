/// VIT-AP Sports — AppButton widget (Apple Design System).
///
/// Component specification:
/// - Pill shape (StadiumBorder)
/// - Primary: primaryFill with onPrimary text (#1D1D1F / #FFFFFF light; #F5F5F7 / #1D1D1F dark)
/// - Secondary: fillSecondary with textPrimary (#E8E8ED / #1D1D1F light; #2C2C2E / #F5F5F7 dark)
/// - Outlined: transparent with hairline border and textPrimary
/// - Text: borderless, textPrimary label
/// - Destructive: loss-tinted container with loss text; filled loss in confirmation dialogs
/// - DestructiveInline: transparent with hairline loss border and loss text
///
/// Heights: 48 (default), 40 (compact). Min touch target: 48dp.
/// Motion: 120ms press scale (0.98) with curve Cubic(0.28, 0.11, 0.32, 1.0).
/// Haptic: light impact on primary actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
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

  double get _height => widget.size.isCompact
      ? AppSpacing.buttonHeightCompact
      : AppSpacing.buttonHeightPrimary;

  EdgeInsetsGeometry get _padding => EdgeInsets.symmetric(
        horizontal: widget.size.isCompact ? 16.0 : 20.0,
      );

  TextStyle get _textStyle => widget.size.isCompact
      ? AppTypography.callout.copyWith(fontWeight: FontWeight.w600)
      : AppTypography.headline;

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    if (widget.variant == AppButtonVariant.primary) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final disabledAlpha = (AppColors.overlayDisabledContent * 255).round();

    Color bgColor;
    Color fgColor;
    BorderSide side = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = colors.primaryFill;
        fgColor = colors.onPrimary;
      case AppButtonVariant.secondary:
        bgColor = colors.fillSecondary;
        fgColor = colors.textPrimary;
      case AppButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = colors.textPrimary;
        side = BorderSide(color: colors.divider, width: 1.0);
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = colors.textPrimary;
      case AppButtonVariant.destructive:
        bgColor = colors.loss.withAlpha(isDark ? 41 : 26);
        fgColor = colors.loss;
      case AppButtonVariant.destructiveInline:
        bgColor = Colors.transparent;
        fgColor = colors.loss;
        side = BorderSide(color: colors.loss.withAlpha(isDark ? 60 : 40), width: 1.0);
    }

    final effectiveFgColor = isDisabled ? fgColor.withAlpha(disabledAlpha) : fgColor;
    final effectiveBgColor = isDisabled
        ? (bgColor == Colors.transparent
            ? Colors.transparent
            : bgColor.withAlpha((AppColors.overlayDisabledContainer * 255).round()))
        : bgColor;

    Widget buttonWidget = SizedBox(
      height: _height,
      child: Material(
        color: effectiveBgColor,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const StadiumBorder(),
          splashColor: Colors.transparent,
          highlightColor: fgColor.withAlpha(20),
          onTap: isDisabled ? null : _handleTap,
          onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
          child: Padding(
            padding: _padding,
            child: Center(
              child: _buildContent(effectiveFgColor),
            ),
          ),
        ),
      ),
    );

    // Apply 0.98 scale animation on press unless user prefers reduced motion
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    if (!reduceMotion) {
      buttonWidget = AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: AppMotion.pressDuration,
        curve: AppMotion.curve,
        child: buttonWidget,
      );
    }

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: SizedBox(
          width: widget.isExpanded ? double.infinity : null,
          child: buttonWidget,
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: widget.size.isCompact ? 18 : 20, color: textColor),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              widget.label,
              style: _textStyle.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      style: _textStyle.copyWith(color: textColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
