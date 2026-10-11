import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/profile/widgets/player_career_stats_card.dart';

void main() {
  group('PlayerCareerStatsCard Tests', () {
    testWidgets('renders all real cricket stats including SR, runs, sixes, fours, wickets', (tester) async {
      final cricketRow = {
        'sport': 'cricket',
        'sport_display_name': 'Cricket',
        'matches_played': 5,
        'career_counters': {
          'matches_won': 4,
          'matches_lost': 1,
          'mvps': 2,
          'runs_scored': 175,
          'balls_faced': 118,
          'fours': 18,
          'sixes': 6,
          'outs': 3,
          'wickets_taken': 7,
          'balls_bowled': 48,
          'runs_conceded': 52,
          'maidens': 2,
          'catches': 3,
          'run_outs': 1,
          'stumpings': 0,
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerCareerStatsCard(sportRow: cricketRow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('5 Matches • 4 W - 1 L (80% Win Rate)'), findsOneWidget);
      expect(find.text('2 MVP'), findsOneWidget);

      // Verify batting metrics: Runs, Balls, SR, Fours, Sixes
      expect(find.text('RUNS'), findsOneWidget);
      expect(find.text('175'), findsOneWidget);

      expect(find.text('BALLS'), findsNWidgets(2)); // batting balls & bowling balls
      expect(find.text('118'), findsOneWidget);

      expect(find.text('STRIKE RATE'), findsOneWidget);
      // 175 / 118 * 100 = 148.3
      expect(find.text('148.3'), findsOneWidget);

      expect(find.text('FOURS (4s)'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);

      expect(find.text('SIXES (6s)'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // Verify bowling metrics: Wickets, Overs, Economy, Runs Given, Maidens
      expect(find.text('WICKETS'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      expect(find.text('OVERS'), findsOneWidget);
      expect(find.text('8.0'), findsOneWidget); // 48 balls = 8.0 overs

      expect(find.text('RUNS GIVEN'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);

      expect(find.text('ECONOMY'), findsOneWidget);
      // 52 / 8.0 = 6.50
      expect(find.text('6.50'), findsOneWidget);

      expect(find.text('MAIDENS'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 MVPs & 2 maidens

      // Verify fielding
      expect(find.text('CATCHES'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('RUN OUTS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders football stats properly', (tester) async {
      final footballRow = {
        'sport': 'football',
        'sport_display_name': 'Football',
        'matches_played': 3,
        'career_counters': {
          'matches_won': 2,
          'matches_lost': 1,
          'goals': 4,
          'assists': 2,
          'saves': 5,
          'clean_sheets': 1,
          'yellow_cards': 1,
          'red_cards': 0,
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerCareerStatsCard(sportRow: footballRow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Football'), findsOneWidget);
      expect(find.text('GOALS'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('ASSISTS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('G + A'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('SAVES'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders properly when career_counters is a JSON string', (tester) async {
      final cricketRow = {
        'sport': 'cricket',
        'sport_display_name': 'Cricket',
        'matches_played': 2,
        'career_counters': '{"matches_won":2,"matches_lost":0,"runs_scored":88,"balls_faced":50,"fours":8,"sixes":3}',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerCareerStatsCard(sportRow: cricketRow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('2 Matches • 2 W - 0 L (100% Win Rate)'), findsOneWidget);
      expect(find.text('RUNS'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // fours
    });
  });
}
