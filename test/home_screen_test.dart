import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/authority_verification_screen.dart';
import 'package:resqshield/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen builds and renders cleanly on tablet/desktop viewports', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify key elements exist on the Authority Command Center
    expect(find.text('JalGuard'), findsWidgets);
    expect(find.text('AUTHORITY COMMAND'), findsOneWidget);
    expect(find.text('Active Citizen SOS Triage'), findsOneWidget);

    // Verify situation stats from user image
    expect(find.text('Villages Evac'), findsOneWidget);
    expect(find.text('People at Risk'), findsOneWidget);
    expect(find.text('SOS Active'), findsOneWidget);
    expect(find.text('Shelters Full'), findsOneWidget);
    expect(find.text('Roads Blocked'), findsWidgets);

    // Verify Active Citizen SOS Triage table columns and data
    expect(find.text('#'), findsOneWidget);
    expect(find.text('Location'), findsWidgets);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Assigned Team'), findsOneWidget);
    expect(find.text('Last Updated'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);

    expect(find.text('#284'), findsOneWidget);
    expect(find.text('#281'), findsOneWidget);
    expect(find.text('Mawphlang Riverfront'), findsWidgets);
    expect(find.text('Nongstoin Valley Lowland'), findsWidgets);
    expect(find.text('6 People'), findsWidgets);
    expect(find.text('1 Elderly'), findsWidgets);
    expect(find.text('Medical Urgency'), findsWidgets);
    expect(find.text('Assign Team'), findsWidgets);
    expect(find.text('View Location'), findsWidgets);
    expect(find.text('Resolve'), findsWidgets);
  });

  testWidgets('AuthorityVerificationScreen mounts and renders cleanly', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AuthorityVerificationScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Authority Authorization'), findsOneWidget);
    expect(find.text('GOVT OF INDIA • DISASTER AUTHORITY'), findsOneWidget);
    expect(find.text('PHONE NUMBER AS PER OFFICIAL GOV ID'), findsOneWidget);
    expect(find.text('Official Gov ID'), findsOneWidget);
    expect(find.text('Continue to Phone OTP'), findsOneWidget);

    // Tap continue to OTP
    await tester.tap(find.text('Continue to Phone OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Official ID Phone Verification'), findsOneWidget);
  });

  testWidgets('HomeScreen displays modern Evacuation, Routes, Shelters, and SITREP sections matching screenshot', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Evacuation Management
    expect(find.text('EVACUATION MANAGEMENT (SECTOR A)'), findsOneWidget);
    expect(find.text('HIGH PRIORITY'), findsOneWidget);
    expect(find.text('67% Evacuated'), findsOneWidget);
    expect(find.text('1,903 / 2,840'), findsOneWidget);
    expect(find.text('Remaining: 937'), findsOneWidget);
    expect(find.text('People Evacuated'), findsOneWidget);
    expect(find.text('People Remaining'), findsOneWidget);
    expect(find.text('Total Capacity'), findsOneWidget);
    expect(find.text('Sectors Covered'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);

    // 2. Evacuation Routes Status
    expect(find.text('EVACUATION ROUTES STATUS'), findsOneWidget);
    expect(find.text('View on Map'), findsOneWidget);
    expect(find.text('Route A  —  Shelter 1 (Nearbying Kott)'), findsOneWidget);
    expect(find.text('Safe'), findsOneWidget);
    expect(find.text('Recommended >'), findsOneWidget);
    expect(find.text('Route B  —  Shelter 2 (Valley East)'), findsOneWidget);
    expect(find.text('Moderate Risk'), findsOneWidget);
    expect(find.text('Route C  —  Shelter 3 (River Bridge)'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('NOTIFY CITIZENS'), findsOneWidget);
    expect(find.text('VIEW SAFE ROUTE'), findsOneWidget);

    // 3. Shelters & Relief Resources
    expect(find.text('SHELTERS & RELIEF RESOURCES'), findsOneWidget);
    expect(find.text('18 Active Shelters'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
    expect(find.text('Meenakshipuram Community Center'), findsOneWidget);
    expect(find.text('72 / 100'), findsOneWidget);
    expect(find.text('St. Anthony Relief Hall'), findsOneWidget);
    expect(find.text('184 / 200'), findsOneWidget);
    expect(find.text('Near Capacity'), findsOneWidget);
    expect(find.text('Valley Convent High School'), findsOneWidget);
    expect(find.text('200 / 200'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
    expect(find.text('Northeast Indoor Stadium'), findsOneWidget);
    expect(find.text('120 / 250'), findsOneWidget);

    // 4. Disaster Operations SITREP
    expect(find.text('DISASTER OPERATIONS SITREP'), findsOneWidget);
    expect(find.text('GENERATE SITREP'), findsOneWidget);
    expect(find.text('11:45'), findsOneWidget);
    expect(find.text('Rescue team reached Sector C and is assisting 42 residents.'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('Water level at Damodar River crossed warning mark (8.2m).'), findsOneWidget);
    expect(find.text('Heavy Rainfall Alert'), findsOneWidget);
    expect(find.text('Next 6-8 hours'), findsOneWidget);

    // 5. Bottom Command Bar
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Live Map'), findsOneWidget);
    expect(find.text('Alerts (12)'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
