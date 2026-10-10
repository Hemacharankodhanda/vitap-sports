/// VIT-AP Sports — Football State & Config.
library;

class FootballConfig {
  const FootballConfig({
    this.playersPerSide = 7,
    this.halfLengthMinutes = 20,
    this.halves = 2,
    this.extraTime = false,
    this.shootout = false,
    this.isKnockout = false,
    this.walkoverGoals = 3,
  });

  final int playersPerSide;
  final int halfLengthMinutes;
  final int halves;
  final bool extraTime;
  final bool shootout;
  final bool isKnockout;
  final int walkoverGoals;

  factory FootballConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FootballConfig();
    return FootballConfig(
      playersPerSide: json['players_per_side'] as int? ?? 7,
      halfLengthMinutes: json['half_length_minutes'] as int? ?? 20,
      halves: json['halves'] as int? ?? 2,
      extraTime: json['extra_time'] as bool? ?? false,
      shootout: json['shootout'] as bool? ?? false,
      isKnockout: json['is_knockout'] as bool? ?? false,
      walkoverGoals: json['walkover_goals'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'players_per_side': playersPerSide,
        'half_length_minutes': halfLengthMinutes,
        'halves': halves,
        'extra_time': extraTime,
        'shootout': shootout,
        'is_knockout': isKnockout,
        'walkover_goals': walkoverGoals,
      };
}

class ShootoutKick {
  const ShootoutKick({
    required this.teamId,
    required this.playerId,
    required this.scored,
  });

  final String teamId;
  final String playerId;
  final bool scored;

  factory ShootoutKick.fromJson(Map<String, dynamic> json) => ShootoutKick(
        teamId: json['team_id']?.toString() ?? '',
        playerId: json['player_id']?.toString() ?? '',
        scored: json['scored'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'player_id': playerId,
        'scored': scored,
      };
}

class GoalRecord {
  const GoalRecord({
    required this.teamId,
    required this.scorerId,
    this.assistId,
    this.kind = 'open_play',
    this.minute = 0,
    this.isOwnGoal = false,
  });

  final String teamId;
  final String scorerId;
  final String? assistId;
  final String kind;
  final int minute;
  final bool isOwnGoal;

  factory GoalRecord.fromJson(Map<String, dynamic> json) => GoalRecord(
        teamId: json['team_id']?.toString() ?? '',
        scorerId: json['scorer_id']?.toString() ?? '',
        assistId: json['assist_id']?.toString(),
        kind: json['kind']?.toString() ?? 'open_play',
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        isOwnGoal: json['is_own_goal'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'scorer_id': scorerId,
        'assist_id': assistId,
        'kind': kind,
        'minute': minute,
        'is_own_goal': isOwnGoal,
      };
}

class FootballState {
  const FootballState({
    required this.homeId,
    required this.awayId,
    this.homeScore = 0,
    this.awayScore = 0,
    this.currentPeriod = 'not_started',
    this.periodStartTimes = const {},
    this.addedTimeMinutes = const {},
    this.pitchPlayers = const {},
    this.benchPlayers = const {},
    this.usedSubstitutes = const {},
    this.redCardedPlayers = const {},
    this.yellowCards = const {},
    this.goals = const [],
    this.shootoutKicks = const [],
    this.shootoutHomeScore = 0,
    this.shootoutAwayScore = 0,
    this.shootoutCompleted = false,
    this.isCompleted = false,
    this.winnerId,
    this.isDraw = false,
    this.forfeitTeamId,
  });

  final String homeId;
  final String awayId;
  final int homeScore;
  final int awayScore;
  final String currentPeriod; // not_started, first_half, half_time, second_half, extra_time_1, extra_time_break, extra_time_2, full_time, shootout, completed
  final Map<String, String> periodStartTimes; // period -> iso8601 string
  final Map<String, int> addedTimeMinutes; // period -> minutes
  final Map<String, List<String>> pitchPlayers; // teamId -> playerIds
  final Map<String, List<String>> benchPlayers; // teamId -> playerIds
  final Map<String, List<String>> usedSubstitutes; // teamId -> playerIds
  final Set<String> redCardedPlayers;
  final Map<String, int> yellowCards; // playerId -> count
  final List<GoalRecord> goals;
  final List<ShootoutKick> shootoutKicks;
  final int shootoutHomeScore;
  final int shootoutAwayScore;
  final bool shootoutCompleted;
  final bool isCompleted;
  final String? winnerId;
  final bool isDraw;
  final String? forfeitTeamId;

  Map<String, dynamic> get playerStats {
    final stats = <String, Map<String, dynamic>>{};
    
    void add(String pid, String key, dynamic val) {
      stats.putIfAbsent(pid, () => {});
      if (val is int) {
        stats[pid]![key] = (stats[pid]![key] as int? ?? 0) + val;
      } else if (val is bool) {
        stats[pid]![key] = (stats[pid]![key] as bool? ?? false) || val;
      }
    }

    for (final goal in goals) {
      if (goal.isOwnGoal) {
        add(goal.scorerId, 'own_goals', 1);
      } else {
        add(goal.scorerId, 'goals', 1);
        if (goal.assistId != null) {
          add(goal.assistId!, 'assists', 1);
        }
      }
    }

    for (final entry in yellowCards.entries) {
      add(entry.key, 'yellow_cards', entry.value);
    }
    for (final pid in redCardedPlayers) {
      add(pid, 'red_cards', 1);
    }

    return stats;
  }

