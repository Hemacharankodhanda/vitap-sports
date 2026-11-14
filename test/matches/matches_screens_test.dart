import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/services/local_prefs_service.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/widgets/app_segmented.dart';
import 'package:vitap_sports/features/matches/data/models/match_model.dart';
import 'package:vitap_sports/features/matches/providers/match_providers.dart';
import 'package:vitap_sports/features/matches/screens/matches_list_screen.dart';
import 'package:vitap_sports/features/teams/providers/team_providers.dart';

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

  final testUpcomingMatch = MatchModel(
    id: 'm-upcoming-1',
    sportId: 'cricket',
    sportName: 'Cricket',
    venue: 'Main Oval',
    scheduledAt: DateTime.now().add(const Duration(days: 1)),
    status: 'upcoming',
    createdBy: 'u1',
    homeTeamName: 'Warriors',
    awayTeamName: 'Titans',
  );

  group('MatchesListScreen Widget Tests', () {
    testWidgets('renders AppSegmented with Upcoming, Live, Completed tabs and updates view', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(_FakeLocalPrefsService()),
            sportsListProvider.overrideWith((ref) => Future.value([])),
            matchesListProvider('upcoming').overrideWith((ref) => Future.value([testUpcomingMatch])),
            matchesListProvider('live').overrideWith((ref) => Future.value([])),
            matchesListProvider('completed').overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const MatchesListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
      expect(find.byType(AppSegmented<String>), findsOneWidget);
      expect(find.widgetWithText(AppSegmented<String>, 'Upcoming'), findsOneWidget);
      expect(find.widgetWithText(AppSegmented<String>, 'Live'), findsOneWidget);
      expect(find.widgetWithText(AppSegmented<String>, 'Completed'), findsOneWidget);
      expect(find.text('Warriors'), findsOneWidget);
      expect(find.text('Titans'), findsOneWidget);
    });

    testWidgets('survives 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(_FakeLocalPrefsService()),
            sportsListProvider.overrideWith((ref) => Future.value([])),
            matchesListProvider('upcoming').overrideWith((ref) => Future.value([testUpcomingMatch])),
            matchesListProvider('live').overrideWith((ref) => Future.value([])),
            matchesListProvider('completed').overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const MatchesListScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
