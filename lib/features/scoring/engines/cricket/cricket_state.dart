/// VIT-AP Sports — Cricket State & Config.
library;

class CricketConfig {
  const CricketConfig({
    this.oversPerInnings = 6,
    this.playersPerSide = 11,
    int? maxOversPerBowler,
    this.widesAddRun = true,
    this.noBallsAddRun = true,
    this.lastManStanding = false,
  }) : maxOversPerBowler = maxOversPerBowler ?? ((oversPerInnings + 4) ~/ 5);

  final int oversPerInnings;
  final int playersPerSide;
  final int maxOversPerBowler;
  final bool widesAddRun;
  final bool noBallsAddRun;
  final bool lastManStanding;

  int get maxWickets => lastManStanding ? playersPerSide : playersPerSide - 1;

  factory CricketConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CricketConfig();
    return CricketConfig(
      oversPerInnings: json['overs_per_innings'] as int? ?? 6,
      playersPerSide: json['players_per_side'] as int? ?? 11,
      maxOversPerBowler: json['max_overs_per_bowler'] as int?,
      widesAddRun: json['wides_add_run'] as bool? ?? true,
      noBallsAddRun: json['no_balls_add_run'] as bool? ?? true,
      lastManStanding: json['last_man_standing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'overs_per_innings': oversPerInnings,
        'players_per_side': playersPerSide,
        'max_overs_per_bowler': maxOversPerBowler,
        'wides_add_run': widesAddRun,
        'no_balls_add_run': noBallsAddRun,
        'last_man_standing': lastManStanding,
      };
}

class BatterRecord {
  const BatterRecord({
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.howOut,
    this.bowlerId,
    this.fielderId,
  });

  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isOut;
  final String? howOut;
  final String? bowlerId;
  final String? fielderId;

  double get strikeRate =>
      ballsFaced > 0 ? (runs / ballsFaced) * 100 : 0.0;

  BatterRecord copyWith({
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    bool? isOut,
    String? howOut,
    String? bowlerId,
    String? fielderId,
  }) {
    return BatterRecord(
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      howOut: howOut ?? this.howOut,
      bowlerId: bowlerId ?? this.bowlerId,
      fielderId: fielderId ?? this.fielderId,
    );
  }

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'balls_faced': ballsFaced,
        'fours': fours,
        'sixes': sixes,
        'is_out': isOut,
        'how_out': howOut,
        'bowler_id': bowlerId,
        'fielder_id': fielderId,
        'strike_rate': strikeRate,
      };

  factory BatterRecord.fromJson(Map<String, dynamic> json) => BatterRecord(
        runs: json['runs'] as int? ?? 0,
        ballsFaced: json['balls_faced'] as int? ?? 0,
        fours: json['fours'] as int? ?? 0,
        sixes: json['sixes'] as int? ?? 0,
        isOut: json['is_out'] as bool? ?? false,
        howOut: json['how_out'] as String?,
        bowlerId: json['bowler_id'] as String?,
        fielderId: json['fielder_id'] as String?,
      );
}

class BowlerRecord {
  const BowlerRecord({
    this.ballsBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.wides = 0,
    this.noBalls = 0,
  });

  final int ballsBowled;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final int wides;
  final int noBalls;

  double get oversDecimal =>
      (ballsBowled ~/ 6) + (ballsBowled % 6) / 10.0;

  String get oversString => '${ballsBowled ~/ 6}.${ballsBowled % 6}';

  double get economy =>
      ballsBowled > 0 ? (runsConceded / (ballsBowled / 6.0)) : 0.0;

  BowlerRecord copyWith({
    int? ballsBowled,
    int? maidens,
    int? runsConceded,
    int? wickets,
    int? wides,
    int? noBalls,
  }) {
    return BowlerRecord(
      ballsBowled: ballsBowled ?? this.ballsBowled,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
    );
  }

  Map<String, dynamic> toJson() => {
        'balls_bowled': ballsBowled,
        'overs': oversDecimal,
        'maidens': maidens,
        'runs_conceded': runsConceded,
        'wickets': wickets,
        'wides': wides,
        'no_balls': noBalls,
        'economy': economy,
      };

