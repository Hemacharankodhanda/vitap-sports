/// VIT-AP Sports — Tournament Riverpod Providers.
///
/// State management for tournament listings, detail views, real-time fixtures,
/// entries, admin authorization, and pure-Dart derived standings.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/tournament_service.dart';
import '../domain/models/tournament_models.dart';
import '../engines/standings_engine.dart';

/// Provides the [TournamentService] instance configured with the app's Supabase client.
final tournamentServiceProvider = Provider<TournamentService>((ref) {
  return TournamentService(ref.watch(supabaseClientProvider));
});

/// Current filter state for tournament list screens.
class TournamentFilterState {
  const TournamentFilterState({
    this.sport = 'all',
    this.status = 'all',
  });

  final String sport;
  final String status;

  TournamentFilterState copyWith({
    String? sport,
    String? status,
  }) {
    return TournamentFilterState(
      sport: sport ?? this.sport,
      status: status ?? this.status,
    );
  }
}

final tournamentFilterProvider = StateProvider<TournamentFilterState>((ref) {
  return const TournamentFilterState();
});

/// Fetches tournaments filtered by selected sport and status.
final tournamentsListProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  final filter = ref.watch(tournamentFilterProvider);

  return service.getTournaments(
    sport: filter.sport,
    status: filter.status,
  );
});

/// Fetches detail for a single tournament by [tournamentId].
final tournamentDetailProvider =
    FutureProvider.family<TournamentModel?, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournament(tournamentId);
});

/// Fetches or streams approved entries for [tournamentId].
final tournamentEntriesProvider =
    StreamProvider.family<List<TournamentEntry>, String>((ref, tournamentId) {
  final service = ref.watch(tournamentServiceProvider);
  return service.streamEntries(tournamentId);
});

/// Fetches groups for group-stage tournaments.
final tournamentGroupsProvider =
    FutureProvider.family<List<TournamentGroup>, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getGroups(tournamentId);
});

/// Fetches and streams live fixtures for [tournamentId].
final tournamentFixturesProvider =
    StreamProvider.family<List<TournamentFixture>, String>((ref, tournamentId) {
  final service = ref.watch(tournamentServiceProvider);
  return service.streamFixtures(tournamentId);
});

/// Checks if current authenticated user is an organiser or admin for [tournamentId].
final isTournamentAdminProvider =
    FutureProvider.family<bool, String>((ref, tournamentId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final service = ref.watch(tournamentServiceProvider);
  return service.isUserAdmin(tournamentId, user.id);
});

/// Computes live standings derived on read from completed fixtures and entries.
/// Pure-Dart single source of truth without database drift!
final tournamentStandingsProvider =
    Provider.family<AsyncValue<Map<String, List<TournamentStandingsRow>>>, String>(
        (ref, tournamentId) {
  final tournamentAsync = ref.watch(tournamentDetailProvider(tournamentId));
  final entriesAsync = ref.watch(tournamentEntriesProvider(tournamentId));
  final fixturesAsync = ref.watch(tournamentFixturesProvider(tournamentId));
  final groupsAsync = ref.watch(tournamentGroupsProvider(tournamentId));

  if (tournamentAsync.isLoading || entriesAsync.isLoading || fixturesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (tournamentAsync.hasError) {
    return AsyncValue.error(tournamentAsync.error!, tournamentAsync.stackTrace!);
  }
  if (entriesAsync.hasError) {
    return AsyncValue.error(entriesAsync.error!, entriesAsync.stackTrace!);
  }
  if (fixturesAsync.hasError) {
    return AsyncValue.error(fixturesAsync.error!, fixturesAsync.stackTrace!);
  }

  final tournament = tournamentAsync.value;
  final entries = entriesAsync.value ?? [];
  final fixtures = fixturesAsync.value ?? [];
  final groups = groupsAsync.value ?? [];

  if (tournament == null) {
    return const AsyncValue.data({});
  }

  const engine = StandingsEngine();

  if (tournament.format == TournamentFormat.league || tournament.format == TournamentFormat.knockout) {
    // Single overall standings table
    final rows = engine.calculateStandings(
      sport: tournament.sport,
      entries: entries,
      fixtures: fixtures,
      config: tournament.config,
    );
    return AsyncValue.data({'overall': rows});
  } else {
    // Group stage: compute table per group
    final resultMap = <String, List<TournamentStandingsRow>>{};
    final groupMap = {for (final g in groups) g.id: g.name};

    // If groups list is empty, bucket by group_id on entries or 'Group A'
    final groupIds = entries.map((e) => e.groupId).where((id) => id != null).toSet();
    if (groupIds.isEmpty) {
      final rows = engine.calculateStandings(
        sport: tournament.sport,
        entries: entries,
        fixtures: fixtures,
        config: tournament.config,
      );
      return AsyncValue.data({'overall': rows});
    }

    for (final grpId in groupIds) {
      final grpName = groupMap[grpId] ?? 'Group';
      final grpEntries = entries.where((e) => e.groupId == grpId).toList();
      final grpFixtures = fixtures.where((f) => f.groupId == grpId).toList();

      final rows = engine.calculateStandings(
        sport: tournament.sport,
        entries: grpEntries,
        fixtures: grpFixtures,
        config: tournament.config,
      );
      resultMap[grpName] = rows;
    }

    return AsyncValue.data(resultMap);
  }
});

/// Player tournament honours provider (Champions, Runner-ups, 3rd place)
final playerTournamentHonoursProvider =
    FutureProvider.family<List<TournamentHonour>, String>((ref, userId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.fetchPlayerHonours(userId);
});
