/// VIT-AP Sports — StatusBadge and StatusLabel widgets.
///
/// Component specification:
/// Status label (non-interactive): height 24, radius 8, Caption / w600.
/// - Live: liveContainer, live text, 6 px dot (the only pulsing element in the app)
/// - Upcoming: neutral 6% tint, textSecondary
/// - Completed / FT: 1 px border, textSecondary
/// - Paused: warningContainer, warning text
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
    Border? border;

    switch (variant) {
      case StatusLabelVariant.live:
        bgColor = colors.liveContainer;
        textColor = colors.live;
        break;
      case StatusLabelVariant.upcoming:
        bgColor = colors.textPrimary.withAlpha(15); // 6% tint
        textColor = colors.textSecondary;
        break;
      case StatusLabelVariant.completed:
        bgColor = Colors.transparent;
        textColor = colors.textSecondary;
        border = Border.all(color: colors.border, width: 1);
        break;
      case StatusLabelVariant.paused:
        bgColor = colors.warningContainer;
        textColor = colors.warning;
        break;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (variant == StatusLabelVariant.live) ...[
            _LivePulsingDot(color: colors.live),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: variant == StatusLabelVariant.live ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 6 px pulsing dot (the only pulsing element in the app per spec).
class _LivePulsingDot extends StatefulWidget {
  const _LivePulsingDot({required this.color});

  final Color color;

  @override
  State<_LivePulsingDot> createState() => _LivePulsingDotState();
}

class _LivePulsingDotState extends State<_LivePulsingDot>
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
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
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
