/// VIT-AP Sports — MemberTile widget.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/team_model.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    this.showRemove = false,
    this.onRemove,
  });

  final TeamMember member;
  final bool showRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: member.avatarUrl,
            name: member.userName,
            size: AppAvatarSize.small,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName ?? 'Unknown',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.position != null)
                  Text(
                    member.position!,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (member.isCaptain) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Captain',
                    style: AppTypography.overline.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (showRemove)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                size: AppSpacing.iconInline,
                color: AppColors.error,
              ),
              onPressed: onRemove,
              tooltip: 'Remove member',
            ),
        ],
      ),
    );
  }
}
