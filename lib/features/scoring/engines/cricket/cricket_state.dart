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
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        ballsFaced: (json['balls_faced'] as num?)?.toInt() ?? 0,
        fours: (json['fours'] as num?)?.toInt() ?? 0,
        sixes: (json['sixes'] as num?)?.toInt() ?? 0,
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
        ballsBowled: (json['balls_bowled'] as num?)?.toInt() ?? 0,
        maidens: (json['maidens'] as num?)?.toInt() ?? 0,
        runsConceded: (json['runs_conceded'] as num?)?.toInt() ?? 0,
        wickets: (json['wickets'] as num?)?.toInt() ?? 0,
        wides: (json['wides'] as num?)?.toInt() ?? 0,
        noBalls: (json['no_balls'] as num?)?.toInt() ?? 0,
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
    final extras = (json['extras'] is Map)
        ? Map<String, dynamic>.from(json['extras'] as Map)
        : <String, dynamic>{};

    final battingRaw = json['batting_stats'];
    final batting = (battingRaw is Map)
        ? battingRaw.map((k, v) => MapEntry(
              k.toString(),
              v is Map ? BatterRecord.fromJson(Map<String, dynamic>.from(v)) : const BatterRecord(),
            ))
        : <String, BatterRecord>{};

    final bowlingRaw = json['bowling_stats'];
    final bowling = (bowlingRaw is Map)
        ? bowlingRaw.map((k, v) => MapEntry(
              k.toString(),
              v is Map ? BowlerRecord.fromJson(Map<String, dynamic>.from(v)) : const BowlerRecord(),
            ))
        : <String, BowlerRecord>{};

    final chipsRaw = json['this_over_chips'];
    final thisOverChips = (chipsRaw is List)
        ? chipsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final fowRaw = json['fall_of_wickets'];
    final fallOfWickets = (fowRaw is List)
        ? fowRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return CricketInningsState(
      battingTeamId: json['batting_team_id']?.toString() ?? '',
      bowlingTeamId: json['bowling_team_id']?.toString() ?? '',
      totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
      totalWickets: (json['total_wickets'] as num?)?.toInt() ?? 0,
      legalBalls: (json['legal_balls'] as num?)?.toInt() ?? 0,
      strikerId: json['striker_id']?.toString(),
      nonStrikerId: json['non_striker_id']?.toString(),
      currentBowlerId: json['current_bowler_id']?.toString(),
      lastOverBowlerId: json['last_over_bowler_id']?.toString(),
      isFreeHit: json['is_free_hit'] as bool? ?? false,
      battingStats: batting,
      bowlingStats: bowling,
      thisOverChips: thisOverChips,
      fallOfWickets: fallOfWickets,
      wides: (extras['wides'] as num?)?.toInt() ?? 0,
      noBalls: (extras['no_balls'] as num?)?.toInt() ?? 0,
      byes: (extras['byes'] as num?)?.toInt() ?? 0,
      legByes: (extras['leg_byes'] as num?)?.toInt() ?? 0,
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

  Map<String, dynamic> get playerStats {
    final stats = <String, Map<String, dynamic>>{};
    
    void add(String pid, String key, dynamic val) {
      stats.putIfAbsent(pid, () => {});
      if (val is int) {
        stats[pid]![key] = (stats[pid]![key] as int? ?? 0) + val;
      } else if (val is bool) {
        stats[pid]![key] = (stats[pid]![key] as int? ?? 0) + (val ? 1 : 0);
      }
    }

    void setTeam(String pid, String? teamId) {
      if (teamId != null && teamId.isNotEmpty) {
        stats.putIfAbsent(pid, () => {});
        stats[pid]!['team_id'] = teamId;
      }
    }

    for (final inning in innings) {
      // Batting
      for (final entry in inning.battingStats.entries) {
        final pid = entry.key;
        final r = entry.value;
        setTeam(pid, inning.battingTeamId);
        add(pid, 'runs_scored', r.runs);
        add(pid, 'balls_faced', r.ballsFaced);
        add(pid, 'fours', r.fours);
        add(pid, 'sixes', r.sixes);
        add(pid, 'is_out', r.isOut ? 1 : 0);
        if (r.isOut) add(pid, 'outs', 1);
        if (r.ballsFaced == 0 && r.isOut) add(pid, 'diamond_ducks', 1);
        else if (r.runs == 0 && r.isOut && r.ballsFaced == 1) add(pid, 'golden_ducks', 1);
        else if (r.runs == 0 && r.isOut) add(pid, 'ducks', 1);
      }
      
      // Bowling
      for (final entry in inning.bowlingStats.entries) {
        final pid = entry.key;
        final r = entry.value;
        setTeam(pid, inning.bowlingTeamId);
        add(pid, 'balls_bowled', r.ballsBowled);
        add(pid, 'runs_conceded', r.runsConceded);
        add(pid, 'wickets_taken', r.wickets);
        add(pid, 'maidens', r.maidens);
        add(pid, 'wides_bowled', r.wides);
        add(pid, 'no_balls_bowled', r.noBalls);
      }
      
      // Fielding
      final creditedDismissals = <String>{};
      for (final fow in inning.fallOfWickets) {
        final fielder = fow['fielder_id'] as String?;
        final type = fow['dismissal_type'] as String?;
        final outPlayer = fow['player_id'] as String?;
        if (fielder != null && fielder.isNotEmpty) {
          setTeam(fielder, inning.bowlingTeamId);
          if (outPlayer != null) creditedDismissals.add(outPlayer);
          if (type == 'caught') add(fielder, 'catches', 1);
          if (type == 'run_out') add(fielder, 'run_outs', 1);
          if (type == 'stumped') add(fielder, 'stumpings', 1);
        }
      }
      for (final entry in inning.battingStats.entries) {
        final r = entry.value;
        if (r.isOut && r.fielderId != null && r.fielderId!.isNotEmpty && !creditedDismissals.contains(entry.key)) {
          final fid = r.fielderId!;
          setTeam(fid, inning.bowlingTeamId);
          if (r.howOut == 'caught') add(fid, 'catches', 1);
          if (r.howOut == 'run_out') add(fid, 'run_outs', 1);
          if (r.howOut == 'stumped') add(fid, 'stumpings', 1);
        }
      }
    }
    return stats;
  }

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
        'player_stats': playerStats,
      };

  factory CricketState.fromJson(Map<String, dynamic> json) {
    final inningsRaw = json['innings'];
    final inningsList = (inningsRaw is List)
        ? inningsRaw
            .whereType<Map>()
            .map((e) => CricketInningsState.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CricketInningsState>[];

    final configRaw = json['config'];
    final config = configRaw is Map
        ? CricketConfig.fromJson(Map<String, dynamic>.from(configRaw))
        : const CricketConfig();

    return CricketState(
      homeId: json['home_id']?.toString() ?? 'home',
      awayId: json['away_id']?.toString() ?? 'away',
      config: config,
      currentInningsIndex: (json['current_innings'] as num?)?.toInt() ?? 0,
      innings: inningsList,
      target: (json['target'] as num?)?.toInt(),
      isCompleted: json['is_completed'] as bool? ?? false,
      winnerTeamId: json['winner_team_id']?.toString(),
      resultMarginText: json['result_margin']?.toString(),
      isTie: json['is_tie'] as bool? ?? false,
    );
  }
}
