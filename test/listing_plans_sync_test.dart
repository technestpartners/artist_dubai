import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/features/chat/presentation/views/listing_plans_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _TestHttpOverrides extends HttpOverrides {}

class MockListingApiClient implements ApiClient {
  List<Map<String, dynamic>> plansDb = [
    {
      'id': 1,
      'item_type': 'event',
      'title': 'Event Listing',
      'category': 'Events',
      'badge': 'One-time',
      'price': '199 AED',
      'description': 'Publish a single event on Artist Dubai.',
      'features': [
        'One event listing',
        'Visible in Events and calendar',
        'Gallery photos included',
      ],
      'button_text': 'Pay from My Listings',
      'is_active': 1,
      'sort_order': 1,
    },
    {
      'id': 2,
      'item_type': 'gallery',
      'title': 'Gallery Listing',
      'category': 'Galleries',
      'badge': 'One-time',
      'price': '149 AED',
      'description': 'Publish a single gallery on Artist Dubai.',
      'features': [
        'One gallery listing',
        'Unlimited images',
        'Shareable gallery page',
      ],
      'button_text': 'Pay from My Listings',
      'is_active': 1,
      'sort_order': 2,
    },
    {
      'id': 3,
      'item_type': 'art_centre',
      'title': 'Art Centre Listing',
      'category': 'Art Centres',
      'badge': 'One-time',
      'price': '299 AED',
      'description': 'Publish a single art centre on Artist Dubai.',
      'features': [
        'One art centre listing',
        'Verified venue badge',
        'Direct booking inquiry button',
      ],
      'button_text': 'Pay from My Listings',
      'is_active': 1,
      'sort_order': 3,
    },
  ];

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return {'status': 'success', 'data': plansDb};
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    if (data is Map && data['action'] == 'update') {
      final index = plansDb.indexWhere((p) => p['id'] == data['id'] || p['item_type'] == data['item_type']);
      if (index != -1) {
        plansDb[index] = {
          ...plansDb[index],
          ...Map<String, dynamic>.from(data),
        };
      }
      return {'status': 'success', 'data': {'updated': true}};
    }
    return {'status': 'success'};
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return {'status': 'success'};
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return {'status': 'success'};
  }

  @override
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return {'status': 'success'};
  }
}

void main() {
  late MockListingApiClient mockClient;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'is_logged_in': true, 'user_role': 'admin'});
    await sl.reset();
    await initDependencyInjection();

    mockClient = MockListingApiClient();
    if (sl.isRegistered<ApiClient>()) {
      await sl.unregister<ApiClient>();
    }
    sl.registerLazySingleton<ApiClient>(() => mockClient);
  });

  Widget buildTestHost(Widget child) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  test('ApiService getListingPlans and updateListingPlan connects and updates', () async {
    final api = sl<ApiService>();
    final plans = await api.getListingPlans(forceRefresh: true);
    expect(plans.length, 3);
    expect(plans[0].title, 'Event Listing');
    expect(plans[0].price, '199 AED');

    final updated = await api.updateListingPlan(
      id: 1,
      itemType: 'event',
      title: 'Event Listing VIP',
      category: 'Events',
      badge: 'Popular',
      price: '249 AED',
      description: 'Updated description for VIP event.',
      features: ['Feature 1', 'Feature 2'],
    );
    expect(updated, true);

    final refreshedPlans = await api.getListingPlans(forceRefresh: true);
    expect(refreshedPlans[0].title, 'Event Listing VIP');
    expect(refreshedPlans[0].price, '249 AED');
    expect(refreshedPlans[0].badge, 'Popular');
  });

  testWidgets('ListingPlansView receives dynamic updates via LiveSync', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestHost(const ListingPlansView()));
    await tester.pumpAndSettle();

    expect(find.text('LISTING PLANS'), findsOneWidget);
    expect(find.text('Event Listing'), findsOneWidget);
    expect(find.text('199 AED'), findsOneWidget);

    // Now update plan via ApiService (simulating Admin edit)
    await sl<ApiService>().updateListingPlan(
      id: 1,
      itemType: 'event',
      title: 'Exclusive Event Listing',
      category: 'Events',
      badge: 'Featured',
      price: '350 AED',
      description: 'Premium event listing in Dubai.',
      features: ['Priority calendar placement', 'Social shoutout'],
    );

    await tester.pumpAndSettle();

    expect(find.text('Exclusive Event Listing'), findsOneWidget);
    expect(find.text('350 AED'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
  });
}
