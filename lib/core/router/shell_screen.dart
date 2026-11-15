/// VIT-AP Sports — Shell screen with adaptive Apple navigation.
///
/// Persistent navigation shell:
/// - Compact (< 600 dp): Frosted bottom navigation bar (icon 24 + 11-12sp label always visible,
///   selected = filled icon + textPrimary, unselected = outlined icon + textSecondary, no indicator pill).
/// - Medium (600..1023 dp) / Expanded (>= 1024 dp): Frosted/surface navigation rail on the left.
/// - 5 persistent destinations: Home, Teams, Matches, Board, Profile.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/adaptive_scaffold.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: navigationShell.currentIndex,
      onNavigationChanged: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: const [
        AdaptiveDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        AdaptiveDestination(
          label: 'Teams',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_rounded,
        ),
        AdaptiveDestination(
          label: 'Matches',
          icon: Icons.sports_rounded,
          selectedIcon: Icons.sports_rounded,
        ),
        AdaptiveDestination(
          label: 'Board',
          icon: Icons.leaderboard_outlined,
          selectedIcon: Icons.leaderboard_rounded,
        ),
        AdaptiveDestination(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      body: navigationShell,
    );
  }
}
