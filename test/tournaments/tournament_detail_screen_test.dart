import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/presentation/screens/tournament_detail_screen.dart';
import 'package:vitap_sports/features/tournaments/providers/tournament_providers.dart';

void main() {
  Widget buildTestWidget({
    required String tournamentId,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: const [AppColorsExtension.light],
        ),
        home: TournamentDetailScreen(tournamentId: tournamentId),
      ),
    );
  }

  testWidgets('TournamentDetailScreen renders draft tournament and all tabs work', (tester) async {
    final tournament = TournamentModel(
      id: 't-test-1',
      name: 'VIT-AP Cricket Cup 2026',
      sport: 'cricket',
      format: TournamentFormat.knockout,
      status: TournamentStatus.draft,
      scope: TournamentScope.open,
    );

    await tester.pumpWidget(
      buildTestWidget(
        tournamentId: 't-test-1',
        overrides: [
          tournamentDetailProvider('t-test-1').overrideWith((ref) => Future.value(tournament)),
          tournamentEntriesProvider('t-test-1').overrideWith((ref) => Stream.value([])),
          tournamentFixturesProvider('t-test-1').overrideWith((ref) => Stream.value([])),
          tournamentGroupsProvider('t-test-1').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('t-test-1').overrideWith((ref) => Future.value(true)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VIT-AP Cricket Cup 2026'), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Tournament Information'), findsOneWidget);

    // Switch to Fixtures tab
    await tester.tap(find.text('Fixtures'));
    await tester.pumpAndSettle();
    expect(find.text('No fixtures generated'), findsOneWidget);

    // Switch to Table tab
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    // Switch to Bracket tab
    await tester.tap(find.text('Bracket'));
    await tester.pumpAndSettle();
    expect(find.text('Bracket has not been generated yet'), findsOneWidget);

    // Switch to Stats tab
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Matches Played'), findsOneWidget);

    // Switch to Teams tab
    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();
    expect(find.text('No registered entries yet'), findsOneWidget);
  });

  testWidgets('TournamentDetailScreen handles null tournament gracefully', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        tournamentId: 't-test-null',
        overrides: [
          tournamentDetailProvider('t-test-null').overrideWith((ref) => Future.value(null)),
          tournamentEntriesProvider('t-test-null').overrideWith((ref) => Stream.value([])),
          tournamentFixturesProvider('t-test-null').overrideWith((ref) => Stream.value([])),
          tournamentGroupsProvider('t-test-null').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('t-test-null').overrideWith((ref) => Future.value(false)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Tournament not found'), findsOneWidget);
  });

  testWidgets('TournamentDetailScreen handles tournament load error gracefully', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        tournamentId: 't-test-err',
        overrides: [
          tournamentDetailProvider('t-test-err').overrideWith((ref) => Future.error(Exception('Failed to load tournament'))),
          tournamentEntriesProvider('t-test-err').overrideWith((ref) => Stream.value([])),
          tournamentFixturesProvider('t-test-err').overrideWith((ref) => Stream.value([])),
          tournamentGroupsProvider('t-test-err').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('t-test-err').overrideWith((ref) => Future.value(false)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('TournamentDetailScreen handles stream errors without blanking out', (tester) async {
    final tournament = TournamentModel(
      id: 't-test-err-streams',
      name: 'Stream Error Cup',
      sport: 'cricket',
      format: TournamentFormat.knockout,
      status: TournamentStatus.draft,
      scope: TournamentScope.open,
    );

    await tester.pumpWidget(
      buildTestWidget(
        tournamentId: 't-test-err-streams',
        overrides: [
          tournamentDetailProvider('t-test-err-streams').overrideWith((ref) => Future.value(tournament)),
          tournamentEntriesProvider('t-test-err-streams').overrideWith((ref) => Stream.error(Exception('Realtime error'))),
          tournamentFixturesProvider('t-test-err-streams').overrideWith((ref) => Stream.error(Exception('Realtime error'))),
          tournamentGroupsProvider('t-test-err-streams').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('t-test-err-streams').overrideWith((ref) => Future.value(false)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Stream Error Cup'), findsWidgets);
    expect(find.text('Tournament Information'), findsOneWidget);

    // Switch to Table tab (which depends on tournamentStandingsProvider)
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('TournamentDetailScreen displays pending entries with Team Info, Approve, and Decline buttons for organiser', (tester) async {
    final tournament = TournamentModel(
      id: 't-test-approval',
      name: 'Approval Championship',
      sport: 'cricket',
      format: TournamentFormat.knockout,
      status: TournamentStatus.registrationOpen,
      scope: TournamentScope.open,
    );

    final entries = [
      const TournamentEntry(
        id: 'entry-1',
        tournamentId: 't-test-approval',
        kind: EntryKind.team,
        teamId: 'team-deepak',
        displayName: 'Deepak XI',
        status: EntryStatus.pending,
      ),
    ];

    await tester.pumpWidget(
      buildTestWidget(
        tournamentId: 't-test-approval',
        overrides: [
          tournamentDetailProvider('t-test-approval').overrideWith((ref) => Future.value(tournament)),
          tournamentEntriesProvider('t-test-approval').overrideWith((ref) => Stream.value(entries)),
          tournamentFixturesProvider('t-test-approval').overrideWith((ref) => Stream.value([])),
          tournamentGroupsProvider('t-test-approval').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('t-test-approval').overrideWith((ref) => Future.value(true)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // In Overview tab: Organiser alert for pending applications is shown
    expect(find.text('1 Team Application Pending'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);

    // Switch to Teams tab
    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();

    // Verify team details, badges, and action buttons
    expect(find.text('Deepak XI'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('Team Info'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });
}
