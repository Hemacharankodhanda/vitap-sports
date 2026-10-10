import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/models/user_model.dart';
import '../../teams/data/models/team_model.dart';

final leaderboardSportProvider = StateProvider<String>((ref) => 'All');
final cricketCategoryProvider = StateProvider<String>((ref) => 'Batting'); // 'Batting', 'Bowling', 'Fielding'

int _getInt(Map<String, dynamic> map, String key) {
  final val = map[key];
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
  return 0;
}

final topPlayersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final selectedSport = ref.watch(leaderboardSportProvider);
  final cricketCategory = ref.watch(cricketCategoryProvider);

  if (selectedSport == 'All') {
    final res = await Supabase.instance.client
        .from('users')
        .select()
        .order('wins', ascending: false)
        .limit(10);
        
    return (res as List).map((e) {
      final user = UserModel.fromJson(e);
      return {
        'id': user.id,
        'name': user.name,
        'avatar_url': user.avatarUrl,
        'primary_stat': '${user.wins} Wins',
        'secondary_stat': '${user.mvpCount} MVPs',
      };
    }).toList();
  } else {
    final sportLower = selectedSport.toLowerCase();
    
    final res = await Supabase.instance.client
        .from('player_leaderboard')
        .select();
        
    List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(res)
        .where((row) {
          final s = (row['sport']?.toString() ?? '').toLowerCase();
          return s == sportLower || s.contains(sportLower);
        })
        .toList();
    
    // Sort logic based on sport and category
    if (sportLower == 'cricket') {
      if (cricketCategory == 'Bowling') {
        players.sort((a, b) {
          final aCounters = a['career_counters'] as Map<String, dynamic>? ?? {};
          final bCounters = b['career_counters'] as Map<String, dynamic>? ?? {};
          final aWkts = _getInt(aCounters, 'wickets_taken');
          final bWkts = _getInt(bCounters, 'wickets_taken');
          if (bWkts != aWkts) return bWkts.compareTo(aWkts);

          final aBalls = _getInt(aCounters, 'balls_bowled');
          final bBalls = _getInt(bCounters, 'balls_bowled');
          final aRuns = _getInt(aCounters, 'runs_conceded');
          final bRuns = _getInt(bCounters, 'runs_conceded');
          final aEcon = aBalls > 0 ? (aRuns / (aBalls / 6.0)) : 999.0;
          final bEcon = bBalls > 0 ? (bRuns / (bBalls / 6.0)) : 999.0;
          return aEcon.compareTo(bEcon);
        });

        return players.take(15).map((p) {
          final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
          final wkts = _getInt(counters, 'wickets_taken');
          final balls = _getInt(counters, 'balls_bowled');
          final overs = '${balls ~/ 6}.${balls % 6}';
          final runs = _getInt(counters, 'runs_conceded');
          final maidens = _getInt(counters, 'maidens');
          final econ = balls > 0 ? (runs / (balls / 6.0)).toStringAsFixed(2) : '0.00';

          return {
            'id': p['player_id'],
            'name': p['name'],
            'avatar_url': p['avatar_url'],
            'primary_stat': '$wkts Wickets',
            'secondary_stat': 'Econ: $econ • $overs Ov • $maidens M',
          };
        }).toList();
      } else if (cricketCategory == 'Fielding') {
        players.sort((a, b) {
          final aCounters = a['career_counters'] as Map<String, dynamic>? ?? {};
          final bCounters = b['career_counters'] as Map<String, dynamic>? ?? {};
          final aCatches = _getInt(aCounters, 'catches');
          final aRunOuts = _getInt(aCounters, 'run_outs');
          final aStumpings = _getInt(aCounters, 'stumpings');
          final aDismissals = aCatches + aRunOuts + aStumpings;

          final bCatches = _getInt(bCounters, 'catches');
          final bRunOuts = _getInt(bCounters, 'run_outs');
          final bStumpings = _getInt(bCounters, 'stumpings');
          final bDismissals = bCatches + bRunOuts + bStumpings;

          if (bDismissals != aDismissals) return bDismissals.compareTo(aDismissals);
          return bCatches.compareTo(aCatches);
        });

        return players.take(15).map((p) {
          final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
          final catches = _getInt(counters, 'catches');
          final runOuts = _getInt(counters, 'run_outs');
          final stumpings = _getInt(counters, 'stumpings');
          final total = catches + runOuts + stumpings;

          return {
            'id': p['player_id'],
            'name': p['name'],
            'avatar_url': p['avatar_url'],
            'primary_stat': '$total Dismissals',
            'secondary_stat': '$catches Catches • $runOuts Run Outs • $stumpings Stumpings',
          };
        }).toList();
      } else {
        // Default: Batting
        players.sort((a, b) {
          final aCounters = a['career_counters'] as Map<String, dynamic>? ?? {};
          final bCounters = b['career_counters'] as Map<String, dynamic>? ?? {};
          final aRuns = _getInt(aCounters, 'runs_scored');
          final bRuns = _getInt(bCounters, 'runs_scored');
          if (bRuns != aRuns) return bRuns.compareTo(aRuns);

          final aBalls = _getInt(aCounters, 'balls_faced');
          final bBalls = _getInt(bCounters, 'balls_faced');
          final aSr = aBalls > 0 ? (aRuns / aBalls) : 0.0;
          final bSr = bBalls > 0 ? (bRuns / bBalls) : 0.0;
          return bSr.compareTo(aSr);
        });

        return players.take(15).map((p) {
          final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
          final runs = _getInt(counters, 'runs_scored');
          final balls = _getInt(counters, 'balls_faced');
          final fours = _getInt(counters, 'fours');
          final sixes = _getInt(counters, 'sixes');
          final sr = balls > 0 ? ((runs / balls) * 100).toStringAsFixed(1) : '0.0';

          return {
            'id': p['player_id'],
            'name': p['name'],
            'avatar_url': p['avatar_url'],
            'primary_stat': '$runs Runs',
            'secondary_stat': 'SR: $sr • $fours (4s) • $sixes (6s)',
          };
        }).toList();
      }
    } else {
      // Football & Badminton
      players.sort((a, b) {
        final aCounters = a['career_counters'] ?? {};
        final bCounters = b['career_counters'] ?? {};
        num aVal = 0;
        num bVal = 0;
        if (sportLower == 'football') {
          aVal = aCounters['goals'] ?? 0;
          bVal = bCounters['goals'] ?? 0;
        } else if (sportLower == 'badminton') {
          aVal = aCounters['points_won'] ?? 0;
          bVal = bCounters['points_won'] ?? 0;
        }
        return bVal.compareTo(aVal);
      });

      return players.take(10).map((p) {
        final counters = p['career_counters'] ?? {};
        String primary = '';
        String secondary = '';
        if (sportLower == 'football') {
          final goals = counters['goals'] ?? 0;
          final assists = counters['assists'] ?? 0;
          primary = '$goals Goals';
          secondary = '$assists Assists';
        } else if (sportLower == 'badminton') {
          final points = counters['points_won'] ?? 0;
          primary = '$points Points';
          secondary = '${p['matches_played']} Matches';
        }

        return {
          'id': p['player_id'],
          'name': p['name'],
          'avatar_url': p['avatar_url'],
          'primary_stat': primary,
          'secondary_stat': secondary,
        };
      }).toList();
    }
  }
});

final topTeamsProvider = FutureProvider<List<TeamModel>>((ref) async {
  final selectedSport = ref.watch(leaderboardSportProvider);
  
  var query = Supabase.instance.client
      .from('teams')
      .select('*, sports!inner(*), team_members(*)');
      
  if (selectedSport != 'All') {
    query = query.eq('sports.name', selectedSport);
  }
      
  final res = await query.order('wins', ascending: false).limit(10);
  return (res as List).map((json) => TeamModel.fromJson(json)).toList();
});
