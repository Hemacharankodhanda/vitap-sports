/// VIT-AP Sports — Profile service.
///
/// CRUD operations for user profile + user_sports in Supabase.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'models/user_model.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  Future<UserModel?> getProfile(String userId) async {
    final response = await _client
        .from('users')
        .select('*, user_sports(*, sports(*))')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    final statsResponse = await _client
        .from('player_career_stats')
        .select('*')
        .eq('player_id', userId);

    // Build sport lookup map: sportId -> sportName
    final sportIdToName = <String, String>{};
    final userSportsRaw = response['user_sports'] as List<dynamic>? ?? [];
    for (final item in userSportsRaw) {
      if (item is Map) {
        final sId = item['sport_id']?.toString();
        final sObj = item['sports'] as Map<String, dynamic>?;
        final sName = sObj?['name']?.toString();
        if (sId != null && sName != null) {
          sportIdToName[sId] = sName;
        }
      }
    }

    // Resolve any remaining sports via sports table
    try {
      final sportsData = await _client.from('sports').select('id, name');
      for (final s in sportsData) {
        final id = s['id']?.toString();
        final name = s['name']?.toString();
        if (id != null && name != null) {
          sportIdToName[id] = name;
        }
      }
    } catch (_) {}

    final List<Map<String, dynamic>> resolvedStats = [];
    final Set<String> sportsWithStats = {};

    for (final raw in (statsResponse as List<dynamic>)) {
      if (raw is Map) {
        final row = Map<String, dynamic>.from(raw);
        if (row['career_counters'] is String) {
          try {
            row['career_counters'] = jsonDecode(row['career_counters'] as String);
          } catch (_) {}
        }
        final rawSport = row['sport']?.toString() ?? 'cricket';
        final resolvedSport = sportIdToName[rawSport] ?? rawSport;
        row['sport'] = resolvedSport.toLowerCase();
        row['sport_display_name'] = resolvedSport;
        resolvedStats.add(row);
        sportsWithStats.add(resolvedSport.toLowerCase());
      }
    }

    // Provide zeroed stats entry for registered sports without matches yet
    for (final entry in sportIdToName.values) {
      if (!sportsWithStats.contains(entry.toLowerCase())) {
        resolvedStats.add({
          'player_id': userId,
          'sport': entry.toLowerCase(),
          'sport_display_name': entry,
          'matches_played': 0,
          'career_counters': <String, dynamic>{},
        });
        sportsWithStats.add(entry.toLowerCase());
      }
    }

    // If there is only one sport with matches or single sport, and career_counters has 0 wins/losses while users row has stats, bridge them
    if (resolvedStats.isNotEmpty) {
      final activeSports = resolvedStats.where((s) => ((s['matches_played'] as num?)?.toInt() ?? 0) > 0).toList();
      final target = activeSports.length == 1 ? activeSports.first : (resolvedStats.length == 1 ? resolvedStats.first : null);
      if (target != null) {
        final counters = Map<String, dynamic>.from((target['career_counters'] as Map<String, dynamic>?) ?? {});
        final userWins = (response['wins'] as num?)?.toInt() ?? 0;
        final userLosses = (response['losses'] as num?)?.toInt() ?? 0;
        final userMvps = (response['mvp_count'] as num?)?.toInt() ?? 0;
        if (((counters['matches_won'] as num?)?.toInt() ?? 0) == 0 && userWins > 0) {
          counters['matches_won'] = userWins;
        }
        if (((counters['matches_lost'] as num?)?.toInt() ?? 0) == 0 && userLosses > 0) {
          counters['matches_lost'] = userLosses;
        }
        if (((counters['mvps'] as num?)?.toInt() ?? 0) == 0 && userMvps > 0) {
          counters['mvps'] = userMvps;
        }
        target['career_counters'] = counters;
      }
    }

    final Map<String, dynamic> mutableResponse = Map<String, dynamic>.from(response);
    mutableResponse['career_stats'] = resolvedStats;

    return UserModel.fromJson(mutableResponse);
  }

  /// Fetch any user's profile by ID.
  Future<UserModel?> getUserProfile(String userId) async {
    return getProfile(userId);
  }

  /// Create a new profile (onboarding).
  Future<UserModel> createProfile({
    required String userId,
    required String name,
    required String branch,
    required String year,
    required String hostelBlock,
    required List<String> sportNames,
    required Map<String, String> skillLevels,
    String? avatarUrl,
  }) async {
    // Insert user row
    await _client.from('users').upsert({
      'id': userId,
      'name': name,
      'branch': branch,
      'year': year,
      'hostel_block': hostelBlock,
      'avatar_url': avatarUrl,
    });

    // Get sport IDs from names
    final sportsData = await _client
        .from('sports')
        .select('id, name')
        .inFilter('name', sportNames);

    // Insert user_sports
    final userSports = <Map<String, dynamic>>[];
    for (final sport in sportsData) {
      final sportName = sport['name'] as String;
      userSports.add({
        'user_id': userId,
        'sport_id': sport['id'],
        'skill_level': skillLevels[sportName] ?? 'Beginner',
      });
    }

    if (userSports.isNotEmpty) {
      await _client.from('user_sports').upsert(userSports);
    }

    return (await getProfile(userId))!;
  }

  /// Update profile fields.
  Future<UserModel> updateProfile(String userId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('users').update(updates).eq('id', userId);
    return (await getProfile(userId))!;
  }

  /// Update user sports and skill levels.
  Future<void> updateUserSports(
    String userId,
    List<String> sportNames,
    Map<String, String> skillLevels,
  ) async {
    // Remove existing
    await _client.from('user_sports').delete().eq('user_id', userId);

    // Get sport IDs
    final sportsData = await _client
        .from('sports')
        .select('id, name')
        .inFilter('name', sportNames);

    final userSports = <Map<String, dynamic>>[];
    for (final sport in sportsData) {
      final sportName = sport['name'] as String;
      userSports.add({
        'user_id': userId,
        'sport_id': sport['id'],
        'skill_level': skillLevels[sportName] ?? 'Beginner',
      });
    }

    if (userSports.isNotEmpty) {
      await _client.from('user_sports').insert(userSports);
    }
  }

  /// Upload avatar image and return URL.
  Future<String> uploadAvatar(String userId, Uint8List imageData) async {
    final path = '$userId/avatar.jpg';

    await _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .getPublicUrl(path);
  }
}
