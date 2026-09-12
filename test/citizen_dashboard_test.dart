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

  testWidgets('CitizenDashboardScreen back button navigates to RoleSelectionScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find back arrow in AppBar
    final backButton = find.byIcon(Icons.arrow_back_rounded);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Verify RoleSelectionScreen is displayed instead of login
    expect(find.text('Select Your Role'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Flood warning card zoom + and - buttons update map scale indicator', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify active alert buttons exist with their labels
    expect(find.text('View Alert →'), findsOneWidget);
    expect(find.text('Safety Instructions >'), findsOneWidget);

    // Scroll until zoom controls are visible
    final zoomInBtn = find.byKey(const Key('alert_map_zoom_in'));
    await tester.scrollUntilVisible(
      zoomInBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(zoomInBtn, findsOneWidget);
    // Initial scale text is '2 km'
    expect(find.text('2 km'), findsOneWidget);

    // Tap zoom in (+) button
    await tester.tap(zoomInBtn);
    await tester.pumpAndSettle();

    // At zoom 1.25, scale changes to '1.5 km'
    expect(find.text('1.5 km'), findsOneWidget);

    // Tap zoom in (+) again -> 1.50 -> '1 km'
    await tester.tap(zoomInBtn);
    await tester.pumpAndSettle();
    expect(find.text('1 km'), findsOneWidget);

    // Tap zoom out (-) -> 1.25 -> '1.5 km'
    final zoomOutBtn = find.byKey(const Key('alert_map_zoom_out'));
    expect(zoomOutBtn, findsOneWidget);
    await tester.tap(zoomOutBtn);
    await tester.pumpAndSettle();
    expect(find.text('1.5 km'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Government Relief Centre displays 62% capacity and 4 supply chips', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll until Government Relief Centre is visible
    await tester.scrollUntilVisible(
      find.text('Government Relief Centre'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Government Relief Centre title and capacity
    expect(find.text('Government Relief Centre'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);

    // Verify all 4 supply chips are rendered: Food, Water, Medical, Power
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Medical'), findsAtLeastNWidgets(1));
    expect(find.text('Power'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Alert card contains real detailed map and weather forecast has hourly outlook without map', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Active Alert Card has the detailed map with Doppler radar and river hazard
    expect(find.text('Heavy Rainfall + Rising River Alert'), findsOneWidget);
    expect(find.text('LIVE DOPPLER RADAR'), findsOneWidget);
    expect(find.textContaining('Damodar: 214.6m'), findsOneWidget);
    expect(find.textContaining('68 mm/h'), findsAtLeastNWidgets(1));

    // Verify map controls (+, -, radar toggle, recenter)
    expect(find.byKey(const Key('alert_map_zoom_in')), findsOneWidget);
    expect(find.byKey(const Key('alert_map_zoom_out')), findsOneWidget);
    expect(find.byKey(const Key('rain_map_radar_toggle')), findsOneWidget);
    expect(find.byKey(const Key('rain_map_recenter')), findsOneWidget);

    // Scroll to map controls and tap radar toggle
    await tester.scrollUntilVisible(
      find.byKey(const Key('rain_map_radar_toggle')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rain_map_radar_toggle')), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 2. Scroll to Weather & Rain Forecast card and verify hourly outlook without map
    await tester.scrollUntilVisible(
      find.text('Heavy rainfall expected today'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Heavy rainfall expected today'), findsOneWidget);
    expect(find.text('View Forecast'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('+1 hr'), findsOneWidget);
    expect(find.text('+2 hr'), findsOneWidget);
    expect(find.text('+3 hr'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Local Conditions card displays circular icons, live report badge, and telemetry metrics', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll until Local Conditions card is visible
    await tester.scrollUntilVisible(
      find.text('LOCAL CONDITIONS (YOUR AREA)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('LOCAL CONDITIONS (YOUR AREA)'), findsOneWidget);
    expect(find.text('Live Report'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsAtLeastNWidgets(1));

    // Verify all 4 tiles
    expect(find.text('Rainfall'), findsOneWidget);
    expect(find.text('Heavy'), findsOneWidget);
    expect(find.text('Continuous'), findsOneWidget);
    expect(find.byIcon(Icons.cloudy_snowing), findsAtLeastNWidgets(1));

    expect(find.text('River Level'), findsOneWidget);
    expect(find.text('Rising rapidly'), findsOneWidget);
    expect(find.text('Damodar River'), findsOneWidget);
    expect(find.byIcon(Icons.waves_rounded), findsAtLeastNWidgets(1));

    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
    expect(find.text('Humidity: 94%'), findsOneWidget);
    expect(find.byIcon(Icons.thermostat_rounded), findsAtLeastNWidgets(1));

    expect(find.text('Wind Speed'), findsOneWidget);
    expect(find.text('18 km/h'), findsOneWidget);
    expect(find.text('Heading East'), findsOneWidget);
    expect(find.byIcon(Icons.air_rounded), findsAtLeastNWidgets(1));

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}



