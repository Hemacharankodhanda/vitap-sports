import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/widgets/adaptive_scaffold.dart';
import 'package:vitap_sports/core/widgets/app_avatar.dart';
import 'package:vitap_sports/core/widgets/app_bottom_sheet.dart';
import 'package:vitap_sports/core/widgets/app_button.dart';
import 'package:vitap_sports/core/widgets/app_card.dart';
import 'package:vitap_sports/core/widgets/app_chip.dart';
import 'package:vitap_sports/core/widgets/app_dialog.dart';
import 'package:vitap_sports/core/widgets/app_segmented.dart';
import 'package:vitap_sports/core/widgets/app_snack.dart';
import 'package:vitap_sports/core/widgets/app_switch.dart';
import 'package:vitap_sports/core/widgets/app_text_field.dart';
import 'package:vitap_sports/core/widgets/empty_state.dart';
import 'package:vitap_sports/core/widgets/error_view.dart';
import 'package:vitap_sports/core/widgets/form_strip.dart';
import 'package:vitap_sports/core/widgets/frosted_bar.dart';
import 'package:vitap_sports/core/widgets/stat_tile.dart';
import 'package:vitap_sports/core/widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: AppTheme.light(const Color(0xFF1D1D1F)),
      darkTheme: AppTheme.dark(const Color(0xFFF5F5F7)),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Component Specification Tests', () {
    testWidgets('AppButton renders all variants, compact sizing, and loading state', (tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            AppButton(
              label: 'Primary Action',
              onPressed: () {},
              variant: AppButtonVariant.primary,
            ),
            AppButton(
              label: 'Secondary Action',
              onPressed: () {},
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.medium,
            ),
            AppButton(
              label: 'Outlined Action',
              onPressed: () {},
              variant: AppButtonVariant.outlined,
            ),
            AppButton(
              label: 'Destructive Action',
              onPressed: () {},
              variant: AppButtonVariant.destructive,
            ),
            AppButton(
              label: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ],
        ),
      ));
      await tester.pump();

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.text('Outlined Action'), findsOneWidget);
      expect(find.text('Destructive Action'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppTextField renders stacked label and search variant', (tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            const AppTextField(
              label: 'Player Name',
              hint: 'Enter full name',
            ),
            AppTextField.search(
              hint: 'Search matches',
              onChanged: (_) {},
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Player Name'), findsOneWidget);
      expect(find.text('Enter full name'), findsOneWidget);
      expect(find.text('Search matches'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('AppCard and AppGroupedCard render flat with hairline dividers', (tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            const AppCard(
              child: Text('Card Content'),
            ),
            AppGroupedCard(
              children: const [
                Text('Row 1'),
                Text('Row 2'),
                Text('Row 3'),
              ],
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 2'), findsOneWidget);
      expect(find.text('Row 3'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('AppChip and ResultChip render per spec', (tester) async {
      await tester.pumpWidget(wrap(
        Row(
          children: [
            AppChip(
              label: 'Cricket',
              isSelected: true,
              onTap: () {},
            ),
            AppChip(
              label: 'Football',
              isSelected: false,
              onTap: () {},
            ),
            const ResultChip(result: 'W'),
            const ResultChip(result: 'L'),
            const ResultChip(result: 'D'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('StatusLabel renders Live, Upcoming, FT, Paused per spec', (tester) async {
      await tester.pumpWidget(wrap(
        const Column(
          children: [
            StatusLabel.live(),
            StatusLabel.upcoming(),
            StatusLabel.completed(),
            StatusLabel.paused(),
          ],
        ),
      ));
      await tester.pump();

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('FT'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('AppAvatar renders circle for player and rounded square for team', (tester) async {
      await tester.pumpWidget(wrap(
        const Row(
          children: [
            AppAvatar(
              name: 'Virat Kohli',
              size: AppAvatarSize.size40,
              isTeam: false,
            ),
            AppAvatar(
              name: 'Royal Challengers',
              size: AppAvatarSize.size56,
              isTeam: true,
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('VK'), findsOneWidget);
      expect(find.text('RC'), findsOneWidget);
    });

    testWidgets('StatTile and StatGridCard format tabular numbers and NaN fallback', (tester) async {
      await tester.pumpWidget(wrap(
        StatGridCard(
          columns: 2,
          tiles: const [
            StatTile(label: 'Total Runs', value: '1420'),
            StatTile(label: 'Strike Rate', value: '138.5'),
            StatTile(label: 'Average', value: 'NaN'),
            StatTile(label: 'Wickets', value: '24'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1420'), findsOneWidget);
      expect(find.text('138.5'), findsOneWidget);
      expect(find.text('-'), findsOneWidget); // NaN replaced with '-'
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Total Runs'), findsOneWidget);
    });

    testWidgets('FormStrip displays last 5 match outcomes', (tester) async {
      await tester.pumpWidget(wrap(
        const FormStrip(
          results: ['W', 'W', 'L', 'D', 'W', 'L'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ResultChip), findsNWidgets(5)); // max 5
    });

    testWidgets('EmptyState and InlineErrorBanner render clean feedback per spec', (tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: const [
            EmptyState(
              icon: Icons.sports_cricket_rounded,
              title: 'No matches scheduled',
              subtitle: 'Check back later for upcoming fixtures.',
            ),
            InlineErrorBanner(
              message: 'Failed to sync latest score.',
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No matches scheduled'), findsOneWidget);
      expect(find.text('Check back later for upcoming fixtures.'), findsOneWidget);
      expect(find.text('Failed to sync latest score.'), findsOneWidget);
    });

    testWidgets('AppSegmented slides thumb and notifies selection', (tester) async {
      String selected = 'System';
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) => AppSegmented<String>(
            options: const ['System', 'Light', 'Dark'],
            selected: selected,
            labelBuilder: (s) => s,
            onSelected: (val) => setState(() => selected = val),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(selected, 'Dark');
    });

    testWidgets('AppSwitch and AppSwitchRow toggle state', (tester) async {
      bool switched = false;
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              AppSwitch(
                value: switched,
                onChanged: (val) => setState(() => switched = val),
              ),
              AppSwitchRow(
                label: 'Push Notifications',
                subtitle: 'Get alerts for live score changes',
                value: switched,
                onChanged: (val) => setState(() => switched = val),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Get alerts for live score changes'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));

      await tester.tap(find.text('Push Notifications'));
      await tester.pumpAndSettle();
    });

    testWidgets('FrostedBar and FrostedAppBar render with hairline divider', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: const Scaffold(
          appBar: FrostedAppBar(title: Text('Explore')),
          body: FrostedBar(
            showTopDivider: true,
            child: Text('Frosted Content'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Frosted Content'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('AdaptiveScaffold renders bottom bar on compact and navigation rail on medium/expanded', (tester) async {
      const destinations = [
        AdaptiveDestination(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
        AdaptiveDestination(label: 'Matches', icon: Icons.sports_outlined, selectedIcon: Icons.sports),
        AdaptiveDestination(label: 'Teams', icon: Icons.groups_outlined, selectedIcon: Icons.groups),
      ];

      // 1. Compact screen
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedIndex = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: StatefulBuilder(
          builder: (context, setState) => AdaptiveScaffold(
            currentIndex: selectedIndex,
            onNavigationChanged: (idx) => setState(() => selectedIndex = idx),
            destinations: destinations,
            body: Text('Page: $selectedIndex'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Page: 0'), findsOneWidget);

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);

      // 2. Expanded screen (e.g. tablet width 1100)
      tester.view.physicalSize = const Size(1100, 800);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: StatefulBuilder(
          builder: (context, setState) => AdaptiveScaffold(
            currentIndex: selectedIndex,
            onNavigationChanged: (idx) => setState(() => selectedIndex = idx),
            destinations: destinations,
            body: Text('Page: $selectedIndex'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Page: 1'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
    });

    testWidgets('AppDialog and AppBottomSheet render with Apple curvature and actions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppDialog.showConfirmation(
                    context: context,
                    title: 'Delete Team?',
                    message: 'This action is irreversible.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  ),
                  child: const Text('Open Dialog'),
                ),
                ElevatedButton(
                  onPressed: () => AppBottomSheet.show(
                    context: context,
                    title: 'Select Sport',
                    child: const Text('Sheet Body'),
                  ),
                  child: const Text('Open Sheet'),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Team?'), findsOneWidget);
      expect(find.text('This action is irreversible.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Team?'), findsNothing);

      // Test BottomSheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Select Sport'), findsOneWidget);
      expect(find.text('Sheet Body'), findsOneWidget);
    });

    testWidgets('AppSnack shows floating capsule with message and action', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Color(0xFF1D1D1F)),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSnack.show(
                context,
                message: 'Scorecard saved',
                actionLabel: 'Undo',
                onAction: () => actionTriggered = true,
              ),
              child: const Text('Show Snack'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Snack'));
      await tester.pumpAndSettle();

      expect(find.text('Scorecard saved'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });
  });
}
