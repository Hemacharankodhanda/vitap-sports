import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/profile/data/models/user_model.dart';
import 'package:vitap_sports/features/profile/widgets/player_career_stats_card.dart';

void main() {
  group('UserModel Stats Calculation Tests', () {
    test('accurately derives 0 losses when player won all matches', () {
      final json = {
        'id': 'u1',
        'name': 'Test Player',
        'matches_played': 10, // stale DB value
        'wins': 5,            // stale DB value
        'losses': 5,          // stale DB value
        'career_stats': [
          {
            'sport': 'badminton',
            'matches_played': 3,
            'career_counters': {
              'matches_won': 3,
              'matches_lost': 0,
            },
          },
        ],
      };

      final user = UserModel.fromJson(json);
      expect(user.matchesPlayed, 3);
      expect(user.wins, 3);
      expect(user.losses, 0); // Must be 0, not stale 5!
    });

    test('accurately derives 0 wins when player lost all matches', () {
      final json = {
        'id': 'u2',
        'name': 'Test Player 2',
        'matches_played': 10,
        'wins': 4,            // stale DB value
        'losses': 6,          // stale DB value
        'career_stats': [
          {
            'sport': 'football',
            'matches_played': 4,
            'career_counters': {
              'matches_won': 0,
              'matches_lost': 4,
            },
          },
        ],
      };

      final user = UserModel.fromJson(json);
      expect(user.matchesPlayed, 4);
      expect(user.wins, 0); // Must be 0, not stale 4!
      expect(user.losses, 4);
    });

    test('accurately sums stats across multiple sports', () {
      final json = {
        'id': 'u3',
        'name': 'Multi-Sport Player',
        'matches_played': 0,
        'wins': 0,
        'losses': 0,
        'career_stats': [
          {
            'sport': 'cricket',
            'matches_played': 5,
            'career_counters': {
              'matches_won': 3,
              'matches_lost': 2,
              'mvps': 1,
            },
          },
          {
            'sport': 'badminton',
            'matches_played': 4,
            'career_counters': {
              'matches_won': 2,
              'matches_lost': 2,
              'mvps': 1,
            },
          },
        ],
      };

      final user = UserModel.fromJson(json);
      expect(user.matchesPlayed, 9);
      expect(user.wins, 5);
      expect(user.losses, 4);
      expect(user.mvpCount, 2);
    });

    test('enforces mathematical guarantee: matchesPlayed >= wins + losses', () {
      final json = {
        'id': 'u4',
        'name': 'Player With Inconsistent Counters',
        'matches_played': 2,
        'wins': 2,
        'losses': 2,
      };

      final user = UserModel.fromJson(json);
      // Even if raw matches_played says 2, since wins=2 and losses=2, total matches played must be at least 4
      expect(user.matchesPlayed, 4);
      expect(user.wins, 2);
      expect(user.losses, 2);
    });

    test('supports alternative counter keys like wins, losses, won, lost', () {
      final json = {
        'id': 'u5',
        'name': 'Player With Alt Keys',
        'career_stats': [
          {
            'sport': 'badminton',
            'matches_played': 3,
            'career_counters': {
              'wins': 2,
              'losses': 1,
            },
          },
        ],
      };

      final user = UserModel.fromJson(json);
      expect(user.matchesPlayed, 3);
      expect(user.wins, 2);
      expect(user.losses, 1);
    });
  });

  group('PlayerCareerStatsCard Visual Accuracy Tests', () {
    testWidgets('renders accurate win rate and effective matches when matchesPlayed was undercounted', (tester) async {
      final row = {
        'sport': 'badminton',
        'sport_display_name': 'Badminton',
        'matches_played': 0, // was 0 in DB
        'career_counters': {
          'matches_won': 3,
          'matches_lost': 1,
          'points_won': 84,
          'service_points_won': 32,
          'games_won': 6,
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerCareerStatsCard(sportRow: row),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 W + 1 L = 4 matches, 3 / 4 = 75%
      expect(find.text('4 Matches • 3 W - 1 L (75% Win Rate)'), findsOneWidget);
      expect(find.text('POINTS WON'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
      expect(find.text('SERVE POINTS'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('GAMES WON'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });
  });
}
