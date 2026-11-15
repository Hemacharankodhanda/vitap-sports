/// VIT-AP Sports — AppBottomSheet widget (Apple Design System).
///
/// Component specification:
/// - Top radius 28, surfaceElevated background, elevation 0.
/// - Scrim 40% (0x66000000).
/// - 36 x 5 pill drag handle in fillSecondary / textSecondary.
/// - Padding 20 horizontal. Headline title, primary action pinned at bottom.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.bottomAction,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final Widget? bottomAction;

  /// Show this bottom sheet using the standard Material modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? bottomAction,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    final colors = context.appColors;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: true,
      elevation: 0,
      barrierColor: Colors.black.withAlpha((AppColors.scrimOpacity * 255).round()),
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (_) => AppBottomSheet(
        title: title,
        bottomAction: bottomAction,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: colors.fillSecondary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Title
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                title!,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: colors.divider),
          ],

          // Content
          Flexible(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),

          // Pinned bottom action
          if (bottomAction != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: bottomAction!,
            ),
          ],
        ],
      ),
    );
  }
}
