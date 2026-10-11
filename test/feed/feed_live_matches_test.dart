/// VIT-AP Sports — Live Matches Home Feed & Real-time Update Tests.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/services/local_prefs_service.dart';
import 'package:vitap_sports/features/feed/screens/feed_screen.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/providers/match_providers.dart';
import 'package:vitap_sports/features/matches/screens/match_detail_screen.dart';
import 'package:vitap_sports/features/scoring/providers/live_scorer_providers.dart';
import 'package:vitap_sports/features/teams/providers/team_providers.dart';

class _FakeLocalPrefsService extends Fake implements LocalPrefsService {
  @override
  String get selectedSport => 'Cricket';

  @override
  Future<void> setSelectedSport(String sport) async {}
}

void main() {
  group('Home Page Live Matches & Real-time Score Updates Tests', () {
    testWidgets('FeedScreen displays Live Matches section with live score when matches are live', (tester) async {
      final liveMatch = MatchModel(
        id: 'live-match-1',
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now(),
        status: 'live',
        createdBy: 'user-1',
        homeTeamName: 'Warriors',
        awayTeamName: 'Titans',
        score: {
          'innings': [
            {
              'batting_team_id': 'home',
              'total_runs': 142,
              'total_wickets': 3,
              'legal_balls': 98,
            }
          ]
        },
        participants: const [
          MatchParticipant(
            matchId: 'live-match-1',
            teamId: 'team-1',
            teamName: 'Warriors',
            side: 'home',
          ),
          MatchParticipant(
            matchId: 'live-match-1',
            teamId: 'team-2',
            teamName: 'Titans',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(_FakeLocalPrefsService()),
            sportsListProvider.overrideWith((ref) async => [
              {'name': 'Cricket'},
              {'name': 'Football'},
              {'name': 'Badminton'},
            ]),
            liveMatchesStreamProvider.overrideWith(
              (ref) => Stream.value([liveMatch]),
            ),
          ],
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Live Matches section is rendered on home feed
      expect(find.text('Live Matches'), findsOneWidget);
      expect(find.text('Warriors'), findsWidgets);
      expect(find.text('Titans'), findsWidgets);
      // Verify live score is visible
      expect(find.textContaining('142/3'), findsOneWidget);
    });

    testWidgets('MatchDetailScreen updates live score in real time via liveMatchStreamProvider', (tester) async {
      const matchId = 'live-detail-1';
      final streamController = StreamController<Map<String, dynamic>?>();

      final initialMatch = MatchModel(
        id: matchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Oval Ground',
        scheduledAt: DateTime.now(),
        status: 'live',
        createdBy: 'user-1',
        homeTeamName: 'Lions',
        awayTeamName: 'Tigers',
        score: {
          'innings': [
            {
              'batting_team_id': 'home',
              'total_runs': 50,
              'total_wickets': 1,
              'legal_balls': 36,
            }
          ]
        },
        participants: const [
          MatchParticipant(
            matchId: matchId,
            teamId: 'team-1',
            teamName: 'Lions',
            side: 'home',
          ),
          MatchParticipant(
            matchId: matchId,
            teamId: 'team-2',
            teamName: 'Tigers',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchDetailProvider(matchId).overrideWith((ref) async => initialMatch),
            liveMatchStreamProvider(matchId).overrideWith((ref) => streamController.stream),
          ],
          child: const MaterialApp(
            home: MatchDetailScreen(matchId: matchId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initial score check
      expect(find.textContaining('50/1'), findsOneWidget);
      expect(find.text('LIVE SCORE'), findsOneWidget);

      // Emit realtime score change (e.g. six hit: 56/1)
      streamController.add({
        'id': matchId,
        'status': 'live',
        'score': {
          'innings': [
            {
              'batting_team_id': 'home',
              'total_runs': 56,
              'total_wickets': 1,
              'legal_balls': 37,
            }
          ]
        }
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Realtime live score reflects new runs immediately
      expect(find.textContaining('56/1'), findsOneWidget);

      await streamController.close();
    });
  });
}
