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
  });
}
