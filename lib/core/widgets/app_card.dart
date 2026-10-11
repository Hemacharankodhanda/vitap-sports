/// VIT-AP Sports — AppCard and AppGroupedCard widgets.
///
/// Component specification:
/// - Standard card: surface, 1 px border, radius 12, padding 16, elevation 0.
/// - The whole card is tappable with pressed overlay (no bouncy motion or entrance animation).
/// - Grouped list card: holds rows separated by inset hairlines (16 indent, or 72 with avatar).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? colors.border,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.accent.withAlpha(15),
        highlightColor: colors.textPrimary.withAlpha(12),
        child: card,
      );
    }

    return card;
  }
}

/// A card holding rows separated by inset hairlines per component specification.
class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    super.key,
    required this.children,
    this.hasAvatars = false,
    this.margin,
  });

  final List<Widget> children;
  final bool hasAvatars;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final indent = hasAvatars ? 72.0 : 16.0;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: indent,
                  color: colors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
