import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/engines/cricket/cricket_engine.dart';
import 'package:vitap_sports/features/scoring/engines/cricket/cricket_state.dart';

void main() {
  group('CricketEngine Tests', () {
    late CricketEngine engine;
    late CricketConfig config;

    setUp(() {
      engine = CricketEngine();
      config = const CricketConfig(oversPerInnings: 2, playersPerSide: 4); // 3 wickets = all out
    });

    test('wide does not advance the over and adds 1+runs charged to bowler', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {
          'striker_id': 'batter_1',
          'non_striker_id': 'batter_2',
          'opening_bowler_id': 'bowler_1',
        },
      );

      // Normal ball: 1 run (legal, ball 1)
      state = engine.apply(state, MatchEvent(
        id: '1', matchId: 'm', seq: 1, type: 'delivery',
        payload: {'kind': 'normal', 'runs': 1},
      ));
      expect(state.activeInnings!.legalBalls, equals(1));
      expect(state.activeInnings!.totalRuns, equals(1));

      // Wide ball: adds 1 penalty + 1 run = 2 total, legal balls DOES NOT ADVANCE
      state = engine.apply(state, MatchEvent(
        id: '2', matchId: 'm', seq: 2, type: 'delivery',
        payload: {'kind': 'wide', 'runs': 1},
      ));
      expect(state.activeInnings!.legalBalls, equals(1)); // Still 1!
      expect(state.activeInnings!.totalRuns, equals(3));
      expect(state.activeInnings!.bowlingStats['bowler_1']!.runsConceded, equals(3));
      expect(state.activeInnings!.wides, equals(2));
    });

    test('no-ball sets free hit and on next ball only run out is allowed', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {
          'striker_id': 'b1',
          'non_striker_id': 'b2',
          'opening_bowler_id': 'bowl1',
        },
      );

      // No ball delivery
      state = engine.apply(state, MatchEvent(
        id: '1', matchId: 'm', seq: 1, type: 'delivery',
        payload: {'kind': 'no_ball', 'runs': 0},
      ));
      expect(state.activeInnings!.isFreeHit, isTrue);

      // On free hit: bowled attempt should fail validation
      final bowledErr = engine.validate(state, MatchEvent(
        id: '2', matchId: 'm', seq: 2, type: 'delivery',
        payload: {'kind': 'normal', 'runs': 0, 'is_wicket': true, 'dismissal_type': 'bowled'},
      ));
      expect(bowledErr, contains('only run out is allowed'));

      // Run out on free hit is allowed
      final runOutErr = engine.validate(state, MatchEvent(
        id: '3', matchId: 'm', seq: 3, type: 'delivery',
        payload: {'kind': 'normal', 'runs': 0, 'is_wicket': true, 'dismissal_type': 'run_out'},
      ));
      expect(runOutErr, isNull);
    });

    test('byes not credited to batter or bowler', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      state = engine.apply(state, MatchEvent(
        id: '1', matchId: 'm', seq: 1, type: 'delivery',
        payload: {'kind': 'bye', 'runs': 2},
      ));

      expect(state.activeInnings!.totalRuns, equals(2));
      expect(state.activeInnings!.byes, equals(2));
      expect(state.activeInnings!.battingStats['b1']!.runs, equals(0)); // 0 off bat!
      expect(state.activeInnings!.bowlingStats['bowl1']!.runsConceded, equals(0)); // 0 charged!
    });

    test('odd runs swap strike; over end swaps strike', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      // Ball 1: 1 run -> strike swaps to b2
      state = engine.apply(state, MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'delivery', payload: {'kind': 'normal', 'runs': 1}));
      expect(state.activeInnings!.strikerId, equals('b2'));

      // Ball 2: 2 runs -> strike stays at b2
      state = engine.apply(state, MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'delivery', payload: {'kind': 'normal', 'runs': 2}));
      expect(state.activeInnings!.strikerId, equals('b2'));

      // Ball 3, 4, 5: dot balls (0 runs)
      for (int i = 3; i <= 5; i++) {
        state = engine.apply(state, MatchEvent(id: '$i', matchId: 'm', seq: i, type: 'delivery', payload: {'kind': 'normal', 'runs': 0}));
      }
      expect(state.activeInnings!.strikerId, equals('b2'));

      // Ball 6 (last ball of over): 1 run
      // Individual ball swaps strike (b2 -> b1), but end of over also swaps ends (b1 -> b2), so net = b2 stays!
      state = engine.apply(state, MatchEvent(id: '6', matchId: 'm', seq: 6, type: 'delivery', payload: {'kind': 'normal', 'runs': 1}));
      expect(state.activeInnings!.strikerId, equals('b2'));
      // Over completed -> Bowler must change
      expect(state.activeInnings!.currentBowlerId, isNull);
      expect(state.activeInnings!.lastOverBowlerId, equals('bowl1'));
    });

    test('maiden detection: 6 legal dots with zero runs conceded', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      // 6 consecutive dot balls
      for (int i = 1; i <= 6; i++) {
        state = engine.apply(state, MatchEvent(id: '$i', matchId: 'm', seq: i, type: 'delivery', payload: {'kind': 'normal', 'runs': 0}));
      }

      expect(state.activeInnings!.bowlingStats['bowl1']!.maidens, equals(1));
    });

    test('all out ends innings; second innings target & win margin correct', () {
      // playersPerSide: 4 -> max wickets = 3
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      // 3 wickets
      state = engine.apply(state, MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'delivery', payload: {'kind': 'normal', 'runs': 10, 'is_wicket': true, 'dismissal_type': 'bowled', 'new_batter_id': 'b3'}));
      state = engine.apply(state, MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'delivery', payload: {'kind': 'normal', 'runs': 5, 'is_wicket': true, 'dismissal_type': 'bowled', 'new_batter_id': 'b4'}));
      state = engine.apply(state, MatchEvent(id: '3', matchId: 'm', seq: 3, type: 'delivery', payload: {'kind': 'normal', 'runs': 0, 'is_wicket': true, 'dismissal_type': 'bowled'}));

      // Innings 1 all out! Total runs = 15. Target = 16.
      expect(state.innings[0].isComplete, isTrue);
      expect(state.target, equals(16));
      expect(state.currentInningsIndex, equals(1));

      // 2nd innings starts for team_away
      state = engine.apply(state, MatchEvent(id: 's2', matchId: 'm', seq: 4, type: 'set_bowler', payload: {'bowler_id': 'bowl2'}));
      state = engine.apply(state, MatchEvent(id: 's3', matchId: 'm', seq: 5, type: 'set_batters', payload: {'striker_id': 'a1', 'non_striker_id': 'a2'}));

      // Chasing team scores 16 runs off 3 balls -> reaches target!
      state = engine.apply(state, MatchEvent(id: 'c1', matchId: 'm', seq: 6, type: 'delivery', payload: {'kind': 'normal', 'runs': 6, 'is_boundary': true}));
      state = engine.apply(state, MatchEvent(id: 'c2', matchId: 'm', seq: 7, type: 'delivery', payload: {'kind': 'normal', 'runs': 6, 'is_boundary': true}));
      state = engine.apply(state, MatchEvent(id: 'c3', matchId: 'm', seq: 8, type: 'delivery', payload: {'kind': 'normal', 'runs': 4, 'is_boundary': true}));

      expect(state.isCompleted, isTrue);
      expect(state.winnerTeamId, equals('team_away'));
      expect(state.resultMarginText, equals('won by 3 wickets'));
    });

    test('property: folding all events reproduces snapshot and undo restores previous state', () {
      final events = [
        MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'delivery', payload: {'kind': 'normal', 'runs': 4, 'is_boundary': true}),
        MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'delivery', payload: {'kind': 'normal', 'runs': 1}),
        MatchEvent(id: '3', matchId: 'm', seq: 3, type: 'delivery', payload: {'kind': 'wide', 'runs': 0}),
      ];

      final folded = engine.fold(
        config,
        events,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );
      final snapshot = engine.toSnapshot(folded);
      final restored = engine.fromSnapshot(snapshot, config);

      expect(restored.activeInnings!.totalRuns, equals(6)); // 4 + 1 + (1 wide) = 6
      expect(restored.activeInnings!.legalBalls, equals(2));

      // Undo last event (remove wide)
      final eventsWithoutLast = events.sublist(0, events.length - 1);
      final beforeLast = engine.fold(
        config,
        eventsWithoutLast,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );
      expect(beforeLast.activeInnings!.totalRuns, equals(5));
      expect(beforeLast.activeInnings!.legalBalls, equals(2));
    });

    test('wicket delivery increments totalWickets and bowler wickets, and marks batter as out', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      expect(state.activeInnings!.totalWickets, equals(0));
      expect(state.activeInnings!.bowlingStats['bowl1']!.wickets, equals(0));

      // Bowled delivery with new batter b3
      state = engine.apply(state, MatchEvent(
        id: 'w1',
        matchId: 'm',
        seq: 1,
        type: 'delivery',
        payload: {
          'is_wicket': true,
          'kind': 'normal',
          'dismissal_type': 'bowled',
          'out_batter_id': 'b1',
          'new_batter_id': 'b3',
          'runs': 0,
        },
      ));

      expect(state.activeInnings!.totalWickets, equals(1));
      expect(state.activeInnings!.bowlingStats['bowl1']!.wickets, equals(1));
      expect(state.activeInnings!.battingStats['b1']!.isOut, isTrue);
      expect(state.activeInnings!.battingStats['b1']!.howOut, equals('bowled'));
      expect(state.activeInnings!.strikerId, equals('b3'));
      expect(state.activeInnings!.fallOfWickets.length, equals(1));
      expect(state.activeInnings!.fallOfWickets.first['wicket'], equals(1));
      expect(state.activeInnings!.fallOfWickets.first['player_id'], equals('b1'));
    });

    test('wicket delivery accepts showWicketSheet payload (dismissed_batter_id, runs_completed)', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'striker_id': 'b1', 'non_striker_id': 'b2', 'opening_bowler_id': 'bowl1'},
      );

      // Run out of non-striker b2 with 1 run completed
      state = engine.apply(state, MatchEvent(
        id: 'w2',
        matchId: 'm',
        seq: 1,
        type: 'delivery',
        payload: {
          'is_wicket': true,
          'kind': 'normal',
          'dismissal_type': 'run_out',
          'dismissed_batter_id': 'b2',
          'new_batter_id': 'b3',
          'runs_completed': 1,
        },
      ));

      expect(state.activeInnings!.totalWickets, equals(1));
      expect(state.activeInnings!.totalRuns, equals(1));
      // Run out is not credited to bowler's wickets tally
      expect(state.activeInnings!.bowlingStats['bowl1']!.wickets, equals(0));
      expect(state.activeInnings!.battingStats['b2']!.isOut, isTrue);
      expect(state.activeInnings!.battingStats['b2']!.howOut, equals('run_out'));
      // Striker b1 is still not out
      expect(state.activeInnings!.battingStats['b1']!.isOut, isFalse);
    });
  });
}
