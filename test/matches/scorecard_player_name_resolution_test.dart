import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/widgets/professional_scorecard.dart';
import 'package:vitap_sports/features/scoring/engines/cricket/cricket_state.dart';

Widget wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(const Color(0xFF2563EB)),
    darkTheme: AppTheme.dark(const Color(0xFF60A5FA)),
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('Scorecard Player Name Resolution Tests', () {
    testWidgets('Resolves "Batter 1", "Batter 2", and "Bowler 1" to actual participant names', (tester) async {
      final match = MatchModel(
        id: 'match-1',
        sportId: 's-cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now(),
        createdBy: 'u-1',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
        status: 'live',
        participants: const [
          MatchParticipant(
            matchId: 'match-1',
            teamId: 'team-warriors',
            userId: 'user-w1',
            userName: 'Rahul Sharma',
            side: 'home',
          ),
          MatchParticipant(
            matchId: 'match-1',
            teamId: 'team-warriors',
            userId: 'user-w2',
            userName: 'Priya Patel',
            side: 'home',
          ),
          MatchParticipant(
            matchId: 'match-1',
            teamId: 'team-titans',
            userId: 'user-t1',
            userName: 'Amit Verma',
            side: 'away',
          ),
        ],
      );

      final state = CricketState(
        homeId: 'team-warriors',
        awayId: 'team-titans',
        config: const CricketConfig(oversPerInnings: 20, playersPerSide: 11),
        innings: [
          CricketInningsState(
            battingTeamId: 'team-warriors',
            bowlingTeamId: 'team-titans',
            strikerId: 'Batter 1',
            nonStrikerId: 'Batter 2',
            currentBowlerId: 'Bowler 1',
            battingStats: {
              'Batter 1': const BatterRecord(runs: 24, ballsFaced: 18, fours: 3, sixes: 0, isOut: false),
              'Batter 2': const BatterRecord(runs: 12, ballsFaced: 10, fours: 1, sixes: 0, isOut: true, howOut: 'bowled', bowlerId: 'Bowler 1'),
            },
            bowlingStats: {
              'Bowler 1': const BowlerRecord(ballsBowled: 6, runsConceded: 8, wickets: 1, maidens: 0),
            },
          ),
        ],
        currentInningsIndex: 0,
      );

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: state,
          playerNames: const {}, // Empty! Must fallback to participant names
        ),
      ));
      await tester.pumpAndSettle();

      // Must find actual participant names instead of "Batter 1", "Batter 2", "Bowler 1"
      expect(find.text('Rahul Sharma*'), findsOneWidget);
      expect(find.text('Priya Patel'), findsOneWidget);
      expect(find.text('Amit Verma'), findsOneWidget);
      expect(find.text('b Amit Verma'), findsOneWidget);

      // Must NOT find placeholder literals in the tables
      expect(find.text('Batter 1*'), findsNothing);
      expect(find.text('Batter 2'), findsNothing);
      expect(find.text('Bowler 1'), findsNothing);
    });

    testWidgets('Fallbacks to Team Qualified Names when team has no registered squad members', (tester) async {
      final match = MatchModel(
        id: 'match-2',
        sportId: 's-cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now(),
        createdBy: 'u-1',
        homeTeamName: 'Hawks',
        awayTeamName: 'Eagles',
        status: 'live',
        participants: const [
          MatchParticipant(
            matchId: 'match-2',
            teamId: 'team-hawks',
            teamName: 'Hawks',
            side: 'home',
          ),
          MatchParticipant(
            matchId: 'match-2',
            teamId: 'team-eagles',
            teamName: 'Eagles',
            side: 'away',
          ),
        ],
      );

      final state = CricketState(
        homeId: 'team-hawks',
        awayId: 'team-eagles',
        config: const CricketConfig(oversPerInnings: 20, playersPerSide: 11),
        innings: [
          CricketInningsState(
            battingTeamId: 'team-hawks',
            bowlingTeamId: 'team-eagles',
            strikerId: 'Batter 1',
            nonStrikerId: 'Batter 2',
            currentBowlerId: 'Bowler 1',
            battingStats: {
              'Batter 1': const BatterRecord(runs: 15, ballsFaced: 12, fours: 2, sixes: 0, isOut: false),
              'Batter 2': const BatterRecord(runs: 8, ballsFaced: 6, fours: 1, sixes: 0, isOut: false),
            },
            bowlingStats: {
              'Bowler 1': const BowlerRecord(ballsBowled: 6, runsConceded: 10, wickets: 0, maidens: 0),
            },
          ),
        ],
        currentInningsIndex: 0,
      );

      await tester.pumpWidget(wrapWithTheme(
        ProfessionalScorecard(
          match: match,
          scoringState: state,
          playerNames: const {},
        ),
      ));
      await tester.pumpAndSettle();

      // Must display team-branded fallback names
      expect(find.text('Hawks Player 1*'), findsOneWidget);
      expect(find.text('Hawks Player 2*'), findsOneWidget);
      expect(find.text('Eagles Bowler 1'), findsOneWidget);

      // Must NOT find generic unbranded placeholders
      expect(find.text('Batter 1*'), findsNothing);
      expect(find.text('Batter 2'), findsNothing);
      expect(find.text('Bowler 1'), findsNothing);
    });
  });
}
