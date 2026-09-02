import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/login_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_artist_profile_view.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_category_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/gallery_registration_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/book_artist_view.dart';
import 'package:artist_dubai/features/profile/presentation/views/profile_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'renish@gmail.com',
      'user_name': 'Renish Artistry',
      'has_completed_onboarding': true,
    });
    await sl.reset();
    await initDependencyInjection();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData(useMaterial3: true),
    );
  }

  group('Frontend All Forms & Data Entry Comprehensive Verification', () {
    testWidgets('1. RegisterView Data Entry Form UI & Submission Elements', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const RegisterView()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('Create Account'), findsWidgets);

      await tester.enterText(find.byType(TextField).at(0), 'Fatima Calligrapher');
      await tester.enterText(find.byType(TextField).at(1), 'fatima.new@artistdubai.com');
      await tester.enterText(find.byType(TextField).at(2), 'Pass@123456');
      await tester.enterText(find.byType(TextField).at(3), 'Pass@123456');
      await tester.pump();

      expect(find.text('Fatima Calligrapher'), findsOneWidget);
    });

    testWidgets('2. LoginView Data Entry Form UI & Submission Elements', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const LoginView()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Sign In'), findsWidgets);

      await tester.enterText(find.byType(TextField).at(0), 'renish@gmail.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();

      expect(find.text('renish@gmail.com'), findsOneWidget);
    });

    testWidgets('3. CreateArtistProfileView Data Entry Form UI & Inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const CreateArtistProfileView()));
      await tester.pumpAndSettle();

      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Zayd Al-Nuaimi');
        await tester.pump();
        expect(find.text('Zayd Al-Nuaimi'), findsOneWidget);
      }
    });

    testWidgets('4. CreateArtEventView Data Entry Form UI & Inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const CreateArtEventView()));
      await tester.pumpAndSettle();

      expect(find.text('Event Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Dubai Generative Expo 2026');
        await tester.pump();
        expect(find.text('Dubai Generative Expo 2026'), findsOneWidget);
      }
    });

    testWidgets('5. CreateCategoryView Data Entry Form UI & Inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const CreateCategoryView()));
      await tester.pumpAndSettle();

      expect(find.text('Category Name *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Glass & Mosaic Art');
        await tester.pump();
        expect(find.text('Glass & Mosaic Art'), findsWidgets);
      }
    });

    testWidgets('6. GalleryRegistrationView Data Entry Form UI & Inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const GalleryRegistrationView()));
      await tester.pumpAndSettle();

      expect(find.text('GALLERIES | ART CENTERS'), findsOneWidget);
      expect(find.text('Registration received'), findsOneWidget);
      expect(find.text('Back to home'), findsOneWidget);
    });

    testWidgets('7. BookArtistView Data Entry Form UI & Inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const BookArtistView()));
      await tester.pumpAndSettle();

      expect(find.text('Book an Artist'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Sheikh Zayed Cultural Group');
        await tester.pump();
        expect(find.text('Sheikh Zayed Cultural Group'), findsOneWidget);
      }
    });

    testWidgets('8. ProfileView Account Settings & Edit Profile UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const ProfileView()));
      await tester.pumpAndSettle();

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile Details'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
