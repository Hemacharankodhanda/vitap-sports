import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitap_sports/core/router/app_router.dart';
import 'package:vitap_sports/core/services/local_prefs_service.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/features/auth/data/auth_service.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/presentation/screens/tournament_list_screen.dart';
import 'package:vitap_sports/features/tournaments/providers/tournament_providers.dart';

class _FakeAuthService implements AuthService {
  @override
  Session? get currentSession => Session(
        accessToken: 'mock-token',
        tokenType: 'bearer',
        user: const User(
          id: 'u-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        ),
      );

  @override
  User? get currentUser => const User(
        id: 'u-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  bool isAllowedDomain() => true;

  @override
  Future<bool> hasCompletedOnboarding() async => true;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Navigating to /tournaments/:id directly and via TournamentListScreen resolves', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final tournament = TournamentModel(
      id: 'tourney-abc',
      name: 'Spring Badminton Open',
      sport: 'badminton',
      format: TournamentFormat.knockout,
      status: TournamentStatus.draft,
      scope: TournamentScope.open,
    );

    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
          tournamentDetailProvider('tourney-abc').overrideWith((ref) => Future.value(tournament)),
          tournamentEntriesProvider('tourney-abc').overrideWith((ref) => Stream.value([])),
          tournamentFixturesProvider('tourney-abc').overrideWith((ref) => Stream.value([])),
          tournamentGroupsProvider('tourney-abc').overrideWith((ref) => Future.value([])),
          isTournamentAdminProvider('tourney-abc').overrideWith((ref) => Future.value(false)),
          tournamentsListProvider.overrideWith((ref) => Future.value([tournament])),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: ThemeData(
                brightness: Brightness.light,
                extensions: const [AppColorsExtension.light],
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final router = container.read(routerProvider);

    // 1. Navigate to /leaderboard/tournaments
    router.go('/leaderboard/tournaments');
    await tester.pumpAndSettle();

    expect(find.byType(TournamentListScreen), findsOneWidget);
    expect(find.text('Spring Badminton Open'), findsOneWidget);

    // 2. Tap on the tournament card to open it
    await tester.tap(find.text('Spring Badminton Open'));
    await tester.pumpAndSettle();

    // Check if tournament detail screen rendered or blank screen
    expect(find.text('Tournament Information'), findsOneWidget);
  });
}
