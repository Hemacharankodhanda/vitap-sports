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
