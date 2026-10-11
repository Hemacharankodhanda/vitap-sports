import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/widgets/professional_scorecard.dart';
import 'package:vitap_sports/features/scoring/engines/badminton/badminton_state.dart';
import 'package:vitap_sports/features/scoring/engines/cricket/cricket_state.dart';
import 'package:vitap_sports/features/scoring/engines/football/football_state.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(const Color(0xFF2563EB)),
      darkTheme: AppTheme.dark(const Color(0xFF60A5FA)),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  MatchModel createTestMatch({
    required String id,
    required String sportId,
    String? sportName,
    String status = 'completed',
    String? homeTeamName,
    String? awayTeamName,
  }) {
    return MatchModel(
      id: id,
      sportId: sportId,
      sportName: sportName,
      venue: 'Main Ground',
      scheduledAt: DateTime.now(),
      status: status,
      createdBy: 'u1',
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
    );
  }

  group('ProfessionalScorecard Design Rules Tests', () {
    testWidgets('Renders cricket scorecard with professional tables and tabular figures', (tester) async {
      final match = createTestMatch(
        id: 'cricket_m1',
        sportId: 's-cricket',
        sportName: 'Cricket',
        status: 'completed',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
      );

      final state = CricketState(
        homeId: 't1',
        awayId: 't2',
        innings: [
          CricketInningsState(
            battingTeamId: 't1',
            bowlingTeamId: 't2',
            totalRuns: 165,
            totalWickets: 4,
            legalBalls: 120,
            byes: 4,
            legByes: 2,
            wides: 3,
            noBalls: 1,
            battingStats: {
              'p1': const BatterRecord(
                runs: 58,
                ballsFaced: 36,
                fours: 6,
                sixes: 2,
                isOut: true,
                howOut: 'bowled',
                bowlerId: 'b1',
              ),
              'p2': const BatterRecord(
                runs: 45,
                ballsFaced: 30,
                fours: 4,
                sixes: 1,
                isOut: false,
              ),
            },
            bowlingStats: {
              'b1': const BowlerRecord(
                ballsBowled: 24,
                runsConceded: 28,
                wickets: 2,
                maidens: 0,
              ),
            },
          ),
        ],
        currentInningsIndex: 0,
      );

      final playerNames = {
        'p1': 'Virat K',
        'p2': 'Rohit S',
        'b1': 'Jasprit B',
      };

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: state,
          playerNames: playerNames,
        ),
      ));
      await tester.pumpAndSettle();

      // Headers and tables
      expect(find.text('BATTER'), findsOneWidget);
      expect(find.text('BOWLER'), findsOneWidget);
      expect(find.text('Virat K'), findsOneWidget);
      expect(find.text('Rohit S*'), findsOneWidget);
      expect(find.text('b Jasprit B'), findsOneWidget);
      expect(find.text('not out'), findsOneWidget);
      expect(find.text('Jasprit B'), findsOneWidget);

      // Total and extras
      expect(find.text('Extras'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('165/4'), findsWidgets);
    });

    testWidgets('Renders football scorecard with clean chrome and no emojis', (tester) async {
      final match = createTestMatch(
        id: 'football_m1',
        sportId: 's-football',
        sportName: 'Football',
        status: 'live',
        homeTeamName: 'Red Bulls',
        awayTeamName: 'Blue Wings',
      );

      final state = FootballState(
        homeId: 't1',
        awayId: 't2',
        homeScore: 2,
        awayScore: 1,
        goals: const [
          GoalRecord(
            scorerId: 'p1',
            teamId: 't1',
            minute: 15,
            isOwnGoal: false,
            assistId: 'p2',
          ),
          GoalRecord(
            scorerId: 'p1',
            teamId: 't1',
            minute: 42,
            isOwnGoal: false,
          ),
        ],
        yellowCards: const {
          'p1': 1,
        },
      );

      final playerNames = {
        'p1': 'Marcus R',
        'p2': 'Bruno F',
      };

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: state,
          playerNames: playerNames,
        ),
      ));
      await tester.pumpAndSettle();

      // Clean headers without emojis
      expect(find.text('PLAYER'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('YC'), findsOneWidget);
      expect(find.text('RC'), findsOneWidget);

      // Verify no emoji in chrome
      expect(find.textContaining('⚽'), findsNothing);
      expect(find.textContaining('🎯'), findsNothing);
      expect(find.textContaining('🟨'), findsNothing);
      expect(find.textContaining('🟥'), findsNothing);

      // Players
      expect(find.text('Marcus R'), findsOneWidget);
      expect(find.text('Bruno F'), findsOneWidget);
    });

    testWidgets('Renders badminton scorecard with games summary and game cards', (tester) async {
      final match = createTestMatch(
        id: 'badminton_m1',
        sportId: 's-badminton',
        sportName: 'Badminton',
        status: 'completed',
        homeTeamName: 'Team Alpha',
        awayTeamName: 'Team Beta',
      );

      final state = const BadmintonState(
        homeId: 't1',
        awayId: 't2',
        homeGamesWon: 2,
        awayGamesWon: 1,
        games: [
          BadmintonGame(homePoints: 21, awayPoints: 18, isCompleted: true, winnerId: 't1'),
          BadmintonGame(homePoints: 17, awayPoints: 21, isCompleted: true, winnerId: 't2'),
          BadmintonGame(homePoints: 21, awayPoints: 14, isCompleted: true, winnerId: 't1'),
        ],
      );

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: state,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Team Alpha'), findsOneWidget);
      expect(find.text('Team Beta'), findsOneWidget);
      expect(find.text('Game 1'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      expect(find.text('Game 3'), findsOneWidget);
      expect(find.text('21'), findsWidgets);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('Renders clean empty state when no events yet', (tester) async {
      final match = createTestMatch(
        id: 'empty_m1',
        sportId: 's-cricket',
        sportName: 'Cricket',
        status: 'upcoming',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
      );

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: null,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Scorecard in progress'), findsOneWidget);
      expect(find.textContaining('appear once scoring begins'), findsOneWidget);
    });
  });
}
