/// VIT-AP Sports — Team providers (Riverpod).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/sport_filter_provider.dart';
import '../data/models/team_model.dart';
import '../data/team_service.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.watch(supabaseClientProvider));
});

final teamsListProvider = FutureProvider<List<TeamModel>>((ref) async {
  final service = ref.watch(teamServiceProvider);
  final selectedSport = ref.watch(sportFilterProvider);
  
  // Get sport ID for the selected sport name
  final sports = await service.getSports();
  final sport = sports.firstWhere(
    (s) => s['name'] == selectedSport, 
    orElse: () => sports.first,
  );
  
  return service.getTeams(sportId: sport['id'] as String);
});

final teamDetailProvider = FutureProvider.family<TeamModel?, String>(
  (ref, teamId) async {
    final service = ref.watch(teamServiceProvider);
    return service.getTeam(teamId);
  },
);

final userTeamsProvider = FutureProvider<List<TeamModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(teamServiceProvider);
  return service.getUserTeams(userId);
});

final sportsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(teamServiceProvider);
  return service.getSports();
});
