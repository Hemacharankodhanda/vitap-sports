/// VIT-AP Sports — Sport Filter Bar
///
/// A horizontal scrolling bar of chips to select the active sport context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/teams/providers/team_providers.dart';
import '../providers/sport_filter_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SportFilterBar extends ConsumerWidget implements PreferredSizeWidget {
  const SportFilterBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsListProvider);
    final selectedSport = ref.watch(sportFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: sportsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (sportsList) {
          // Filter to only the 3 required sports for now
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

              return ChoiceChip(
                label: Text(sportName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(sportFilterProvider.notifier).setSport(sportName);
                  }
                },
                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                selectedColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                labelStyle: TextStyle(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.transparent,
                ),
                showCheckmark: false,
              );
            },
          );
        },
      ),
    );
  }
}
