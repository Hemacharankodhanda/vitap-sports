/// VIT-AP Sports — AdaptiveScaffold widget (Apple Design System).
///
/// Responsive navigation scaffold:
/// - Compact (< 600 dp): Frosted bottom navigation bar (icon 24 + 11-12sp label always visible,
///   selected = filled icon + textPrimary, unselected = outlined icon + textSecondary, no indicator pill).
/// - Medium (600..1023 dp) / Expanded (>= 1024 dp): Navigation rail on the left with hairline divider.
/// - Hairline dividers (0.5 to 1 px) with backdrop blur and RepaintBoundary.
library;

import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
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
        body: body,
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
    return FrostedBar(
      showTopDivider: true,
      height: AppSpacing.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++) ...[
                Expanded(
                  child: _BottomNavItem(
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: colors.textPrimary.withAlpha(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? destination.selectedIcon : destination.icon,
            size: AppSpacing.iconNav,
            color: color,
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: TextStyle(
              fontFamily: AppTypography.caption.fontFamily,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.transparent,
      highlightColor: colors.textPrimary.withAlpha(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? destination.selectedIcon : destination.icon,
              size: AppSpacing.iconNav,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontFamily: AppTypography.caption.fontFamily,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
