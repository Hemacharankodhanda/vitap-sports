/// VIT-AP Sports — Team service.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'models/team_model.dart';

class TeamService {
  TeamService(this._client);
  final SupabaseClient _client;

  static const _teamSelect =
      '*, sports(*), captain:users!teams_captain_id_fkey(*), team_members(*, users(*))';

  Future<List<TeamModel>> getTeams({
    int page = 0,
    int pageSize = SupabaseConstants.defaultPageSize,
    String? sportId,
  }) async {
    var query = _client.from('teams').select(_teamSelect);
    if (sportId != null) query = query.eq('sport_id', sportId);
    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return data.map((e) => TeamModel.fromJson(e)).toList();
  }

  Future<TeamModel?> getTeam(String teamId) async {
    try {
      final data = await _client
          .from('teams')
          .select(_teamSelect)
          .eq('id', teamId)
          .maybeSingle();
      if (data != null) return TeamModel.fromJson(data);
    } catch (_) {
      // Fallback without captain constraint alias if fkey differs in schema
      try {
        final fallback = await _client
            .from('teams')
            .select('*, sports(*), team_members(*, users(*))')
            .eq('id', teamId)
            .maybeSingle();
        if (fallback != null) return TeamModel.fromJson(fallback);
      } catch (_) {
        // Last-resort simple select
        try {
          final basic = await _client
              .from('teams')
              .select()
              .eq('id', teamId)
              .maybeSingle();
          if (basic != null) return TeamModel.fromJson(basic);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> deleteTeam(String teamId) async {
    // Delete dependent records first to avoid foreign key constraints
    await _client.from('team_members').delete().eq('team_id', teamId);
    await _client.from('match_participants').delete().eq('team_id', teamId);
    await _client.from('teams').delete().eq('id', teamId);
  }

  Future<List<TeamModel>> getUserTeams(String userId) async {
    final memberRows = await _client
        .from('team_members')
        .select('team_id')
        .eq('user_id', userId);
    final teamIds = memberRows.map((e) => e['team_id'] as String).toList();
    if (teamIds.isEmpty) return [];

    final data = await _client
        .from('teams')
        .select(_teamSelect)
        .inFilter('id', teamIds);
    return data.map((e) => TeamModel.fromJson(e)).toList();
  }
  Future<bool> hasTeamForSport(String userId, String sportId) async {
    final count = await _client
        .from('teams')
        .select('id')
        .eq('captain_id', userId)
        .eq('sport_id', sportId)
        .count(CountOption.exact);
    return count.count > 0;
  }


  Future<TeamModel> createTeam({
    required String name,
    required String sportId,
    required String captainId,
    String? description,
    String? logoUrl,
  }) async {
    final response = await _client.from('teams').insert({
      'name': name,
      'sport_id': sportId,
      'captain_id': captainId,
      'description': description,
      'logo_url': logoUrl,
    }).select('id').single();

    final teamId = response['id'] as String;

    // Add captain as team member
    await _client.from('team_members').insert({
      'team_id': teamId,
      'user_id': captainId,
      'role': 'captain',
    });

    return (await getTeam(teamId))!;
  }

  Future<void> joinTeam(String teamId, String userId) async {
    await _client.from('team_members').insert({
      'team_id': teamId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> leaveTeam(String teamId, String userId) async {
    await _client
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }

  Future<void> removeMember(String teamId, String userId) async {
    await leaveTeam(teamId, userId);
  }

  Future<String> uploadTeamLogo(String teamId, Uint8List imageData) async {
    final path = '$teamId/logo.jpg';
    await _client.storage.from(SupabaseConstants.teamLogosBucket).uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _client.storage.from(SupabaseConstants.teamLogosBucket).getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> getSports() async {
    return _client.from('sports').select('id, name, icon').order('name');
  }
}
