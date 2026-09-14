import 'dart:io';
import 'package:artist_dubai/app/app.dart';
import 'package:artist_dubai/app/routes/app_router.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/splash/presentation/views/splash_screen_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'has_completed_onboarding': true});
    await sl.reset();
    await initDependencyInjection();
  });

  testWidgets('Test natural router initialization', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();

    expect(AppRouter.router.state.uri.toString(), isNotEmpty);
    expect(find.byType(SplashScreenView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pumpAndSettle();

    expect(AppRouter.router.state.uri.toString(), '/home');
  });

  testWidgets('Test direct navigation to /artist/1', (WidgetTester tester) async {
    AppRouter.router.go('/artist/1');
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(AppRouter.router.state.uri.toString(), '/artist/1');
  });

  testWidgets('Test direct navigation to /event-detail?id=1', (WidgetTester tester) async {
    AppRouter.router.go('/event-detail?id=1');
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(AppRouter.router.state.uri.toString(), '/event-detail?id=1');
  });

  testWidgets('Test alias redirect /artist?id=2 -> /artist/2', (WidgetTester tester) async {
    AppRouter.router.go('/artist?id=2');
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(AppRouter.router.state.uri.toString(), '/artist/2');
  });

  testWidgets('Test alias redirect /event/3 -> /event-detail?id=3', (WidgetTester tester) async {
    AppRouter.router.go('/event/3');
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(AppRouter.router.state.uri.toString(), '/event-detail?id=3');
  });
}
