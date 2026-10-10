/// VIT-AP Sports — AppCard widget.
///
/// Unified card with consistent corner radius, padding, and elevation.
/// Used for team cards, match cards, player cards — all share this base.
library;

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_spacing.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.elevation,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? elevation;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: 1)
            : null,
        boxShadow: [
          if ((widget.elevation ?? AppSpacing.cardElevation) > 0)
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: (widget.elevation ?? AppSpacing.cardElevation) * 4,
              offset: Offset(0, (widget.elevation ?? AppSpacing.cardElevation)),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: widget.padding ??
              const EdgeInsets.all(AppSpacing.cardPadding),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: card,
        ),
      );
    }

    return card.animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
