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

    testWidgets('Tapping Wide button opens extra runs sheet, calculates total runs, and updates score', (tester) async {
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

      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('Wide'), findsOneWidget);

      // Scroll to Wide and tap
      await tester.ensureVisible(find.text('Wide'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wide'));
      await tester.pumpAndSettle();

      // Verify Wide sheet is displayed with calculation
      expect(find.text('Wide Delivery (Wd)'), findsOneWidget);
      expect(find.text('Total Runs on this Delivery:'), findsOneWidget);
      expect(find.text('Confirm (1 Run)'), findsOneWidget);

      // Tap +1 extra run (e.g. 1 bye taken on wide)
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      // Calculation updates to 2 runs (1 penalty + 1 extra)
      expect(find.text('Confirm (2 Runs)'), findsOneWidget);

      // Confirm
      await tester.ensureVisible(find.text('Confirm (2 Runs)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm (2 Runs)'));
      await tester.pumpAndSettle();

      // Scroll back up to verify live score header has 2/0 (2 runs, 0 wickets, 0.0 overs)
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.text('2/0'), findsOneWidget);
      expect(find.text('Wd+1'), findsOneWidget);
    });

    testWidgets('Tapping No Ball button opens extra runs sheet, calculates total runs (1 NB + extras), and updates score', (tester) async {
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

      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('No Ball'), findsOneWidget);

      // Scroll to No Ball and tap
      await tester.ensureVisible(find.text('No Ball'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Ball'));
      await tester.pumpAndSettle();

      // Verify No Ball sheet is displayed
      expect(find.text('No Ball Delivery (Nb)'), findsOneWidget);
      expect(find.text('Confirm (1 Run)'), findsOneWidget);

      // Tap +4 (boundary off no-ball)
      await tester.tap(find.text('+4'));
      await tester.pumpAndSettle();

      // Calculation updates to 5 runs (1 NB + 4 off bat)
      expect(find.text('Confirm (5 Runs)'), findsOneWidget);

      // Confirm
      await tester.ensureVisible(find.text('Confirm (5 Runs)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm (5 Runs)'));
      await tester.pumpAndSettle();

      // Scroll back up to verify live score header has 5/0 (5 runs, 0 wickets, 0.0 overs)
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.text('5/0'), findsOneWidget);
      expect(find.text('Nb+4'), findsOneWidget);
    });
  });
}
