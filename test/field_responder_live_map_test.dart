import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/field_responder_view.dart';

void main() {
  testWidgets('FieldResponderView Live Map Dashboard renders faithfully to reference image',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FieldResponderView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Header verification
    expect(find.text('JalGuard'), findsOneWidget);
    expect(find.text('Field Operations'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

    // 2. Active Mission Card
    expect(find.text('ACTIVE MISSION'), findsOneWidget);
    expect(find.text('#RS-204'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('Mawphlang Riverbank Flood Extraction'), findsOneWidget);
    expect(find.textContaining('12 people trapped'), findsOneWidget);
    expect(find.textContaining('2.8 km'), findsOneWidget);
    expect(find.textContaining('ETA 9 min'), findsOneWidget);
    expect(find.text('View Mission'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);

    // 3. Route Hazard Banner
    expect(find.text('Route Hazard'), findsOneWidget);
    expect(find.textContaining('Eastern bridge reported unsafe'), findsOneWidget);
    expect(find.textContaining('Alt Route'), findsOneWidget);

    // 4. Filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Mission'), findsOneWidget);
    expect(find.text('Flood'), findsOneWidget);
    expect(find.text('Roads'), findsOneWidget);
    expect(find.text('Shelters'), findsOneWidget);

    // 5. Floating map controls
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

    // 6. Action Dock
    expect(find.text('Request\nBackup'), findsOneWidget);
    expect(find.text('Report\nHazard'), findsOneWidget);
    expect(find.text('Control\nRoom'), findsOneWidget);
    expect(find.text('Share\nLocation'), findsOneWidget);

    // 7. Bottom Navigation
    expect(find.text('Live Map'), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('SOS Desk'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Badge on SOS Desk
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('FieldResponderView Report Hazard bottom sheet matches screenshot 2',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FieldResponderView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap "Report Hazard" button in action dock
    final reportHazardBtn = find.text('Report\nHazard');
    expect(reportHazardBtn, findsOneWidget);
    await tester.tap(reportHazardBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Report Hazard sheet contents
    expect(find.text('Report Hazard'), findsOneWidget);

    // 8 hazard type cards
    expect(find.text('Flooded Road'), findsOneWidget);
    expect(find.text('Landslide'), findsOneWidget);
    expect(find.text('Road Blocked'), findsOneWidget);
    expect(find.text('Bridge Damage'), findsOneWidget);
    expect(find.text('Building Damage'), findsOneWidget);
    expect(find.text('People Trapped'), findsOneWidget);
    expect(find.text('Water Level Rising'), findsOneWidget);
    expect(find.text('Road Clear / Safe'), findsOneWidget);

    // Photo attachment section
    expect(find.text('Add Photo (Required)'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    // Telemetry location card
    expect(find.text('Location (Auto)'), findsOneWidget);
    expect(find.textContaining('25.5672, 91.8831'), findsOneWidget);

    // Submit button
    expect(find.text('Submit Report'), findsOneWidget);

    // Tap a hazard option (e.g. Landslide)
    await tester.tap(find.text('Landslide'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap submit report
    await tester.tap(find.text('Submit Report'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Should show snackbar confirmation
    expect(find.textContaining('Hazard report submitted: Landslide'), findsOneWidget);
  });

  testWidgets('FieldResponderView map controls and filters interact properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FieldResponderView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap filter chip 'Flood'
    await tester.tap(find.text('Flood'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap layer switch button
    await tester.tap(find.byIcon(Icons.layers_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    // Expect snackbar showing layer switched
    expect(find.textContaining('Map Style:'), findsOneWidget);

    // Tap Navigate button
    await tester.tap(find.text('Navigate'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Navigating...'), findsOneWidget);
  });
}
