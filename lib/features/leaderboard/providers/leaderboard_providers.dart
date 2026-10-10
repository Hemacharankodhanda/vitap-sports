import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/models/user_model.dart';
import '../../teams/data/models/team_model.dart';

final leaderboardSportProvider = StateProvider<String>((ref) => 'All');

final topPlayersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final selectedSport = ref.watch(leaderboardSportProvider);

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
    
    // Sort logic based on sport
    players.sort((a, b) {
        final aCounters = a['career_counters'] ?? {};
        final bCounters = b['career_counters'] ?? {};
        
        num aVal = 0;
        num bVal = 0;
        
        if (sportLower == 'cricket') {
            aVal = aCounters['runs_scored'] ?? 0;
            bVal = bCounters['runs_scored'] ?? 0;
        } else if (sportLower == 'football') {
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
        
        if (sportLower == 'cricket') {
            final runs = counters['runs_scored'] ?? 0;
            final wickets = counters['wickets_taken'] ?? 0;
            final ballsFace = counters['balls_faced'] ?? 0;
            final sr = ballsFace > 0 ? ((runs / ballsFace) * 100).toStringAsFixed(1) : '0.0';
            
            final fours = counters['fours'] ?? 0;
            final sixes = counters['sixes'] ?? 0;
            
            primary = '$runs Runs';
            secondary = '$wickets Wkts • SR: $sr • 4s/6s: $fours/$sixes';
        } else if (sportLower == 'football') {
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
