import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/splash/presentation/views/splash_screen_view.dart';

void main() {
  group('Splash Screen Responsive & Asset Verification', () {
    test('1. Verify all generated splash variant files exist on disk', () {
      final requiredFiles = [
        // Flutter assets
        'assets/images/splash_screen_art.png',
        'assets/images/splash_screen_art_standard.png',
        'assets/images/splash_screen_art_modern.png',
        'assets/images/splash_screen_art_tall.png',
        'assets/images/splash_screen_art_tablet.png',
        'assets/images/splash_screen_art_wide.png',
        'assets/images/splash_screen_art_fold_inner.png',
        'assets/images/splash_screen_art_fold_cover.png',
        // Android drawables
        'android/app/src/main/res/drawable/launch_image.png',
        'android/app/src/main/res/drawable-v21/launch_image.png',
        'android/app/src/main/res/drawable-nodpi/launch_image.png',
        'android/app/src/main/res/drawable-long/launch_image.png',
        'android/app/src/main/res/drawable-land/launch_image.png',
        'android/app/src/main/res/drawable-sw600dp/launch_image.png',
        'android/app/src/main/res/drawable-sw720dp/launch_image.png',
        'android/app/src/main/res/drawable-nodpi/launch_splash_icon.png',
        // iOS launch images
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png',
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      ];

      for (final relPath in requiredFiles) {
        final f = File(relPath);
        expect(f.existsSync(), isTrue, reason: 'File must exist: $relPath');
        expect(f.lengthSync(), greaterThan(1000), reason: 'File must not be empty: $relPath');
      }
    });

    test('2. Verify resolveSplashAsset maps correct aspect ratios including Fold and Flip', () {
      // Landscape / Wide Desktop (16:9 = 1.777)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1920, 1080)),
        SplashScreenView.splashWidePath,
      );

      // Foldable Inner / Unfolded Screen (Galaxy Z Fold 4/5/6: 1812 x 2176, ratio 0.832; 1:1, ratio 1.0)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1812, 2176)),
        SplashScreenView.splashFoldInnerPath,
      );
      expect(
        SplashScreenView.resolveSplashAsset(const Size(2048, 2048)),
        SplashScreenView.splashFoldInnerPath,
      );

      // Tablet / iPad (3:4 = 0.75, 10:16 = 0.625)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1536, 2048)),
        SplashScreenView.splashTabletPath,
      );

      // Standard Mobile 16:9 (9:16 = 0.5625)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 1920)),
        SplashScreenView.splashStandardPath,
      );

      // Modern Flagship 19.5:9 (9:19.5 = 0.4615)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 2340)),
        SplashScreenView.splashModernPath,
      );

      // Ultra-Tall Modern 20:9 (9:20 = 0.45)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 2400)),
        SplashScreenView.splashTallPath,
      );

      // Foldable Outer Cover Screen (Galaxy Z Fold 5/6: 904 x 2316, ratio 0.390; 23.1:9)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(904, 2316)),
        SplashScreenView.splashFoldCoverPath,
      );

      // Flip Phone Unfolded (Galaxy Z Flip 5/6: 1080 x 2640, ratio 0.409; 22:9)
      expect(
        SplashScreenView.resolveSplashAsset(const Size(1080, 2640)),
        SplashScreenView.splashFoldCoverPath,
      );
    });

    testWidgets('3. Renders across multiple screen aspect ratios without overflows', (
      WidgetTester tester,
    ) async {
      final testSizes = [
        const Size(360, 800),   // 20:9 mobile
        const Size(390, 844),   // 19.5:9 iPhone 14
        const Size(412, 732),   // 16:9 standard
        const Size(768, 1024),  // 3:4 iPad
        const Size(1280, 720),  // 16:9 desktop
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreenView(),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SplashScreenView), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
    });
  });
}
