/// VIT-AP Sports — Match Detail Winner & Completed Match Tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/providers/match_providers.dart';
import 'package:vitap_sports/features/matches/screens/match_detail_screen.dart';

void main() {
  group('MatchDetailScreen Winner Card Tests', () {
    const testMatchId = 'm-winner-1';

    testWidgets('Displays winner card and margin on completed match', (tester) async {
      final completedMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        createdBy: 'u-1',
        homeScore: 165,
        awayScore: 140,
        result: {
          'winner_team_id': 'team-1',
          'loser_team_id': 'team-2',
          'result_margin': 'Warriors won by 25 runs',
          'is_draw': false,
        },
        participants: const [
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-1',
            teamName: 'Warriors',
            side: 'home',
          ),
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-2',
            teamName: 'Titans',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            matchDetailProvider(testMatchId).overrideWith((ref) async => completedMatch),
          ],
          child: const MaterialApp(
            home: MatchDetailScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Winner Card presence with winning team name in title and margin in subtitle
      expect(find.text('Warriors Won'), findsOneWidget);
      expect(find.text('won by 25 runs'), findsOneWidget);
      expect(find.text('Winner Won'), findsNothing);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      // Verify Scorecard button exists
      expect(find.text('Scorecard'), findsOneWidget);

      // Verify "Edit Scorecard" is NOT present on completed match
      expect(find.text('Edit Scorecard'), findsNothing);
      expect(find.text('Live Scorer'), findsNothing);
    });

    testWidgets('Displays winning team name when margin is unprefixed (won by 4 wickets)', (tester) async {
      final completedMatch = MatchModel(
        id: testMatchId,
        sportId: 's-cricket',
        sportName: 'Cricket',
        venue: 'Main Ground',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        createdBy: 'u-1',
        result: {
          'winner_team_id': 'team-2',
          'result_margin': 'won by 4 wickets',
          'is_draw': false,
        },
        participants: const [
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-1',
            teamName: 'Warriors',
            side: 'home',
          ),
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-2',
            teamName: 'Titans',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            matchDetailProvider(testMatchId).overrideWith((ref) async => completedMatch),
          ],
          child: const MaterialApp(
            home: MatchDetailScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifies winning team name Titans is shown, NOT "Winner Won"
      expect(find.text('Titans Won'), findsOneWidget);
      expect(find.text('won by 4 wickets'), findsOneWidget);
      expect(find.text('Winner Won'), findsNothing);
    });

    testWidgets('Displays match drawn / tied card when is_draw is true', (tester) async {
      final tiedMatch = MatchModel(
        id: testMatchId,
        sportId: 's-football',
        sportName: 'Football',
        venue: 'Ground A',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        createdBy: 'u-1',
        homeScore: 2,
        awayScore: 2,
        result: {
          'is_draw': true,
          'result_margin': 'Full Time 2 - 2',
        },
        participants: const [
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-1',
            teamName: 'Alpha FC',
            side: 'home',
          ),
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-2',
            teamName: 'Beta FC',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            matchDetailProvider(testMatchId).overrideWith((ref) async => tiedMatch),
          ],
          child: const MaterialApp(
            home: MatchDetailScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Match Drawn / Tied'), findsOneWidget);
      expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
      expect(find.text('Full Time 2 - 2'), findsOneWidget);
    });

    testWidgets('Hides winner card on live match', (tester) async {
      final liveMatch = MatchModel(
        id: testMatchId,
        sportId: 's-football',
        sportName: 'Football',
        venue: 'Ground A',
        scheduledAt: DateTime.now(),
        status: 'live',
        createdBy: 'u-1',
        homeScore: 1,
        awayScore: 0,
        participants: const [
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-1',
            teamName: 'Alpha FC',
            side: 'home',
          ),
          MatchParticipant(
            matchId: testMatchId,
            teamId: 'team-2',
            teamName: 'Beta FC',
            side: 'away',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            matchDetailProvider(testMatchId).overrideWith((ref) async => liveMatch),
          ],
          child: const MaterialApp(
            home: MatchDetailScreen(matchId: testMatchId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
      expect(find.text('Live Scorer'), findsOneWidget);
    });

    test('MatchModel.updateFromRealtime updates scheduledAt when match is started', () {
      final initialTime = DateTime.parse('2026-10-10T10:00:00.000Z');
      final match = MatchModel(
        id: testMatchId,
        sportId: 's-football',
        venue: 'Main Ground',
        createdBy: 'u-1',
        scheduledAt: initialTime,
        status: 'scheduled',
      );

      final newStartTime = '2026-10-12T14:30:00.000Z';
      final updated = match.updateFromRealtime({
        'status': 'live',
        'scheduled_at': newStartTime,
      });

      expect(updated.status, 'live');
      expect(updated.scheduledAt, DateTime.parse(newStartTime));
    });
  });
}
