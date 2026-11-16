/// VIT-AP Sports — Auth Router Redirect & OAuth Callback Tests.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitap_sports/core/router/app_router.dart';
import 'package:vitap_sports/core/services/local_prefs_service.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/core/widgets/loading_indicator.dart';
import 'package:vitap_sports/features/auth/data/auth_service.dart';
import 'package:vitap_sports/features/auth/providers/auth_provider.dart';
import 'package:vitap_sports/features/auth/screens/login_screen.dart';
import 'package:vitap_sports/features/feed/screens/feed_screen.dart';

class _MockAuthService implements AuthService {
  _MockAuthService({Session? initialSession}) : _session = initialSession;

  Session? _session;
  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  void emitSession(Session? session, AuthChangeEvent event) {
    _session = session;
    _controller.add(AuthState(event, session));
  }

  @override
  bool isAllowedDomain() => true;

  @override
  Future<bool> hasCompletedOnboarding() async => true;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

Session _createMockSession() {
  return Session(
    accessToken: 'mock-access-token',
    tokenType: 'bearer',
    user: const User(
      id: 'u-123',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Unauthenticated user is redirected to LoginScreen', (tester) async {
    final mockAuth = _MockAuthService(initialSession: null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: ThemeData(
                extensions: const [AppColorsExtension.light],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('OAuth deep link callback holds on loginCallback screen and transitions to home on sign-in without bouncing to login', (tester) async {
    final mockAuth = _MockAuthService(initialSession: null);
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: ThemeData(
                extensions: const [AppColorsExtension.light],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially on login
    expect(find.byType(LoginScreen), findsOneWidget);

    // Simulate incoming OAuth deep link before Supabase finishes async token parsing
    final router = container.read(routerProvider);
    router.go(AppRoutes.loginCallback);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Active route is loginCallback and LoadingIndicator is displayed
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginCallback);
    expect(find.byType(LoadingIndicator), findsOneWidget);

    // Supabase finishes async parsing and emits signedIn
    final session = _createMockSession();
    mockAuth.emitSession(session, AuthChangeEvent.signedIn);

    // routerProvider with refreshListenable immediately navigates to FeedScreen (Home)
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    expect(find.byType(FeedScreen), findsOneWidget);
  });

  testWidgets('Signing out redirects from authenticated screen to LoginScreen', (tester) async {
    final initialSession = _createMockSession();
    final mockAuth = _MockAuthService(initialSession: initialSession);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: ThemeData(
                extensions: const [AppColorsExtension.light],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FeedScreen), findsOneWidget);

    // Trigger sign out
    await mockAuth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
