import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen builds and renders with updated sizing and layout', (tester) async {
    // Test on standard mobile display (390 x 844)
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    // Verify Brand Header
    expect(find.text('Safer Routes • Real-Time Alert • Stronger Communities'), findsOneWidget);

    // Verify Login Card header
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('New Account'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to continue to ResQShield'), findsOneWidget);

    // Verify enlarged Remember Me and Forgot Password
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Verify Login button
    expect(find.text('Login'), findsOneWidget);

    // Verify enlarged Google and Apple social buttons
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    // Verify Security footer
    expect(find.text('Secure Government Portal'), findsOneWidget);

    // Tap Remember me to toggle
    await tester.tap(find.text('Remember me'));
    await tester.pump();
  });

  testWidgets('LoginScreen renders cleanly on compact viewport without overflow', (tester) async {
    // Compact mobile viewport
    tester.view.physicalSize = const Size(720, 1440);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('LoginScreen renders doubled width container center-aligned on wide desktop', (tester) async {
    // Wide desktop viewport (1280 x 800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Verify AnimatedContainer exists and has the doubled width (960px)
    final animatedContainerFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedContainer && widget.constraints?.maxWidth == 960.0 ||
          (widget is SizedBox && widget.width == 960.0),
    );
    expect(animatedContainerFinder, findsWidgets);

    // Verify it is centered
    final centerFinder = find.ancestor(
      of: animatedContainerFinder.first,
      matching: find.byType(Center),
    );
    expect(centerFinder, findsWidgets);
  });
}

