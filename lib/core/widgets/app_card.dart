/// VIT-AP Sports — AppCard and AppGroupedCard widgets (Apple Design System).
///
/// Component specification:
/// - Standard card: surface fill, radius 24, padding 20, borderless, elevation 0.
/// - Tappable cards receive smooth highlight on press with no bounce or ripple bursts.
/// - Grouped list card: holds rows separated by inset hairline dividers (hairline 0.5-1px).
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
    final cardColor = color ?? colors.surface;
    final radius = BorderRadius.circular(AppSpacing.radiusCard);

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: radius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Semantics(
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: Colors.transparent,
            highlightColor: colors.textPrimary.withAlpha(10),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

/// A card holding rows separated by inset hairlines per Apple grouped list specification.
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
    final radius = BorderRadius.circular(AppSpacing.radiusCard);
    final indent = hasAvatars ? 72.0 : 20.0;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: indent,
                  color: colors.divider,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
