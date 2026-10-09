/// VIT-AP Sports — Scorecard providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/scorecard_service.dart';

final scorecardServiceProvider = Provider<ScorecardService>((ref) {
  return ScorecardService(ref.watch(supabaseClientProvider));
});

final scorecardDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, matchId) async {
  return ref.read(scorecardServiceProvider).getScorecardData(matchId);
});
