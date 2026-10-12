/// VIT-AP Sports — Leaderboard Screen Widget Tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/leaderboard/providers/leaderboard_providers.dart';
import 'package:vitap_sports/features/leaderboard/screens/leaderboard_screen.dart';

void main() {
  group('LeaderboardScreen Widget Tests', () {
    testWidgets('shows sport chips without All and displays tabular cricket batting stats', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Cricket'),
          cricketCategoryProvider.overrideWith((ref) => 'Batting'),
          topPlayersProvider.overrideWith((ref) async => [
            {
              'id': 'p1',
              'name': 'Rohit Sharma',
              'avatar_url': null,
              'runs': 450,
              'balls': 321,
              'fours': 38,
              'sixes': 15,
              'sr': '140.2',
              'primary_stat': '450 Runs',
              'secondary_stat': 'SR: 140.2 • 38 (4s) • 15 (6s)',
            },
          ]),
          topTeamsProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeaderboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check sport chips: All must be absent, sports must be present
      expect(find.text('All'), findsNothing);
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Badminton'), findsOneWidget);

      // Check cricket subcategories are visible
      expect(find.text('Batting'), findsOneWidget);
      expect(find.text('Bowling'), findsOneWidget);
      expect(find.text('Fielding'), findsOneWidget);

      // Check dynamic header and player name
      expect(find.text('Top Batting Leaders'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);

      // Check tabular column headers
      expect(find.text('PLAYER'), findsOneWidget);
      expect(find.text('RUNS'), findsOneWidget);
      expect(find.text('SR'), findsOneWidget);
      expect(find.text('4s'), findsOneWidget);
      expect(find.text('6s'), findsOneWidget);

      // Check player stat numbers
      expect(find.text('450'), findsOneWidget);
      expect(find.text('140.2'), findsOneWidget);
    });

    testWidgets('switching cricket category updates header and shows tabular bowling columns', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Cricket'),
          topPlayersProvider.overrideWith((ref) async => [
            {
              'id': 'p2',
              'name': 'Jasprit Bumrah',
              'avatar_url': null,
              'wickets': 18,
              'overs': '24.0',
              'runs_conceded': 125,
              'maidens': 3,
              'econ': '5.20',
              'primary_stat': '18 Wickets',
              'secondary_stat': 'Econ: 5.20 • 24.0 Ov • 3 M',
            },
          ]),
          topTeamsProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeaderboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Bowling' category chip
      await tester.tap(find.text('Bowling'));
      await tester.pumpAndSettle();

      expect(container.read(cricketCategoryProvider), 'Bowling');
      expect(find.text('Top Bowling Leaders'), findsOneWidget);
      expect(find.text('WKTS'), findsOneWidget);
      expect(find.text('ECON'), findsOneWidget);
      expect(find.text('Jasprit Bumrah'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('5.20'), findsOneWidget);

      // Tap 'Fielding' category chip
      await tester.tap(find.text('Fielding'));
      await tester.pumpAndSettle();

      expect(container.read(cricketCategoryProvider), 'Fielding');
      expect(find.text('Top Fielding Leaders'), findsOneWidget);
      expect(find.text('DISM'), findsOneWidget);
      expect(find.text('CT'), findsOneWidget);
    });

    testWidgets('hides cricket category chips and displays football tabular columns', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Football'),
          topPlayersProvider.overrideWith((ref) async => [
            {
              'id': 'f1',
              'name': 'Lionel Messi',
              'avatar_url': null,
              'matches_played': 10,
              'goals': 14,
              'assists': 8,
              'primary_stat': '14 Goals',
              'secondary_stat': '8 Assists',
            },
          ]),
          topTeamsProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeaderboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Top Players'), findsOneWidget);
      expect(find.text('Batting'), findsNothing);
      expect(find.text('Bowling'), findsNothing);
      expect(find.text('Fielding'), findsNothing);

      // Check Football tabular headers and player stat
      expect(find.text('GOALS'), findsOneWidget);
      expect(find.text('AST'), findsOneWidget);
      expect(find.text('Lionel Messi'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}
