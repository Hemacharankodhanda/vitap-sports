/// VIT-AP Sports — Scorer Screen Widget Tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitap_sports/features/scorecards/screens/scorecard_edit_screen.dart';
import 'package:vitap_sports/features/scoring/data/live_scorer_service.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/presentation/widgets/live_score_header.dart';
import 'package:vitap_sports/features/scoring/providers/live_scorer_providers.dart';

class FakeRealtimeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus, Object?)? callback, Duration? timeout]) {
    return this;
  }
}

class FakeWidgetScorerService extends Fake implements LiveScorerService {
  FakeWidgetScorerService({required this.matchData});

  final Map<String, dynamic> matchData;

  @override
  Future<Map<String, dynamic>?> fetchMatch(String matchId) async => matchData;

  @override
  Future<List<MatchEvent>> fetchEvents(String matchId) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchTeamPlayers(String teamId) async => [];

  @override
  RealtimeChannel subscribeToEvents({
    required String matchId,
    required void Function(MatchEvent event) onInsert,
    required void Function(String eventId) onDelete,
  }) {
    return FakeRealtimeChannel();
  }

  @override
  Future<Map<String, dynamic>> recordEvent({
    required String matchId,
    required MatchEvent event,
    required Map<String, dynamic> snapshot,
  }) async => {'success': true};

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {}
}

void main() {
  group('ScorecardEditScreen Widget Tests', () {
    const testMatchId = 'm-test-1';
    const currentUserId = 'u-scorer';

    Widget createTestWidget({
      required Map<String, dynamic> matchData,
      String? userId = currentUserId,
    }) {
      final fakeService = FakeWidgetScorerService(matchData: matchData);

      return ProviderScope(
        overrides: [
          liveScorerServiceProvider.overrideWithValue(fakeService),
          liveScorerNotifierProvider(testMatchId).overrideWith(
            (ref) => LiveScorerNotifier(
              fakeService,
              userId,
              matchId: testMatchId,
            ),
          ),
        ],
        child: const MaterialApp(
          home: ScorecardEditScreen(matchId: testMatchId),
        ),
      );
    }

    testWidgets('Renders unauthorized restriction card for non-scorers', (tester) async {
      final matchData = {
        'id': testMatchId,
        'sports': {'name': 'Football'},
        'created_by': 'different-user',
        'status': 'live',
        'match_participants': [],
      };

      await tester.pumpWidget(createTestWidget(
        matchData: matchData,
        userId: 'unauthorized-user',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Scoring Restricted'), findsOneWidget);
    });

    testWidgets('Renders pre-match setup flow for scheduled matches', (tester) async {
      final matchData = {
        'id': testMatchId,
        'sports': {'name': 'Cricket'},
        'created_by': currentUserId,
        'status': 'scheduled',
        'match_participants': [
          {'side': 'home', 'team_id': 'team-a', 'teams': {'name': 'Team Alpha'}},
          {'side': 'away', 'team_id': 'team-b', 'teams': {'name': 'Team Beta'}},
        ],
      };

      await tester.pumpWidget(createTestWidget(matchData: matchData));
      await tester.pumpAndSettle();

      expect(find.text('Pre-Match Setup'), findsOneWidget);
      expect(find.text('Start Live Match'), findsOneWidget);
      expect(find.text('Toss Winner'), findsOneWidget);
    });

    testWidgets('Renders live action grid and always-visible Undo on live match', (tester) async {
      final matchData = {
        'id': testMatchId,
        'sports': {'name': 'Football'},
        'created_by': currentUserId,
        'status': 'live',
        'match_participants': [
          {'side': 'home', 'team_id': 'team-a', 'teams': {'name': 'Team Alpha'}},
          {'side': 'away', 'team_id': 'team-b', 'teams': {'name': 'Team Beta'}},
        ],
      };

      await tester.pumpWidget(createTestWidget(matchData: matchData));
      await tester.pumpAndSettle();

      // Check header and action buttons
      expect(find.text('Team Alpha vs Team Beta'), findsWidgets);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Finish Match'), findsOneWidget);
    });

    testWidgets('Tapping Wicket button opens wicket sheet and updates wickets count', (tester) async {
      final matchData = {
        'id': testMatchId,
        'sports': {'name': 'Cricket'},
        'created_by': currentUserId,
        'status': 'live',
        'config': {'overs_per_innings': 20, 'players_per_side': 11},
        'match_participants': [
          {'side': 'home', 'team_id': 'team-a', 'teams': {'name': 'Team Alpha'}},
          {'side': 'away', 'team_id': 'team-b', 'teams': {'name': 'Team Beta'}},
        ],
      };

      await tester.pumpWidget(createTestWidget(matchData: matchData));
      await tester.pumpAndSettle();

      // Initial score is 0/0
      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('Wicket'), findsOneWidget);

      // Scroll to Wicket button and tap
      await tester.ensureVisible(find.text('Wicket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wicket'));
      await tester.pumpAndSettle();

      // Wicket Details sheet is displayed
      expect(find.text('Wicket Details'), findsOneWidget);
      expect(find.text('Confirm Wicket'), findsOneWidget);

      // Confirm wicket
      await tester.ensureVisible(find.text('Confirm Wicket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Wicket'));
      await tester.pumpAndSettle();

      // Scroll back up to verify live score header has 0/1
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Score is now 0/1 (1 wicket updated!)
      expect(find.text('0/1'), findsOneWidget);
    });
  });
}
