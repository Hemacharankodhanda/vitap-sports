/// VIT-AP Sports — Team detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/widgets/stats_row.dart';
import '../providers/team_providers.dart';
import '../widgets/member_tile.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: AppSpacing.iconNav),
            onPressed: () => ref.invalidate(teamDetailProvider(teamId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const ShimmerProfile(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        ),
        data: (team) {
          if (team == null) {
            return const ErrorView(message: 'Team not found');
          }

          final isCaptain = currentUserId == team.captainId;
          final isMember = team.members.any((m) => m.userId == currentUserId);

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
            ),
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ─── Team Logo + Name ─────────────────────
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      imageUrl: team.logoUrl,
                      name: team.name,
                      size: AppAvatarSize.xlarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(team.name, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      team.sportName ?? 'Unknown Sport',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (team.description != null &&
                        team.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        team.description!,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ─── Stats ────────────────────────────────
              StatsRow(stats: [
                StatItem(label: 'Played', value: team.totalMatches.toString()),
                StatItem(label: 'Wins', value: team.wins.toString()),
                StatItem(label: 'Losses', value: team.losses.toString()),
                StatItem(label: 'Draws', value: team.draws.toString()),
              ]),
              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Join/Leave ───────────────────────────
              if (!isMember && !isCaptain)
                AppButton(
                  label: 'Join Team',
                  onPressed: () async {
                    if (currentUserId == null) return;
                    await ref
                        .read(teamServiceProvider)
                        .joinTeam(teamId, currentUserId);
                    ref.invalidate(teamDetailProvider(teamId));
                  },
                )
              else if (isMember && !isCaptain)
                AppButton(
                  label: 'Leave Team',
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    if (currentUserId == null) return;
                    await ref
                        .read(teamServiceProvider)
                        .leaveTeam(teamId, currentUserId);
                    ref.invalidate(teamDetailProvider(teamId));
                  },
                )
              else if (isCaptain)
                AppButton(
                  label: 'Delete Team',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.delete_outline_rounded,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Team'),
                        content: const Text('Are you sure you want to delete this team? This will also remove all players. This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(teamServiceProvider).deleteTeam(teamId);
                        ref.invalidate(teamsListProvider);
                        if (context.mounted) context.pop();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              
              if (!isMember && !isCaptain || isMember && !isCaptain || isCaptain)
                const SizedBox(height: AppSpacing.sectionGap),

              // ─── Roster ───────────────────────────────
              SectionHeader(
                title: 'Roster (${team.members.length})',
              ),
              const SizedBox(height: AppSpacing.md),
              if (team.members.isEmpty)
                const EmptyState(
                  icon: Icons.person_outline_rounded,
                  title: 'No members yet',
                )
              else
                ...team.members.map((member) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MemberTile(
                        member: member,
                        showRemove: isCaptain && member.userId != team.captainId,
                        onRemove: () async {
                          await ref
                              .read(teamServiceProvider)
                              .removeMember(teamId, member.userId);
                          ref.invalidate(teamDetailProvider(teamId));
                        },
                      ),
                    )),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}
