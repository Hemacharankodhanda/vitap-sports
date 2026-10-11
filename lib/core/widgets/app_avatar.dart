/// VIT-AP Sports — AppAvatar widget.
///
/// Component specification:
/// - Sizes: 24, 32, 40, 56.
/// - Players are circles, teams are rounded squares (radius 8, or 12 at 56).
/// - Initials fallback uses one neutral tint with textSecondary letters.
/// - 150 ms fade-in for network images with neutral placeholder.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppAvatarSize {
  size24(24, 10, 6),
  size32(32, 12, 8),
  size40(40, 14, 8),
  size56(56, 18, 12);

  const AppAvatarSize(this.dimension, this.fontSize, this.teamRadius);
  final double dimension;
  final double fontSize;
  final double teamRadius;

  // Backward compatibility aliases
  static const small = AppAvatarSize.size32;
  static const medium = AppAvatarSize.size40;
  static const large = AppAvatarSize.size56;
  static const xlarge = AppAvatarSize.size56;
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.size40,
    this.isTeam = false,
    this.onTap,
    this.showBorder = false,
  });

  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final bool isTeam;
  final VoidCallback? onTap;
  final bool showBorder;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  BorderRadius? get _borderRadius =>
      isTeam ? BorderRadius.circular(size.teamRadius) : null;

  BoxShape get _shape => isTeam ? BoxShape.rectangle : BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        fadeInDuration: const Duration(milliseconds: 150),
        imageBuilder: (_, imageProvider) => Container(
          width: size.dimension,
          height: size.dimension,
          decoration: BoxDecoration(
            shape: _shape,
            borderRadius: _borderRadius,
            border: showBorder ? Border.all(color: colors.border, width: 1) : null,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (_, __) => _buildFallback(context, colors),
        errorWidget: (_, __, ___) => _buildFallback(context, colors),
      );
    } else {
      avatar = _buildFallback(context, colors);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: isTeam ? BorderRadius.circular(size.teamRadius) : BorderRadius.circular(size.dimension / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: size.dimension,
      height: size.dimension,
      decoration: BoxDecoration(
        shape: _shape,
        borderRadius: _borderRadius,
        color: colors.surfaceVariant,
        border: showBorder ? Border.all(color: colors.border, width: 1) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: size.fontSize,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
