/// VIT-AP Sports — AppAvatar widget.
///
/// Circular avatar with cached network image and fallback initials.
/// Consistent sizing per context: small (32), medium (48), large (72), xlarge (96).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppAvatarSize { small, medium, large, xlarge }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.medium,
    this.onTap,
    this.showBorder = false,
  });

  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final VoidCallback? onTap;
  final bool showBorder;

  double get _dimension {
    switch (size) {
      case AppAvatarSize.small:
        return AppSpacing.avatarSmall;
      case AppAvatarSize.medium:
        return AppSpacing.avatarMedium;
      case AppAvatarSize.large:
        return AppSpacing.avatarLarge;
      case AppAvatarSize.xlarge:
        return AppSpacing.avatarXLarge;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppAvatarSize.small:
        return 12;
      case AppAvatarSize.medium:
        return 16;
      case AppAvatarSize.large:
        return 24;
      case AppAvatarSize.xlarge:
        return 32;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (_, imageProvider) => Container(
          width: _dimension,
          height: _dimension,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (_, __) => _buildFallback(context),
        errorWidget: (_, __, ___) => _buildFallback(context),
      );
    } else {
      avatar = _buildFallback(context);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withAlpha(20),
        border: showBorder
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.body.copyWith(
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
