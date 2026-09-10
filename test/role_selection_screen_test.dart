import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/role_selection_screen.dart';

void main() {
  testWidgets('RoleSelectionScreen displays 4 role containers and allows selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('Select Your Role'), findsOneWidget);

    // Verify all 4 roles are present
    expect(find.text('Authority Command Center'), findsOneWidget);
    expect(find.text('Field Responder'), findsOneWidget);
    expect(find.text('Citizen / General Public'), findsOneWidget);
    expect(find.text('Technical / Admin Console'), findsOneWidget);

    // Verify initial selection is Citizen
    expect(find.text('Continue to Citizen Login'), findsOneWidget);

    // Tap on Authority role
    await tester.tap(find.text('Authority Command Center'));
    await tester.pumpAndSettle();
    expect(find.text('Access Command Center'), findsOneWidget);

    // Tap on Field Responder role
    await tester.tap(find.text('Field Responder'));
    await tester.pumpAndSettle();
    expect(find.text('Open Tactical Field Portal'), findsOneWidget);

    // Tap on Admin role
    await tester.tap(find.text('Technical / Admin Console'));
    await tester.pumpAndSettle();
    expect(find.text('Open Admin Console'), findsOneWidget);

    // Tap back on Citizen role
    await tester.tap(find.text('Citizen / General Public'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to Citizen Login'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('RoleSelectionScreen operates without overflow on compact screen',
      (WidgetTester tester) async {
    // Test on a small 360x640 screen
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('Authority Command Center'), findsOneWidget);
    expect(find.text('Field Responder'), findsOneWidget);
    expect(find.text('Citizen / General Public'), findsOneWidget);
    expect(find.text('Technical / Admin Console'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('RoleSelectionScreen operates in landscape / 2x2 grid layout',
      (WidgetTester tester) async {
    // Landscape mode: 800x480
    tester.view.physicalSize = const Size(1600, 960);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('Authority Command Center'), findsOneWidget);
    expect(find.text('Field Responder'), findsOneWidget);

    // Tap on Field Responder in grid
    await tester.tap(find.text('Field Responder'));
    await tester.pumpAndSettle();
    expect(find.text('Open Tactical Field Portal'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
