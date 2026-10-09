/// VIT-AP Sports — Sport Registry.
///
/// Maps sport names to their respective pure ScoringEngine instances.
library;

import '../engines/badminton/badminton_engine.dart';
import '../engines/badminton/badminton_state.dart';
import '../engines/cricket/cricket_engine.dart';
import '../engines/cricket/cricket_state.dart';
import '../engines/football/football_engine.dart';
import '../engines/football/football_state.dart';
import 'match_event.dart';
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

  /// Deserializes raw JSON into the sport-specific typed configuration.
  static dynamic parseConfig(String sportName, Map<String, dynamic>? json) {
    final key = sportName.trim().toLowerCase();
    switch (key) {
      case 'cricket':
        return CricketConfig.fromJson(json);
      case 'football':
        return FootballConfig.fromJson(json);
      case 'badminton':
        return BadmintonConfig.fromJson(json);
      default:
        return json ?? <String, dynamic>{};
    }
  }

  /// Initial state helper invoking the registered engine.
  static dynamic initialState({
    required String sportName,
    required Map<String, dynamic>? configJson,
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final engine = getEngine(sportName);
    if (engine == null) return null;
    final config = parseConfig(sportName, configJson);
    return engine.initialState(
      config,
      homeId: homeId,
      awayId: awayId,
      extra: extra,
    );
  }

  /// Folds match events sequentially for the given sport.
  static dynamic fold({
    required String sportName,
    required Map<String, dynamic>? configJson,
    required List<MatchEvent> events,
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final engine = getEngine(sportName);
    if (engine == null) return null;
    final config = parseConfig(sportName, configJson);
    return engine.fold(
      config,
      events,
      homeId: homeId,
      awayId: awayId,
      extra: extra,
    );
  }
}
