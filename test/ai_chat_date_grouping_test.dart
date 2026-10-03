import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/features/ai/presentation/views/ai_art_guide_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initDependencyInjection();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('AiArtGuideView groups chat sessions date-wise and shows date and time', (tester) async {
    final now = DateTime.now();
    final todaySession = {
      'id': 'chat_today_1',
      'title': 'How do I register as an artist in this app?',
      'updatedAt': now.subtract(const Duration(minutes: 15)).toIso8601String(),
      'messages': [
        {
          'text': 'How do I register as an artist in this app?',
          'isUser': true,
          'timestamp': now.subtract(const Duration(minutes: 15)).toIso8601String(),
        }
      ],
    };

    final yesterdaySession = {
      'id': 'chat_yesterday_1',
      'title': 'Which art districts can I visit in Dubai?',
      'updatedAt': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'messages': [
        {
          'text': 'Which art districts can I visit in Dubai?',
          'isUser': true,
          'timestamp': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        }
      ],
    };

    final olderSession = {
      'id': 'chat_older_1',
      'title': 'Ideas for a weekend art tour in Dubai',
      'updatedAt': now.subtract(const Duration(days: 4)).toIso8601String(),
      'messages': [
        {
          'text': 'Ideas for a weekend art tour in Dubai',
          'isUser': true,
          'timestamp': now.subtract(const Duration(days: 4)).toIso8601String(),
        }
      ],
    };

    // Pre-populate storage with sessions from different dates
    final storage = sl<StorageService>();
    storage.setString('ai_chat_sessions_v1', jsonEncode([
      todaySession,
      yesterdaySession,
      olderSession,
    ]));

    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AiArtGuideView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the "Your chats" drawer using history icon
    final historyBtn = find.byTooltip('Your chats');
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Verify drawer header
    final drawer = find.byType(Drawer);
    expect(find.descendant(of: drawer, matching: find.text('Your chats')), findsOneWidget);

    // Verify date group headers exist in drawer
    expect(find.descendant(of: drawer, matching: find.text('TODAY')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('YESTERDAY')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('PREVIOUS 7 DAYS')), findsOneWidget);

    // Verify session titles exist in drawer
    expect(find.descendant(of: drawer, matching: find.text('How do I register as an artist in this app?')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('Which art districts can I visit in Dubai?')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('Ideas for a weekend art tour in Dubai')), findsOneWidget);

    // Verify date and time formatted text exists on cards (contains 'Today •' and 'Yesterday •')
    expect(find.descendant(of: drawer, matching: find.textContaining('Today •')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.textContaining('Yesterday •')), findsOneWidget);
  });
}
