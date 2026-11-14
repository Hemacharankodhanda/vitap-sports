/// VIT-AP Sports — AppAvatar widget (Apple Design System).
///
/// Component specification:
/// - Players are circles (BoxShape.circle).
/// - Teams are rounded squares (radius 12).
/// - Sizes: 24, 32, 40, 56.
/// - Fallback initials use fillSecondary background with textSecondary letters.
/// - 150 ms smooth fade-in for network images.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppAvatarSize {
  size24(24, 10, 6),
  size32(32, 12, 8),
  size40(40, 14, 10),
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
      isTeam ? BorderRadius.circular(AppSpacing.radiusAvatarTeam) : null;

  BoxShape get _shape => isTeam ? BoxShape.rectangle : BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheDim = (size.dimension * dpr).round();
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        fadeInDuration: const Duration(milliseconds: 150),
        memCacheWidth: cacheDim,
        memCacheHeight: cacheDim,
        imageBuilder: (_, imageProvider) => Container(
          width: size.dimension,
          height: size.dimension,
          decoration: BoxDecoration(
            shape: _shape,
            borderRadius: _borderRadius,
            border: showBorder ? Border.all(color: colors.divider, width: 0.5) : null,
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
      return Semantics(
        button: true,
        label: name != null ? '$name avatar' : 'Avatar',
        child: InkWell(
          onTap: onTap,
          borderRadius: isTeam
              ? BorderRadius.circular(AppSpacing.radiusAvatarTeam)
              : BorderRadius.circular(size.dimension / 2),
          splashColor: Colors.transparent,
          highlightColor: colors.textPrimary.withAlpha(15),
          child: avatar,
        ),
      );
    }

    return avatar;
  }

  Widget _buildFallback(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: size.dimension,
      height: size.dimension,
      decoration: BoxDecoration(
        color: colors.fillSecondary,
        shape: _shape,
        borderRadius: _borderRadius,
        border: showBorder ? Border.all(color: colors.divider, width: 0.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: AppTypography.callout.fontFamily,
          fontSize: size.fontSize,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
