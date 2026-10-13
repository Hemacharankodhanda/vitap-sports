import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/presentation/widgets/tournament_honours_section.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      extensions: const [AppColorsExtension.light],
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('TournamentHonour Domain Model Tests', () {
    test('TournamentHonour serialization and deserialization', () {
      const honour = TournamentHonour(
        tournamentId: 't-100',
        tournamentName: 'Inter-Hostel Cricket Trophy 2026',
        sport: 'cricket',
        rank: HonourRank.champion,
        year: '2026',
        teamOrEntryName: 'MH-2 Titans',
        isOfficial: true,
      );

      final json = honour.toJson();
      expect(json['tournament_id'], equals('t-100'));
      expect(json['rank'], equals('champion'));
      expect(json['is_official'], isTrue);

      final restored = TournamentHonour.fromJson(json);
      expect(restored.tournamentId, equals('t-100'));
      expect(restored.rank, equals(HonourRank.champion));
      expect(restored.year, equals('2026'));
      expect(restored.isOfficial, isTrue);
    });

    test('HonourRank parses runner_up and third_place strings', () {
      final ru = TournamentHonour.fromJson({
        'tournament_id': 't-2',
        'rank': 'runner_up',
      });
      expect(ru.rank, equals(HonourRank.runnerUp));

      final tp = TournamentHonour.fromJson({
        'tournament_id': 't-3',
        'rank': 'third_place',
      });
      expect(tp.rank, equals(HonourRank.thirdPlace));
    });
  });

  group('TournamentHonoursSection Widget Tests', () {
    testWidgets('Renders empty state when honours list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TournamentHonoursSection(honours: []),
        ),
      );

      expect(find.text('Tournament Honours'), findsOneWidget);
      expect(
        find.textContaining('No tournament honours yet'),
        findsOneWidget,
      );
    });

    testWidgets('Renders Champion, Runner-up, and 3rd Place cards', (tester) async {
      final honours = [
        const TournamentHonour(
          tournamentId: 't-1',
          tournamentName: 'VIT-AP Premier League',
          sport: 'cricket',
          rank: HonourRank.champion,
          year: '2026',
          teamOrEntryName: 'MH-1 Warriors',
          isOfficial: true,
        ),
        const TournamentHonour(
          tournamentId: 't-2',
          tournamentName: 'Badminton Open Championship',
          sport: 'badminton',
          rank: HonourRank.runnerUp,
          year: '2025',
          teamOrEntryName: 'Vikram / Arjun',
          isOfficial: false,
        ),
        const TournamentHonour(
          tournamentId: 't-3',
          tournamentName: 'Campus Football Super Cup',
          sport: 'football',
          rank: HonourRank.thirdPlace,
          year: '2025',
          teamOrEntryName: 'CSE Strikers',
          isOfficial: true,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          TournamentHonoursSection(honours: honours),
        ),
      );

      // Verify Headers and Tags
      expect(find.text('Tournament Honours'), findsOneWidget);
      expect(find.text('CHAMPION'), findsOneWidget);
      expect(find.text('RUNNER-UP'), findsOneWidget);
      expect(find.text('3RD PLACE'), findsOneWidget);

      // Verify Tournament and Team Names
      expect(find.text('VIT-AP Premier League'), findsOneWidget);
      expect(find.text('CRICKET • MH-1 Warriors'), findsOneWidget);
      expect(find.text('Badminton Open Championship'), findsOneWidget);
      expect(find.text('BADMINTON • Vikram / Arjun'), findsOneWidget);
      expect(find.text('Campus Football Super Cup'), findsOneWidget);
      expect(find.text('FOOTBALL • CSE Strikers'), findsOneWidget);

      // Verify Official Badges
      expect(find.text('• Official'), findsNWidgets(2));
    });
  });
}
