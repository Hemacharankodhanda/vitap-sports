/// VIT-AP Sports — Leaderboard screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedSport = ref.watch(leaderboardSportProvider);
    final playersAsync = ref.watch(topPlayersProvider);
    final teamsAsync = ref.watch(topTeamsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/leaderboard/tournaments'),
            tooltip: 'Tournaments',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Sport filter
          SizedBox(
            height: AppSpacing.chipHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Cricket', 'Football', 'Badminton'].map((sport) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: sport,
                    isSelected: selectedSport == sport,
                    onTap: () => ref.read(leaderboardSportProvider.notifier).state = sport,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Top Players section
          const SectionHeader(title: 'Top Players'),
          const SizedBox(height: AppSpacing.md),
          playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (players) {
              if (players.isEmpty) {
                return const EmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'No leaderboard data yet',
                  subtitle: 'Play matches to appear on the leaderboard!',
                );
              }
              return Column(
                children: players.asMap().entries.map((e) {
                  final index = e.key;
                  final player = e.value as Map<String, dynamic>;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      onTap: () {
                        if (player['id'] != null) {
                          context.go('/leaderboard/player/${player['id']}');
                        }
                      },
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey[400]
                                      : index == 2
                                          ? Colors.brown[300]
                                          : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppAvatar(
                            imageUrl: player['avatar_url'] as String?,
                            name: player['name'] as String? ?? 'Player',
                            size: AppAvatarSize.medium,
                          ),
                        ],
                      ),
                      title: Text(player['name'] as String? ?? 'Player', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('${player['primary_stat']} • ${player['secondary_stat']}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Top Teams section
          const SectionHeader(title: 'Top Teams'),
          const SizedBox(height: AppSpacing.md),
          teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (teams) {
              if (teams.isEmpty) {
                return const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No team rankings yet',
                  subtitle: 'Teams will be ranked after completing matches.',
                );
              }
              return Column(
                children: teams.asMap().entries.map((e) {
                  final index = e.key;
                  final team = e.value;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey[400]
                                      : index == 2
                                          ? Colors.brown[300]
                                          : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppAvatar(
                            imageUrl: team.logoUrl,
                            name: team.name,
                            size: AppAvatarSize.medium,
                          ),
                        ],
                      ),
                      title: Text(team.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('${team.sportName ?? "Team"} • ${team.wins}W - ${team.losses}L - ${team.draws}D'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
