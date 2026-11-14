/// VIT-AP Sports — Auth Screens Widget Tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitap_sports/core/theme/app_theme.dart';
import 'package:vitap_sports/core/widgets/app_button.dart';
import 'package:vitap_sports/core/widgets/app_chip.dart';
import 'package:vitap_sports/core/widgets/app_segmented.dart';
import 'package:vitap_sports/features/auth/screens/login_screen.dart';
import 'package:vitap_sports/features/auth/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders Apple-inspired layout with clean typography and pill button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(const Color(0xFF1D1D1F)),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIT-AP Sports'), findsOneWidget);
      expect(find.textContaining('Your campus sports community'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with your @vitap.ac.in email'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Survives 200% text scale without overflowing', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              theme: AppTheme.light(const Color(0xFF1D1D1F)),
              home: const LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIT-AP Sports'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders all fields, chips, and segmented skill level controls', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(const Color(0xFF1D1D1F)),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tell us about yourself'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Branch'), findsOneWidget);
      expect(find.text('1st Year'), findsOneWidget);
      expect(find.text('MH-1'), findsOneWidget);
      expect(find.text('Cricket'), findsOneWidget);

      // Scroll down to reveal sports section
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Select 'Cricket' sport chip
      await tester.tap(find.text('Cricket'));
      await tester.pumpAndSettle();

      // Scroll further down to reveal AppSegmented
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify AppSegmented appears for Cricket skill level
      expect(find.byType(AppSegmented<String>), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);

      // Tap 'Intermediate'
      await tester.tap(find.text('Intermediate'));
      await tester.pumpAndSettle();

      // Verify Complete Profile button
      expect(find.widgetWithText(AppButton, 'Complete Profile'), findsOneWidget);
    });
  });
}
