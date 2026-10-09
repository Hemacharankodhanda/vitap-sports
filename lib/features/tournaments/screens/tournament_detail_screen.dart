/// VIT-AP Sports — Tournament detail screen (placeholder).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Tournament')),
      body: const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Tournament details',
        subtitle: 'Bracket and standings will appear here.',
      ),
    );
  }
}
