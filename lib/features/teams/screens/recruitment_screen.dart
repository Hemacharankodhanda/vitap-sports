/// VIT-AP Sports — Recruitment screen (placeholder).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class RecruitmentScreen extends StatelessWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Recruitment')),
      body: const EmptyState(
        icon: Icons.person_search_rounded,
        title: 'No open positions',
        subtitle: 'Teams looking for players will appear here.',
      ),
    );
  }
}
