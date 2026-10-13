/// VIT-AP Sports — Public Profile screen.
///
/// View another player's profile: avatar, name, branch/year, stats, badges, sports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../tournaments/presentation/widgets/tournament_honours_section.dart';
import '../../tournaments/providers/tournament_providers.dart';
import '../providers/profile_provider.dart';
import '../widgets/badge_grid.dart';
import '../widgets/player_career_stats_card.dart';
import '../widgets/stats_row.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.playerId,
  });

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(playerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Player Profile'),
      ),
      body: profileAsync.when(
        loading: () => const ShimmerProfile(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(playerId)),
        ),
        data: (profile) {
          if (profile == null) {
            return const ErrorView(message: 'Player not found');
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

              // ─── Per-Sport Career Stats ─────────────────
              if (profile.careerStatsRaw != null && profile.careerStatsRaw!.isNotEmpty) ...[
                const SectionHeader(title: 'Career Stats'),
                const SizedBox(height: AppSpacing.md),
                ...profile.careerStatsRaw!.map(
                  (sportRow) => PlayerCareerStatsCard(sportRow: sportRow),
                ),
                const SizedBox(height: AppSpacing.md),
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

              // ─── Tournament Honours ─────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final honoursAsync = ref.watch(playerTournamentHonoursProvider(profile.id));
                  return TournamentHonoursSection(
                    honours: honoursAsync.value ?? const [],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Achievements ───────────────────────────
              const SectionHeader(title: 'Achievements'),
              const SizedBox(height: AppSpacing.md),
              const BadgeGrid(),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
          );
        },
      ),
    );
  }
}
