/// VIT-AP Sports — AppBottomSheet widget.
///
/// Component specification:
/// - Top radius 16.
/// - 32 x 4 drag handle in borderStrong.
/// - Padding 16 horizontal. Headline title, primary action pinned at bottom.
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
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      child: Padding(
        padding: padding ??
            const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 32 x 4 drag handle in borderStrong
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.headline.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Flexible(child: child),
            if (bottomAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              bottomAction!,
            ],
          ],
        ),
      ),
    );
  }
}
