/// VIT-AP Sports — Tournament List Screen.
///
/// Overview list with sport & status filters and tournament creation entry point.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
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
      appBar: AppBar(
        title: Text(
          'Tournaments',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tournamentsListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
        onPressed: () => CreateTournamentSheet.show(context),
      ),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Sport Chips
                _filterChip(
                  label: 'All Sports',
                  isSelected: filter.sport == 'all',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(sport: 'all'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Cricket',
                  isSelected: filter.sport == 'cricket',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(sport: 'cricket'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Badminton',
                  isSelected: filter.sport == 'badminton',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(sport: 'badminton'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Football',
                  isSelected: filter.sport == 'football',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(sport: 'football'),
                ),
                const SizedBox(width: 16),
                Container(height: 20, width: 1, color: colors.border),
                const SizedBox(width: 16),

                // Status Chips
                _filterChip(
                  label: 'All Status',
                  isSelected: filter.status == 'all',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(status: 'all'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Live',
                  isSelected: filter.status == 'live',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(status: 'live'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Registration Open',
                  isSelected: filter.status == 'registration_open',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(status: 'registration_open'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Completed',
                  isSelected: filter.status == 'completed',
                  onTap: () => ref.read(tournamentFilterProvider.notifier).state =
                      filter.copyWith(status: 'completed'),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.border),

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
                    padding: const EdgeInsets.all(16),
                    itemCount: tournaments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
