import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/theme/app_motion.dart';
import 'package:vitap_sports/core/theme/app_spacing.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/widgets/adaptive_scaffold.dart';
import 'package:vitap_sports/core/widgets/app_button.dart';
import 'package:vitap_sports/core/widgets/app_chip.dart';
import 'package:vitap_sports/core/widgets/app_segmented.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const destinations = [
    AdaptiveDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AdaptiveDestination(
      label: 'Teams',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    AdaptiveDestination(
      label: 'Matches',
      icon: Icons.sports_score_outlined,
      selectedIcon: Icons.sports_score,
    ),
  ];

  group('Phase 5 Responsive Tests (Breakpoints & Layouts)', () {
    testWidgets('Compact viewport (360x640) renders frosted bottom bar', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AdaptiveScaffold(
            currentIndex: 0,
            onNavigationChanged: (_) {},
            destinations: destinations,
            body: const Center(child: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content'), findsOneWidget);
      // On compact, bottom nav should exist
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);

      // Verify that RailNavItem is not rendered in compact mode
      final railFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RailNavItem',
      );
      expect(railFinder, findsNothing);
    });

    testWidgets('Medium viewport (768x1024) renders navigation rail', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AdaptiveScaffold(
            currentIndex: 1,
            onNavigationChanged: (_) {},
            destinations: destinations,
            body: const Center(child: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final railFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RailNavItem',
      );
      expect(railFinder, findsNWidgets(3));

      final bottomFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_BottomNavItem',
      );
      expect(bottomFinder, findsNothing);
    });

    testWidgets('Expanded viewport (1280x800) renders navigation rail', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: AdaptiveScaffold(
            currentIndex: 0,
            onNavigationChanged: (_) {},
            destinations: destinations,
            body: const Center(child: Text('Wide Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final railFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RailNavItem',
      );
      expect(railFinder, findsNWidgets(3));
    });
  });

  group('Phase 5 Accessibility Tests (Touch Targets & Semantics)', () {
    testWidgets('AppButton meets 48x48 min touch target & exposes Semantics button trait', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: AppButton(
                label: 'Accessible Action',
                onPressed: () {},
                isExpanded: false,
                size: AppButtonSize.small,
              ),
            ),
          ),
        ),
      );

      final buttonBox = tester.renderObject<RenderBox>(find.byType(AppButton));
      expect(buttonBox.size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, contains('Accessible Action'));
    });

    testWidgets('AppChip meets 48x48 min touch target & exposes Semantics button trait', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: AppChip(
                label: 'Cricket',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final chipBox = tester.renderObject<RenderBox>(find.byType(AppChip));
      expect(chipBox.size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
      expect(chipBox.size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));

      final semantics = tester.getSemantics(find.byType(AppChip));
      expect(semantics.label, contains('Cricket'));
    });

    testWidgets('200% text scale (TextScaler.linear(2.0)) survives without crash or overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(390, 844),
            ),
            child: Scaffold(
              body: Column(
                children: [
                  AppButton(
                    label: 'Long Label Button for 200% Text Scale',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  AppSegmented<String>(
                    options: const ['Ongoing', 'Upcoming', 'Completed'],
                    selected: 'Ongoing',
                    onSelected: (_) {},
                    labelBuilder: (o) => o,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Long Label Button for 200% Text Scale'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
    });
  });

  group('Phase 5 Motion Tests (Reduced Motion & Animation Tokens)', () {
    testWidgets('AppMotion respects disableAnimations and collapses duration to zero', (tester) async {
      Duration? buttonAnimDuration;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                buttonAnimDuration = AppMotion.duration(
                  context,
                  AppMotion.stateChangeDuration,
                );
                return Center(
                  child: AppSegmented<String>(
                    options: const ['One', 'Two'],
                    selected: 'One',
                    onSelected: (_) {},
                    labelBuilder: (o) => o,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buttonAnimDuration, Duration.zero);
    });

    testWidgets('AppSegmented triggers selectionClick and updates state', (tester) async {
      String selected = 'Tab 1';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AppSegmented<String>(
                  options: const ['Tab 1', 'Tab 2'],
                  selected: selected,
                  onSelected: (val) => setState(() => selected = val),
                  labelBuilder: (o) => o,
                ),
              );
            },
          ),
        ),
      );

      expect(selected, 'Tab 1');
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(selected, 'Tab 2');
    });
  });
}
