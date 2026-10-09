/// VIT-AP Sports — Matches list screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/sport_filter_bar.dart';
import '../providers/match_providers.dart';
import '../widgets/match_card.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Upcoming', 'Live', 'Completed'];
  static const _statuses = ['upcoming', 'live', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = _statuses[_tabController.index];
    final matchesAsync = ref.watch(
      matchesListProvider(currentStatus),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: AppSpacing.iconNav),
            onPressed: () => ref.invalidate(matchesListProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/matches/create'),
            tooltip: 'Create Match',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          const SportFilterBar(),
          Expanded(
            child: matchesAsync.when(
              loading: () => const ShimmerList(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  matchesListProvider(currentStatus),
                ),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return EmptyState(
                    icon: Icons.sports_rounded,
                    title: 'No ${_tabs[_tabController.index].toLowerCase()} matches',
                    subtitle: 'Matches will appear here when created.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                    vertical: AppSpacing.lg,
                  ),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, index) => MatchCard(
                    match: matches[index],
                    onTap: () => context.go('/matches/${matches[index].id}'),
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
