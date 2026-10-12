import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/widgets/match_card.dart';

void main() {
  group('Google-Style MatchCard Cricket Scorecard Tests', () {
    const testMatchId = 'm-cricket-google-1';

    testWidgets('Renders 1st innings live cricket match like Google with batting icon and CRR', (tester) async {
      final liveMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        format: 'T20',
        venue: 'Main Ground',
        scheduledAt: DateTime.now(),
        status: 'live',
        createdBy: 'u-1',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
        participants: const [
          MatchParticipant(matchId: testMatchId, teamId: 't-1', teamName: 'Warriors', side: 'home'),
          MatchParticipant(matchId: testMatchId, teamId: 't-2', teamName: 'Titans', side: 'away'),
        ],
        config: const {'overs_per_innings': 20},
        score: {
          'current_innings_index': 0,
          'innings': [
            {
              'batting_team_id': 't-1',
              'bowling_team_id': 't-2',
              'total_runs': 54,
              'total_wickets': 1,
              'legal_balls': 36, // 6.0 overs
              'is_complete': false,
            }
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(match: liveMatch),
          ),
        ),
      );

      // Verify Google-style header
      expect(find.text('CRICKET • T20'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Verify team names
      expect(find.text('Warriors'), findsOneWidget);
      expect(find.text('Titans'), findsOneWidget);

      // Batting indicator on active team
      expect(find.text('🏏'), findsOneWidget);

      // Score and overs for batting team
      expect(find.textContaining('54/1'), findsOneWidget);
      expect(find.textContaining('(6.0)'), findsOneWidget);

      // Other team has not batted yet
      expect(find.text('Yet to bat'), findsOneWidget);

      // CRR status line
      expect(find.textContaining('CRR 9.0'), findsOneWidget);
    });

    testWidgets('Renders 2nd innings live chase like Google with need equation & RRR', (tester) async {
      final chasingMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        format: 'T20',
        venue: 'Main Ground',
        scheduledAt: DateTime.now(),
        status: 'live',
        createdBy: 'u-1',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
        participants: const [
          MatchParticipant(matchId: testMatchId, teamId: 't-1', teamName: 'Warriors', side: 'home'),
          MatchParticipant(matchId: testMatchId, teamId: 't-2', teamName: 'Titans', side: 'away'),
        ],
        config: const {'overs_per_innings': 20},
        score: {
          'current_innings_index': 1,
          'target': 166,
          'innings': [
            {
              'batting_team_id': 't-1',
              'bowling_team_id': 't-2',
              'total_runs': 165,
              'total_wickets': 4,
              'legal_balls': 120, // 20.0 overs
              'is_complete': true,
            },
            {
              'batting_team_id': 't-2',
              'bowling_team_id': 't-1',
              'total_runs': 142,
              'total_wickets': 8,
              'legal_balls': 111, // 18.3 overs (9 balls left)
              'is_complete': false,
            }
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(match: chasingMatch),
          ),
        ),
      );

      // Both team scores are visible
      expect(find.textContaining('165/4'), findsOneWidget);
      expect(find.textContaining('(20.0)'), findsOneWidget);
      expect(find.textContaining('142/8'), findsOneWidget);
      expect(find.textContaining('(18.3)'), findsOneWidget);

      // Google chase equation banner: "Titans need 24 runs in 9 balls (RRR 16.0)"
      expect(find.textContaining('Titans need 24 runs in 9 balls'), findsOneWidget);
      expect(find.textContaining('RRR 16.0'), findsOneWidget);
    });

    testWidgets('Renders completed cricket match with winner highlight and result margin', (tester) async {
      final completedMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'completed',
        createdBy: 'u-1',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
        participants: const [
          MatchParticipant(matchId: testMatchId, teamId: 't-1', teamName: 'Warriors', side: 'home'),
          MatchParticipant(matchId: testMatchId, teamId: 't-2', teamName: 'Titans', side: 'away'),
        ],
        result: const {
          'winner_team_id': 't-1',
          'winner_team_name': 'Warriors',
          'result_margin': 'Warriors won by 25 runs',
        },
        score: {
          'innings': [
            {
              'batting_team_id': 't-1',
              'total_runs': 165,
              'total_wickets': 4,
              'legal_balls': 120,
            },
            {
              'batting_team_id': 't-2',
              'total_runs': 140,
              'total_wickets': 9,
              'legal_balls': 120,
            }
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(match: completedMatch),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.textContaining('165/4'), findsOneWidget);
      expect(find.textContaining('140/9'), findsOneWidget);
      expect(find.text('Warriors won by 25 runs'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Renders upcoming cricket match with team rows and scheduled time', (tester) async {
      final upcomingMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        format: '10 Overs',
        venue: 'North Ground',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        status: 'scheduled',
        createdBy: 'u-1',
        homeTeamName: 'Knights',
        awayTeamName: 'Strikers',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(match: upcomingMatch),
          ),
        ),
      );

      expect(find.text('CRICKET • 10 OVERS'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Knights'), findsOneWidget);
      expect(find.text('Strikers'), findsOneWidget);
      expect(find.text('North Ground'), findsOneWidget);
      // No live batting indicator
      expect(find.text('🏏'), findsNothing);
    });
  });
}
