/// VIT-AP Sports — Sport Filter State.
///
/// Manages the currently selected sport across the app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_prefs_service.dart';

final availableSportsProvider = Provider<List<String>>((ref) {
  // Hardcoded for now based on requirements.
  return ['Cricket', 'Football', 'Badminton'];
});

class SportFilterNotifier extends StateNotifier<String> {
  SportFilterNotifier(this._prefs) : super(_prefs.selectedSport);

  final LocalPrefsService _prefs;

  void setSport(String sport) {
    state = sport;
    _prefs.setSelectedSport(sport);
  }
}

final sportFilterProvider = StateNotifierProvider<SportFilterNotifier, String>((ref) {
  final prefs = ref.watch(localPrefsProvider);
  return SportFilterNotifier(prefs);
});
