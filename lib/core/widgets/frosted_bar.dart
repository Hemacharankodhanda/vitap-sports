/// VIT-AP Sports — FrostedBar widgets (Apple Design System).
///
/// Component specification:
/// - Navigation bars use background at 80% opacity with backdrop blur (sigma 20)
///   and a hairline divider (0.5 to 1 px).
/// - Fall back to opaque color if blur is unsupported.
/// - Always wrapped in RepaintBoundary for optimal rendering performance.
library;

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FrostedBar extends StatelessWidget {
  const FrostedBar({
    super.key,
    required this.child,
    this.height,
    this.showTopDivider = false,
    this.showBottomDivider = false,
    this.padding,
    this.blurSigma = 20.0,
  });

  final Widget child;
  final double? height;
  final bool showTopDivider;
  final bool showBottomDivider;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background at 80% opacity for frosted blur effect
    final frostedColor = (isDark ? Colors.black : Colors.white).withAlpha((0.80 * 255).round());

    Widget content = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: frostedColor,
        border: Border(
          top: showTopDivider
              ? BorderSide(color: colors.divider, width: 0.5)
              : BorderSide.none,
          bottom: showBottomDivider
              ? BorderSide(color: colors.divider, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: child,
    );

    // If on web or unsupported platforms, blur may be disabled or heavy, but BackdropFilter is standard in Flutter
    content = ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );

    return RepaintBoundary(
      child: content,
    );
  }
}

/// PreferredSizeWidget implementation for use as an AppBar in Scaffold
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.bottom,
    this.height = AppSpacing.topBarHeight,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(
        height + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    return FrostedBar(
      showBottomDivider: true,
      child: SafeArea(
        bottom: false,
        child: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: leading,
          title: title,
          actions: actions,
          centerTitle: centerTitle,
          bottom: bottom,
        ),
      ),
    );
  }
}
