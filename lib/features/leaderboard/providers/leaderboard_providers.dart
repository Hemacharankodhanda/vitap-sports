import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/models/user_model.dart';
import '../../teams/data/models/team_model.dart';

final leaderboardSportProvider = StateProvider<String>((ref) => 'Cricket');
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
  final sportLower = (selectedSport.isEmpty ? 'cricket' : selectedSport).toLowerCase();

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

      return players.take(20).map((p) {
        final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
        final matches = (p['matches_played'] as num?)?.toInt() ?? 0;
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
          'matches_played': matches,
          'wickets': wkts,
          'overs': overs,
          'runs_conceded': runs,
          'maidens': maidens,
          'econ': econ,
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

      return players.take(20).map((p) {
        final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
        final matches = (p['matches_played'] as num?)?.toInt() ?? 0;
        final catches = _getInt(counters, 'catches');
        final runOuts = _getInt(counters, 'run_outs');
        final stumpings = _getInt(counters, 'stumpings');
        final total = catches + runOuts + stumpings;

        return {
          'id': p['player_id'],
          'name': p['name'],
          'avatar_url': p['avatar_url'],
          'matches_played': matches,
          'dismissals': total,
          'catches': catches,
          'run_outs': runOuts,
          'stumpings': stumpings,
          'primary_stat': '$total Dismissals',
          'secondary_stat': '$catches Catches • $runOuts Run Outs • $stumpings Stumpings',
        };
      }).toList();
    } else {
      // Default: Batting - ranked based on average score
      double calculateBattingAvg(Map<String, dynamic> counters, int matches) {
        if (counters['batting_avg'] != null) {
          return (counters['batting_avg'] as num).toDouble();
        }
        if (counters['average'] != null) {
          return (counters['average'] as num).toDouble();
        }
        final runs = _getInt(counters, 'runs_scored');
        final outs = _getInt(counters, 'outs');
        if (outs > 0) {
          return runs / outs;
        } else if (runs > 0) {
          final innings = _getInt(counters, 'innings');
          final denom = innings > 0 ? innings : (matches > 0 ? matches : 1);
          return runs / denom;
        }
        return 0.0;
      }

      players.sort((a, b) {
        final aCounters = a['career_counters'] as Map<String, dynamic>? ?? {};
        final bCounters = b['career_counters'] as Map<String, dynamic>? ?? {};
        final aMatches = (a['matches_played'] as num?)?.toInt() ?? 0;
        final bMatches = (b['matches_played'] as num?)?.toInt() ?? 0;

        final aAvg = calculateBattingAvg(aCounters, aMatches);
        final bAvg = calculateBattingAvg(bCounters, bMatches);
        // 1. Rank by Average score (descending)
        if (bAvg != aAvg) return bAvg.compareTo(aAvg);

        // 2. Tie-break: Runs scored (descending)
        final aRuns = _getInt(aCounters, 'runs_scored');
        final bRuns = _getInt(bCounters, 'runs_scored');
        if (bRuns != aRuns) return bRuns.compareTo(aRuns);

        // 3. Tie-break: Strike rate (descending)
        final aBalls = _getInt(aCounters, 'balls_faced');
        final bBalls = _getInt(bCounters, 'balls_faced');
        final aSr = aBalls > 0 ? (aRuns / aBalls) : 0.0;
        final bSr = bBalls > 0 ? (bRuns / bBalls) : 0.0;
        return bSr.compareTo(aSr);
      });

      return players.take(20).map((p) {
        final counters = p['career_counters'] as Map<String, dynamic>? ?? {};
        final matches = (p['matches_played'] as num?)?.toInt() ?? 0;
        final runs = _getInt(counters, 'runs_scored');
        final balls = _getInt(counters, 'balls_faced');
        final fours = _getInt(counters, 'fours');
        final sixes = _getInt(counters, 'sixes');
        final sr = balls > 0 ? ((runs / balls) * 100).toStringAsFixed(1) : '0.0';
        final avgNum = calculateBattingAvg(counters, matches);
        final avg = avgNum.toStringAsFixed(1);

        return {
          'id': p['player_id'],
          'name': p['name'],
          'avatar_url': p['avatar_url'],
          'matches_played': matches,
          'runs': runs,
          'avg': avg,
          'fours': fours,
          'sixes': sixes,
          'sr': sr,
          'primary_stat': '$avg Avg',
          'secondary_stat': 'Avg: $avg • SR: $sr • $runs Runs • $fours (4s) • $sixes (6s)',
        };
      }).toList();
    }
  } else {
    // Football & Badminton
    players.sort((a, b) {
      final aCounters = a['career_counters'] is Map ? a['career_counters'] as Map : {};
      final bCounters = b['career_counters'] is Map ? b['career_counters'] as Map : {};
      num aVal = 0;
      num bVal = 0;
      if (sportLower == 'football') {
        aVal = _getInt(Map<String, dynamic>.from(aCounters), 'goals');
        bVal = _getInt(Map<String, dynamic>.from(bCounters), 'goals');
      } else if (sportLower == 'badminton') {
        int getBadmintonPts(Map<String, dynamic> c) {
          final pw = _getInt(c, 'points_won');
          if (pw > 0) return pw;
          final pts = _getInt(c, 'points');
          if (pts > 0) return pts;
          return _getInt(c, 'total_points');
        }
        aVal = getBadmintonPts(Map<String, dynamic>.from(aCounters));
        bVal = getBadmintonPts(Map<String, dynamic>.from(bCounters));
      }
      return bVal.compareTo(aVal);
    });

    return players.take(20).map((p) {
      final counters = p['career_counters'] is Map
          ? Map<String, dynamic>.from(p['career_counters'] as Map)
          : <String, dynamic>{};
      final matches = (p['matches_played'] as num?)?.toInt() ?? 0;
      String primary = '';
      String secondary = '';
      int goals = 0;
      int assists = 0;
      int points = 0;

      if (sportLower == 'football') {
        goals = _getInt(counters, 'goals');
        assists = _getInt(counters, 'assists');
        primary = '$goals Goals';
        secondary = '$assists Assists';
      } else if (sportLower == 'badminton') {
        final pw = _getInt(counters, 'points_won');
        points = pw > 0 ? pw : (_getInt(counters, 'points') > 0 ? _getInt(counters, 'points') : _getInt(counters, 'total_points'));
        primary = '$points Points';
        secondary = '$matches Matches';
      }

      return {
        'id': p['player_id'],
        'name': p['name'],
        'avatar_url': p['avatar_url'],
        'matches_played': matches,
        'goals': goals,
        'assists': assists,
        'points': points,
        'primary_stat': primary,
        'secondary_stat': secondary,
      };
    }).toList();
  }
});

final topTeamsProvider = FutureProvider<List<TeamModel>>((ref) async {
  final selectedSport = ref.watch(leaderboardSportProvider);
  
  var query = Supabase.instance.client
      .from('teams')
      .select('*, sports!inner(*), team_members(*)');
      
  if (selectedSport.isNotEmpty && selectedSport != 'All') {
    query = query.eq('sports.name', selectedSport);
  }
      
  final res = await query.order('wins', ascending: false).limit(15);
  return (res as List).map((json) => TeamModel.fromJson(json)).toList();
});
