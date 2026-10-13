import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/presentation/widgets/bracket_node_card.dart';
import 'package:vitap_sports/features/tournaments/presentation/widgets/knockout_bracket_view.dart';
import 'package:vitap_sports/features/tournaments/presentation/widgets/tournament_card.dart';
import 'package:vitap_sports/features/tournaments/presentation/widgets/tournament_standings_table.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      extensions: const [AppColorsExtension.light],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TournamentCard Widget Tests', () {
    testWidgets('Renders tournament details, status, format, and scope', (tester) async {
      final tournament = TournamentModel(
        id: 't-card-1',
        name: 'VIT-AP Premier League 2026',
        sport: 'cricket',
        format: TournamentFormat.knockout,
        status: TournamentStatus.live,
        scope: TournamentScope.hostel,
        isOfficial: true,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 10),
      );

      bool tapped = false;

      await tester.pumpWidget(
        _wrap(
          TournamentCard(
            tournament: tournament,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('VIT-AP Premier League 2026'), findsOneWidget);
      expect(find.text('CRICKET'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Knockout'), findsOneWidget);
      expect(find.text('Hostel: Block'), findsOneWidget);
      expect(find.text('OFFICIAL'), findsOneWidget);

      await tester.tap(find.byType(TournamentCard));
      expect(tapped, isTrue);
    });
  });

  group('BracketNodeCard Widget Tests', () {
    testWidgets('Renders match slots with scores and winner indicator', (tester) async {
      const entryA = TournamentEntry(id: 'e-1', tournamentId: 't-1', displayName: 'MH-1 Block A', seed: 1);
      const entryB = TournamentEntry(id: 'e-2', tournamentId: 't-1', displayName: 'LH-2 Block B', seed: 8);

      const fix = TournamentFixture(
        id: 'fix-1',
        tournamentId: 't-1',
        stage: FixtureStage.knockout,
        round: 1,
        position: 1,
        roundLabel: 'Quarter-Final 1',
        entryAId: 'e-1',
        entryBId: 'e-2',
        winnerEntryId: 'e-1',
        result: {'home_score': '145/3', 'away_score': '120/8'},
        status: FixtureStatus.completed,
      );

      bool cardTapped = false;

      await tester.pumpWidget(
        _wrap(
          BracketNodeCard(
            fixture: fix,
            entryA: entryA,
            entryB: entryB,
            onTap: () => cardTapped = true,
          ),
        ),
      );

      expect(find.text('MH-1 Block A'), findsOneWidget);
      expect(find.text('LH-2 Block B'), findsOneWidget);
      expect(find.text('145/3'), findsOneWidget);
      expect(find.text('120/8'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      await tester.tap(find.byType(BracketNodeCard));
      expect(cardTapped, isTrue);
    });

    testWidgets('Renders Bye label when fixture is a bye', (tester) async {
      const entryA = TournamentEntry(id: 'e-1', tournamentId: 't-1', displayName: 'Top Seed', seed: 1);
      const fix = TournamentFixture(
        id: 'fix-bye',
        tournamentId: 't-1',
        stage: FixtureStage.knockout,
        round: 1,
        position: 1,
        roundLabel: 'Round 1',
        entryAId: 'e-1',
        winnerEntryId: 'e-1',
        isBye: true,
        status: FixtureStatus.completed,
      );

      await tester.pumpWidget(
        _wrap(
          const BracketNodeCard(
            fixture: fix,
            entryA: entryA,
          ),
        ),
      );

      expect(find.text('Top Seed'), findsOneWidget);
      expect(find.text('Bye'), findsOneWidget);
    });

    testWidgets('Renders LIVE badge when fixture is active', (tester) async {
      const entryA = TournamentEntry(id: 'e-1', tournamentId: 't-1', displayName: 'Team Alpha');
      const entryB = TournamentEntry(id: 'e-2', tournamentId: 't-1', displayName: 'Team Beta');
      const fix = TournamentFixture(
        id: 'fix-live',
        tournamentId: 't-1',
        stage: FixtureStage.knockout,
        round: 2,
        position: 1,
        roundLabel: 'Semi-Final 1',
        entryAId: 'e-1',
        entryBId: 'e-2',
        result: {'score_a': '21', 'score_b': '19'},
        status: FixtureStatus.live,
      );

      await tester.pumpWidget(
        _wrap(
          const BracketNodeCard(
            fixture: fix,
            entryA: entryA,
            entryB: entryB,
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });
  });

  group('TournamentStandingsTable Widget Tests', () {
    testWidgets('Renders football table with tabular GD and qualification markers', (tester) async {
      final rows = [
        const TournamentStandingsRow(
          entryId: 'e-1',
          displayName: 'FC Barcelona VIT',
          played: 3,
          won: 2,
          drawn: 1,
          lost: 0,
          points: 7,
          goalDifference: 5,
        ),
        const TournamentStandingsRow(
          entryId: 'e-2',
          displayName: 'Real Madrid VIT',
          played: 3,
          won: 2,
          drawn: 0,
          lost: 1,
          points: 6,
          goalDifference: 2,
        ),
        const TournamentStandingsRow(
          entryId: 'e-3',
          displayName: 'Atletico VIT',
          played: 3,
          won: 0,
          drawn: 1,
          lost: 2,
          points: 1,
          goalDifference: -7,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          TournamentStandingsTable(
            sport: 'football',
            rows: rows,
            qualifiersCount: 2,
          ),
        ),
      );

      expect(find.text('FC Barcelona VIT'), findsOneWidget);
      expect(find.text('Real Madrid VIT'), findsOneWidget);
      expect(find.text('Atletico VIT'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('-7'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('Top 2 teams qualify for knockout phase'), findsOneWidget);
    });

    testWidgets('Renders cricket table with formatted NRR', (tester) async {
      final rows = [
        const TournamentStandingsRow(
          entryId: 'e-1',
          displayName: 'Strikers XI',
          played: 2,
          won: 2,
          lost: 0,
          points: 4,
          netRunRate: 1.250,
        ),
        const TournamentStandingsRow(
          entryId: 'e-2',
          displayName: 'Bowlers XI',
          played: 2,
          won: 0,
          lost: 2,
          points: 0,
          netRunRate: -1.250,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          TournamentStandingsTable(
            sport: 'cricket',
            rows: rows,
          ),
        ),
      );

      expect(find.text('Strikers XI'), findsOneWidget);
      expect(find.text('+1.250'), findsOneWidget);
      expect(find.text('-1.250'), findsOneWidget);
    });
  });

  group('KnockoutBracketView Widget Tests', () {
    testWidgets('Renders bracket with round labels and node cards', (tester) async {
      final entries = [
        const TournamentEntry(id: 'e-1', tournamentId: 't-1', displayName: 'Team 1', seed: 1),
        const TournamentEntry(id: 'e-2', tournamentId: 't-1', displayName: 'Team 2', seed: 2),
        const TournamentEntry(id: 'e-3', tournamentId: 't-1', displayName: 'Team 3', seed: 3),
        const TournamentEntry(id: 'e-4', tournamentId: 't-1', displayName: 'Team 4', seed: 4),
      ];

      final fixtures = [
        const TournamentFixture(
          id: 'sf-1',
          tournamentId: 't-1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 1,
          roundLabel: 'Semi-Final 1',
          entryAId: 'e-1',
          entryBId: 'e-4',
          winnerEntryId: 'e-1',
          nextFixtureId: 'final-1',
          nextSlot: 'A',
          status: FixtureStatus.completed,
        ),
        const TournamentFixture(
          id: 'sf-2',
          tournamentId: 't-1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 2,
          roundLabel: 'Semi-Final 2',
          entryAId: 'e-2',
          entryBId: 'e-3',
          winnerEntryId: 'e-2',
          nextFixtureId: 'final-1',
          nextSlot: 'B',
          status: FixtureStatus.completed,
        ),
        const TournamentFixture(
          id: 'final-1',
          tournamentId: 't-1',
          stage: FixtureStage.knockout,
          round: 2,
          position: 1,
          roundLabel: 'Final',
          entryAId: 'e-1',
          entryBId: 'e-2',
          status: FixtureStatus.scheduled,
        ),
      ];

      TournamentFixture? selectedFixture;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 600,
            width: 800,
            child: KnockoutBracketView(
              fixtures: fixtures,
              entries: entries,
              onFixtureTap: (f) => selectedFixture = f,
            ),
          ),
        ),
      );

      // Verify Round headers are rendered
      expect(find.text('Semi-Final 1').first, findsOneWidget);
      expect(find.text('Final').first, findsOneWidget);

      // Verify node cards rendered
      expect(find.byType(BracketNodeCard), findsNWidgets(3));

      // Tap final node
      await tester.tap(find.byType(BracketNodeCard).last);
      expect(selectedFixture?.id, equals('final-1'));
    });
  });
}
