/// VIT-AP Sports — Create tournament screen (placeholder).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class CreateTournamentScreen extends StatelessWidget {
  const CreateTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Create Tournament')),
      body: const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Coming soon',
        subtitle: 'Tournament creation will be available soon.',
      ),
    );
  }
}
