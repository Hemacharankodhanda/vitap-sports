/// VIT-AP Sports — Profile service.
///
/// CRUD operations for user profile + user_sports in Supabase.
library;

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

    final Map<String, dynamic> mutableResponse = Map<String, dynamic>.from(response);
    mutableResponse['career_stats'] = statsResponse;

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
