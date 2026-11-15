/// VIT-AP Sports — Sport Filter Bar (Apple Design System).
///
/// A horizontal scrolling bar of pill chips to select the active sport context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/teams/providers/team_providers.dart';
import '../providers/sport_filter_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_chip.dart';

class SportFilterBar extends ConsumerWidget implements PreferredSizeWidget {
  const SportFilterBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsListProvider);
    final selectedSport = ref.watch(sportFilterProvider);

    return SizedBox(
      height: 48,
      child: sportsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (sportsList) {
          final availableSports = sportsList
              .where((s) => ['Cricket', 'Football', 'Badminton'].contains(s['name']))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            scrollDirection: Axis.horizontal,
            itemCount: availableSports.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final sport = availableSports[index];
              final sportName = sport['name'] as String;
              final isSelected = sportName == selectedSport;

              return AppChip(
                label: sportName,
                isSelected: isSelected,
                onTap: () {
                  ref.read(sportFilterProvider.notifier).setSport(sportName);
                },
              );
            },
          );
        },
      ),
    );
  }
}
