import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/features/chat/data/chat_service.dart';
import 'package:artist_dubai/features/chat/domain/models/artist_message_model.dart';
import 'package:artist_dubai/features/chat/presentation/views/artist_chat_view.dart';
import 'package:artist_dubai/features/chat/presentation/views/listing_plans_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class _TestHttpOverrides extends HttpOverrides {}

class MockChatApiClient implements ApiClient {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'status': 'success', 'data': []},
      statusCode: 200,
    );
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'status': 'success', 'data': {'id': '1'}},
      statusCode: 200,
    );
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response(requestOptions: RequestOptions(path: path), data: {}, statusCode: 200);
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response(requestOptions: RequestOptions(path: path), data: {}, statusCode: 200);
  }

  @override
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response(requestOptions: RequestOptions(path: path), data: {}, statusCode: 200);
  }
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await sl.reset();
    await initDependencyInjection();

    // Override ApiClient with immediate mock to avoid network timeouts in tests
    if (sl.isRegistered<ApiClient>()) {
      sl.unregister<ApiClient>();
    }
    sl.registerSingleton<ApiClient>(MockChatApiClient());
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

  group('ArtistMessageModel Tests', () {
    test('JSON serialization & deserialization works correctly', () {
      final now = DateTime.now();
      final model = ArtistMessageModel(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Allen Baiyee',
        senderEmail: 'allen@example.com',
        recipientId: 'artist_12',
        recipientName: 'Frankie DeChiazza',
        recipientCategory: 'Mixed Media',
        subject: 'Collaboration Inquiry',
        message: 'Hello, I loved your latest artwork in Dubai!',
        createdAt: now,
        isRead: false,
      );

      final json = model.toJson();
      expect(json['id'], 'msg_1');
      expect(json['recipient_name'], 'Frankie DeChiazza');
      expect(json['subject'], 'Collaboration Inquiry');

      final fromJson = ArtistMessageModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.senderName, model.senderName);
      expect(fromJson.recipientName, model.recipientName);
      expect(fromJson.subject, model.subject);
      expect(fromJson.message, model.message);
    });
  });

  group('ChatService Tests', () {
    test('Default monthly allowance starts at 10 and decrements with messages', () async {
      final chatService = sl<ChatService>();

      expect(chatService.getMaxMonthlyAllowance(), 10);
      expect(chatService.getRemainingAllowance(), 10);
      expect(chatService.canSendMessage(), isTrue);

      // Send a message
      final msg = await chatService.sendMessage(
        recipientId: 'artist_99',
        recipientName: 'Test Artist',
        recipientCategory: 'Photography',
        subject: 'Art Expo',
        message: 'Are you participating in the upcoming event?',
      );

      expect(msg.recipientName, 'Test Artist');
      expect(chatService.getRemainingAllowance(), 9);

      // Get messages list
      final list = await chatService.getMessages();
      expect(list.length, 1);
      expect(list.first.subject, 'Art Expo');
    });

    test('Upgrade plan increases maximum allowance', () async {
      final chatService = sl<ChatService>();
      await chatService.setMaxMonthlyAllowance(50);
      expect(chatService.getMaxMonthlyAllowance(), 50);
      expect(chatService.getRemainingAllowance(), 50);
    });
  });

  group('ListingPlansView Widget Tests', () {
    testWidgets('Renders all listing plans: Event, Gallery, and Art Centre', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHost(const ListingPlansView()));
      await tester.pump();

      expect(find.text('LISTING PLANS'), findsOneWidget);
      expect(find.text('Event Listing'), findsOneWidget);
      expect(find.text('199 AED'), findsOneWidget);
      expect(find.text('Gallery Listing'), findsOneWidget);
      expect(find.text('149 AED'), findsOneWidget);
      expect(find.text('Art Centre Listing'), findsOneWidget);
      expect(find.text('299 AED'), findsOneWidget);
      expect(find.text('Hosted by Nizar Fahem'), findsOneWidget);
    });
  });

  group('ArtistChatView Widget Tests', () {
    testWidgets('Renders allowance card and switches between Messages and Send tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHost(const ArtistChatView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check header & allowance
      expect(find.text('ARTIST CHAT'), findsOneWidget);
      expect(find.textContaining('10 of 10 messages left this month'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);

      // In Messages tab, empty state is displayed
      expect(find.text('No messages yet. Search for an artist in the Send tab to start a conversation.'), findsOneWidget);

      // Switch to Send tab
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check Send tab form elements
      expect(find.text('Send to Artist'), findsOneWidget);
      expect(find.text('Search artist by name...'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Write your message...'), findsOneWidget);
      expect(find.text('Attach a flyer image (optional)'), findsOneWidget);
      expect(find.text('Select an Artist First'), findsOneWidget);
    });
  });
}
