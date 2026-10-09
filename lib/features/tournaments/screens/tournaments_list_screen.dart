/// VIT-AP Sports — Tournaments list screen.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';

class TournamentsListScreen extends StatelessWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: AppSpacing.iconNav),
            onPressed: () {
              // TODO: Navigate to create tournament
            },
            tooltip: 'Create Tournament',
          ),
        ],
      ),
      body: const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No tournaments yet',
        subtitle: 'Create a tournament to get started!',
      ),
    );
  }
}