  FootballState copyWith({
    String? homeId,
    String? awayId,
    int? homeScore,
    int? awayScore,
    String? currentPeriod,
    Map<String, String>? periodStartTimes,
    Map<String, int>? addedTimeMinutes,
    Map<String, List<String>>? pitchPlayers,
    Map<String, List<String>>? benchPlayers,
    Map<String, List<String>>? usedSubstitutes,
    Set<String>? redCardedPlayers,
    Map<String, int>? yellowCards,
    List<GoalRecord>? goals,
    List<ShootoutKick>? shootoutKicks,
    int? shootoutHomeScore,
    int? shootoutAwayScore,
    bool? shootoutCompleted,
    bool? isCompleted,
    String? winnerId,
    bool? isDraw,
    String? forfeitTeamId,
  }) {
    return FootballState(
      homeId: homeId ?? this.homeId,
      awayId: awayId ?? this.awayId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      periodStartTimes: periodStartTimes ?? this.periodStartTimes,
      addedTimeMinutes: addedTimeMinutes ?? this.addedTimeMinutes,
      pitchPlayers: pitchPlayers ?? this.pitchPlayers,
      benchPlayers: benchPlayers ?? this.benchPlayers,
      usedSubstitutes: usedSubstitutes ?? this.usedSubstitutes,
      redCardedPlayers: redCardedPlayers ?? this.redCardedPlayers,
      yellowCards: yellowCards ?? this.yellowCards,
      goals: goals ?? this.goals,
      shootoutKicks: shootoutKicks ?? this.shootoutKicks,
      shootoutHomeScore: shootoutHomeScore ?? this.shootoutHomeScore,
      shootoutAwayScore: shootoutAwayScore ?? this.shootoutAwayScore,
      shootoutCompleted: shootoutCompleted ?? this.shootoutCompleted,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerId: winnerId ?? this.winnerId,
      isDraw: isDraw ?? this.isDraw,
      forfeitTeamId: forfeitTeamId ?? this.forfeitTeamId,
    );
  }

  Map<String, dynamic> toJson() => {
        'home_id': homeId,
        'away_id': awayId,
        'home_score': homeScore,
        'away_score': awayScore,
        'current_period': currentPeriod,
        'period_start_times': periodStartTimes,
        'added_time_minutes': addedTimeMinutes,
        'pitch_players': pitchPlayers,
        'bench_players': benchPlayers,
        'used_substitutes': usedSubstitutes,
        'red_carded_players': redCardedPlayers.toList(),
        'yellow_cards': yellowCards,
        'goals': goals.map((g) => g.toJson()).toList(),
        'shootout_kicks': shootoutKicks.map((k) => k.toJson()).toList(),
        'shootout_home_score': shootoutHomeScore,
        'shootout_away_score': shootoutAwayScore,
        'shootout_completed': shootoutCompleted,
        'is_completed': isCompleted,
        'winner_id': winnerId,
        'is_draw': isDraw,
        'forfeit_team_id': forfeitTeamId,
        'player_stats': playerStats,
      };

  factory FootballState.fromJson(Map<String, dynamic> json) {
    final goalsRaw = json['goals'];
    final goalsList = (goalsRaw is List)
        ? goalsRaw
            .whereType<Map>()
            .map((g) => GoalRecord.fromJson(Map<String, dynamic>.from(g)))
            .toList()
        : const <GoalRecord>[];

    final kicksRaw = json['shootout_kicks'];
    final kicksList = (kicksRaw is List)
        ? kicksRaw
            .whereType<Map>()
            .map((k) => ShootoutKick.fromJson(Map<String, dynamic>.from(k)))
            .toList()
        : const <ShootoutKick>[];

    Map<String, List<String>> parsePlayerMap(dynamic val) {
      if (val is! Map) return const {};
      return val.map((k, v) => MapEntry(
            k.toString(),
            (v is List) ? v.map((e) => e.toString()).toList() : <String>[],
          ));
    }

    return FootballState(
      homeId: json['home_id']?.toString() ?? 'home',
      awayId: json['away_id']?.toString() ?? 'away',
      homeScore: (json['home_score'] as num?)?.toInt() ?? 0,
      awayScore: (json['away_score'] as num?)?.toInt() ?? 0,
      currentPeriod: json['current_period']?.toString() ?? 'not_started',
      periodStartTimes: (json['period_start_times'] is Map)
          ? (json['period_start_times'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      addedTimeMinutes: (json['added_time_minutes'] is Map)
          ? (json['added_time_minutes'] as Map)
              .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0))
          : const {},
      pitchPlayers: parsePlayerMap(json['pitch_players']),
      benchPlayers: parsePlayerMap(json['bench_players']),
      usedSubstitutes: parsePlayerMap(json['used_substitutes']),
      redCardedPlayers: (json['red_carded_players'] is List)
          ? (json['red_carded_players'] as List).map((e) => e.toString()).toSet()
          : <String>{},
      yellowCards: (json['yellow_cards'] is Map)
          ? (json['yellow_cards'] as Map)
              .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0))
          : const {},
      goals: goalsList,
      shootoutKicks: kicksList,
      shootoutHomeScore: (json['shootout_home_score'] as num?)?.toInt() ?? 0,
      shootoutAwayScore: (json['shootout_away_score'] as num?)?.toInt() ?? 0,
      shootoutCompleted: json['shootout_completed'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      winnerId: json['winner_id']?.toString(),
      isDraw: json['is_draw'] as bool? ?? false,
      forfeitTeamId: json['forfeit_team_id']?.toString(),
    );
  }
}
