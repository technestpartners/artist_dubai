import 'dart:io';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/splash/presentation/views/splash_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('Splash Screen Responsive Aspect-Ratio Test Suite', () {
    test('1. Aspect-Ratio Asset Selection for All Device Screen Classes', () {
      // Ultra-tall screens (9:20, 9:21, 9:22 -> e.g. Samsung Galaxy S23/S24, Sony Xperia)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 2400)),
        SplashScreenView.splashTallPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(360, 800)),
        SplashScreenView.splashTallPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 2520)),
        SplashScreenView.splashTallPath,
      );

      // Modern flagship screens (9:19.5 -> iPhone 13/14/15/16 Pro & Max, Pixel 8/9)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1179, 2556)),
        SplashScreenView.splashModernPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(393, 852)),
        SplashScreenView.splashModernPath,
      );

      // Classic standard smartphones (9:16 -> iPhone SE, older Android phones)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 1920)),
        SplashScreenView.splashStandardPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(360, 640)),
        SplashScreenView.splashStandardPath,
      );

      // Tablets & Foldables (3:4, 4:3 -> iPad mini/Air/Pro, Galaxy Tab)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1536, 2048)),
        SplashScreenView.splashTabletPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(768, 1024)),
        SplashScreenView.splashTabletPath,
      );

      // Desktop / Web / Landscape (16:9, 16:10)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1920, 1080)),
        SplashScreenView.splashWidePath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1440, 900)),
        SplashScreenView.splashWidePath,
      );

      // Edge case: zero size fallback
      expect(
        SplashScreenView.resolveSplashAsset(Size.zero),
        SplashScreenView.splashImagePath,
      );
    });

    test('2. All Aspect Ratio Splash Image Assets Exist on Disk', () {
      final assets = [
        SplashScreenView.splashTallPath,
        SplashScreenView.splashModernPath,
        SplashScreenView.splashStandardPath,
        SplashScreenView.splashTabletPath,
        SplashScreenView.splashWidePath,
        SplashScreenView.splashImagePath,
      ];

      for (final asset in assets) {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: 'Asset missing: $asset');
        expect(file.lengthSync(), greaterThan(10000), reason: 'Asset empty: $asset');
      }
    });

    testWidgets('3. SplashScreenView Renders Gracefully across All Device Viewports', (
      WidgetTester tester,
    ) async {
      final viewports = [
        const Size(360, 800),   // 9:20 Tall Android
        const Size(393, 852),   // 9:19.5 Modern iPhone
        const Size(360, 640),   // 9:16 Classic Phone
        const Size(768, 1024),  // 3:4 iPad / Tablet
        const Size(1920, 1080), // 16:9 Desktop Landscape
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreenView(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SplashScreenView), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
    });
  });
}
