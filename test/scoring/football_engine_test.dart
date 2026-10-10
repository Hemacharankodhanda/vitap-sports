import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/engines/football/football_engine.dart';
import 'package:vitap_sports/features/scoring/engines/football/football_state.dart';

void main() {
  group('FootballEngine Tests', () {
    late FootballEngine engine;
    late FootballConfig config;

    setUp(() {
      engine = FootballEngine();
      config = const FootballConfig(playersPerSide: 7, halfLengthMinutes: 20);
    });

    test('own goal credits opponent and records as own goal', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');
      state = engine.apply(state, MatchEvent(
        id: '1', matchId: 'm1', seq: 1, type: 'period_start', payload: {'period': 'first_half'},
      ));

      // Home player scores an own goal
      state = engine.apply(state, MatchEvent(
        id: '2', matchId: 'm1', seq: 2, type: 'own_goal', teamId: 'team_home', playerId: 'player_h1',
        payload: {'minute': 10},
      ));

      expect(state.homeScore, equals(0));
      expect(state.awayScore, equals(1)); // Opponent credited with the point!
      expect(state.goals.length, equals(1));
      expect(state.goals.first.isOwnGoal, isTrue);
      expect(state.goals.first.scorerId, equals('player_h1'));
    });

    test('second yellow card automatically creates red card and removes from pitch', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {
          'home_lineup': ['player_h1', 'player_h2'],
          'away_lineup': ['player_a1', 'player_a2'],
        },
      );
      state = engine.apply(state, MatchEvent(
        id: '1', matchId: 'm1', seq: 1, type: 'period_start', payload: {'period': 'first_half'},
      ));

      // 1st yellow
      state = engine.apply(state, MatchEvent(
        id: '2', matchId: 'm1', seq: 2, type: 'yellow_card', teamId: 'team_home', playerId: 'player_h1',
      ));
      expect(state.yellowCards['player_h1'], equals(1));
      expect(state.redCardedPlayers.contains('player_h1'), isFalse);
      expect(state.pitchPlayers['team_home']!.contains('player_h1'), isTrue);

      // 2nd yellow
      state = engine.apply(state, MatchEvent(
        id: '3', matchId: 'm1', seq: 3, type: 'yellow_card', teamId: 'team_home', playerId: 'player_h1',
      ));
      expect(state.yellowCards['player_h1'], equals(2));
      expect(state.redCardedPlayers.contains('player_h1'), isTrue); // Auto red!
      expect(state.pitchPlayers['team_home']!.contains('player_h1'), isFalse); // Removed from pitch!
    });

    test('substitution validation: player_out on pitch, player_in on bench and not carded', () {
      final state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {
          'home_lineup': ['player_h1', 'player_h2'],
          'home_bench': ['player_sub1'],
          'away_lineup': ['player_a1'],
        },
      );

      // Valid sub
      final validErr = engine.validate(state, MatchEvent(
        id: '1', matchId: 'm1', seq: 1, type: 'substitution', teamId: 'team_home',
        payload: {'player_out': 'player_h1', 'player_in': 'player_sub1'},
      ));
      expect(validErr, isNull);

      // Invalid sub: player_out not on pitch
      final invalidOutErr = engine.validate(state, MatchEvent(
        id: '2', matchId: 'm1', seq: 2, type: 'substitution', teamId: 'team_home',
        payload: {'player_out': 'player_nonexistent', 'player_in': 'player_sub1'},
      ));
      expect(invalidOutErr, contains('not on the pitch'));

      // Invalid sub: player_in not on bench
      final invalidInErr = engine.validate(state, MatchEvent(
        id: '3', matchId: 'm1', seq: 3, type: 'substitution', teamId: 'team_home',
        payload: {'player_out': 'player_h1', 'player_in': 'player_not_on_bench'},
      ));
      expect(invalidInErr, contains('not on the bench'));
    });

    test('shootout stops early when mathematically decided and score does not alter match score', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');
      state = state.copyWith(currentPeriod: 'shootout', homeScore: 1, awayScore: 1);

      // Round 1: Home scores (1), Away misses (0)
      state = engine.apply(state, MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'shootout_kick', teamId: 'team_home', playerId: 'p1', payload: {'scored': true}));
      state = engine.apply(state, MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'shootout_kick', teamId: 'team_away', playerId: 'p2', payload: {'scored': false}));

      // Round 2: Home scores (2), Away misses (0)
      state = engine.apply(state, MatchEvent(id: '3', matchId: 'm', seq: 3, type: 'shootout_kick', teamId: 'team_home', playerId: 'p3', payload: {'scored': true}));
      state = engine.apply(state, MatchEvent(id: '4', matchId: 'm', seq: 4, type: 'shootout_kick', teamId: 'team_away', playerId: 'p4', payload: {'scored': false}));

      // Round 3: Home scores (3), Away misses (0) -> Away has only 2 kicks left, max possible = 2, Home has 3. Decided!
      state = engine.apply(state, MatchEvent(id: '5', matchId: 'm', seq: 5, type: 'shootout_kick', teamId: 'team_home', playerId: 'p5', payload: {'scored': true}));
      state = engine.apply(state, MatchEvent(id: '6', matchId: 'm', seq: 6, type: 'shootout_kick', teamId: 'team_away', playerId: 'p6', payload: {'scored': false}));

      expect(state.shootoutCompleted, isTrue);
      expect(state.winnerId, equals('team_home'));
      expect(state.shootoutHomeScore, equals(3));
      expect(state.shootoutAwayScore, equals(0));
      // Regular match score MUST NOT CHANGE
      expect(state.homeScore, equals(1));
      expect(state.awayScore, equals(1));
    });

    test('property: folding all events reproduces snapshot and undo restores previous state', () {
      final events = [
        MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'period_start', payload: {'period': 'first_half'}),
        MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'goal', teamId: 'team_home', playerId: 'p1', payload: {'minute': 5}),
        MatchEvent(id: '3', matchId: 'm', seq: 3, type: 'goal', teamId: 'team_away', playerId: 'p2', payload: {'minute': 15}),
      ];

      final folded = engine.fold(config, events, homeId: 'team_home', awayId: 'team_away');
      final snapshot = engine.toSnapshot(folded);
      final restored = engine.fromSnapshot(snapshot, config);

      expect(restored.homeScore, equals(1));
      expect(restored.awayScore, equals(1));
      expect(restored.goals.length, equals(2));

      // Undo last event
      final eventsWithoutLast = events.sublist(0, events.length - 1);
      final beforeLast = engine.fold(config, eventsWithoutLast, homeId: 'team_home', awayId: 'team_away');
      expect(beforeLast.homeScore, equals(1));
      expect(beforeLast.awayScore, equals(0));
    });
  });
}
