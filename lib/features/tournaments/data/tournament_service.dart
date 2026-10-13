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
        .eq('tournament_id', tournamentId)
        .order('seed', ascending: true, nullsFirst: false)
        .order('registered_at', ascending: true);

    return (data as List).map((e) => TournamentEntry.fromJson(e as Map<String, dynamic>)).toList();
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
        .eq('tournament_id', tournamentId)
        .order('round', ascending: true)
        .order('position', ascending: true);

    return (data as List).map((e) => TournamentFixture.fromJson(e as Map<String, dynamic>)).toList();
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
        .order('round', ascending: true)
        .map((data) => data.map((e) => TournamentFixture.fromJson(e)).toList());
  }

  /// Realtime stream of tournament entries.
  Stream<List<TournamentEntry>> streamEntries(String tournamentId) {
    return _client
        .from('tournament_entries')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .order('registered_at', ascending: true)
        .map((data) => data.map((e) => TournamentEntry.fromJson(e)).toList());
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
}
