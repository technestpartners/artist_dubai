import 'dart:convert';
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

    testWidgets('Tapping Plans opens Chat Allowance Plans modal and allows upgrade', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHost(const ArtistChatView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('10 of 10 messages left this month'), findsOneWidget);

      // Tap Plans button
      await tester.tap(find.text('Plans'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal is open
      expect(find.text('Chat Allowance Plans'), findsOneWidget);
      expect(find.text('Starter Plan'), findsOneWidget);
      expect(find.text('Pro Artist'), findsOneWidget);
      expect(find.text('Unlimited VIP'), findsOneWidget);
      expect(find.text('49 AED'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);

      // Tap Upgrade to Pro
      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal closed and allowance card updated
      expect(sl<ChatService>().getMaxMonthlyAllowance(), 50);
      expect(find.textContaining('50 of 50 messages left this month'), findsOneWidget);
    });

    testWidgets('Displays incoming messages with sender info and allows opening details with Reply button', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Prepopulate an incoming message in local storage
      final now = DateTime.now();
      final incomingMessage = ArtistMessageModel(
        id: 'msg_incoming_1',
        senderId: 'artist_42',
        senderName: 'Sara Al Khateeb',
        senderEmail: 'sara@artdubai.com',
        recipientId: 'my_artist_1',
        recipientName: 'My Profile',
        recipientCategory: 'Calligraphy',
        subject: 'Exhibition Invite',
        message: 'We would love to feature your recent calligraphic sculptures.',
        createdAt: now,
        isRead: false,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', 'myprofile@artdubai.com');
      await prefs.setString('artist_profile_id', 'my_artist_1');
      await prefs.setString('artist_chat_messages', jsonEncode([incomingMessage.toJson()]));

      await tester.pumpWidget(buildTestHost(const ArtistChatView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check if pills are shown
      expect(find.textContaining('All (1)'), findsOneWidget);
      expect(find.textContaining('Inbox (1)'), findsOneWidget);
      expect(find.textContaining('Sent (0)'), findsOneWidget);

      // Verify that the incoming message shows 'From: Sara Al Khateeb'
      expect(find.textContaining('From: Sara Al Khateeb'), findsOneWidget);
      expect(find.text('Exhibition Invite'), findsOneWidget);
      expect(find.text('Inbox'), findsWidgets);

      // Tap message to open detail modal
      await tester.tap(find.text('Exhibition Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Modal is open, showing sender email, full message, and Reply button
      expect(find.text('sara@artdubai.com'), findsOneWidget);
      expect(find.text('We would love to feature your recent calligraphic sculptures.'), findsWidgets);
      expect(find.text('Reply'), findsOneWidget);

      // Tap Reply button
      await tester.tap(find.text('Reply'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switches to Send tab with recipient set and prefilled subject
      expect(find.text('Send to Artist'), findsOneWidget);
      expect(find.textContaining('Sara Al Khateeb'), findsOneWidget);
      expect(find.text('Re: Exhibition Invite'), findsOneWidget);
    });

    testWidgets('Displays sent messages, opens detail modal with recipient info and allows Reply/Follow-up', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final sentMessage = ArtistMessageModel(
        id: 'msg_sent_1',
        senderId: 'my_artist_1',
        senderName: 'My Profile',
        senderEmail: 'myprofile@artdubai.com',
        recipientId: 'admin_1',
        recipientName: 'Dubai Art Administrator',
        recipientCategory: 'Arabic Calligraphy',
        subject: 'Inquiry',
        message: 'Hello, checking on the submission status.',
        createdAt: now,
        isRead: true,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', 'myprofile@artdubai.com');
      await prefs.setString('artist_profile_id', 'my_artist_1');
      await prefs.setString('artist_chat_messages', jsonEncode([sentMessage.toJson()]));

      await tester.pumpWidget(buildTestHost(const ArtistChatView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Sent (1)'), findsOneWidget);
      expect(find.textContaining('To: Dubai Art Administrator'), findsOneWidget);

      // Open message detail modal
      await tester.tap(find.textContaining('To: Dubai Art Administrator'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Modal is open with recipient details, subject, and Reply button
      expect(find.text('Arabic Calligraphy'), findsWidgets);
      expect(find.text('Inquiry'), findsWidgets);
      expect(find.text('Hello, checking on the submission status.'), findsWidgets);
      expect(find.text('Reply'), findsOneWidget);

      // Tap Reply button
      await tester.tap(find.text('Reply'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switches to Send tab with recipient set and prefilled subject
      expect(find.text('Send to Artist'), findsOneWidget);
      expect(find.textContaining('Dubai Art Administrator'), findsOneWidget);
      expect(find.text('Re: Inquiry'), findsOneWidget);
    });
  });
}


