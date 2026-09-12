import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/screens/authority_verification_screen.dart';
import 'package:resqshield/screens/field_responder_verification_screen.dart';
import 'package:resqshield/screens/technical_admin_verification_screen.dart';
import 'package:resqshield/screens/otp_screen.dart';

void main() {
  group('Authorization & OTP Screens Card Width & Background Tests', () {
    testWidgets('AuthorityVerificationScreen mounts cleanly on desktop and mobile', (tester) async {
      // Desktop viewport (1280 wide)
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: AuthorityVerificationScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Authority Authorization'), findsOneWidget);
      expect(find.text('Continue to Phone OTP'), findsOneWidget);

      // Verify that SizedBox constraints do not exceed 960 width
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCardWidthSizedBox = sizedBoxes.any((box) => box.width != null && box.width! <= 960.0 && box.width! > 500.0);
      expect(hasCardWidthSizedBox, isTrue);
    });

    testWidgets('FieldResponderVerificationScreen mounts cleanly and has citizen login background', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: FieldResponderVerificationScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Field Responder Authorization'), findsOneWidget);
      expect(find.text('Verify & Request Tactical OTP'), findsOneWidget);

      // Verify card width limit <= 960
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCardWidthSizedBox = sizedBoxes.any((box) => box.width != null && box.width! <= 960.0 && box.width! > 500.0);
      expect(hasCardWidthSizedBox, isTrue);

      // Verify background image is screen_bg_1.png (Citizen Login background)
      final imageWidgets = tester.widgetList<Image>(find.byType(Image));
      final hasBg1 = imageWidgets.any((img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/screen_bg_1.png');
      expect(hasBg1, isTrue);
    });

    testWidgets('TechnicalAdminVerificationScreen mounts cleanly and has citizen login background', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TechnicalAdminVerificationScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Technical Admin Console'), findsOneWidget);
      expect(find.text('Verify & Request Admin OTP'), findsOneWidget);

      // Verify card width limit <= 960
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCardWidthSizedBox = sizedBoxes.any((box) => box.width != null && box.width! <= 960.0 && box.width! > 500.0);
      expect(hasCardWidthSizedBox, isTrue);

      // Verify background image is screen_bg_1.png (Citizen Login background)
      final imageWidgets = tester.widgetList<Image>(find.byType(Image));
      final hasBg1 = imageWidgets.any((img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/screen_bg_1.png');
      expect(hasBg1, isTrue);
    });

    testWidgets('Citizen WaterWavesScreen (OTP) renders 2-column layout on desktop with side graphic and security message', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WaterWavesScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text("We've sent a 6-digit code to"), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text("Didn't receive the code?"), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
      expect(find.text('Your Security Matters'), findsOneWidget);
      expect(find.text('Please enter the OTP to verify your identity and continue safely.'), findsOneWidget);

      // Verify card width limit <= 960
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCardWidthSizedBox = sizedBoxes.any((box) => box.width != null && box.width! <= 960.0 && box.width! > 500.0);
      expect(hasCardWidthSizedBox, isTrue);

      // Verify background image is screen_bg_2.png
      final imageWidgets = tester.widgetList<Image>(find.byType(Image));
      final hasBg2 = imageWidgets.any((img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/screen_bg_2.png');
      expect(hasBg2, isTrue);
    });

    testWidgets('Citizen WaterWavesScreen (OTP) renders cleanly without overflow on compact mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WaterWavesScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text("We've sent a 6-digit code to"), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
    });

    testWidgets('Citizen WaterWavesScreen (OTP) phone shows locked state initially and unlocks with tick when all 6 digits entered', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WaterWavesScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Initial state: phone is locked
      expect(find.text('DEVICE LOCKED'), findsOneWidget);
      expect(find.text('Enter 6-digit OTP'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('UNLOCKED'), findsNothing);

      // Enter 6 digits into the text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Allow AnimatedSwitcher transition to fully complete
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 200));

      // Unlocked state: phone shows UNLOCKED and Identity Verified tick
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('Identity Verified ✓'), findsOneWidget);
      expect(find.text('DEVICE LOCKED'), findsNothing);
      expect(find.text('Identity Confirmed'), findsOneWidget);
    });
  });
}