  factory BowlerRecord.fromJson(Map<String, dynamic> json) => BowlerRecord(
        ballsBowled: json['balls_bowled'] as int? ?? 0,
        maidens: json['maidens'] as int? ?? 0,
        runsConceded: json['runs_conceded'] as int? ?? 0,
        wickets: json['wickets'] as int? ?? 0,
        wides: json['wides'] as int? ?? 0,
        noBalls: json['no_balls'] as int? ?? 0,
      );
}

class CricketInningsState {
  const CricketInningsState({
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.legalBalls = 0,
    this.strikerId,
    this.nonStrikerId,
    this.currentBowlerId,
    this.lastOverBowlerId,
    this.isFreeHit = false,
    this.battingStats = const {},
    this.bowlingStats = const {},
    this.thisOverChips = const [],
    this.currentOverChargeableRuns = 0,
    this.fallOfWickets = const [],
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.isComplete = false,
  });

  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int totalWickets;
  final int legalBalls;
  final String? strikerId;
  final String? nonStrikerId;
  final String? currentBowlerId;
  final String? lastOverBowlerId;
  final bool isFreeHit;
  final Map<String, BatterRecord> battingStats;
  final Map<String, BowlerRecord> bowlingStats;
  final List<String> thisOverChips;
  final int currentOverChargeableRuns;
  final List<Map<String, dynamic>> fallOfWickets;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final bool isComplete;

  double get overs => (legalBalls ~/ 6) + (legalBalls % 6) / 10.0;
  int get totalExtras => wides + noBalls + byes + legByes;
  double get runRate => legalBalls > 0 ? (totalRuns / (legalBalls / 6.0)) : 0.0;

