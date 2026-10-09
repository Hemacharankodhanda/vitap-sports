/// VIT-AP Sports — Sport Registry.
///
/// Maps sport names to their respective pure ScoringEngine instances.
library;

import '../engines/badminton/badminton_engine.dart';
import '../engines/cricket/cricket_engine.dart';
import '../engines/football/football_engine.dart';
import 'scoring_engine.dart';

class SportRegistry {
  SportRegistry._();

  static final Map<String, ScoringEngine> _registry = {
    'Cricket': CricketEngine(),
    'Badminton': BadmintonEngine(),
    'Football': FootballEngine(),
  };

  static ScoringEngine? getEngine(String sportName) {
    // Normalizes case or aliases (e.g. 'cricket', 'badminton', 'football')
    final key = _registry.keys.firstWhere(
      (k) => k.toLowerCase() == sportName.trim().toLowerCase(),
      orElse: () => '',
    );
    if (key.isEmpty) return null;
    return _registry[key];
  }

  static void register(String sportName, ScoringEngine engine) {
    _registry[sportName] = engine;
  }

  static List<String> get supportedSports => _registry.keys.toList();
}
