/// VIT-AP Sports — AdaptiveScaffold widget (Apple Design System).
///
/// Responsive navigation scaffold:
/// - Compact (< 600 dp): Frosted bottom navigation bar (icon 24 + 11-12sp label always visible,
///   selected = filled icon + textPrimary, unselected = outlined icon + textSecondary, no indicator pill).
/// - Medium (600..1023 dp) / Expanded (>= 1024 dp): Navigation rail on the left with hairline divider.
/// - Hairline dividers (0.5 to 1 px) with backdrop blur and RepaintBoundary.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'frosted_bar.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Key? key;
}

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCompact = AppBreakpoints.isCompact(context);

    if (isCompact) {
      return Scaffold(
        backgroundColor: backgroundColor ?? colors.background,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: _SwipeTabDetector(
          currentIndex: currentIndex,
          maxIndex: destinations.length - 1,
          onNavigationChanged: onNavigationChanged,
          child: body,
        ),
        bottomNavigationBar: _buildBottomNav(context, colors),
      );
    }

    // Medium & Expanded: Navigation Rail on the left
    return Scaffold(
      backgroundColor: backgroundColor ?? colors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _buildNavigationRail(context, colors),
          VerticalDivider(width: 1, thickness: 0.5, color: colors.divider),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppColorsExtension colors) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final animDuration = reduceMotion ? Duration.zero : AppMotion.stateChangeDuration;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FrostedBar(
      showTopDivider: true,
      height: AppSpacing.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final count = destinations.length;
              final tabWidth = count > 0 ? totalWidth / count : 0.0;
              final activeIndex =
                  (currentIndex >= 0 && currentIndex < count) ? currentIndex : 0;
              final capsuleWidth = (tabWidth - 12.0).clamp(44.0, 68.0);
              final capsuleLeft =
                  (activeIndex * tabWidth) + (tabWidth - capsuleWidth) / 2;

              return _SwipeTabDetector(
                currentIndex: currentIndex,
                maxIndex: destinations.length - 1,
                onNavigationChanged: onNavigationChanged,
                child: Stack(
                  children: [
                    // ─── Smooth Sliding Capsule Highlight ─────
                    AnimatedPositioned(
                      duration: animDuration,
                      curve: AppMotion.curve,
                      left: capsuleLeft,
                      top: 4,
                      bottom: 4,
                      width: capsuleWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? colors.fillSecondary.withAlpha(150)
                              : colors.fillSecondary.withAlpha(200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 40 : 15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Destination Items ─────────────────────
                    Row(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Expanded(
                            child: _BottomNavItem(
                              key: destinations[i].key,
                              destination: destinations[i],
                              isSelected: i == currentIndex,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onNavigationChanged(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: 80,
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < destinations.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: _RailNavItem(
                  key: destinations[i].key,
                  destination: destinations[i],
                  isSelected: i == currentIndex,
                  onTap: () => onNavigationChanged(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isSelected ? colors.textPrimary : colors.textSecondary;
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final animDuration = reduceMotion ? Duration.zero : AppMotion.stateChangeDuration;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.10 : 1.0,
              duration: animDuration,
              curve: AppMotion.curve,
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                size: AppSpacing.iconNav,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: animDuration,
              curve: AppMotion.curve,
              style: TextStyle(
                fontFamily: AppTypography.caption.fontFamily,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.1,
              ),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isSelected ? colors.textPrimary : colors.textSecondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final animDuration = reduceMotion ? Duration.zero : AppMotion.stateChangeDuration;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: animDuration,
          curve: AppMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? colors.fillSecondary.withAlpha(160)
                    : colors.fillSecondary.withAlpha(200))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.10 : 1.0,
                duration: animDuration,
                curve: AppMotion.curve,
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: AppSpacing.iconNav,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                curve: AppMotion.curve,
                style: TextStyle(
                  fontFamily: AppTypography.caption.fontFamily,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  destination.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeTabDetector extends StatefulWidget {
  const _SwipeTabDetector({
    required this.currentIndex,
    required this.maxIndex,
    required this.onNavigationChanged,
    required this.child,
  });

  final int currentIndex;
  final int maxIndex;
  final ValueChanged<int> onNavigationChanged;
  final Widget child;

  @override
  State<_SwipeTabDetector> createState() => _SwipeTabDetectorState();
}

class _SwipeTabDetectorState extends State<_SwipeTabDetector> {
  double _dragDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragDistance = 0.0,
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.primaryDelta ?? 0.0;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        final distance = _dragDistance;
        _dragDistance = 0.0;

        if (distance < -50.0 || velocity < -200.0) {
          // Swiped Left -> Next tab
          if (widget.currentIndex < widget.maxIndex) {
            HapticFeedback.selectionClick();
            widget.onNavigationChanged(widget.currentIndex + 1);
          }
        } else if (distance > 50.0 || velocity > 200.0) {
          // Swiped Right -> Previous tab
          if (widget.currentIndex > 0) {
            HapticFeedback.selectionClick();
            widget.onNavigationChanged(widget.currentIndex - 1);
          }
        }
      },
      child: widget.child,
    );
  }
}
