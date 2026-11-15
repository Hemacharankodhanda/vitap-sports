/// VIT-AP Sports — Navigation Shell and Theme Settings Tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitap_sports/core/router/shell_screen.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/theme/app_theme_provider.dart';
import 'package:vitap_sports/core/widgets/app_segmented.dart';
import 'package:vitap_sports/features/settings/screens/theme_settings_screen.dart';

class MockNavigationShell extends StatefulWidget implements StatefulNavigationShell {
  const MockNavigationShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    onDestinationSelected(index);
  }

  @override
  State<MockNavigationShell> createState() => _MockNavigationShellState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockNavigationShellState extends State<MockNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Shell Branch: ${widget.currentIndex}'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ShellScreen Navigation Tests', () {
    testWidgets('Renders all 5 destinations and switches branches on tap', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: StatefulBuilder(
          builder: (context, setState) {
            return ShellScreen(
              navigationShell: MockNavigationShell(
                currentIndex: activeIndex,
                onDestinationSelected: (idx) {
                  setState(() => activeIndex = idx);
                },
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Board'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Teams (index 1)
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();
      expect(activeIndex, 1);

      // Tap on Matches (index 2)
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();
      expect(activeIndex, 2);
    });

    testWidgets('Swiping horizontally on body or bottom bar changes active tab', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int activeIndex = 0;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: StatefulBuilder(
          builder: (context, setState) {
            return ShellScreen(
              navigationShell: MockNavigationShell(
                currentIndex: activeIndex,
                onDestinationSelected: (idx) {
                  setState(() => activeIndex = idx);
                },
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(activeIndex, 0);

      // Swipe left on body (horizontal drag left with velocity)
      await tester.drag(find.text('Shell Branch: 0'), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(activeIndex, 1);

      // Swipe right on body (horizontal drag right with velocity)
      await tester.drag(find.text('Shell Branch: 1'), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(activeIndex, 0);
    });

    testWidgets('Switches to Navigation Rail layout on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int activeIndex = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: StatefulBuilder(
          builder: (context, setState) {
            return ShellScreen(
              navigationShell: MockNavigationShell(
                currentIndex: activeIndex,
                onDestinationSelected: (idx) {
                  setState(() => activeIndex = idx);
                },
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Board'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });
  });

  group('ThemeSettingsScreen Tests', () {
    testWidgets('Renders AppSegmented and changes theme mode', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(const Color(0xFF1D1D1F)),
            home: const ThemeSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byType(AppSegmented<ThemeMode>), findsOneWidget);

      // Tap on 'Dark' option in segmented control
      final darkFinder = find.descendant(
        of: find.byType(AppSegmented<ThemeMode>),
        matching: find.text('Dark'),
      );
      expect(darkFinder, findsOneWidget);

      await tester.tap(darkFinder);
      await tester.pumpAndSettle();

      expect(container.read(themeProvider).themeMode, ThemeMode.dark);
    });
  });
}
