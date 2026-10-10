/// VIT-AP Sports — Leaderboard Screen Widget Tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/leaderboard/providers/leaderboard_providers.dart';
import 'package:vitap_sports/features/leaderboard/screens/leaderboard_screen.dart';

void main() {
  group('LeaderboardScreen Widget Tests', () {
    testWidgets('shows cricket category chips when Cricket is selected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Cricket'),
          cricketCategoryProvider.overrideWith((ref) => 'Batting'),
          topPlayersProvider.overrideWith((ref) async => [
            {
              'id': 'p1',
              'name': 'Rohit Sharma',
              'avatar_url': null,
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

      // Check sport chips
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Badminton'), findsOneWidget);

      // Check cricket subcategories are visible
      expect(find.text('Batting'), findsOneWidget);
      expect(find.text('Bowling'), findsOneWidget);
      expect(find.text('Fielding'), findsOneWidget);

      // Check dynamic header and player stats
      expect(find.text('Top Batting Leaders'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('450 Runs'), findsOneWidget);
      expect(find.text('SR: 140.2 • 38 (4s) • 15 (6s)'), findsOneWidget);
    });

    testWidgets('switching cricket category updates header and active state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Cricket'),
          topPlayersProvider.overrideWith((ref) async => [
            {
              'id': 'p2',
              'name': 'Jasprit Bumrah',
              'avatar_url': null,
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

      // Tap 'Fielding' category chip
      await tester.tap(find.text('Fielding'));
      await tester.pumpAndSettle();

      expect(container.read(cricketCategoryProvider), 'Fielding');
      expect(find.text('Top Fielding Leaders'), findsOneWidget);
    });

    testWidgets('hides cricket category chips when sport is not Cricket', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leaderboardSportProvider.overrideWith((ref) => 'Football'),
          topPlayersProvider.overrideWith((ref) async => []),
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
    });
  });
}
