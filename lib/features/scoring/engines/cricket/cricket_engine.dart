/// VIT-AP Sports — Authoritative Cricket Scoring Engine.
// ignore_for_file: use_null_aware_elements
library;

import '../../domain/match_event.dart';
import '../../domain/scoring_engine.dart';
import 'cricket_state.dart';

class CricketEngine extends ScoringEngine<CricketState, CricketConfig> {
  @override
  String get sport => 'Cricket';

  @override
  CricketState initialState(
    CricketConfig config, {
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final battingFirstTeamId = extra?['batting_first_team_id'] as String? ?? homeId;
    final bowlingFirstTeamId = battingFirstTeamId == homeId ? awayId : homeId;

    final strikerId = (extra?['striker_id'] as String?) ??
        (extra?['opening_striker'] as String?) ??
        'Batter 1';
    final nonStrikerId = (extra?['non_striker_id'] as String?) ??
        (extra?['opening_non_striker'] as String?) ??
        'Batter 2';
    final openingBowlerId = (extra?['opening_bowler_id'] as String?) ??
        (extra?['opening_bowler'] as String?) ??
        'Bowler 1';

    final firstInnings = CricketInningsState(
      battingTeamId: battingFirstTeamId,
      bowlingTeamId: bowlingFirstTeamId,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      currentBowlerId: openingBowlerId,
      battingStats: {
        strikerId: const BatterRecord(),
        nonStrikerId: const BatterRecord(),
      },
      bowlingStats: {
        openingBowlerId: const BowlerRecord(),
      },
    );

    return CricketState(
      homeId: homeId,
      awayId: awayId,
      config: config,
      innings: [firstInnings],
      currentInningsIndex: 0,
    );
  }

  @override
  String? validate(CricketState state, MatchEvent event) {
    if (state.isCompleted) return 'Match is already completed';
    final active = state.activeInnings;
    if (active == null || active.isComplete) return 'Current innings is already complete';

    switch (event.type) {
      case 'set_bowler':
      case 'select_bowler':
        final bowlerId = event.payload['bowler_id'] as String?;
        if (bowlerId == null) return 'Bowler ID is required';
        if (bowlerId == active.lastOverBowlerId) {
          return 'Bowler cannot bowl two consecutive overs';
        }
        return null;

      case 'set_batters':
        final striker = event.payload['striker_id'] as String?;
        final nonStriker = event.payload['non_striker_id'] as String?;
        if (striker == null || nonStriker == null) return 'Striker and non-striker required';
        if (striker == nonStriker) return 'Striker and non-striker must be different players';
        return null;

      case 'delivery':
        if (active.strikerId == null || active.nonStrikerId == null) {
          return 'Striker and non-striker must be set before bowling';
        }
        if (active.currentBowlerId == null) {
          return 'A bowler must be selected for this over';
        }

        final kind = event.payload['kind'] as String? ?? 'normal';
        final isWicket = event.payload['is_wicket'] as bool? ?? false;
        final dismissal = event.payload['dismissal_type'] as String?;

        if (isWicket && dismissal != null) {
          // Free hit restrictions: only run out
          if (active.isFreeHit && dismissal != 'run_out') {
            return 'On a Free Hit, only run out is allowed';
          }
          // No-ball restrictions: only run out
          if (kind == 'no_ball' && dismissal != 'run_out') {
            return 'On a No-ball, only run out is allowed';
          }
          // Wide restrictions: only stumped, run out, hit wicket
          if (kind == 'wide' && !['stumped', 'run_out', 'hit_wicket'].contains(dismissal)) {
            return 'On a Wide, only stumped, run out, or hit wicket is allowed';
          }
        }
        return null;

      default:
        return null;
    }
  }

  @override
  CricketState apply(CricketState state, MatchEvent event) {
    switch (event.type) {
      case 'set_bowler':
      case 'select_bowler':
        return _applySetBowler(state, event);

      case 'set_batters':
        return _applySetBatters(state, event);

      case 'delivery':
        return _applyDelivery(state, event);

      case 'finish_match':
        return state.copyWith(isCompleted: true);

      default:
        return state;
    }
  }

  CricketState _applySetBowler(CricketState state, MatchEvent event) {
    final active = state.activeInnings ?? state.innings.firstOrNull;
    if (active == null) return state;
    final bowlerId = (event.payload['bowler_id'] as String?) ?? 'Bowler';
    final bowlingStats = Map<String, BowlerRecord>.from(active.bowlingStats);
    if (!bowlingStats.containsKey(bowlerId)) {
      bowlingStats[bowlerId] = const BowlerRecord();
    }

    final updatedInnings = active.copyWith(
      currentBowlerId: bowlerId,
      bowlingStats: bowlingStats,
    );

    return _replaceActiveInnings(state, updatedInnings);
  }

  CricketState _applySetBatters(CricketState state, MatchEvent event) {
    final active = state.activeInnings ?? state.innings.firstOrNull;
    if (active == null) return state;
    final striker = (event.payload['striker_id'] as String?) ?? 'Batter 1';
    final nonStriker = (event.payload['non_striker_id'] as String?) ?? 'Batter 2';

    final battingStats = Map<String, BatterRecord>.from(active.battingStats);
    if (!battingStats.containsKey(striker)) battingStats[striker] = const BatterRecord();
    if (!battingStats.containsKey(nonStriker)) battingStats[nonStriker] = const BatterRecord();

    final updatedInnings = active.copyWith(
      strikerId: striker,
      nonStrikerId: nonStriker,
      battingStats: battingStats,
    );

    return _replaceActiveInnings(state, updatedInnings);
  }

  CricketState _applyDelivery(CricketState state, MatchEvent event) {
    final config = state.config;
    final active = state.activeInnings ??
        (state.innings.isNotEmpty
            ? state.innings.first
            : initialState(config, homeId: state.homeId, awayId: state.awayId).activeInnings!);
    final kind = event.payload['kind'] as String? ?? 'normal';
    final runs = (event.payload['runs'] as int?) ??
        (event.payload['runs_completed'] as int?) ??
        0;
    final isBoundary = event.payload['is_boundary'] as bool? ?? false;
    final isWicket = event.payload['is_wicket'] as bool? ?? false;
    final dismissal = event.payload['dismissal_type'] as String?;
    final fielderId = event.payload['fielder_id'] as String?;
    final dismissedBatterId = event.payload['out_batter_id'] as String? ??
        event.payload['dismissed_batter_id'] as String? ??
        active.strikerId;
    final newBatterId = event.payload['new_batter_id'] as String?;
    final battersCrossed = event.payload['batters_crossed'] as bool? ?? false;

    int runsAddedToTeam = 0;
    int runsChargedToBowler = 0;
    int physicallyRun = 0;
    bool isLegal = false;
    bool nextFreeHit = false;
    String chip = '$runs';

    final battingStats = Map<String, BatterRecord>.from(active.battingStats);
    final bowlingStats = Map<String, BowlerRecord>.from(active.bowlingStats);
    var striker = active.strikerId ?? (event.payload['striker_id'] as String?) ?? 'Striker';
    var nonStriker = active.nonStrikerId ?? (event.payload['non_striker_id'] as String?) ?? 'Non-Striker';
    final bowlerId = active.currentBowlerId ?? (event.payload['bowler_id'] as String?) ?? 'Bowler';
    var currentBowler = bowlingStats[bowlerId] ?? const BowlerRecord();
    var currentStriker = battingStats[striker] ?? const BatterRecord();

    int widesCount = active.wides;
    int noBallsCount = active.noBalls;
    int byesCount = active.byes;
    int legByesCount = active.legByes;

    switch (kind) {
      case 'normal':
        isLegal = true;
        runsChargedToBowler = runs;
        runsAddedToTeam = runs;
        physicallyRun = isBoundary ? 0 : runs;
        chip = isWicket ? 'W' : (runs == 4 && isBoundary ? '4' : (runs == 6 && isBoundary ? '6' : '$runs'));

        currentStriker = currentStriker.copyWith(
          runs: currentStriker.runs + runs,
          ballsFaced: currentStriker.ballsFaced + 1,
          fours: isBoundary && runs == 4 ? currentStriker.fours + 1 : currentStriker.fours,
          sixes: isBoundary && runs == 6 ? currentStriker.sixes + 1 : currentStriker.sixes,
        );
        break;

      case 'wide':
        isLegal = false;
        final wideExtra = 1;
        final additionalRuns = runs;
        runsAddedToTeam = wideExtra + additionalRuns;
        runsChargedToBowler = wideExtra + additionalRuns;
        widesCount += (wideExtra + additionalRuns);
        physicallyRun = additionalRuns;
        chip = additionalRuns > 0 ? 'Wd+$additionalRuns' : 'Wd';
        nextFreeHit = active.isFreeHit; // Free hit carried over!
        break;

      case 'no_ball':
        isLegal = false;
        final noBallPenalty = 1;
        runsAddedToTeam = noBallPenalty + runs;
        runsChargedToBowler = noBallPenalty + runs;
        noBallsCount += noBallPenalty;
        physicallyRun = isBoundary ? 0 : runs;
        chip = runs > 0 ? 'Nb+$runs' : 'Nb';
        nextFreeHit = true; // Free hit granted!

        currentStriker = currentStriker.copyWith(
          runs: currentStriker.runs + runs,
          ballsFaced: currentStriker.ballsFaced + 1,
          fours: isBoundary && runs == 4 ? currentStriker.fours + 1 : currentStriker.fours,
          sixes: isBoundary && runs == 6 ? currentStriker.sixes + 1 : currentStriker.sixes,
        );
        break;

      case 'bye':
      case 'leg_bye':
        isLegal = true;
        runsAddedToTeam = runs;
        physicallyRun = runs;
        chip = kind == 'bye' ? 'B$runs' : 'Lb$runs';
        if (kind == 'bye') {
          byesCount += runs;
        } else {
          legByesCount += runs;
        }
        currentStriker = currentStriker.copyWith(
          ballsFaced: currentStriker.ballsFaced + 1,
        );
        break;
    }

    // Wicket processing
    int newWickets = active.totalWickets;
    final fow = List<Map<String, dynamic>>.from(active.fallOfWickets);

    if (isWicket && dismissal != null) {
      newWickets += 1;
      chip = 'W';
      final bool creditedToBowler = ['bowled', 'caught', 'lbw', 'stumped', 'hit_wicket'].contains(dismissal);

      fow.add({
        'wicket': newWickets,
        'score': active.totalRuns + runsAddedToTeam,
        'overs': (active.legalBalls + (isLegal ? 1 : 0)) ~/ 6 + ((active.legalBalls + (isLegal ? 1 : 0)) % 6) / 10.0,
        'player_id': dismissedBatterId,
      });

      if (creditedToBowler) {
        currentBowler = currentBowler.copyWith(wickets: currentBowler.wickets + 1);
      }

      final isStrikerOut = dismissedBatterId == (active.strikerId ?? striker);
      if (isStrikerOut) {
        currentStriker = currentStriker.copyWith(
          isOut: true,
          howOut: dismissal,
          bowlerId: creditedToBowler ? bowlerId : null,
          fielderId: fielderId,
        );
        battingStats[dismissedBatterId ?? striker] = currentStriker;
      } else {
        final outBatterRecord = (battingStats[dismissedBatterId] ?? const BatterRecord()).copyWith(
          isOut: true,
          howOut: dismissal,
          bowlerId: creditedToBowler ? bowlerId : null,
          fielderId: fielderId,
        );
        if (dismissedBatterId != null) {
          battingStats[dismissedBatterId] = outBatterRecord;
        }
        battingStats[active.strikerId ?? striker] = currentStriker;
      }

      // Replace dismissed batter with new batter
      if (newBatterId != null) {
        battingStats[newBatterId] = const BatterRecord();
        if (isStrikerOut) {
          striker = newBatterId;
          if (battersCrossed) {
            final tmp = striker;
            striker = nonStriker;
            nonStriker = tmp;
          }
        } else {
          nonStriker = newBatterId;
        }
      }
    } else {
      battingStats[active.strikerId ?? striker] = currentStriker;
    }

    // Bowler stats update
    currentBowler = currentBowler.copyWith(
      ballsBowled: isLegal ? currentBowler.ballsBowled + 1 : currentBowler.ballsBowled,
      runsConceded: currentBowler.runsConceded + runsChargedToBowler,
      wides: kind == 'wide' ? currentBowler.wides + (1 + runs) : currentBowler.wides,
      noBalls: kind == 'no_ball' ? currentBowler.noBalls + 1 : currentBowler.noBalls,
    );
    bowlingStats[bowlerId] = currentBowler;

    // Strike swap on odd physically run runs
    if (physicallyRun % 2 != 0) {
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
    }

    // Check legal ball and over progression
    final int newLegalBalls = isLegal ? active.legalBalls + 1 : active.legalBalls;
    final int newTotalRuns = active.totalRuns + runsAddedToTeam;
    final List<String> newChips = [...active.thisOverChips, chip];
    int newChargeableThisOver = active.currentOverChargeableRuns + (kind == 'normal' || kind == 'wide' || kind == 'no_ball' ? runsChargedToBowler : 0);
    String? newLastOverBowler = active.lastOverBowlerId;
    String? newCurrentBowler = bowlerId;

    // End of over check (every 6 legal deliveries)
    if (isLegal && newLegalBalls % 6 == 0 && newLegalBalls > 0) {
      // End of over: batters swap ends (applied after delivery strike swap)
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;

      // Maiden detection: 0 runs off bat & no wides/no-balls
      if (newChargeableThisOver == 0) {
        bowlingStats[bowlerId] = bowlingStats[bowlerId]!.copyWith(
          maidens: bowlingStats[bowlerId]!.maidens + 1,
        );
      }

      newLastOverBowler = bowlerId;
      newCurrentBowler = null; // New bowler must be chosen
      newChips.clear();
      newChargeableThisOver = 0;
    }

    // Check innings end conditions
    final int maxBalls = config.oversPerInnings * 6;
    final bool allOut = newWickets >= config.maxWickets;
    final bool oversFinished = newLegalBalls >= maxBalls;
    final bool targetReached = state.target != null && newTotalRuns >= state.target!;

    final bool inningsEnded = allOut || oversFinished || targetReached;

    final updatedInnings = active.copyWith(
      totalRuns: newTotalRuns,
      totalWickets: newWickets,
      legalBalls: newLegalBalls,
      strikerId: striker,
      nonStrikerId: nonStriker,
      currentBowlerId: newCurrentBowler,
      clearCurrentBowler: newCurrentBowler == null,
      lastOverBowlerId: newLastOverBowler,
      isFreeHit: nextFreeHit,
      battingStats: battingStats,
      bowlingStats: bowlingStats,
      thisOverChips: newChips,
      currentOverChargeableRuns: newChargeableThisOver,
      fallOfWickets: fow,
      wides: widesCount,
      noBalls: noBallsCount,
      byes: byesCount,
      legByes: legByesCount,
      isComplete: inningsEnded,
    );

    // If 1st innings ends -> set target & start 2nd innings
    if (inningsEnded && state.currentInningsIndex == 0) {
      final targetScore = newTotalRuns + 1;
      final secondInnings = CricketInningsState(
        battingTeamId: active.bowlingTeamId,
        bowlingTeamId: active.battingTeamId,
      );

      return state.copyWith(
        innings: [updatedInnings, secondInnings],
        currentInningsIndex: 1,
        target: targetScore,
      );
    }

    // If 2nd innings ends -> match complete & compute result margin
    if (inningsEnded && state.currentInningsIndex == 1) {
      final firstInnings = state.innings[0];
      String? winnerId;
      String? marginText;
      bool isTie = false;

      if (newTotalRuns > firstInnings.totalRuns) {
        winnerId = active.battingTeamId;
        final wicketsRemaining = config.maxWickets - newWickets;
        marginText = 'won by $wicketsRemaining wickets';
      } else if (newTotalRuns < firstInnings.totalRuns) {
        winnerId = firstInnings.battingTeamId;
        final runsMargin = firstInnings.totalRuns - newTotalRuns;
        marginText = 'won by $runsMargin runs';
      } else {
        isTie = true;
        marginText = 'Match Tied';
      }

      return state.copyWith(
        innings: [firstInnings, updatedInnings],
        isCompleted: true,
        winnerTeamId: winnerId,
        resultMarginText: marginText,
        isTie: isTie,
      );
    }

    return _replaceActiveInnings(state, updatedInnings);
  }

  CricketState _replaceActiveInnings(CricketState state, CricketInningsState innings) {
    final list = List<CricketInningsState>.from(state.innings);
    list[state.currentInningsIndex] = innings;
    return state.copyWith(innings: list);
  }

  @override
  List<ScoringAction> availableActions(CricketState state) {
    if (state.isCompleted) return const [];
    final active = state.activeInnings;
    if (active == null || active.isComplete) return const [];

    final actions = <ScoringAction>[];

    // Batters selection needed
    if (active.strikerId == null || active.nonStrikerId == null) {
      actions.add(const ScoringAction(
        id: 'set_batters',
        label: 'Select Batters',
        type: 'set_batters',
        isPrimary: true,
      ));
      return actions;
    }

    // Bowler selection needed
    if (active.currentBowlerId == null) {
      actions.add(const ScoringAction(
        id: 'select_bowler',
        label: 'Select Bowler for Next Over',
        type: 'select_bowler',
        isPrimary: true,
      ));
      return actions;
    }

    // Common run actions
    for (final r in [0, 1, 2, 3, 4, 6]) {
      actions.add(ScoringAction(
        id: 'run_$r',
        label: '$r',
        type: 'delivery',
        payload: {
          'kind': 'normal',
          'runs': r,
          'is_boundary': r == 4 || r == 6,
        },
        isPrimary: r == 4 || r == 6,
      ));
    }

    // Extras
    actions.add(const ScoringAction(
      id: 'wide',
      label: 'Wide',
      type: 'delivery',
      payload: {'kind': 'wide', 'runs': 0},
    ));

    actions.add(const ScoringAction(
      id: 'no_ball',
      label: 'No Ball',
      type: 'delivery',
      payload: {'kind': 'no_ball', 'runs': 0},
    ));

    actions.add(const ScoringAction(
      id: 'bye',
      label: 'Bye',
      type: 'delivery',
      payload: {'kind': 'bye', 'runs': 1},
    ));

    actions.add(const ScoringAction(
      id: 'leg_bye',
      label: 'Leg Bye',
      type: 'delivery',
      payload: {'kind': 'leg_bye', 'runs': 1},
    ));

    // Wicket
    actions.add(const ScoringAction(
      id: 'wicket',
      label: 'Wicket',
      type: 'delivery',
      payload: {'is_wicket': true, 'kind': 'normal', 'dismissal_type': 'bowled'},
      isDestructive: true,
    ));

    return actions;
  }

  @override
  bool isComplete(CricketState state) => state.isCompleted;

  @override
  Map<String, dynamic> result(CricketState state) {
    return {
      'innings': state.innings.map((i) => i.toJson()).toList(),
      'winner_team_id': state.winnerTeamId,
      'result_margin': state.resultMarginText,
      'is_tie': state.isTie,
      'target': state.target,
    };
  }

  @override
  Map<String, dynamic> toSnapshot(CricketState state) => state.toJson();

  @override
  CricketState fromSnapshot(Map<String, dynamic> json, CricketConfig config) =>
      CricketState.fromJson(json);
}
