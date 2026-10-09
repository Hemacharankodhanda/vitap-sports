import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/engines/badminton/badminton_engine.dart';
import 'package:vitap_sports/features/scoring/engines/badminton/badminton_state.dart';

void main() {
  group('BadmintonEngine Tests', () {
    late BadmintonEngine engine;
    late BadmintonConfig config;

    setUp(() {
      engine = BadmintonEngine();
      config = const BadmintonConfig();
    });

    test('20-20 deuce requires 2-point lead: 22-20 ends game', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');

      // Score 20-20
      for (int i = 0; i < 20; i++) {
        state = engine.apply(state, MatchEvent(id: 'h_$i', matchId: 'm', seq: i * 2 + 1, type: 'rally_won', teamId: 'team_home'));
        state = engine.apply(state, MatchEvent(id: 'a_$i', matchId: 'm', seq: i * 2 + 2, type: 'rally_won', teamId: 'team_away'));
      }
      expect(state.games[0].homePoints, equals(20));
      expect(state.games[0].awayPoints, equals(20));
      expect(state.games[0].isCompleted, isFalse);

      // 21-20 does NOT end the game
      state = engine.apply(state, MatchEvent(id: 'h_21', matchId: 'm', seq: 41, type: 'rally_won', teamId: 'team_home'));
      expect(state.games[0].homePoints, equals(21));
      expect(state.games[0].isCompleted, isFalse);

      // 22-20 ENDS game 1 (lead of 2)
      state = engine.apply(state, MatchEvent(id: 'h_22', matchId: 'm', seq: 42, type: 'rally_won', teamId: 'team_home'));
      expect(state.games[0].isCompleted, isTrue);
      expect(state.games[0].homePoints, equals(22));
      expect(state.homeGamesWon, equals(1));
      expect(state.currentGameIndex, equals(1)); // Advanced to game 2
    });

    test('29-29 sudden death cap: next point at 30 wins game (30-29)', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');

      // Simulate up to 29-29
      final game29 = BadmintonGame(homePoints: 29, awayPoints: 29);
      state = state.copyWith(games: [game29], currentGameIndex: 0);

      // 30th point
      state = engine.apply(state, MatchEvent(id: 'p30', matchId: 'm', seq: 60, type: 'rally_won', teamId: 'team_home'));
      expect(state.games[0].homePoints, equals(30));
      expect(state.games[0].awayPoints, equals(29));
      expect(state.games[0].isCompleted, isTrue); // Cap of 30 ends the game!
      expect(state.homeGamesWon, equals(1));
    });

    test('serving court parity (even=right, odd=left) in singles', () {
      var state = engine.initialState(
        config,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {'home_players': ['h_player'], 'away_players': ['a_player']},
      );
      // At 0-0 (even) -> Right court
      expect(state.courtPositions['team_home']!['right'], equals('h_player'));
      expect(state.servingTeamId, equals('team_home'));

      // Home wins rally -> 1-0 (odd)
      state = engine.apply(state, MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'rally_won', teamId: 'team_home'));
      expect(state.games[0].homePoints, equals(1));
      // Serving pair swapped: player now in Left court (odd parity)
      expect(state.courtPositions['team_home']!['left'], equals('h_player'));

      // Home wins rally -> 2-0 (even)
      state = engine.apply(state, MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'rally_won', teamId: 'team_home'));
      expect(state.games[0].homePoints, equals(2));
      // Serving pair swapped back to Right court (even parity)
      expect(state.courtPositions['team_home']!['right'], equals('h_player'));
    });

    test('doubles server rotation: same server keeps serving and swaps courts, receiver gains serve without swapping', () {
      final doublesConfig = const BadmintonConfig(format: 'doubles');
      var state = engine.initialState(
        doublesConfig,
        homeId: 'team_home',
        awayId: 'team_away',
        extra: {
          'home_players': ['h1', 'h2'],
          'away_players': ['a1', 'a2'],
          'first_server_team_id': 'team_home',
          'first_server_id': 'h1',
        },
      );

      // Home court at 0-0: Right: h1, Left: h2
      expect(state.courtPositions['team_home']!['right'], equals('h1'));
      expect(state.courtPositions['team_home']!['left'], equals('h2'));
      expect(state.currentServerId, equals('h1'));

      // Home wins rally -> score 1-0: h1 keeps serve, but swaps courts
      state = engine.apply(state, MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'rally_won', teamId: 'team_home'));
      expect(state.currentServerId, equals('h1'));
      expect(state.courtPositions['team_home']!['left'], equals('h1'));
      expect(state.courtPositions['team_home']!['right'], equals('h2'));

      // Away wins rally -> Away gains serve, NO swapping on either side
      state = engine.apply(state, MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'rally_won', teamId: 'team_away'));
      expect(state.servingTeamId, equals('team_away'));
      // Away score is 1 (odd) -> player in Away Left court serves (a2)
      expect(state.currentServerId, equals('a2'));
    });

    test('interval prompt at 11 and change ends in game 3', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');

      // Win 10 points
      for (int i = 1; i <= 10; i++) {
        state = engine.apply(state, MatchEvent(id: '$i', matchId: 'm', seq: i, type: 'rally_won', teamId: 'team_home'));
      }
      expect(state.intervalPrompt, isNull);

      // 11th point -> interval 60s prompt
      state = engine.apply(state, MatchEvent(id: '11', matchId: 'm', seq: 11, type: 'rally_won', teamId: 'team_home'));
      expect(state.intervalPrompt, equals('interval 60s'));

      // In game 3 (index 2)
      state = state.copyWith(
        games: [const BadmintonGame(), const BadmintonGame(), const BadmintonGame(homePoints: 10)],
        currentGameIndex: 2,
      );
      state = engine.apply(state, MatchEvent(id: '11_g3', matchId: 'm', seq: 100, type: 'rally_won', teamId: 'team_home'));
      expect(state.intervalPrompt, equals('interval 60s - change ends'));
    });

    test('retire and walkover results are recorded accurately', () {
      var state = engine.initialState(config, homeId: 'team_home', awayId: 'team_away');

      // Walkover: recorded as 2-0 (21-0, 21-0)
      final walkoverState = engine.apply(state, MatchEvent(
        id: 'wo', matchId: 'm', seq: 1, type: 'walkover', teamId: 'team_away',
      ));
      expect(walkoverState.isCompleted, isTrue);
      expect(walkoverState.winnerId, equals('team_home'));
      expect(walkoverState.homeGamesWon, equals(2));
      expect(walkoverState.games[0].homePoints, equals(21));
      expect(walkoverState.games[0].awayPoints, equals(0));
      expect(walkoverState.games[1].homePoints, equals(21));
      expect(walkoverState.games[1].awayPoints, equals(0));
    });

    test('property: folding all events reproduces stored snapshot and undo restores exact state', () {
      final events = [
        MatchEvent(id: '1', matchId: 'm', seq: 1, type: 'rally_won', teamId: 'team_home'),
        MatchEvent(id: '2', matchId: 'm', seq: 2, type: 'rally_won', teamId: 'team_away'),
        MatchEvent(id: '3', matchId: 'm', seq: 3, type: 'rally_won', teamId: 'team_home'),
      ];

      final folded = engine.fold(config, events, homeId: 'team_home', awayId: 'team_away');
      final snapshot = engine.toSnapshot(folded);
      final restored = engine.fromSnapshot(snapshot, config);

      expect(restored.games[0].homePoints, equals(2));
      expect(restored.games[0].awayPoints, equals(1));

      // Undo last event
      final eventsWithoutLast = events.sublist(0, events.length - 1);
      final beforeLast = engine.fold(config, eventsWithoutLast, homeId: 'team_home', awayId: 'team_away');
      expect(beforeLast.games[0].homePoints, equals(1));
      expect(beforeLast.games[0].awayPoints, equals(1));
    });
  });
}
