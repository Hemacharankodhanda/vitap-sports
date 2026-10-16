/// VIT-AP Sports — Tournament Service.
///
/// Handles database queries, realtime subscriptions, and RPC invocations for
/// tournaments, entries, groups, fixtures, and draw management.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/tournament_models.dart';

class TournamentService {
  TournamentService(this._client);
  final SupabaseClient _client;

  // ─── Query Operations ────────────────────────────────────────────────────

  /// Fetches tournaments with optional filters for [sport] and [status].
  Future<List<TournamentModel>> getTournaments({
    String? sport,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client.from('tournaments').select('*');
    if (sport != null && sport.isNotEmpty && sport.toLowerCase() != 'all') {
      query = query.eq('sport', sport.toLowerCase());
    }
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query = query.eq('status', status.toLowerCase());
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => TournamentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches a single tournament by [id].
  Future<TournamentModel?> getTournament(String id) async {
    final data = await _client.from('tournaments').select('*').eq('id', id).maybeSingle();
    return data != null ? TournamentModel.fromJson(data) : null;
  }

  /// Fetches approved entries for [tournamentId].
  Future<List<TournamentEntry>> getEntries(String tournamentId) async {
    final data = await _client
        .from('tournament_entries')
        .select('*')
        .eq('tournament_id', tournamentId);

    final entries = (data as List)
        .map((e) => TournamentEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) {
      if (a.seed != null && b.seed != null) {
        return a.seed!.compareTo(b.seed!);
      }
      if (a.seed != null) return -1;
      if (b.seed != null) return 1;
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      return 0;
    });
    return _deduplicateEntries(entries);
  }

  /// Fetches groups for [tournamentId].
  Future<List<TournamentGroup>> getGroups(String tournamentId) async {
    final data = await _client
        .from('tournament_groups')
        .select('*')
        .eq('tournament_id', tournamentId)
        .order('order_index', ascending: true);

    return (data as List).map((e) => TournamentGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches fixtures for [tournamentId].
  Future<List<TournamentFixture>> getFixtures(String tournamentId) async {
    final data = await _client
        .from('tournament_fixtures')
        .select('*')
        .eq('tournament_id', tournamentId);

    final fixtures = (data as List)
        .map((e) => TournamentFixture.fromJson(e as Map<String, dynamic>))
        .toList();
    fixtures.sort((a, b) {
      final rComp = a.round.compareTo(b.round);
      if (rComp != 0) return rComp;
      return a.position.compareTo(b.position);
    });
    return fixtures;
  }

  /// Checks if current user is an admin or organiser of [tournamentId].
  Future<bool> isUserAdmin(String tournamentId, String userId) async {
    final res = await _client.rpc(
      'is_tournament_admin',
      params: {
        'p_tournament_id': tournamentId,
        'p_user_id': userId,
      },
    );
    return res == true;
  }

  // ─── Realtime Streams ────────────────────────────────────────────────────

  /// Realtime stream of tournament fixtures.
  Stream<List<TournamentFixture>> streamFixtures(String tournamentId) {
    return _client
        .from('tournament_fixtures')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .map((data) {
          final fixtures = data.map((e) => TournamentFixture.fromJson(e)).toList();
          fixtures.sort((a, b) {
            final rComp = a.round.compareTo(b.round);
            if (rComp != 0) return rComp;
            return a.position.compareTo(b.position);
          });
          return fixtures;
        });
  }

  /// Realtime stream of tournament entries.
  Stream<List<TournamentEntry>> streamEntries(String tournamentId) {
    return _client
        .from('tournament_entries')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .map((data) {
          final entries = data.map((e) => TournamentEntry.fromJson(e)).toList();
          entries.sort((a, b) {
            if (a.seed != null && b.seed != null) {
              return a.seed!.compareTo(b.seed!);
            }
            if (a.seed != null) return -1;
            if (b.seed != null) return 1;
            if (a.createdAt != null && b.createdAt != null) {
              return a.createdAt!.compareTo(b.createdAt!);
            }
            return 0;
          });
          return _deduplicateEntries(entries);
        });
  }

  /// Sanitizes and collapses duplicate entries for the same team or user.
  List<TournamentEntry> _deduplicateEntries(List<TournamentEntry> raw) {
    final seenIds = <String>{};
    final seenTeamIds = <String>{};
    final seenUserIds = <String>{};
    final seenNames = <String>{};
    final unique = <TournamentEntry>[];

    final sorted = List<TournamentEntry>.from(raw);
    sorted.sort((a, b) {
      if (a.status == EntryStatus.approved && b.status != EntryStatus.approved) return -1;
      if (b.status == EntryStatus.approved && a.status != EntryStatus.approved) return 1;
      return 0;
    });

    for (final e in sorted) {
      if (e.status == EntryStatus.withdrawn || e.status == EntryStatus.disqualified) {
        continue;
      }

      if (e.id.isNotEmpty && seenIds.contains(e.id)) continue;

      if (e.teamId != null && e.teamId!.isNotEmpty && seenTeamIds.contains(e.teamId)) {
        continue;
      }

      if (e.userId != null && e.userId!.isNotEmpty && seenUserIds.contains(e.userId)) {
        continue;
      }

      final normName = e.displayName.trim().toLowerCase();
      if (normName.isNotEmpty && seenNames.contains(normName)) {
        continue;
      }

      if (e.id.isNotEmpty) seenIds.add(e.id);
      if (e.teamId != null && e.teamId!.isNotEmpty) seenTeamIds.add(e.teamId!);
      if (e.userId != null && e.userId!.isNotEmpty) seenUserIds.add(e.userId!);
      if (normName.isNotEmpty) seenNames.add(normName);

      unique.add(e);
    }
    return unique;
  }

  // ─── RPC Operations ──────────────────────────────────────────────────────

  /// Creates a tournament via security definer RPC.
  Future<TournamentModel> createTournament({
    required String name,
    required String sport,
    required TournamentFormat format,
    TournamentScope scope = TournamentScope.open,
    Map<String, dynamic> config = const {},
    Map<String, dynamic> eligibility = const {},
    int? maxEntries,
    DateTime? registrationDeadline,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _client.rpc(
      'create_tournament',
      params: {
        'p_name': name,
        'p_sport': sport.toLowerCase(),
        'p_format': format.sqlValue,
        'p_scope': scope.name,
        'p_config': config,
        'p_eligibility': eligibility,
        'p_max_entries': maxEntries,
        'p_registration_deadline': registrationDeadline?.toIso8601String(),
        'p_start_date': startDate?.toIso8601String(),
        'p_end_date': endDate?.toIso8601String(),
      },
    );
    return TournamentModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Updates the lifecycle status of [tournamentId].
  Future<TournamentModel> updateTournamentStatus({
    required String tournamentId,
    required TournamentStatus status,
  }) async {
    final res = await _client.rpc(
      'update_tournament_status',
      params: {
        'p_tournament_id': tournamentId,
        'p_status': status.sqlValue,
      },
    );
    return TournamentModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Registers an entry for [tournamentId].
  Future<TournamentEntry> registerEntry({
    required String tournamentId,
    required EntryKind kind,
    String? teamId,
    String? userId,
    String? partnerId,
    String? displayName,
    Map<String, dynamic> metadata = const {},
  }) async {
    final res = await _client.rpc(
      'register_tournament_entry',
      params: {
        'p_tournament_id': tournamentId,
        'p_kind': kind.name,
        'p_team_id': teamId,
        'p_user_id': userId,
        'p_partner_id': partnerId,
        'p_display_name': displayName,
        'p_metadata': metadata,
      },
    );
    return TournamentEntry.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Withdraws an entry from [tournamentId].
  Future<void> withdrawEntry({
    required String tournamentId,
    required String entryId,
    String reason = 'Participant withdrawal',
  }) async {
    await _client.rpc(
      'withdraw_tournament_entry',
      params: {
        'p_tournament_id': tournamentId,
        'p_entry_id': entryId,
        'p_reason': reason,
      },
    );
  }

  /// Approves a pending entry for [tournamentId].
  Future<TournamentEntry> approveEntry({
    required String tournamentId,
    required String entryId,
  }) async {
    final res = await _client.rpc(
      'approve_tournament_entry',
      params: {
        'p_tournament_id': tournamentId,
        'p_entry_id': entryId,
      },
    );
    return TournamentEntry.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Rejects an entry for [tournamentId].
  Future<TournamentEntry> rejectEntry({
    required String tournamentId,
    required String entryId,
    String reason = 'Entry rejected by organiser',
  }) async {
    final res = await _client.rpc(
      'reject_tournament_entry',
      params: {
        'p_tournament_id': tournamentId,
        'p_entry_id': entryId,
        'p_reason': reason,
      },
    );
    return TournamentEntry.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Saves the generated tournament draw (groups + fixtures).
  Future<void> generateDraw({
    required String tournamentId,
    required List<TournamentFixture> fixtures,
    List<TournamentGroup> groups = const [],
  }) async {
    final fixturesJson = fixtures.map((f) => f.toJson()).toList();
    final groupsJson = groups.map((g) => g.toJson()).toList();

    await _client.rpc(
      'generate_tournament_draw',
      params: {
        'p_tournament_id': tournamentId,
        'p_fixtures': fixturesJson,
        'p_groups': groupsJson,
      },
    );
  }

  /// Schedules a fixture.
  Future<void> scheduleFixture({
    required String fixtureId,
    required DateTime scheduledAt,
    String? venue,
  }) async {
    await _client.rpc(
      'schedule_tournament_fixture',
      params: {
        'p_fixture_id': fixtureId,
        'p_scheduled_at': scheduledAt.toIso8601String(),
        'p_venue': venue,
      },
    );
  }

  /// Initializes a live-scoreable match record for [fixtureId].
  Future<String> createMatchForFixture(String fixtureId) async {
    final res = await _client.rpc(
      'create_match_for_fixture',
      params: {
        'p_fixture_id': fixtureId,
      },
    );
    return (res as Map)['match_id'] as String;
  }

  /// Fetches tournament podium honours (championships, runner-up medals) for [userId].
  Future<List<TournamentHonour>> fetchPlayerHonours(String userId) async {
    try {
      final entriesRes = await _client
          .from('tournament_entries')
          .select('id, tournament_id, display_name, player_ids, tournaments(id, name, sport, start_date, is_official, status)')
          .filter('player_ids', 'cs', '{"$userId"}');

      final honours = <TournamentHonour>[];
      for (final rawEntry in entriesRes as List) {
        final tData = rawEntry['tournaments'] as Map<String, dynamic>?;
        if (tData == null || tData['status'] != 'completed') continue;

        final tId = tData['id'] as String;
        final entryId = rawEntry['id'] as String;

        final fixturesRes = await _client
            .from('tournament_fixtures')
            .select('id, stage, round, winner_entry_id, entry_a_id, entry_b_id')
            .eq('tournament_id', tId)
            .order('round', ascending: false);

        final fixtures = fixturesRes as List;
        if (fixtures.isEmpty) continue;

        final finalFix = fixtures.firstWhere(
          (f) => f['stage'] == 'knockout',
          orElse: () => null,
        );

        if (finalFix != null) {
          final winnerId = finalFix['winner_entry_id'] as String?;
          final aId = finalFix['entry_a_id'] as String?;
          final bId = finalFix['entry_b_id'] as String?;

          final year = tData['start_date'] != null
              ? DateTime.tryParse(tData['start_date'] as String)?.year.toString() ?? '2026'
              : '2026';

          if (winnerId == entryId) {
            honours.add(TournamentHonour(
              tournamentId: tId,
              tournamentName: tData['name'] as String? ?? 'Tournament',
              sport: tData['sport'] as String? ?? 'cricket',
              rank: HonourRank.champion,
              year: year,
              teamOrEntryName: rawEntry['display_name'] as String? ?? 'Entry',
              isOfficial: tData['is_official'] as bool? ?? false,
            ));
          } else if (winnerId != null && (aId == entryId || bId == entryId)) {
            honours.add(TournamentHonour(
              tournamentId: tId,
              tournamentName: tData['name'] as String? ?? 'Tournament',
              sport: tData['sport'] as String? ?? 'cricket',
              rank: HonourRank.runnerUp,
              year: year,
              teamOrEntryName: rawEntry['display_name'] as String? ?? 'Entry',
              isOfficial: tData['is_official'] as bool? ?? false,
            ));
          }
        }
      }
      return honours;
    } catch (_) {
      return [];
    }
  }
}
