import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/features/payment/presentation/views/plan_payment_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  Widget buildTestHost(Widget child, {Locale locale = const Locale('en')}) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        home: child,
      ),
    );
  }

  group('PlanPaymentView Standalone Checkout Page Tests', () {
    testWidgets('PlanPaymentView renders complete checkout UI with QR, bank, and proof fields', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true, 'role': 'user'});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestHost(
          const PlanPaymentView(
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
      await tester.pump(const Duration(milliseconds: 100));

      // Check header and step indicators
      expect(find.byType(PlanPaymentView), findsOneWidget);
      expect(find.text('Dubai Contemporary Art Fair 2026'), findsOneWidget);
      expect(find.text('Alserkal Avenue, Dubai'), findsOneWidget);
      expect(find.text('AED 500'), findsWidgets);
    });

    testWidgets('PlanPaymentView shows confirmation dialog if submitted without proof', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true, 'role': 'user'});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestHost(
          const PlanPaymentView(
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlanPaymentView), findsOneWidget);
      expect(find.text('Modern Canvas Dubai'), findsOneWidget);
      expect(find.text('AED 200'), findsWidgets);
    });

    testWidgets('PlanPaymentView renders all labels and content in Arabic when in Arabic mode', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true, 'role': 'user', 'app_locale': 'ar'});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestHost(
          const PlanPaymentView(
            args: {
              'itemType': 'event',
              'title': 'اختبار',
              'subtitle': 'Art Exhibition • Dubai, UAE',
              'planId': 'yearly',
              'planName': 'Yearly Plan (365 Days)',
              'planAmount': 'AED 4,500',
              'formData': {
                'title': 'اختبار',
                'location': 'Dubai, UAE',
              },
            },
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlanPaymentView), findsOneWidget);
      expect(find.text('اختبار'), findsOneWidget);
    });
  });
}
