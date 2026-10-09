/// VIT-AP Sports — Live Scorer Service.
///
/// Handles database queries, Supabase RPCs, and Realtime event streaming
/// for live match scoring.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/match_event.dart';

class LiveScorerService {
  LiveScorerService(this._client);
  final SupabaseClient _client;

  SupabaseClient get client => _client;

  /// Fetches a match record with sports and participant details.
  Future<Map<String, dynamic>?> fetchMatch(String matchId) async {
    final data = await _client
        .from('matches')
        .select('*, sports(*), match_participants(*, teams(*), users(*))')
        .eq('id', matchId)
        .maybeSingle();
    return data;
  }

  /// Fetches all historical match events in chronological order.
  Future<List<MatchEvent>> fetchEvents(String matchId) async {
    final response = await _client
        .from('match_events')
        .select('*')
        .eq('match_id', matchId)
        .order('seq', ascending: true);

    final list = response as List<dynamic>;
    return list
        .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Atomically records a scoring event via Postgres RPC.
  Future<Map<String, dynamic>> recordEvent({
    required String matchId,
    required MatchEvent event,
    required Map<String, dynamic> snapshot,
  }) async {
    final response = await _client.rpc(
      'record_event',
      params: {
        'p_match_id': matchId,
        'p_event': event.toJson(),
        'p_snapshot': snapshot,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': true};
  }

  /// Atomically un-does the specified event and rolls back the snapshot.
  Future<Map<String, dynamic>> undoEvent({
    required String matchId,
    required String eventId,
    required Map<String, dynamic> snapshot,
  }) async {
    final response = await _client.rpc(
      'undo_event',
      params: {
        'p_match_id': matchId,
        'p_event_id': eventId,
        'p_snapshot': snapshot,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': true};
  }

  /// Atomically completes the match, writes results, and updates stats.
  Future<Map<String, dynamic>> finishMatch({
    required String matchId,
    required Map<String, dynamic> result,
    required Map<String, dynamic> finalScore,
  }) async {
    final response = await _client.rpc(
      'finish_match',
      params: {
        'p_match_id': matchId,
        'p_result': result,
        'p_final_score': finalScore,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': true};
  }

  /// Takes over scoring role for the caller (if creator or captain).
  Future<Map<String, dynamic>> takeOverScoring(String matchId) async {
    final response = await _client.rpc(
      'take_over_scoring',
      params: {
        'p_match_id': matchId,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': true};
  }

  /// Starts a scheduled match with sport-specific initial config and state.
  Future<void> startMatch({
    required String matchId,
    required Map<String, dynamic> config,
    required Map<String, dynamic> initialScore,
  }) async {
    try {
      await _client.rpc(
        'start_match',
        params: {
          'p_match_id': matchId,
          'p_config': config,
          'p_initial_score': initialScore,
        },
      );
    } catch (_) {
      // Fallback to direct update if RPC is not deployed yet
      await _client.from('matches').update({
        'status': 'live',
        'config': config,
        'score': initialScore,
      }).eq('id', matchId);
    }
  }

  /// Fetches players belonging to a team from team_members table.
  Future<List<Map<String, dynamic>>> fetchTeamPlayers(String teamId) async {
    try {
      final response = await _client
          .from('team_members')
          .select('team_id, user_id, role, position, users(id, name, avatar_url)')
          .eq('team_id', teamId);
      return (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Realtime stream of the matches row for live viewer updates.
  Stream<Map<String, dynamic>?> streamMatch(String matchId) {
    return _client
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Subscribes to real-time events for this match.
  /// Caller must subscribe first before loading initial events to avoid drop.
  RealtimeChannel subscribeToEvents({
    required String matchId,
    required void Function(MatchEvent event) onInsert,
    required void Function(String eventId) onDelete,
  }) {
    final channel = _client.channel('match_events:$matchId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'match_events',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'match_id',
        value: matchId,
      ),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
          if (payload.newRecord.isNotEmpty) {
            onInsert(MatchEvent.fromJson(payload.newRecord));
          }
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          final id = payload.oldRecord['id'] as String?;
          if (id != null) {
            onDelete(id);
          }
        }
      },
    );
    channel.subscribe();
    return channel;
  }

  /// Unsubscribes and cleans up channel.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
