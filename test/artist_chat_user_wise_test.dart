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
import 'package:artist_dubai/features/chat/domain/models/artist_message_model.dart';
import 'package:artist_dubai/features/chat/presentation/views/artist_chat_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class _TestHttpOverrides extends HttpOverrides {}

class _MockChatApiClient implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'status': 'success', 'data': []},
      statusCode: 200,
    );
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
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

    if (sl.isRegistered<ApiClient>()) {
      sl.unregister<ApiClient>();
    }
    sl.registerSingleton<ApiClient>(_MockChatApiClient());
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
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: child,
      ),
    );
  }

  group('Artist Chat User-Wise Grouping & Conversation Thread Tests', () {
    testWidgets(
      'Groups multiple messages with the same user into a single user-wise card with conversation thread',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final now = DateTime.now();

        // 1. Outgoing sent message to Dubai Art Administrator
        final msgSent = ArtistMessageModel(
          id: 'msg_1',
          senderId: 'my_user_1',
          senderName: 'Test Artist',
          senderEmail: 'test@artist.com',
          recipientId: '28',
          recipientName: 'Dubai Art Administrator',
          recipientCategory: 'Art Exhibition',
          subject: 'Test',
          message: 'Hello, here is my inquiry.',
          createdAt: now.subtract(const Duration(minutes: 1)),
          isRead: true,
        );

        // 2. Incoming reply from Dubai Art Administrator
        final msgInbox = ArtistMessageModel(
          id: 'msg_2',
          senderId: '28',
          senderName: 'Dubai Art Administrator',
          senderEmail: 'admin@artistdubai.com',
          recipientId: 'my_user_1',
          recipientName: 'Test Artist',
          recipientCategory: 'Artist',
          subject: 'Re: test',
          message: "It's Good! We received your artwork.",
          createdAt: now,
          isRead: false,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', 'test@artist.com');
        await prefs.setString('artist_profile_id', 'my_user_1');
        await prefs.setString(
          'artist_chat_messages',
          jsonEncode([msgSent.toJson(), msgInbox.toJson()]),
        );

        await tester.pumpWidget(buildTestHost(const ArtistChatView()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        // 1. Verify Pills show counts
        expect(find.textContaining('All (2)'), findsOneWidget);
        expect(find.textContaining('Inbox (1)'), findsOneWidget);
        expect(find.textContaining('Sent (1)'), findsOneWidget);

        // 2. In default User-wise mode:
        // Exactly ONE User-wise card is displayed for Dubai Art Administrator!
        expect(find.text('Dubai Art Administrator'), findsWidgets);
        expect(find.text('2 Msgs'), findsOneWidget);
        expect(find.textContaining('View Conversation (2) →'), findsOneWidget);

        // The latest message preview is shown
        expect(find.text('Re: test'), findsOneWidget);
        expect(find.text("It's Good! We received your artwork."), findsOneWidget);

        // 3. Tap view mode toggle to switch to individual "Messages" mode
        expect(find.text('By User'), findsOneWidget);
        expect(find.text('Messages'), findsWidgets);

        await tester.tap(find.byIcon(Icons.mail_outline_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In Messages mode, both individual cards are displayed separately
        expect(find.textContaining('From: Dubai Art Administrator'), findsOneWidget);
        expect(find.textContaining('To: Dubai Art Administrator'), findsOneWidget);

        // Switch back to "By User" mode
        await tester.tap(find.byIcon(Icons.people_alt_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 4. Tap the User-wise card to open the Conversation Thread modal
        await tester.tap(find.textContaining('View Conversation (2) →'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Modal should open with full thread containing both sent and incoming messages
        expect(find.text('Hello, here is my inquiry.'), findsOneWidget);
        expect(find.text("It's Good! We received your artwork."), findsWidgets);
        expect(find.text('2 Messages'), findsOneWidget);

        // Verify quick reply field exists
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Reply'), findsOneWidget);

        // Tap Reply button to verify handoff to full Send tab
        await tester.tap(find.text('Reply'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Now on Send tab with recipient prefilled
        expect(find.text('Send to Artist'), findsOneWidget);
        expect(find.textContaining('Dubai Art Administrator'), findsOneWidget);
        expect(find.text('Re: test'), findsOneWidget);
      },
    );
  });
}
