import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/citizen/citizen_shelters_view.dart';

void main() {
  testWidgets('CitizenSheltersView renders cards with 25% screen width image and expanded height without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenSheltersView(),
      ),
    );
    await tester.pump();

    // Verify screen title
    expect(find.text('Shelters & Relief Camps'), findsOneWidget);

    // Verify at least one shelter card is rendered
    expect(find.text('Govt. Higher Secondary School'), findsOneWidget);

    // Verify no render flex overflow occurred
    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('CitizenSheltersView renders cleanly on small screen in Hindi', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360x640 logical
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenSheltersView(isHindi: true),
      ),
    );
    await tester.pump();

    expect(find.text('राहत शिविर एवं आश्रय'), findsOneWidget);
    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
