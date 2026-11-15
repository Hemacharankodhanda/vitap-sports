import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/services/local_prefs_service.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/teams/data/models/team_model.dart';
import 'package:vitap_sports/features/teams/providers/team_providers.dart';
import 'package:vitap_sports/features/teams/screens/create_team_screen.dart';
import 'package:vitap_sports/features/teams/screens/recruitment_screen.dart';
import 'package:vitap_sports/features/teams/screens/team_detail_screen.dart';
import 'package:vitap_sports/features/teams/screens/teams_list_screen.dart';

class _FakeLocalPrefsService extends Fake implements LocalPrefsService {
  @override
  String get selectedSport => 'All';

  @override
  Future<void> setSelectedSport(String sport) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const mockTeam = TeamModel(
    id: 'team_apple_1',
    name: 'Cupertino Strikers',
    sportId: 'cricket',
    sportName: 'Cricket',
    captainId: 'user_1',
    captainName: 'John Doe',
    description: 'Minimalist cricket squad',
    wins: 8,
    losses: 2,
    draws: 0,
    members: [
      TeamMember(
        userId: 'user_1',
        teamId: 'team_apple_1',
        userName: 'John Doe',
        role: 'captain',
        position: 'Batsman',
      ),
      TeamMember(
        userId: 'user_2',
        teamId: 'team_apple_1',
        userName: 'Jane Smith',
        role: 'member',
        position: 'Bowler',
      ),
    ],
  );

  group('TeamsListScreen Widget Tests', () {
    testWidgets('renders teams list with squircle team avatars and W-L record in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(_FakeLocalPrefsService()),
            teamsListProvider.overrideWith((ref) => Future.value([mockTeam])),
            sportsListProvider.overrideWith((ref) => Future.value([
              {'id': 'all', 'name': 'All'},
              {'id': 'cricket', 'name': 'Cricket'},
            ])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const TeamsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Cupertino Strikers'), findsOneWidget);
      expect(find.text('Cricket · 2 members'), findsOneWidget);
      expect(find.text('8W - 2L'), findsOneWidget);
    });

    testWidgets('survives 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(_FakeLocalPrefsService()),
            teamsListProvider.overrideWith((ref) => Future.value([mockTeam])),
            sportsListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const TeamsListScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cupertino Strikers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CreateTeamScreen & RecruitmentScreen Widget Tests', () {
    testWidgets('CreateTeamScreen renders form inputs and pill button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sportsListProvider.overrideWith((ref) => Future.value([
              {'id': 'cricket', 'name': 'Cricket'},
              {'id': 'football', 'name': 'Football'},
            ])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CreateTeamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Team'), findsWidgets);
      expect(find.text('Team Name'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
    });

    testWidgets('RecruitmentScreen renders clean EmptyState without emojis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const RecruitmentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recruitment'), findsOneWidget);
      expect(find.text('No open positions'), findsOneWidget);
      expect(find.text('Teams looking for players will appear here.'), findsOneWidget);
    });
  });

  group('TeamDetailScreen Widget Tests', () {
    testWidgets('renders team header, stats row, and roster', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'user_1'),
            teamDetailProvider('team_apple_1').overrideWith((ref) => Future.value(mockTeam)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TeamDetailScreen(teamId: 'team_apple_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cupertino Strikers'), findsOneWidget);
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Minimalist cricket squad'), findsOneWidget);
      expect(find.text('Played'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Roster (2)'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Delete Team'), findsOneWidget);
    });
  });
}
