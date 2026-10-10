import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders label and responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    await tester.tap(find.text('Test Button'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
