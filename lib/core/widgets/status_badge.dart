/// VIT-AP Sports — StatusBadge and StatusLabel widgets (Apple Design System).
///
/// Component specification:
/// Status label (non-interactive): height 24, pill shape (radius 999), Caption w600.
/// - Live: live-tinted container with 6 px pulsing red dot (only pulsing element in the app)
/// - Upcoming: fillSecondary background, textSecondary text
/// - Completed: surface background, textSecondary text
/// - Paused: warningContainer tint, warning text
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum MatchStatus { upcoming, live, completed, cancelled, paused }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final MatchStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MatchStatus.live:
        return const StatusLabel.live();
      case MatchStatus.upcoming:
        return const StatusLabel.upcoming();
      case MatchStatus.completed:
        return const StatusLabel.completed();
      case MatchStatus.cancelled:
        return const StatusLabel(
          label: 'Cancelled',
          variant: StatusLabelVariant.completed,
        );
      case MatchStatus.paused:
        return const StatusLabel.paused();
    }
  }
}

enum StatusLabelVariant { live, upcoming, completed, paused }

class StatusLabel extends StatelessWidget {
  const StatusLabel({
    super.key,
    required this.label,
    required this.variant,
  });

  const StatusLabel.live({super.key, this.label = 'LIVE'})
      : variant = StatusLabelVariant.live;

  const StatusLabel.upcoming({super.key, this.label = 'Upcoming'})
      : variant = StatusLabelVariant.upcoming;

  const StatusLabel.completed({super.key, this.label = 'FT'})
      : variant = StatusLabelVariant.completed;

  const StatusLabel.paused({super.key, this.label = 'Paused'})
      : variant = StatusLabelVariant.paused;

  final String label;
  final StatusLabelVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Color bgColor;
    Color textColor;

    switch (variant) {
      case StatusLabelVariant.live:
        bgColor = colors.liveContainer;
        textColor = colors.live;
      case StatusLabelVariant.upcoming:
        bgColor = colors.fillSecondary;
        textColor = colors.textSecondary;
      case StatusLabelVariant.completed:
        bgColor = colors.surface;
        textColor = colors.textSecondary;
      case StatusLabelVariant.paused:
        bgColor = colors.warningContainer;
        textColor = colors.warning;
    }

    return Container(
      height: AppSpacing.statusBadgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (variant == StatusLabelVariant.live) ...[
            const _PulsingDot(),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

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
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    final colors = context.appColors;
    if (AppMotion.shouldReduceMotion(context)) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: colors.live,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: colors.live,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
