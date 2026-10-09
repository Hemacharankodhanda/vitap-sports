/// VIT-AP Sports — Cricket Scorecard Model.
library;

class CricketScorecardState {
  CricketScorecardState({
    this.totalOvers,
    this.currentInnings = 0,
    this.innings = const [],
  });

  final int? totalOvers;
  final int currentInnings;
  final List<CricketInnings> innings;

  factory CricketScorecardState.fromJson(Map<String, dynamic> json) {
    return CricketScorecardState(
      totalOvers: json['total_overs'] as int?,
      currentInnings: json['current_innings'] as int? ?? 0,
      innings: (json['innings'] as List<dynamic>?)
              ?.map((e) => CricketInnings.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_overs': totalOvers,
        'current_innings': currentInnings,
        'innings': innings.map((e) => e.toJson()).toList(),
      };
      
  /// Helper to get the currently active innings.
  CricketInnings? get activeInnings {
    if (innings.isEmpty) return null;
    if (currentInnings >= innings.length) return null;
    return innings[currentInnings];
  }
}

class CricketInnings {
  CricketInnings({
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalOvers = 0.0, // Format: 15.2 (15 overs, 2 balls)
    this.strikerId,
    this.nonStrikerId,
    this.currentBowlerId,
    this.battingStats = const {},
    this.bowlingStats = const {},
    this.currentOver = const [],
    this.fallOfWickets = const [],
    this.extras = const CricketExtras(),
    this.isComplete = false,
  });

  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;
  final String? strikerId;
  final String? nonStrikerId;
  final String? currentBowlerId;
  
  // Maps userId to their stats
  final Map<String, BatterStats> battingStats;
  final Map<String, BowlerStats> bowlingStats;
  
  // List of ball events in the current over
  final List<BallEvent> currentOver;
  
  final List<FallOfWicket> fallOfWickets;
  final CricketExtras extras;
  final bool isComplete;

  factory CricketInnings.fromJson(Map<String, dynamic> json) {
    return CricketInnings(
      battingTeamId: json['batting_team_id'] as String,
      bowlingTeamId: json['bowling_team_id'] as String,
      totalRuns: json['total_runs'] as int? ?? 0,
      totalWickets: json['total_wickets'] as int? ?? 0,
      totalOvers: (json['total_overs'] as num?)?.toDouble() ?? 0.0,
      strikerId: json['striker_id'] as String?,
      nonStrikerId: json['non_striker_id'] as String?,
      currentBowlerId: json['current_bowler_id'] as String?,
      battingStats: (json['batting_stats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, BatterStats.fromJson(e as Map<String, dynamic>)),
          ) ??
          {},
      bowlingStats: (json['bowling_stats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, BowlerStats.fromJson(e as Map<String, dynamic>)),
          ) ??
          {},
      currentOver: (json['current_over'] as List<dynamic>?)
              ?.map((e) => BallEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fallOfWickets: (json['fall_of_wickets'] as List<dynamic>?)
              ?.map((e) => FallOfWicket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extras: json['extras'] != null 
          ? CricketExtras.fromJson(json['extras'] as Map<String, dynamic>)
          : const CricketExtras(),
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'batting_team_id': battingTeamId,
        'bowling_team_id': bowlingTeamId,
        'total_runs': totalRuns,
        'total_wickets': totalWickets,
        'total_overs': totalOvers,
        'striker_id': strikerId,
        'non_striker_id': nonStrikerId,
        'current_bowler_id': currentBowlerId,
        'batting_stats': battingStats.map((k, v) => MapEntry(k, v.toJson())),
        'bowling_stats': bowlingStats.map((k, v) => MapEntry(k, v.toJson())),
        'current_over': currentOver.map((e) => e.toJson()).toList(),
        'fall_of_wickets': fallOfWickets.map((e) => e.toJson()).toList(),
        'extras': extras.toJson(),
        'is_complete': isComplete,
      };
}

class BatterStats {
  BatterStats({
    required this.userId,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.dismissalType,
    this.bowlerId,
    this.fielderId,
  });

  final String userId;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  
  // e.g., 'bowled', 'caught', 'run_out', 'lbw', 'not_out', null (yet to bat)
  final String? dismissalType; 
  final String? bowlerId; // Who took the wicket
  final String? fielderId; // Who caught/ran out

  bool get isOut => dismissalType != null && dismissalType != 'not_out';

  factory BatterStats.fromJson(Map<String, dynamic> json) {
    return BatterStats(
      userId: json['user_id'] as String,
      runs: json['runs'] as int? ?? 0,
      balls: json['balls'] as int? ?? 0,
      fours: json['fours'] as int? ?? 0,
      sixes: json['sixes'] as int? ?? 0,
      dismissalType: json['dismissal_type'] as String?,
      bowlerId: json['bowler_id'] as String?,
      fielderId: json['fielder_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'dismissal_type': dismissalType,
        'bowler_id': bowlerId,
        'fielder_id': fielderId,
      };
}

class BowlerStats {
  BowlerStats({
    required this.userId,
    this.overs = 0.0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
    this.dotBalls = 0,
    this.wides = 0,
    this.noBalls = 0,
  });

  final String userId;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final int dotBalls;
  final int wides;
  final int noBalls;

  factory BowlerStats.fromJson(Map<String, dynamic> json) {
    return BowlerStats(
      userId: json['user_id'] as String,
      overs: (json['overs'] as num?)?.toDouble() ?? 0.0,
      maidens: json['maidens'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      dotBalls: json['dot_balls'] as int? ?? 0,
      wides: json['wides'] as int? ?? 0,
      noBalls: json['no_balls'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'overs': overs,
        'maidens': maidens,
        'runs': runs,
        'wickets': wickets,
        'dot_balls': dotBalls,
        'wides': wides,
        'no_balls': noBalls,
      };
}

class BallEvent {
  BallEvent({
    required this.runs,
    this.isWide = false,
    this.isNoBall = false,
    this.isLegBye = false,
    this.isBye = false,
    this.isWicket = false,
    this.wicketType,
    this.batterId,
    this.bowlerId,
  });

  final int runs; // Runs off the bat (or extras value)
  final bool isWide;
  final bool isNoBall;
  final bool isLegBye;
  final bool isBye;
  final bool isWicket;
  final String? wicketType;
  final String? batterId;
  final String? bowlerId;
  
  bool get isLegalDelivery => !isWide && !isNoBall;

  factory BallEvent.fromJson(Map<String, dynamic> json) {
    return BallEvent(
      runs: json['runs'] as int? ?? 0,
      isWide: json['is_wide'] as bool? ?? false,
      isNoBall: json['is_no_ball'] as bool? ?? false,
      isLegBye: json['is_leg_bye'] as bool? ?? false,
      isBye: json['is_bye'] as bool? ?? false,
      isWicket: json['is_wicket'] as bool? ?? false,
      wicketType: json['wicket_type'] as String?,
      batterId: json['batter_id'] as String?,
      bowlerId: json['bowler_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'is_wide': isWide,
        'is_no_ball': isNoBall,
        'is_leg_bye': isLegBye,
        'is_bye': isBye,
        'is_wicket': isWicket,
        'wicket_type': wicketType,
        'batter_id': batterId,
        'bowler_id': bowlerId,
      };
      
  /// Get short display string (e.g. '4', '1wd', 'W')
  String get displayString {
    if (isWicket) return 'W';
    if (isWide) return '${runs > 0 ? runs + 1 : 1}wd';
    if (isNoBall) return '${runs > 0 ? runs + 1 : 1}nb';
    if (isLegBye) return '${runs}lb';
    if (isBye) return '${runs}b';
    if (runs == 0) return '•';
    return runs.toString();
  }
}

class FallOfWicket {
  FallOfWicket({
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.batterId,
  });

  final int runs;
  final int wickets;
  final double overs;
  final String batterId;

  factory FallOfWicket.fromJson(Map<String, dynamic> json) {
    return FallOfWicket(
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      overs: (json['overs'] as num?)?.toDouble() ?? 0.0,
      batterId: json['batter_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'wickets': wickets,
        'overs': overs,
        'batter_id': batterId,
      };
}

class CricketExtras {
  const CricketExtras({
    this.wides = 0,
    this.noBalls = 0,
    this.legByes = 0,
    this.byes = 0,
  });

  final int wides;
  final int noBalls;
  final int legByes;
  final int byes;
  
  int get total => wides + noBalls + legByes + byes;

  factory CricketExtras.fromJson(Map<String, dynamic> json) {
    return CricketExtras(
      wides: json['wides'] as int? ?? 0,
      noBalls: json['no_balls'] as int? ?? 0,
      legByes: json['leg_byes'] as int? ?? 0,
      byes: json['byes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'wides': wides,
        'no_balls': noBalls,
        'leg_byes': legByes,
        'byes': byes,
      };
}
