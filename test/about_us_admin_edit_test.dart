import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/about_us/presentation/views/about_us_view.dart';
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'admin@artistdubai.com',
      'user_name': 'Admin User',
      'user_role': 'admin',
    });
    await sl.reset();
    await initDependencyInjection();
  });

  Widget testApp(Widget child) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }

  testWidgets('AboutUsView renders platform content and quote callout properly', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(testApp(const AboutUsView()));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('ABOUT US'), findsOneWidget);
    // Verify Section 1
    expect(find.text('What does it mean to be an artist?'), findsOneWidget);
    // Verify Quote
    expect(
      find.text('“Art does not reproduce the visible; rather, it makes visible.”'),
      findsOneWidget,
    );
    // Verify Tagline
    expect(find.text('Because art has no borders.'), findsOneWidget);
  });

  testWidgets('AdminDashboardView navigates to About Us tab and displays editor', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(testApp(const AdminDashboardView()));
    await tester.pump(const Duration(milliseconds: 200));

    // Look for About Us tab button
    final aboutTabFinder = find.text('About Us');
    expect(aboutTabFinder, findsWidgets);

    // Tap About Us tab
    await tester.tap(aboutTabFinder.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify About Us Content Editor Header
    expect(find.text('About Us Content Editor'), findsOneWidget);
    expect(find.text('Save Changes'), findsWidgets);
    expect(find.text('Preview Page'), findsWidgets);
    expect(find.text('Reset Defaults'), findsWidgets);

    // Verify Language Toggles
    expect(find.text('English (EN)'), findsOneWidget);
    expect(find.text('العربية (AR)'), findsOneWidget);

    // Verify Section Cards
    expect(find.text('Main Page Title'), findsOneWidget);
    expect(find.text('Section 1: What Does It Mean To Be An Artist?'), findsOneWidget);
    expect(find.text('Featured Quote Callout Box'), findsOneWidget);
    expect(find.text('Platform Purpose & Collaboration'), findsOneWidget);
    expect(find.text('Cultural Fusion & Dubai Context'), findsOneWidget);
    expect(find.text('Vision & Closing Creed'), findsOneWidget);

    // Verify Bidirectional Auto-Sync Banner & Controls
    expect(find.text('Bidirectional Auto-Sync'), findsOneWidget);
    expect(find.text('Sync to AR'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('Bidirectional auto-sync translates between English and Arabic', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(testApp(const AdminDashboardView()));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap About Us tab
    final aboutTabFinder = find.text('About Us');
    await tester.tap(aboutTabFinder.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify English is initial tab
    expect(find.text('English (EN)'), findsOneWidget);

    // Enter English text in Main Page Title
    final titleTextField = find.widgetWithText(TextField, 'ABOUT US').first;
    expect(titleTextField, findsOneWidget);

    await tester.enterText(titleTextField, 'Visual Arts');
    // Allow debounce timer (600ms) to fire and translate
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // 2. Switch to Arabic tab
    final arTabFinder = find.text('العربية (AR)');
    await tester.tap(arTabFinder);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // Arabic title should now be 'الفنون البصرية' (translated from 'Visual Arts')
    expect(find.text('الفنون البصرية'), findsWidgets);

    // 3. Edit Arabic text in Arabic tab
    final arTitleField = find.widgetWithText(TextField, 'الفنون البصرية').first;
    expect(arTitleField, findsOneWidget);

    await tester.enterText(arTitleField, 'الرسم المعاصر');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // Switch back to English tab
    final enTabFinder = find.text('English (EN)');
    await tester.tap(enTabFinder);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // English title should now be translated back to 'Contemporary Painting'
    expect(find.text('Contemporary Painting'), findsWidgets);
  });
}

