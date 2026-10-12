/// VIT-AP Sports — Profile service.
///
/// CRUD operations for user profile + user_sports in Supabase.
library;

import 'dart:convert';
import 'dart:math' as math;
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

    // Fetch stats view records
    List<dynamic> statsResponse = [];
    try {
      statsResponse = await _client
          .from('player_career_stats')
          .select('*')
          .eq('player_id', userId);
    } catch (_) {}

    // Fetch individual player match stats rows (if available)
    List<dynamic> matchStatsResponse = [];
    try {
      matchStatsResponse = await _client
          .from('player_match_stats')
          .select('*')
          .eq('player_id', userId);
    } catch (_) {}

    // Fetch match participant records joined with completed matches
    List<dynamic> participantResponse = [];
    try {
      participantResponse = await _client
          .from('match_participants')
          .select('match_id, team_id, side, matches(*, sports(name))')
          .eq('user_id', userId);
    } catch (_) {}

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

    // Per-sport tallies from match participation and match stats
    final perSportTallies = <String, _SportMatchTally>{};

    // 1. Tally from completed match participation
    for (final rawPart in participantResponse) {
      if (rawPart is! Map) continue;
      final m = rawPart['matches'] as Map<String, dynamic>?;
      if (m == null || m['status'] != 'completed') continue;

      final matchId = m['id']?.toString() ?? rawPart['match_id']?.toString() ?? '';
      final sportObj = m['sports'] as Map<String, dynamic>?;
      final rawSport = sportObj?['name']?.toString() ??
          sportIdToName[m['sport_id']?.toString()] ??
          m['sport_id']?.toString() ??
          'cricket';
      final sportName = sportIdToName[rawSport] ?? rawSport;
      final sportKey = sportName.toLowerCase();

      final tally = perSportTallies.putIfAbsent(
        sportKey,
        () => _SportMatchTally(sportName),
      );
      if (matchId.isNotEmpty) tally.matchIds.add(matchId);

      final result = (m['result'] as Map<String, dynamic>?) ?? {};
      final score = (m['score'] as Map<String, dynamic>?) ?? {};
      final pStats = (score['player_stats'] as Map<String, dynamic>?) ?? {};
      final userStats = pStats[userId] as Map<String, dynamic>?;

      bool? isWin;
      if (userStats != null) {
        final w = ((userStats['matches_won'] ?? userStats['wins']) as num?)?.toInt();
        final l = ((userStats['matches_lost'] ?? userStats['losses']) as num?)?.toInt();
        if (w == 1) {
          isWin = true;
        } else if (l == 1) {
          isWin = false;
        }
      }

      if (isWin == null) {
        final isDraw = result['is_draw'] == true || result['is_tie'] == true;
        if (isDraw) {
          // Draw
        } else {
          final winnerSide = result['winner_side']?.toString().toLowerCase();
          final userSide = rawPart['side']?.toString().toLowerCase();
          if (winnerSide != null && (winnerSide == 'home' || winnerSide == 'away')) {
            if (userSide == winnerSide) {
              isWin = true;
            } else if (userSide != null && (userSide == 'home' || userSide == 'away')) {
              isWin = false;
            }
          }

          if (isWin == null) {
            final winnerTeamId = result['winner_team_id']?.toString();
            final userTeamId = rawPart['team_id']?.toString();
            if (winnerTeamId != null && userTeamId != null) {
              if (userTeamId == winnerTeamId) {
                isWin = true;
              } else if (result['loser_team_id']?.toString() == userTeamId) {
                isWin = false;
              }
            }
          }

          if (isWin == null && sportKey.contains('badminton')) {
            final hGames = (result['home_games_won'] ?? result['home_score'] ?? score['home_score'] ?? m['home_score'] as num?)?.toInt();
            final aGames = (result['away_games_won'] ?? result['away_score'] ?? score['away_score'] ?? m['away_score'] as num?)?.toInt();
            if (hGames != null && aGames != null && hGames != aGames) {
              if (userSide == 'home') isWin = hGames > aGames;
              if (userSide == 'away') isWin = aGames > hGames;
            }
          } else if (isWin == null && sportKey.contains('football')) {
            final hScore = (result['home_score'] ?? score['home_score'] ?? m['home_score'] as num?)?.toInt();
            final aScore = (result['away_score'] ?? score['away_score'] ?? m['away_score'] as num?)?.toInt();
            if (hScore != null && aScore != null && hScore != aScore) {
              if (userSide == 'home') isWin = hScore > aScore;
              if (userSide == 'away') isWin = aScore > hScore;
            }
          }
        }
      }

      if (isWin == true) {
        tally.matchWins++;
      } else if (isWin == false) {
        tally.matchLosses++;
      }

      if (result['mvp_user_id']?.toString() == userId || score['mvp_user_id']?.toString() == userId) {
        tally.matchMvps++;
      }
    }

    // 2. Tally from player_match_stats rows
    for (final raw in matchStatsResponse) {
      if (raw is! Map) continue;
      final mid = raw['match_id']?.toString() ?? '';
      final rawSport = raw['sport']?.toString() ?? 'cricket';
      final resolvedSport = sportIdToName[rawSport] ?? rawSport;
      final sportKey = resolvedSport.toLowerCase();

      final tally = perSportTallies.putIfAbsent(
        sportKey,
        () => _SportMatchTally(resolvedSport),
      );
      if (mid.isNotEmpty) tally.matchIds.add(mid);

      var counters = raw['counters'];
      if (counters is String) {
        try { counters = jsonDecode(counters); } catch (_) {}
      }
      final cMap = (counters as Map<String, dynamic>?) ?? {};
      final w = ((cMap['matches_won'] ?? cMap['wins']) as num?)?.toInt() ?? 0;
      final l = ((cMap['matches_lost'] ?? cMap['losses']) as num?)?.toInt() ?? 0;
      final mvp = ((cMap['mvps'] ?? cMap['mvp_count']) as num?)?.toInt() ?? 0;
      tally.pmsWins += w;
      tally.pmsLosses += l;
      tally.pmsMvps += mvp;

      for (final entry in cMap.entries) {
        if (entry.value is num) {
          tally.accumulatedCounters[entry.key] =
              (tally.accumulatedCounters[entry.key] ?? 0) + (entry.value as num);
        }
      }
    }

    // 3. Assemble resolvedStats per sport
    final List<Map<String, dynamic>> resolvedStats = [];
    final Set<String> sportsWithStats = {};

    for (final raw in statsResponse) {
      if (raw is Map) {
        final row = Map<String, dynamic>.from(raw);
        if (row['career_counters'] is String) {
          try {
            row['career_counters'] = jsonDecode(row['career_counters'] as String);
          } catch (_) {}
        }
        final rawSport = row['sport']?.toString() ?? 'cricket';
        final resolvedSport = sportIdToName[rawSport] ?? rawSport;
        final sportKey = resolvedSport.toLowerCase();
        row['sport'] = sportKey;
        row['sport_display_name'] = resolvedSport;

        // Reconcile with perSportTallies
        final tally = perSportTallies[sportKey];
        final counters = Map<String, dynamic>.from(
          (row['career_counters'] as Map<String, dynamic>?) ?? {},
        );

        int viewMatches = (row['matches_played'] as num?)?.toInt() ?? 0;
        int viewWins = ((counters['matches_won'] ?? counters['wins']) as num?)?.toInt() ?? 0;
        int viewLosses = ((counters['matches_lost'] ?? counters['losses']) as num?)?.toInt() ?? 0;
        int viewMvps = ((counters['mvps'] ?? counters['mvp_count']) as num?)?.toInt() ?? 0;

        if (tally != null) {
          viewMatches = math.max(viewMatches, tally.distinctMatches);
          viewWins = math.max(viewWins, tally.effectiveWins);
          viewLosses = math.max(viewLosses, tally.effectiveLosses);
          viewMvps = math.max(viewMvps, tally.effectiveMvps);

          for (final entry in tally.accumulatedCounters.entries) {
            if (!counters.containsKey(entry.key) || ((counters[entry.key] as num?) ?? 0) == 0) {
              counters[entry.key] = entry.value;
            }
          }
        }

        final effectiveMatches = math.max(viewMatches, viewWins + viewLosses);
        row['matches_played'] = effectiveMatches;
        counters['matches_won'] = viewWins;
        counters['matches_lost'] = viewLosses;
        counters['mvps'] = viewMvps;
        row['career_counters'] = counters;
        row['wins'] = viewWins;
        row['losses'] = viewLosses;

        resolvedStats.add(row);
        sportsWithStats.add(sportKey);
      }
    }

    // Add sports discovered in match participation/stats that weren't in player_career_stats view
    for (final entry in perSportTallies.entries) {
      final sportKey = entry.key;
      if (!sportsWithStats.contains(sportKey)) {
        final tally = entry.value;
        final effMatches = math.max(tally.distinctMatches, tally.effectiveWins + tally.effectiveLosses);
        resolvedStats.add({
          'player_id': userId,
          'sport': sportKey,
          'sport_display_name': tally.displayName,
          'matches_played': effMatches,
          'wins': tally.effectiveWins,
          'losses': tally.effectiveLosses,
          'career_counters': {
            ...tally.accumulatedCounters,
            'matches_won': tally.effectiveWins,
            'matches_lost': tally.effectiveLosses,
            'mvps': tally.effectiveMvps,
          },
        });
        sportsWithStats.add(sportKey);
      }
    }

    // Provide zeroed stats entry for registered sports without matches yet
    for (final entry in sportIdToName.values) {
      final sportKey = entry.toLowerCase();
      if (!sportsWithStats.contains(sportKey)) {
        resolvedStats.add({
          'player_id': userId,
          'sport': sportKey,
          'sport_display_name': entry,
          'matches_played': 0,
          'wins': 0,
          'losses': 0,
          'career_counters': <String, dynamic>{},
        });
        sportsWithStats.add(sportKey);
      }
    }

    // If there is only one active sport and counters are zero while users row has stats, bridge them
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

    // Compute overall totals across all sports
    int totalMatches = 0;
    int totalWins = 0;
    int totalLosses = 0;
    int totalMvps = 0;

    for (final row in resolvedStats) {
      final m = (row['matches_played'] as num?)?.toInt() ?? 0;
      final c = (row['career_counters'] as Map<String, dynamic>?) ?? {};
      final w = ((c['matches_won'] ?? c['wins'] ?? row['wins']) as num?)?.toInt() ?? 0;
      final l = ((c['matches_lost'] ?? c['losses'] ?? row['losses']) as num?)?.toInt() ?? 0;
      final mvp = ((c['mvps'] ?? c['mvp_count'] ?? row['mvp_count']) as num?)?.toInt() ?? 0;
      final effM = m < (w + l) ? (w + l) : m;
      totalMatches += effM;
      totalWins += w;
      totalLosses += l;
      totalMvps += mvp;
    }

    final userRowMatches = (response['matches_played'] as num?)?.toInt() ?? 0;
    final userRowWins = (response['wins'] as num?)?.toInt() ?? 0;
    final userRowLosses = (response['losses'] as num?)?.toInt() ?? 0;
    final userRowMvps = (response['mvp_count'] as num?)?.toInt() ?? 0;

    if (totalMatches == 0 && (userRowMatches > 0 || userRowWins > 0 || userRowLosses > 0)) {
      totalMatches = userRowMatches;
      totalWins = userRowWins;
      totalLosses = userRowLosses;
      totalMvps = userRowMvps;
    } else {
      if (userRowWins > totalWins) totalWins = userRowWins;
      if (userRowLosses > totalLosses) totalLosses = userRowLosses;
      if (userRowMatches > totalMatches) totalMatches = userRowMatches;
      if (userRowMvps > totalMvps) totalMvps = userRowMvps;
    }

    if (totalMatches < (totalWins + totalLosses)) {
      totalMatches = totalWins + totalLosses;
    }

    final Map<String, dynamic> mutableResponse = Map<String, dynamic>.from(response);
    mutableResponse['matches_played'] = totalMatches;
    mutableResponse['wins'] = totalWins;
    mutableResponse['losses'] = totalLosses;
    mutableResponse['mvp_count'] = totalMvps;
    mutableResponse['career_stats'] = resolvedStats;

    // Asynchronously heal database if drift detected
    if (totalMatches != userRowMatches || totalWins != userRowWins || totalLosses != userRowLosses || totalMvps != userRowMvps) {
      _client.from('users').update({
        'matches_played': totalMatches,
        'wins': totalWins,
        'losses': totalLosses,
        'mvp_count': totalMvps,
      }).eq('id', userId).then((_) {}, onError: (_) {});
    }

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

class _SportMatchTally {
  _SportMatchTally(this.displayName);
  final String displayName;
  final Set<String> matchIds = {};
  int matchWins = 0;
  int matchLosses = 0;
  int matchMvps = 0;
  int pmsWins = 0;
  int pmsLosses = 0;
  int pmsMvps = 0;
  final Map<String, num> accumulatedCounters = {};

  int get distinctMatches => matchIds.length;
  int get effectiveWins => math.max(matchWins, pmsWins);
  int get effectiveLosses => math.max(matchLosses, pmsLosses);
  int get effectiveMvps => math.max(matchMvps, pmsMvps);
}
