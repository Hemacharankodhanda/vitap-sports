library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/frosted_bar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../providers/tournament_providers.dart';
import '../widgets/create_tournament_sheet.dart';
import '../widgets/tournament_card.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final filter = ref.watch(tournamentFilterProvider);
    final tournamentsAsync = ref.watch(tournamentsListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: FrostedAppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tournamentsListProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primaryFill,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
        onPressed: () => CreateTournamentSheet.show(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReadingWidth),
          child: Column(
            children: [
              // Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: AppBreakpoints.screenPadding(context),
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Sport Chips
                    _filterChip(
                      label: 'All Sports',
                      isSelected: filter.sport == 'all',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(sport: 'all'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Cricket',
                      isSelected: filter.sport == 'cricket',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(sport: 'cricket'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Badminton',
                      isSelected: filter.sport == 'badminton',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(sport: 'badminton'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Football',
                      isSelected: filter.sport == 'football',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(sport: 'football'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(height: 20, width: 1, color: colors.divider),
                    const SizedBox(width: AppSpacing.md),

                    // Status Chips
                    _filterChip(
                      label: 'All Status',
                      isSelected: filter.status == 'all',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(status: 'all'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Live',
                      isSelected: filter.status == 'live',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(status: 'live'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Registration Open',
                      isSelected: filter.status == 'registration_open',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(status: 'registration_open'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      label: 'Completed',
                      isSelected: filter.status == 'completed',
                      onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                          filter.copyWith(status: 'completed'),
                    ),
                  ],
                ),
              ),
              Divider(height: 0.5, thickness: 0.5, color: colors.divider),

              // List Body
              Expanded(
                child: tournamentsAsync.when(
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (err, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(tournamentsListProvider),
                  ),
                  data: (tournaments) {
                    if (tournaments.isEmpty) {
                      return EmptyState(
                        title: 'No tournaments found',
                        subtitle: 'Check back later or organize a new tournament',
                        actionLabel: 'Create Tournament',
                        onAction: () => CreateTournamentSheet.show(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(tournamentsListProvider.future),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppBreakpoints.screenPadding(context),
                          vertical: AppSpacing.md,
                        ),
                        itemCount: tournaments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = tournaments[index];
                          return TournamentCard(
                            tournament: item,
                            onTap: () {
                              final path = GoRouterState.of(context).uri.path;
                              if (path.startsWith('/leaderboard')) {
                                context.push('/leaderboard/tournaments/${item.id}');
                              } else {
                                context.push('/tournaments/${item.id}');
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
