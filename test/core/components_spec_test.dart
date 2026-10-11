import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/theme/app_colors.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/widgets/app_avatar.dart';
import 'package:vitap_sports/core/widgets/app_button.dart';
import 'package:vitap_sports/core/widgets/app_card.dart';
import 'package:vitap_sports/core/widgets/app_chip.dart';
import 'package:vitap_sports/core/widgets/app_dialog.dart';
import 'package:vitap_sports/core/widgets/app_text_field.dart';
import 'package:vitap_sports/core/widgets/empty_state.dart';
import 'package:vitap_sports/core/widgets/error_view.dart';
import 'package:vitap_sports/core/widgets/form_strip.dart';
import 'package:vitap_sports/core/widgets/stat_tile.dart';
import 'package:vitap_sports/core/widgets/status_badge.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(const Color(0xFF2563EB)),
      darkTheme: AppTheme.dark(const Color(0xFF60A5FA)),
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
  });
}
