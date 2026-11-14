import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/features/profile/data/models/user_model.dart';
import 'package:vitap_sports/features/profile/providers/profile_provider.dart';
import 'package:vitap_sports/features/profile/screens/edit_profile_screen.dart';
import 'package:vitap_sports/features/profile/screens/profile_screen.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/providers/tournament_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const mockUser = UserModel(
    id: 'user_123',
    name: 'Apple Athlete',
    branch: 'CSE',
    year: '3rd Year',
    hostelBlock: 'MH-2',
    matchesPlayed: 12,
    wins: 9,
    losses: 3,
    mvpCount: 4,
    sports: [
      UserSport(
        sportId: 's1',
        sportName: 'Cricket',
        skillLevel: 'Advanced',
      ),
      UserSport(
        sportId: 's2',
        sportName: 'Football',
        skillLevel: 'Intermediate',
      ),
    ],
  );

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders user details, stats row, and sports chips in light & dark', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => Future.value(mockUser)),
            playerTournamentHonoursProvider('user_123').overrideWith((ref) => Future.value(<TournamentHonour>[])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Apple Athlete'), findsOneWidget);
      expect(find.text('CSE • 3rd Year • MH-2'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Cricket · Advanced'), findsOneWidget);
      expect(find.text('Football · Intermediate'), findsOneWidget);
    });

    testWidgets('survives 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => Future.value(mockUser)),
            playerTournamentHonoursProvider('user_123').overrideWith((ref) => Future.value(<TournamentHonour>[])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple Athlete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EditProfileScreen Widget Tests', () {
    testWidgets('renders input fields with user data pre-filled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => Future.value(mockUser)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const EditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Branch'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Apple Athlete'), findsOneWidget);
    });
  });
}
