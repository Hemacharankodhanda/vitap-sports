/// VIT-AP Sports — Scorecard service.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class ScorecardService {
  ScorecardService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getScorecardData(String matchId) async {
    final data = await _client
        .from('scorecards')
        .select('data')
        .eq('match_id', matchId)
        .maybeSingle();
    return data?['data'] as Map<String, dynamic>?;
  }

  Future<void> updateScorecardData(String matchId, Map<String, dynamic> stateData) async {
    // Upsert the scorecard data
    await _client.from('scorecards').upsert({
      'match_id': matchId,
      'data': stateData,
    });
  }
}
