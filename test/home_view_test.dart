import 'dart:io';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/features/home/domain/models/menu_card_item.dart';
import 'package:artist_dubai/features/home/presentation/views/home_view.dart';
import 'package:artist_dubai/features/home/presentation/widgets/menu_card_widget.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencyInjection();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeView(),
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }

  group('HomeView 10-Button Layout & Responsiveness', () {
    test('MenuCardItem.items contains 10 items with LOGIN left and AI right', () {
      final items = MenuCardItem.items;
      expect(items.length, 10);
      expect(items[8].title, 'LOGIN');
      expect(items[8].routeName, '/login');
      expect(items[9].title, 'AI');
      expect(items[9].subtitle, 'Art | Artist');
      expect(items[9].routeName, '/ai');
    });

    testWidgets('Renders all 10 buttons with exact equal size on mobile (390x844)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cardFinders = find.byType(MenuCardWidget);
      expect(cardFinders, findsNWidgets(10));

      // Verify LOGIN is left and AI is right in Row 5
      final loginCard = tester.widget<MenuCardWidget>(cardFinders.at(8));
      final aiCard = tester.widget<MenuCardWidget>(cardFinders.at(9));
      expect(loginCard.item.title, 'LOGIN');
      expect(aiCard.item.title, 'AI');

      // Verify all 10 cards have the EXACT same size
      final firstSize = tester.getSize(cardFinders.at(0));
      for (int i = 1; i < 10; i++) {
        final cardSize = tester.getSize(cardFinders.at(i));
        expect(cardSize.width, closeTo(firstSize.width, 0.01),
            reason: 'Card $i width must match card 0 width');
        expect(cardSize.height, closeTo(firstSize.height, 0.01),
            reason: 'Card $i height must match card 0 height');
      }

      // Verify no scrolling widget is active
      expect(find.byType(SingleChildScrollView), findsNothing);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Fits compact short screen (375x667 - iPhone SE) without overflow or scrolling', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cardFinders = find.byType(MenuCardWidget);
      expect(cardFinders, findsNWidgets(10));

      final firstSize = tester.getSize(cardFinders.at(0));
      for (int i = 1; i < 10; i++) {
        final cardSize = tester.getSize(cardFinders.at(i));
        expect(cardSize.width, closeTo(firstSize.width, 0.01));
        expect(cardSize.height, closeTo(firstSize.height, 0.01));
      }

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet layout (768x1024) renders 2 rows x 5 columns with equal size buttons', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cardFinders = find.byType(MenuCardWidget);
      expect(cardFinders, findsNWidgets(10));

      final firstSize = tester.getSize(cardFinders.at(0));
      for (int i = 1; i < 10; i++) {
        final cardSize = tester.getSize(cardFinders.at(i));
        expect(cardSize.width, closeTo(firstSize.width, 0.01));
        expect(cardSize.height, closeTo(firstSize.height, 0.01));
      }

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('When user is logged in, card shows LOGOUT and tap shows logout dialog', (
      WidgetTester tester,
    ) async {
      await sl<StorageService>().setBool('is_logged_in', true);
      await sl<StorageService>().setString('user_name', 'Test Artist');
      await sl<StorageService>().setString('user_email', 'artist@example.com');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cardFinders = find.byType(MenuCardWidget);
      final logoutCard = tester.widget<MenuCardWidget>(cardFinders.at(8));
      expect(logoutCard.item.title, 'LOGOUT');
      expect(find.text('LOGOUT'), findsOneWidget);

      // Tap the LOGOUT card
      await tester.tap(cardFinders.at(8));
      await tester.pumpAndSettle();

      // Verify logout dialog is displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Sign Out'), findsAtLeastNWidgets(1));
      expect(find.text('artist@example.com'), findsOneWidget);
      expect(find.text('Are you sure you want to log out of your account?'), findsOneWidget);

      // Tap Sign Out button in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify user is now logged out and card reverted to LOGIN
      expect(sl<StorageService>().getBool('is_logged_in'), false);
      expect(find.text('LOGIN'), findsOneWidget);
    });
  });
}
