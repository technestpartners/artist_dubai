import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/app/app.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencyInjection();
  });

  testWidgets('Onboarding, Home Dashboard & About Us navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pumpAndSettle();

    // Verify Onboarding Screen
    expect(find.text('Welcome to Dubai Artists'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Skip -> Navigates to Home Dashboard
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify Home Dashboard Header
    expect(find.text('ARTIST DUBAI'), findsOneWidget);
    expect(find.text('COMMUNITY PLATFORM'), findsOneWidget);

    // Verify Visible Dashboard Cards
    expect(find.text('ABOUT US'), findsOneWidget);
    expect(find.text('ARTISTS'), findsOneWidget);
    expect(find.text('GOVERNMENT'), findsOneWidget);
    expect(find.text('Hosted by Nizar Fahem'), findsOneWidget);

    // Tap ABOUT US -> Navigates to About Us Screen
    await tester.tap(find.text('ABOUT US'));
    await tester.pumpAndSettle();

    // Verify About Us screen content
    expect(find.text('Content to be provided.'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
    expect(find.text('Dubai'), findsOneWidget);
  });
}
