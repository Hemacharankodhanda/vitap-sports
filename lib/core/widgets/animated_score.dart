/// VIT-AP Sports — AnimatedScore widget.
///
/// Score numbers animate via TweenAnimationBuilder when value changes.
/// Count-up effect, never a hard snap-to-new-value.
library;

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class AnimatedScore extends StatelessWidget {
  const AnimatedScore({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Text(
        '$prefix$value$suffix',
        style: style ?? AppTypography.scoreDisplay,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, animatedValue, __) {
        return Text(
          '$prefix${animatedValue.round()}$suffix',
          style: style ?? AppTypography.scoreDisplay,
        );
      },
    );
  }
}
