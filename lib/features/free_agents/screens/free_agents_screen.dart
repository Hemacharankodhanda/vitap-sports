/// VIT-AP Sports — Free agents screen (Apple Design System).
///
/// Clean, calm directory for free agents: pill chips filter,
/// calm surface backgrounds, zero emojis.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/frosted_bar.dart';

class FreeAgentsScreen extends StatefulWidget {
  const FreeAgentsScreen({super.key});

  @override
  State<FreeAgentsScreen> createState() => _FreeAgentsScreenState();
}

class _FreeAgentsScreenState extends State<FreeAgentsScreen> {
  String _selectedSport = 'All';

  static const _sports = [
    'All',
    'Cricket',
    'Football',
    'Basketball',
    'Badminton',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const FrostedAppBar(
        title: Text('Free Agents'),
      ),
      body: Column(
        children: [
          // Sport filter
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: 8,
              ),
              itemCount: _sports.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final sport = _sports[index];
                return AppChip(
                  label: sport,
                  isSelected: _selectedSport == sport,
                  onTap: () => setState(() => _selectedSport = sport),
                );
              },
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: colors.divider),

          // Players list / Empty state
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
