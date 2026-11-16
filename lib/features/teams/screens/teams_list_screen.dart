/// VIT-AP Sports — Teams list screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/frosted_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/sport_filter_bar.dart';
import '../providers/team_providers.dart';
import '../widgets/team_card.dart';

class TeamsListScreen extends ConsumerStatefulWidget {
  const TeamsListScreen({super.key});

  @override
  ConsumerState<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends ConsumerState<TeamsListScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = AppBreakpoints.screenPadding(context);
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: FrostedAppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: AppSpacing.iconNav),
            onPressed: () => ref.invalidate(teamsListProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/teams/create'),
            tooltip: 'Create Team',
          ),
          IconButton(
            icon: const Icon(Icons.person_search_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/teams/recruitment'),
            tooltip: 'Recruitment',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Sport Filter Bar ───────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            child: SportFilterBar(
              compact: true,
              padding: EdgeInsets.symmetric(horizontal: padding),
            ),
          ),

          // ─── Team List ──────────────────────────────
          Expanded(
            child: teamsAsync.when(
              loading: () => const ShimmerList(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(teamsListProvider),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No teams yet',
                    subtitle: 'Create a team to get started!',
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: teams.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, index) => TeamCard(
                    team: teams[index],
                    onTap: () => context.go('/teams/${teams[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
