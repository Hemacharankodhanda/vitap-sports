import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/widgets/match_card.dart';
import 'package:vitap_sports/features/matches/widgets/professional_scorecard.dart';
import 'package:vitap_sports/features/scorecards/screens/scorecard_view_screen.dart';
import 'package:vitap_sports/features/scoring/engines/badminton/badminton_engine.dart';
import 'package:vitap_sports/features/scoring/engines/badminton/badminton_state.dart';

void main() {
  group('Badminton Completed Match Scorecard & Layout Tests', () {
    test('BadmintonState.fromJson safely parses player_stats with name and team_id strings', () {
      final json = {
        'home_id': 'p-sindhu',
        'away_id': 'p-saina',
        'current_game_index': 2,
        'home_games_won': 2,
        'away_games_won': 1,
        'is_completed': true,
        'winner_id': 'p-sindhu',
        'games': [
          {'game_number': 1, 'home_points': 21, 'away_points': 18, 'is_completed': true},
          {'game_number': 2, 'home_points': 19, 'away_points': 21, 'is_completed': true},
          {'game_number': 3, 'home_points': 21, 'away_points': 15, 'is_completed': true},
        ],
        'player_stats': {
          'p-sindhu': {
            'name': 'P.V. Sindhu',
            'team_id': 'team-home',
            'points': 61,
            'aces': 5,
          },
          'p-saina': {
            'name': 'Saina Nehwal',
            'team_id': 'team-away',
            'points': 54,
            'aces': 3,
          },
        },
      };

      final state = BadmintonState.fromJson(json);
      expect(state.homeGamesWon, equals(2));
      expect(state.awayGamesWon, equals(1));
      expect(state.isCompleted, isTrue);
      expect(state.winnerId, equals('p-sindhu'));
      expect(state.playerStats['p-sindhu']?['points'], equals(61));
      expect(state.playerStats['p-saina']?['points'], equals(54));
      // String attributes should not crash the engine
      expect(state.playerStats['p-sindhu']?.containsKey('name'), isFalse);
    });

    test('MatchModel.fromJson falls back to score/result games won for homeScore and awayScore', () {
      final matchJson = {
        'id': 'bad-match-1',
        'sport_id': 's-badminton',
        'venue': 'Badminton Indoor Stadium',
        'scheduled_at': '2026-10-12T10:00:00Z',
        'status': 'completed',
        'created_by': 'u-admin',
        'format': 'Singles - Competitive',
        'home_score': null,
        'away_score': null,
        'score': {
          'home_games_won': 2,
          'away_games_won': 0,
          'games': [
            {'game_number': 1, 'home_points': 21, 'away_points': 14, 'is_completed': true},
            {'game_number': 2, 'home_points': 21, 'away_points': 17, 'is_completed': true},
          ],
        },
        'result': {
          'home_games_won': 2,
          'away_games_won': 0,
          'games_summary': '21-14, 21-17',
          'winner_team_name': 'P.V. Sindhu',
          'result_margin': 'P.V. Sindhu won (21-14, 21-17)',
        },
        'match_participants': [
          {
            'match_id': 'bad-match-1',
            'user_id': 'p-sindhu',
            'side': 'home',
            'users': {'name': 'P.V. Sindhu'},
          },
          {
            'match_id': 'bad-match-1',
            'user_id': 'p-saina',
            'side': 'away',
            'users': {'name': 'Saina Nehwal'},
          },
        ],
      };

      final model = MatchModel.fromJson(matchJson);
      expect(model.homeScore, equals(2));
      expect(model.awayScore, equals(0));
      expect(model.resolvedHomeTeamName, equals('P.V. Sindhu'));
      expect(model.resolvedAwayTeamName, equals('Saina Nehwal'));
      expect(model.winningTeamName, equals('P.V. Sindhu'));
    });

    testWidgets('MatchCard displays completed badminton score and does NOT overflow with long names',
        (tester) async {
      // Set tester surface to typical narrow mobile screen (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedMatch = MatchModel(
        id: 'bad-long-1',
        sportId: 's-badminton',
        sportName: 'Badminton',
        venue: 'VIT-AP Indoor Sports Complex Court 1',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'completed',
        format: 'Mens Doubles - Championship League',
        createdBy: 'u-1',
        homeTeamName: 'Srikar Reddy Kodhanda / Hemacharan Kodhanda',
        awayTeamName: 'Chaitanya Varma Alluri / Venkata Sai Kumar',
        homeScore: 2,
        awayScore: 1,
        score: const {
          'home_games_won': 2,
          'away_games_won': 1,
          'games_summary': '21-19, 18-21, 21-16',
          'games': [
            {'game_number': 1, 'home_points': 21, 'away_points': 19, 'is_completed': true},
            {'game_number': 2, 'home_points': 18, 'away_points': 21, 'is_completed': true},
            {'game_number': 3, 'home_points': 21, 'away_points': 16, 'is_completed': true},
          ],
        },
        result: const {
          'home_games_won': 2,
          'away_games_won': 1,
          'games_summary': '21-19, 18-21, 21-16',
          'winner_team_name': 'Srikar Reddy Kodhanda / Hemacharan Kodhanda',
          'result_margin': 'Srikar Reddy Kodhanda / Hemacharan Kodhanda won (21-19, 18-21, 21-16)',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MatchCard(match: completedMatch),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check scores appear
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Verify no overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfessionalScorecard displays badminton games breakdown when match is completed',
        (tester) async {
      final state = BadmintonState.fromJson(const {
        'home_id': 'home',
        'away_id': 'away',
        'home_games_won': 2,
        'away_games_won': 1,
        'is_completed': true,
        'winner_id': 'home',
        'games': [
          {'game_number': 1, 'home_points': 21, 'away_points': 19, 'is_completed': true},
          {'game_number': 2, 'home_points': 18, 'away_points': 21, 'is_completed': true},
          {'game_number': 3, 'home_points': 21, 'away_points': 16, 'is_completed': true},
        ],
        'player_stats': {
          'u-1': {'name': 'Player 1', 'team_id': 'home', 'points': 42},
          'u-2': {'name': 'Player 2', 'team_id': 'away', 'points': 38},
        },
      });

      final match = MatchModel(
        id: 'bad-m-1',
        sportId: 's-badminton',
        sportName: 'Badminton',
        venue: 'Court 2',
        scheduledAt: DateTime.now(),
        status: 'completed',
        createdBy: 'u-1',
        homeTeamName: 'Challengers',
        awayTeamName: 'Defenders',
        homeScore: 2,
        awayScore: 1,
        score: state.toJson(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfessionalScorecard(
                match: match,
                scoringState: state,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show 'Games won'
      expect(find.text('Games won'), findsWidgets);
      expect(find.text('Game 1'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      expect(find.text('Game 3'), findsOneWidget);
      expect(find.text('21'), findsNWidgets(3));
      expect(find.text('Scorecard in progress'), findsNothing);
    });
  });
}
