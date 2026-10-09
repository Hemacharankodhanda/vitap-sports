/// VIT-AP Sports — StatusBadge widget.
///
/// Match status indicator combining icon + color + label.
/// Never color alone — accessibility requirement from design.md.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum MatchStatus { upcoming, live, completed, cancelled }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final MatchStatus status;
  final bool compact;

  Color get _color {
    switch (status) {
      case MatchStatus.live:
        return AppColors.live;
      case MatchStatus.upcoming:
        return AppColors.upcoming;
      case MatchStatus.completed:
        return AppColors.completed;
      case MatchStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  Color get _bgColor {
    switch (status) {
      case MatchStatus.live:
        return AppColors.liveSurface;
      case MatchStatus.upcoming:
        return AppColors.upcomingSurface;
      case MatchStatus.completed:
        return AppColors.completedSurface;
      case MatchStatus.cancelled:
        return AppColors.cancelledSurface;
    }
  }

  IconData get _icon {
    switch (status) {
      case MatchStatus.live:
        return Icons.fiber_manual_record_rounded;
      case MatchStatus.upcoming:
        return Icons.schedule_rounded;
      case MatchStatus.completed:
        return Icons.check_circle_outline_rounded;
      case MatchStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String get _label {
    switch (status) {
      case MatchStatus.live:
        return 'LIVE';
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.live)
            _PulsingDot(color: _color)
          else
            Icon(_icon, size: compact ? 10 : 12, color: _color),
          SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
          Text(
            _label,
            style: (compact ? AppTypography.overline : AppTypography.caption)
                .copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot animation for live match indicator.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
