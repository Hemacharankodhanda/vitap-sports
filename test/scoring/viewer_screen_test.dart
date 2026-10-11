/// VIT-AP Sports — Viewer Screen Widget Tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/providers/match_providers.dart';
import 'package:vitap_sports/features/scorecards/screens/scorecard_view_screen.dart';
import 'package:vitap_sports/features/scoring/data/live_scorer_service.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/providers/live_scorer_providers.dart';

class FakeRealtimeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus, Object?)? callback, Duration? timeout]) {
    return this;
  }
}

class FakeViewerScorerService extends Fake implements LiveScorerService {
  FakeViewerScorerService({
    required this.events,
  });

  List<MatchEvent> events;

  @override
  Future<List<MatchEvent>> fetchEvents(String matchId) async => events;

  @override
  Stream<Map<String, dynamic>?> streamMatch(String matchId) {
    return Stream.value({
      'id': matchId,
      'status': 'live',
      'home_score': 2,
      'away_score': 1,
    });
  }

  @override
  RealtimeChannel subscribeToEvents({
    required String matchId,
    required void Function(MatchEvent event) onInsert,
    required void Function(String eventId) onDelete,
  }) {
    return FakeRealtimeChannel();
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {}
}

void main() {
  group('ScorecardViewScreen Realtime Tests', () {
    const testMatchId = 'm-view-1';

    final fakeMatchModel = MatchModel(
      id: testMatchId,
      sportId: 's-fb',
      sportName: 'Football',
      venue: 'Main Ground',
      scheduledAt: DateTime.now(),
      status: 'live',
      createdBy: 'u-1',
      participants: const [
        MatchParticipant(
          matchId: testMatchId,
          teamId: 'team-home',
          teamName: 'Red Lions',
          side: 'home',
        ),
        MatchParticipant(
          matchId: testMatchId,
          teamId: 'team-away',
          teamName: 'Blue Tigers',
          side: 'away',
        ),
      ],
    );

    testWidgets('Renders live score header and timeline events in realtime', (tester) async {
      final initialEvents = [
        MatchEvent(
          id: 'ev-1',
          matchId: testMatchId,
          seq: 1,
          type: 'goal',
          teamId: 'team-home',
          payload: {'scorer': 'Alex', 'kind': 'open_play'},
        ),
        MatchEvent(
          id: 'ev-2',
          matchId: testMatchId,
          seq: 2,
          type: 'goal',
          teamId: 'team-away',
          payload: {'scorer': 'Ben', 'kind': 'penalty'},
        ),
      ];

      final fakeService = FakeViewerScorerService(events: initialEvents);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveScorerServiceProvider.overrideWithValue(fakeService),
            matchDetailProvider(testMatchId).overrideWith((ref) async => fakeMatchModel),
          ],
          child: const MaterialApp(
            home: ScorecardViewScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Match Title
      expect(find.text('Red Lions vs Blue Tigers'), findsWidgets);

      // Check Live Timeline
      expect(find.text('Live Timeline'), findsOneWidget);
      expect(find.text('2 Events'), findsOneWidget);

      // Check Event Tiles
      expect(find.text('GOAL! Red Lions'), findsOneWidget);
      expect(find.text('GOAL! Blue Tigers'), findsOneWidget);
    });

    testWidgets('Displays EmptyState when no events have been recorded', (tester) async {
      final fakeService = FakeViewerScorerService(events: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveScorerServiceProvider.overrideWithValue(fakeService),
            matchDetailProvider(testMatchId).overrideWith((ref) async => fakeMatchModel),
          ],
          child: const MaterialApp(
            home: ScorecardViewScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Events Yet'), findsOneWidget);
      expect(find.text('0 Events'), findsOneWidget);
    });

    testWidgets('Renders completed cricket match scorecard without white screen even with empty events', (tester) async {
      const cricketMatchId = 'm-cricket-completed';
      final completedCricketMatch = MatchModel(
        id: cricketMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'completed',
        createdBy: 'u-1',
        homeScore: 145,
        awayScore: 120,
        score: {
          'innings': [
            {
              'batting_team_id': 'team-home',
              'bowling_team_id': 'team-away',
              'total_runs': 145,
              'total_wickets': 4,
              'legal_balls': 36,
              'batting_stats': {
                'p-1': {
                  'name': 'Rahul',
                  'runs': 62,
                  'balls_faced': 24,
                  'fours': 6,
                  'sixes': 3,
                  'is_out': false,
                },
              },
              'bowling_stats': {
                'p-2': {
                  'name': 'Karan',
                  'balls_bowled': 12,
                  'maidens': 0,
                  'runs_conceded': 18,
                  'wickets': 2,
                },
              },
            },
          ],
          'player_names': {
            'p-1': 'Rahul',
            'p-2': 'Karan',
          },
          'winner_team_id': 'team-home',
          'result_margin': 'Red Lions won by 25 runs',
        },
        participants: const [
          MatchParticipant(
            matchId: cricketMatchId,
            teamId: 'team-home',
            teamName: 'Red Lions',
            side: 'home',
          ),
          MatchParticipant(
            matchId: cricketMatchId,
            teamId: 'team-away',
            teamName: 'Blue Tigers',
            side: 'away',
          ),
        ],
      );

      final fakeService = FakeViewerScorerService(events: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveScorerServiceProvider.overrideWithValue(fakeService),
            matchDetailProvider(cricketMatchId).overrideWith((ref) async => completedCricketMatch),
          ],
          child: const MaterialApp(
            home: ScorecardViewScreen(matchId: cricketMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar says Match Scorecard
      expect(find.text('Match Scorecard'), findsOneWidget);

      // Check batting innings table header
      expect(find.text('Red Lions Innings'), findsOneWidget);

      // Check player stats rendered in DataTable
      expect(find.text('Rahul*'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.text('Karan'), findsOneWidget);

      // Verify no edit scorer icon in AppBar for completed match
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });
}
