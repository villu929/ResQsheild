import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/citizen/citizen_dashboard_screen.dart';

void main() {
  testWidgets('CitizenDashboardScreen builds and displays key sections', (WidgetTester tester) async {
    // Set a phone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify top bar location and title
    expect(find.byType(CitizenDashboardScreen), findsOneWidget);
    expect(find.text('Shillong, Meghalaya'), findsOneWidget);

    // Verify hero card text
    expect(find.text('YOU ARE CURRENTLY SAFE'), findsOneWidget);

    // Verify bottom navigation bar exists with 5 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Scroll down to reveal Quick Actions section
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify Quick Actions Section & 6 Redesigned Cards
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Safe Route'), findsOneWidget);
    expect(find.text('Navigate Safely'), findsOneWidget);
    expect(find.text('Shelters'), findsOneWidget);
    expect(find.text('View Nearby'), findsOneWidget);
    expect(find.text('Medical'), findsAtLeastNWidgets(1));
    expect(find.text('Get Help'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Stay Connected'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('CitizenDashboardScreen Quick Action SOS tap opens dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pump();

    // Scroll down to Quick Actions
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Tap SOS card
    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    // Confirm Emergency SOS dialog appears
    expect(find.text('Emergency SOS'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
