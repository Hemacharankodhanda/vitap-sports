import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/matches/providers/match_providers.dart';
import 'package:vitap_sports/features/matches/screens/create_match_screen.dart';
import 'package:vitap_sports/features/scoring/domain/player_option.dart';
import 'package:vitap_sports/features/scoring/presentation/widgets/sport_setup_widget.dart';
import 'package:vitap_sports/features/scoring/providers/live_scorer_providers.dart';
import 'package:vitap_sports/features/teams/data/models/team_model.dart';
import 'package:vitap_sports/features/teams/providers/team_providers.dart';

void main() {
  group('Badminton Match Conducting Tests', () {
    final mockSports = [
      {'id': 's-cricket', 'name': 'Cricket'},
      {'id': 's-badminton', 'name': 'Badminton'},
      {'id': 's-football', 'name': 'Football'},
    ];

    final mockPlayers = [
      {'id': 'p-1', 'name': 'P.V. Sindhu', 'avatar_url': null, 'role': 'player'},
      {'id': 'p-2', 'name': 'Saina Nehwal', 'avatar_url': null, 'role': 'player'},
      {'id': 'p-3', 'name': 'Lakshya Sen', 'avatar_url': null, 'role': 'player'},
      {'id': 'p-4', 'name': 'Srikanth Kidambi', 'avatar_url': null, 'role': 'player'},
    ];

    final mockTeams = [
      TeamModel(
        id: 'team-b1',
        name: 'Smashers',
        sportId: 's-badminton',
        captainId: 'u-1',
        createdAt: DateTime.now(),
        members: const [
          TeamMember(teamId: 'team-b1', userId: 'p-1', role: 'member', userName: 'P.V. Sindhu'),
          TeamMember(teamId: 'team-b1', userId: 'p-2', role: 'member', userName: 'Saina Nehwal'),
          TeamMember(teamId: 'team-b1', userId: 'p-3', role: 'member', userName: 'Lakshya Sen'),
        ],
      ),
      TeamModel(
        id: 'team-b2',
        name: 'Shuttlers',
        sportId: 's-badminton',
        captainId: 'u-2',
        createdAt: DateTime.now(),
        members: const [
          TeamMember(teamId: 'team-b2', userId: 'p-4', role: 'member', userName: 'Srikanth Kidambi'),
        ],
      ),
    ];

    testWidgets('Badminton asks singles or doubles; singles hides teams and shows players only', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            sportsListProvider.overrideWith((ref) => mockSports),
            teamsListProvider.overrideWith((ref) => mockTeams),
            teamsBySportProvider.overrideWith((ref, sportId) => mockTeams),
            allPlayersProvider.overrideWith((ref) => mockPlayers),
            playersForSportProvider.overrideWith((ref, sportId) => mockPlayers),
          ],
          child: const MaterialApp(
            home: CreateMatchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, Badminton is not selected, Teams is displayed
      expect(find.text('Sport'), findsOneWidget);

      // Tap Badminton sport chip
      await tester.tap(find.text('Badminton'));
      await tester.pumpAndSettle();

      // Verify Match Type chips appear with Singles and Doubles
      expect(find.text('Match Type'), findsOneWidget);
      expect(find.text('Singles'), findsOneWidget);
      expect(find.text('Doubles'), findsOneWidget);

      // In Singles mode:
      // Option of teams is NOT shown!
      expect(find.text('Teams'), findsNothing);
      expect(find.text('Team 1'), findsNothing);
      expect(find.text('Team 2'), findsNothing);

      // Option of players IS shown!
      expect(find.text('Players'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
    });

    testWidgets('Badminton doubles shows teams and warns if not exactly 2 players', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u-1'),
            sportsListProvider.overrideWith((ref) => mockSports),
            teamsListProvider.overrideWith((ref) => mockTeams),
            teamsBySportProvider.overrideWith((ref, sportId) => mockTeams),
            allPlayersProvider.overrideWith((ref) => mockPlayers),
            playersForSportProvider.overrideWith((ref, sportId) => mockPlayers),
          ],
          child: const MaterialApp(
            home: CreateMatchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Badminton
      await tester.tap(find.text('Badminton'));
      await tester.pumpAndSettle();

      // Tap Doubles
      await tester.tap(find.text('Doubles'));
      await tester.pumpAndSettle();

      // Option of teams IS shown for doubles
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Team 1'), findsOneWidget);
      expect(find.text('Team 2'), findsOneWidget);
      expect(find.text('Doubles: exactly 2 players per team'), findsOneWidget);

      // Option of players (singles) is NOT shown
      expect(find.text('Players'), findsNothing);
    });

    testWidgets('SportSetupWidget shows players for singles and enforces 2 players for doubles', (tester) async {
      final singlesState = ScorerState(
        matchId: 'm-bad-1',
        sport: 'badminton',
        homeId: 'p-1',
        awayId: 'p-2',
        homeName: 'P.V. Sindhu',
        awayName: 'Saina Nehwal',
        homePlayers: const [PlayerOption(id: 'p-1', name: 'P.V. Sindhu')],
        awayPlayers: const [PlayerOption(id: 'p-2', name: 'Saina Nehwal')],
        matchData: const {'format': 'singles'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SportSetupWidget(
                state: singlesState,
                onStartMatch: ({required config, extra}) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In singles: shows player names for toss and selection, NOT team names
      expect(find.text('Players'), findsOneWidget);
      expect(find.text('P.V. Sindhu'), findsWidgets);
      expect(find.text('Saina Nehwal'), findsWidgets);

      // Switch to Doubles
      await tester.tap(find.text('Doubles'));
      await tester.pumpAndSettle();

      // Shows pair cards requiring 2 players
      expect(find.textContaining('Pair'), findsWidgets);
    });
  });
}
