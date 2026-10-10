/// VIT-AP Sports — Profile screen.
///
/// View profile: avatar, name, branch/year, stats, badges, sports.
/// Strict vertical rhythm per design.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/badge_grid.dart';
import '../widgets/stats_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, size: AppSpacing.iconNav),
            onPressed: () => context.go('/profile/theme'),
            tooltip: 'Theme Settings',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: AppSpacing.iconNav),
            onPressed: () => context.go('/profile/edit'),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: AppSpacing.iconNav),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const ShimmerProfile(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const ErrorView(message: 'Profile not found');
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
            ),
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ─── Avatar + Name ──────────────────────────
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      imageUrl: profile.avatarUrl,
                      name: profile.name,
                      size: AppAvatarSize.xlarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      profile.name,
                      style: AppTypography.title.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (profile.branch != null) profile.branch,
                        if (profile.year != null) profile.year,
                        if (profile.hostelBlock != null) profile.hostelBlock,
                      ].join(' • '),
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ─── Stats ──────────────────────────────────
              StatsRow(
                stats: [
                  StatItem(
                    label: 'Matches',
                    value: profile.matchesPlayed.toString(),
                  ),
                  StatItem(
                    label: 'Wins',
                    value: profile.wins.toString(),
                  ),
                  StatItem(
                    label: 'Losses',
                    value: profile.losses.toString(),
                  ),
                  StatItem(
                    label: 'MVP',
                    value: profile.mvpCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Per-Sport Stats ───────────────────────
              if (profile.careerStatsRaw != null && profile.careerStatsRaw!.isNotEmpty) ...[
                const SectionHeader(title: 'Career Stats'),
                const SizedBox(height: AppSpacing.md),
                ...profile.careerStatsRaw!.map((sportRow) {
                  final sportName = ((sportRow['sport'] as String?) ?? 'Unknown').toUpperCase();
                  final counters = sportRow['career_counters'] as Map<String, dynamic>? ?? {};
                  final matches = sportRow['matches_played'] ?? 0;
                  
                  // Helper to safely format counters
                  String val(String key) => (counters[key] ?? 0).toString();

                  List<String> statLines = [];
                  if (sportName == 'CRICKET') {
                    final runs = counters['runs_scored'] ?? 0;
                    final ballsFaced = counters['balls_faced'] ?? 0;
                    final sr = ballsFaced > 0 ? ((runs / ballsFaced) * 100).toStringAsFixed(1) : '0.0';
                    final wickets = counters['wickets_taken'] ?? 0;
                    final fours = counters['fours'] ?? 0;
                    final sixes = counters['sixes'] ?? 0;
                    
                    final runsConceded = counters['runs_conceded'] ?? 0;
                    final ballsBowled = counters['balls_bowled'] ?? 0;
                    final oversBowled = ballsBowled / 6.0;
                    final econ = oversBowled > 0 ? (runsConceded / oversBowled).toStringAsFixed(1) : '0.0';
                    
                    statLines.add('Batting: $runs Runs • SR: $sr');
                    statLines.add('Boundaries: $fours (4s) • $sixes (6s)');
                    if (wickets > 0 || ballsBowled > 0) {
                      statLines.add('Bowling: $wickets Wkts • Econ: $econ');
                    }
                  } else if (sportName == 'FOOTBALL') {
                    statLines.add('Goals: ${val('goals')} • Assists: ${val('assists')}');
                    statLines.add('Saves: ${val('saves')} • Yellow/Red: ${val('yellow_cards')}/${val('red_cards')}');
                  } else if (sportName == 'BADMINTON') {
                    statLines.add('Points: ${val('points_won')}');
                  }

                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sportName,
                                style: AppTypography.title.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (statLines.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                ...statLines.map((line) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    line,
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$matches Matches',
                              style: AppTypography.body.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${val('matches_won')}W - ${val('matches_lost')}L',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // ─── Sports ─────────────────────────────────
              const SectionHeader(title: 'Sports'),
              const SizedBox(height: AppSpacing.md),
              if (profile.sports.isEmpty)
                Text(
                  'No sports added yet',
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: profile.sports
                      .map((sport) => AppChip(
                            label: '${sport.sportName} · ${sport.skillLevel}',
                            isSelected: true,
                          ))
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Achievements ───────────────────────────
              const SectionHeader(
                title: 'Achievements',
                actionLabel: 'See all',
              ),
              const SizedBox(height: AppSpacing.md),
              const BadgeGrid(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}
