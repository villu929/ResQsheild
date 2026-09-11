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
    expect(find.text('You are currently safe'), findsOneWidget);

    // Verify bottom navigation bar exists with 5 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Scroll down to reveal Quick Actions section
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    // Verify Quick Actions Section & 6 Redesigned Cards
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Safe Route'), findsOneWidget);
    expect(find.text('Shelter'), findsOneWidget);
    expect(find.text('Medical'), findsAtLeastNWidgets(1));
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

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
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
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

  testWidgets('CitizenDashboardScreen Do\'s and Don\'ts carousel displays 4 categories and slides correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pump();

    // Scroll down to reveal Do's and Don'ts section
    await tester.scrollUntilVisible(
      find.text("Do's and Don'ts"),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Section Header
    expect(find.text("Do's and Don'ts"), findsOneWidget);

    // Verify all 4 disaster category tabs
    expect(find.text('Urban Flood'), findsOneWidget);
    expect(find.text('Cyclone'), findsOneWidget);
    expect(find.text('Landslide'), findsOneWidget);
    expect(find.text('Lightning'), findsOneWidget);

    // Initial state: Urban Flood & Before Floods
    expect(find.text("Do's and Don'ts during Urban Flood"), findsOneWidget);
    expect(find.text('Before Floods & Warning Signs'), findsOneWidget);

    // Tap 'Cyclone' category chip
    await tester.ensureVisible(find.text('Cyclone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cyclone'));
    await tester.pumpAndSettle();

    // Verify Cyclone banner and Before Cyclone
    expect(find.text("Do's & Don'ts Before, During & After Cyclone"), findsOneWidget);
    expect(find.text('Before Cyclone & Early Alert'), findsOneWidget);

    // Tap 'During' phase button
    await tester.ensureVisible(find.text('During'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('During'));
    await tester.pumpAndSettle();

    // Verify During Cyclone phase
    expect(find.text('During Cyclone & Landfall'), findsOneWidget);

    // Tap "View Full Guide" button
    await tester.ensureVisible(find.text('View Full Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Full Guide'));
    await tester.pumpAndSettle();

    // Confirm safety modal appears
    expect(find.text('Citizen Safety Guide (NDMA)'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

