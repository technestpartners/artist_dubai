import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/payment/presentation/views/plan_payment_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('PlanPaymentView Standalone Checkout Page Tests', () {
    testWidgets('PlanPaymentView renders complete checkout UI with QR, bank, and proof fields', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true, 'role': 'user'});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlanPaymentView(
            args: {
              'itemType': 'event',
              'title': 'Dubai Contemporary Art Fair 2026',
              'subtitle': 'Alserkal Avenue, Dubai',
              'planId': 'monthly',
              'planName': 'Monthly Plan',
              'planAmount': 'AED 500',
              'formData': {
                'title': 'Dubai Contemporary Art Fair 2026',
                'location': 'Alserkal Avenue, Dubai',
              },
            },
          ),
        ),
      );
      await tester.pump();

      // Check header and step indicators
      expect(find.text('Payment & Checkout'), findsOneWidget);
      expect(find.text('Step 2 of 2: Payment & Verification'), findsOneWidget);
      expect(find.text('Scan the QR code or transfer via IBAN, then attach your receipt'), findsOneWidget);

      // Check Order Summary card
      expect(find.text('EVENT PUBLISHING'), findsOneWidget);
      expect(find.text('Dubai Contemporary Art Fair 2026'), findsOneWidget);
      expect(find.text('Alserkal Avenue, Dubai'), findsOneWidget);
      expect(find.text('AED 500'), findsWidgets);

      // Check QR code card
      expect(find.text('Scan QR to Pay'), findsOneWidget);
      expect(find.text('Scan using your UAE Banking app, Apple Pay, Google Pay, or QR reader'), findsOneWidget);

      // Check Bank details
      expect(find.text('Direct Bank Transfer Details'), findsOneWidget);
      expect(find.text('Bank Name: '), findsOneWidget);
      expect(find.text('Account Title: '), findsOneWidget);
      expect(find.text('IBAN / Account #: '), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Check Payment Verification fields
      expect(find.text('Payment Verification & Proof'), findsOneWidget);
      expect(find.text('Transaction Reference / ID (Optional)'), findsOneWidget);
      expect(find.text('Attach Transfer Receipt'), findsOneWidget);

      // Check Action button
      expect(find.widgetWithText(ElevatedButton, 'Confirm & Submit Listing (AED 500)'), findsOneWidget);
    });

    testWidgets('PlanPaymentView shows confirmation dialog if submitted without proof', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true, 'role': 'user'});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlanPaymentView(
            args: {
              'itemType': 'gallery',
              'title': 'Modern Canvas Dubai',
              'subtitle': 'DIFC Gate Village',
              'planId': 'weekly',
              'planName': 'Weekly Plan',
              'planAmount': 'AED 200',
              'formData': {
                'name': 'Modern Canvas Dubai',
              },
            },
          ),
        ),
      );
      await tester.pump();

      // Tap submit button directly without filling transaction ID or uploading proof
      final submitButton = find.widgetWithText(ElevatedButton, 'Confirm & Submit Listing (AED 200)');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pump();

      // Dialog should alert user about missing proof with options
      expect(find.text('No Payment Proof Attached'), findsOneWidget);
      expect(find.text('Attach Receipt'), findsOneWidget);
      expect(find.text('Submit Anyway'), findsOneWidget);
    });
  });
}