  CricketInningsState copyWith({
    String? battingTeamId,
    String? bowlingTeamId,
    int? totalRuns,
    int? totalWickets,
    int? legalBalls,
    String? strikerId,
    String? nonStrikerId,
    String? currentBowlerId,
    bool clearCurrentBowler = false,
    String? lastOverBowlerId,
    bool? isFreeHit,
    Map<String, BatterRecord>? battingStats,
    Map<String, BowlerRecord>? bowlingStats,
    List<String>? thisOverChips,
    int? currentOverChargeableRuns,
    List<Map<String, dynamic>>? fallOfWickets,
    int? wides,
    int? noBalls,
    int? byes,
    int? legByes,
    bool? isComplete,
  }) {
    return CricketInningsState(
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWickets: totalWickets ?? this.totalWickets,
      legalBalls: legalBalls ?? this.legalBalls,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      currentBowlerId: clearCurrentBowler ? null : (currentBowlerId ?? this.currentBowlerId),
      lastOverBowlerId: lastOverBowlerId ?? this.lastOverBowlerId,
      isFreeHit: isFreeHit ?? this.isFreeHit,
      battingStats: battingStats ?? this.battingStats,
      bowlingStats: bowlingStats ?? this.bowlingStats,
      thisOverChips: thisOverChips ?? this.thisOverChips,
      currentOverChargeableRuns:
          currentOverChargeableRuns ?? this.currentOverChargeableRuns,
      fallOfWickets: fallOfWickets ?? this.fallOfWickets,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      byes: byes ?? this.byes,
      legByes: legByes ?? this.legByes,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'batting_team_id': battingTeamId,
        'bowling_team_id': bowlingTeamId,
        'total_runs': totalRuns,
        'total_wickets': totalWickets,
        'legal_balls': legalBalls,
        'total_overs': overs,
        'striker_id': strikerId,
        'non_striker_id': nonStrikerId,
        'current_bowler_id': currentBowlerId,
        'last_over_bowler_id': lastOverBowlerId,
        'is_free_hit': isFreeHit,
        'batting_stats': battingStats.map((k, v) => MapEntry(k, v.toJson())),
        'bowling_stats': bowlingStats.map((k, v) => MapEntry(k, v.toJson())),
        'this_over_chips': thisOverChips,
        'fall_of_wickets': fallOfWickets,
        'extras': {
          'wides': wides,
          'no_balls': noBalls,
          'byes': byes,
          'leg_byes': legByes,
          'total': totalExtras,
        },
        'is_complete': isComplete,
      };

  factory CricketInningsState.fromJson(Map<String, dynamic> json) {
    final extras = (json['extras'] as Map<String, dynamic>?) ?? {};
    final batting = (json['batting_stats'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, BatterRecord.fromJson(v as Map<String, dynamic>)),
        ) ??
        {};
    final bowling = (json['bowling_stats'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, BowlerRecord.fromJson(v as Map<String, dynamic>)),
        ) ??
        {};

    return CricketInningsState(
      battingTeamId: json['batting_team_id'] as String? ?? '',
      bowlingTeamId: json['bowling_team_id'] as String? ?? '',
      totalRuns: json['total_runs'] as int? ?? 0,
      totalWickets: json['total_wickets'] as int? ?? 0,
      legalBalls: json['legal_balls'] as int? ?? 0,
      strikerId: json['striker_id'] as String?,
      nonStrikerId: json['non_striker_id'] as String?,
      currentBowlerId: json['current_bowler_id'] as String?,
      lastOverBowlerId: json['last_over_bowler_id'] as String?,
      isFreeHit: json['is_free_hit'] as bool? ?? false,
      battingStats: batting,
      bowlingStats: bowling,
      thisOverChips: (json['this_over_chips'] as List<dynamic>?)?.cast<String>() ?? [],
      fallOfWickets: (json['fall_of_wickets'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>))
              .toList() ??
          [],
      wides: extras['wides'] as int? ?? 0,
      noBalls: extras['no_balls'] as int? ?? 0,
      byes: extras['byes'] as int? ?? 0,
      legByes: extras['leg_byes'] as int? ?? 0,
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }
}

class CricketState {
  const CricketState({
    required this.homeId,
    required this.awayId,
    this.config = const CricketConfig(),
    this.currentInningsIndex = 0,
    this.innings = const [],
    this.target,
    this.isCompleted = false,
    this.winnerTeamId,
    this.resultMarginText,
    this.isTie = false,
  });

  final String homeId;
  final String awayId;
  final CricketConfig config;
  final int currentInningsIndex;
  final List<CricketInningsState> innings;
  final int? target;
  final bool isCompleted;
  final String? winnerTeamId;
  final String? resultMarginText;
  final bool isTie;

  CricketInningsState? get activeInnings =>
      innings.isNotEmpty && currentInningsIndex < innings.length
          ? innings[currentInningsIndex]
          : null;

  CricketState copyWith({
    String? homeId,
    String? awayId,
    CricketConfig? config,
    int? currentInningsIndex,
    List<CricketInningsState>? innings,
    int? target,
    bool? isCompleted,
    String? winnerTeamId,
    String? resultMarginText,
    bool? isTie,
  }) {
    return CricketState(
      homeId: homeId ?? this.homeId,
      awayId: awayId ?? this.awayId,
      config: config ?? this.config,
      currentInningsIndex: currentInningsIndex ?? this.currentInningsIndex,
      innings: innings ?? this.innings,
      target: target ?? this.target,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      resultMarginText: resultMarginText ?? this.resultMarginText,
      isTie: isTie ?? this.isTie,
    );
  }

  Map<String, dynamic> toJson() => {
        'home_id': homeId,
        'away_id': awayId,
        'config': config.toJson(),
        'current_innings': currentInningsIndex,
        'innings': innings.map((i) => i.toJson()).toList(),
        'target': target,
        'is_completed': isCompleted,
        'winner_team_id': winnerTeamId,
        'result_margin': resultMarginText,
        'is_tie': isTie,
      };

  factory CricketState.fromJson(Map<String, dynamic> json) {
    return CricketState(
      homeId: json['home_id'] as String? ?? 'home',
      awayId: json['away_id'] as String? ?? 'away',
      config: CricketConfig.fromJson(json['config'] as Map<String, dynamic>?),
      currentInningsIndex: json['current_innings'] as int? ?? 0,
      innings: (json['innings'] as List<dynamic>?)
              ?.map((e) => CricketInningsState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      target: json['target'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      winnerTeamId: json['winner_team_id'] as String?,
      resultMarginText: json['result_margin'] as String?,
      isTie: json['is_tie'] as bool? ?? false,
    );
  }
}
