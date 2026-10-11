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

