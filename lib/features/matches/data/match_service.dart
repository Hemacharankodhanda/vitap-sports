/// VIT-AP Sports — Match service.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'models/match_model.dart';

class MatchService {
  MatchService(this._client);
  final SupabaseClient _client;

  static const _matchSelect =
      '*, sports(*), match_participants(*, teams(*), users(*))';

  Future<List<MatchModel>> getMatches({
    int page = 0,
    int pageSize = SupabaseConstants.defaultPageSize,
    String? sportId,
    String? status,
  }) async {
    var query = _client.from('matches').select(_matchSelect);
    if (sportId != null) query = query.eq('sport_id', sportId);
    if (status != null) query = query.eq('status', status);

    final data = await query
        .order('scheduled_at', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return data.map((e) => MatchModel.fromJson(e)).toList();
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final data = await _client
        .from('matches')
        .select(_matchSelect)
        .eq('id', matchId)
        .maybeSingle();
    return data != null ? MatchModel.fromJson(data) : null;
  }

  Future<void> deleteMatch(String matchId) async {
    // Delete dependent records first to avoid foreign key constraints
    await _client.from('scorecards').delete().eq('match_id', matchId);
    await _client.from('match_participants').delete().eq('match_id', matchId);
    await _client.from('matches').delete().eq('id', matchId);
  }

  Future<List<Map<String, dynamic>>> getMatchAnalysis(String matchId) async {
    final data = await _client
        .from('player_match_stats')
        .select('*, users(name, avatar_url)')
        .eq('match_id', matchId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<MatchModel> createMatch({
    required String sportId,
    required String venue,
    required DateTime scheduledAt,
    required String createdBy,
    String? format,
    String? description,
    String? homeTeamId,
    String? awayTeamId,
  }) async {
    final response = await _client.from('matches').insert({
      'sport_id': sportId,
      'venue': venue,
      'scheduled_at': scheduledAt.toIso8601String(),
      'created_by': createdBy,
      'format': format,
      'description': description,
      'status': 'upcoming',
    }).select('id').single();

    final matchId = response['id'] as String;

    if (homeTeamId != null) {
      await _client.from('match_participants').insert({
        'match_id': matchId,
        'team_id': homeTeamId,
        'side': 'home',
      });
    }
    if (awayTeamId != null) {
      await _client.from('match_participants').insert({
        'match_id': matchId,
        'team_id': awayTeamId,
        'side': 'away',
      });
    }

    return (await getMatch(matchId))!;
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    await _client.from('matches').update({'status': status}).eq('id', matchId);
  }

  Future<void> rsvp(String matchId, String userId, String status) async {
    await _client.from('match_participants').upsert({
      'match_id': matchId,
      'user_id': userId,
      'side': 'individual',
      'rsvp_status': status,
    });
  }

  Future<void> setPlayingSquad({
    required String matchId,
    required String teamId,
    required String side,
    required List<String> userIds,
  }) async {
    // First remove any existing individual participants for this team in this match
    await _client
        .from('match_participants')
        .delete()
        .eq('match_id', matchId)
        .eq('team_id', teamId)
        .not('user_id', 'is', null);

    if (userIds.isEmpty) return;

    // Insert the selected players
    final rows = userIds.map((userId) => {
          'match_id': matchId,
          'team_id': teamId,
          'user_id': userId,
          'side': side,
          'rsvp_status': 'confirmed',
        }).toList();

    await _client.from('match_participants').insert(rows);
  }
}
