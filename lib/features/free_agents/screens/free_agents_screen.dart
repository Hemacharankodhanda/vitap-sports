/// VIT-AP Sports — Free agents screen.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';

class FreeAgentsScreen extends StatelessWidget {
  const FreeAgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Free Agents')),
      body: Column(
        children: [
          // Sport filter
          SizedBox(
            height: AppSpacing.chipHeight + AppSpacing.lg * 2,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.sm,
              ),
              children: const [
                AppChip(label: 'All', isSelected: true),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Cricket'),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Football'),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Basketball'),
                SizedBox(width: AppSpacing.sm),
                AppChip(label: 'Badminton'),
              ],
            ),
          ),
          // Players list
          const Expanded(
            child: EmptyState(
              icon: Icons.person_search_rounded,
              title: 'No free agents',
              subtitle:
                  'Players looking for a team will appear here.\nList yourself as available from your profile.',
            ),
          ),
        ],
      ),
    );
  }
}
