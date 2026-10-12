/// VIT-AP Sports — Match providers (Riverpod).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/sport_filter_provider.dart';
import '../../teams/providers/team_providers.dart';
import '../data/match_service.dart';
import '../data/models/match_model.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(supabaseClientProvider));
});

/// All registered players/users for individual/singles selection.
final allPlayersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(playersForSportProvider(null).future);
});

/// Players provider with optional sport filtering and team-member resolution.
final playersForSportProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, sportId) async {
  final client = ref.watch(supabaseClientProvider);
  final users = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  // 1. If sportId is specified, fetch members from teams of this sport first
  if (sportId != null) {
    try {
      final teamRes = await client
          .from('teams')
          .select('id, team_members(user_id, users(id, name, avatar_url))')
          .eq('sport_id', sportId);
      for (final t in teamRes) {
        final members = t['team_members'] as List<dynamic>? ?? [];
        for (final m in members) {
          final u = m['users'] as Map<String, dynamic>?;
          final uid = (m['user_id'] as String?) ?? (u?['id'] as String?);
          if (uid != null && seenIds.add(uid)) {
            final name = (u?['name'] as String?)?.trim();
            users.add({
              'id': uid,
              'name': (name != null && name.isNotEmpty) ? name : 'Player',
              'avatar_url': u?['avatar_url'] as String?,
            });
          }
        }
      }
    } catch (_) {}
  }

  // 2. Fetch all registered users from public.users table (safe columns only)
  try {
    final res = await client
        .from('users')
        .select('id, name, avatar_url')
        .order('name');
    for (final row in res) {
      final id = row['id'] as String?;
      if (id != null && seenIds.add(id)) {
        final name = (row['name'] as String?)?.trim();
        users.add({
          'id': id,
          'name': (name != null && name.isNotEmpty) ? name : 'Player',
          'avatar_url': row['avatar_url'] as String?,
        });
      }
    }
  } catch (_) {}

  // 3. Ensure currently authenticated user is in list
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId != null && !seenIds.contains(currentUserId)) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.userMetadata?['name'] as String?) ??
        (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first ??
        'You';
    seenIds.add(currentUserId);
    users.insert(0, {
      'id': currentUserId,
      'name': '$name (You)',
      'avatar_url': null,
    });
  }

  return users;
});

final matchesListProvider = FutureProvider.family<List<MatchModel>, String?>(
  (ref, status) async {
    final service = ref.watch(matchServiceProvider);
    final selectedSport = ref.watch(sportFilterProvider);
    
    // Get sport ID from the cached sports list
    final sports = await ref.watch(sportsListProvider.future);
    final sport = sports.firstWhere(
      (s) => s['name'] == selectedSport, 
      orElse: () => sports.first,
    );

    return service.getMatches(sportId: sport['id'] as String, status: status);
  },
);

final matchDetailProvider = FutureProvider.family<MatchModel?, String>(
  (ref, matchId) async {
    final service = ref.watch(matchServiceProvider);
    return service.getMatch(matchId);
  },
);

/// Realtime stream of all currently 'live' matches from Supabase.
/// Emits instantly on any score change or ball bowled.
final liveMatchesStreamProvider =
    StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final matchService = ref.watch(matchServiceProvider);
  final selectedSport = ref.watch(sportFilterProvider);

  return client
      .from('matches')
      .stream(primaryKey: ['id'])
      .eq('status', 'live')
      .asyncMap((rows) async {
        if (rows.isEmpty) return <MatchModel>[];

        try {
          final allLive = await matchService.getMatches(status: 'live');
          final rowMap = {for (final r in rows) r['id'] as String: r};

          final updated = allLive.map((m) {
            if (rowMap.containsKey(m.id)) {
              return m.updateFromRealtime(rowMap[m.id]);
            }
            return m;
          }).toList();

          if (selectedSport.isNotEmpty) {
            return updated
                .where((m) =>
                    m.sportName?.toLowerCase() == selectedSport.toLowerCase())
                .toList();
          }

          return updated;
        } catch (_) {
          return <MatchModel>[];
        }
      });
});

final matchAnalysisProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, matchId) async {
    final service = ref.watch(matchServiceProvider);
    return service.getMatchAnalysis(matchId);
  },
);

final matchPlayerNamesProvider =
    FutureProvider.family<Map<String, String>, String>((ref, matchId) async {
  final match = await ref.watch(matchDetailProvider(matchId).future);
  if (match == null) return const <String, String>{};

  final names = <String, String>{};

  // 1. From match.score['player_names']
  if (match.score != null && match.score!['player_names'] is Map) {
    for (final entry in (match.score!['player_names'] as Map).entries) {
      final val = entry.value?.toString();
      if (val != null && val.isNotEmpty) {
        names[entry.key.toString()] = val;
      }
    }
  }

  // 2. From match.score['player_stats']
  if (match.score != null && match.score!['player_stats'] is Map) {
    for (final entry in (match.score!['player_stats'] as Map).entries) {
      if (entry.value is Map && (entry.value as Map)['name'] != null) {
        final val = (entry.value as Map)['name']?.toString();
        if (val != null && val.isNotEmpty) {
          names[entry.key.toString()] = val;
        }
      }
    }
  }

  // 3. From match.participants
  for (final p in match.participants) {
    if (p.userId != null && p.userName != null && p.userName!.isNotEmpty) {
      names[p.userId!] = p.userName!;
    }
  }

  // 4. From team squads if homeTeamId or awayTeamId exist
  final teamService = ref.watch(teamServiceProvider);
  if (match.homeTeamId != null) {
    try {
      final team = await teamService.getTeam(match.homeTeamId!);
      if (team != null) {
        for (final m in team.members) {
          if (m.userId.isNotEmpty && m.userName != null && m.userName!.isNotEmpty) {
            names[m.userId] = m.userName!;
          }
        }
      }
    } catch (_) {}
  }
  if (match.awayTeamId != null) {
    try {
      final team = await teamService.getTeam(match.awayTeamId!);
      if (team != null) {
        for (final m in team.members) {
          if (m.userId.isNotEmpty && m.userName != null && m.userName!.isNotEmpty) {
            names[m.userId] = m.userName!;
          }
        }
      }
    } catch (_) {}
  }

  // 5. Gather any remaining UUIDs found in score / innings
  final unresolvedIds = <String>{};
  void checkKey(String? key) {
    if (key != null && key.isNotEmpty && !names.containsKey(key)) {
      if (key.length == 36 && key.contains('-')) {
        unresolvedIds.add(key);
      }
    }
  }

  if (match.score != null) {
    final pStats = match.score!['player_stats'];
    if (pStats is Map) {
      for (final k in pStats.keys) {
        checkKey(k.toString());
      }
    }
    final innings = match.score!['innings'];
    if (innings is List) {
      for (final inn in innings) {
        if (inn is Map) {
          checkKey(inn['striker_id']?.toString());
          checkKey(inn['non_striker_id']?.toString());
          checkKey(inn['current_bowler_id']?.toString());
          if (inn['batting_stats'] is Map) {
            for (final k in (inn['batting_stats'] as Map).keys) {
              checkKey(k.toString());
            }
          }
          if (inn['bowling_stats'] is Map) {
            for (final k in (inn['bowling_stats'] as Map).keys) {
              checkKey(k.toString());
            }
          }
        }
      }
    }
  }

  if (unresolvedIds.isNotEmpty) {
    try {
      final client = ref.watch(supabaseClientProvider);
      final res = await client
          .from('users')
          .select('id, name')
          .inFilter('id', unresolvedIds.toList());
      for (final row in res) {
        final id = row['id'] as String?;
        final name = row['name'] as String?;
        if (id != null && name != null && name.isNotEmpty) {
          names[id] = name;
        }
      }
    } catch (_) {}
  }

  return names;
});

