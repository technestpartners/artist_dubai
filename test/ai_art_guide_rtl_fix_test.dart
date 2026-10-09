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

  testWidgets('AiArtGuideView renders English response with brand name in LTR when app language is English', (tester) async {
    final now = DateTime.now();
    final englishSession = {
      'id': 'chat_test_1',
      'title': 'Hello test',
      'updatedAt': now.toIso8601String(),
      'messages': [
        {
          'text': 'hello',
          'isUser': true,
          'timestamp': now.toIso8601String(),
        },
        {
          'text': 'Welcome to Artist Dubai (فنان دبي)! How can I help you explore Dubai art?',
          'isUser': false,
          'timestamp': now.toIso8601String(),
        }
      ],
    };

    final storage = sl<StorageService>();
    await storage.setString('ai_chat_sessions_v1', jsonEncode([englishSession]));

    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider(), // Defaults to 'en'
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AiArtGuideView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open drawer and select the session
    final historyBtn = find.byTooltip('Your chats');
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Tap on the session title to load it into active chat
    final sessionItem = find.text('Hello test');
    expect(sessionItem, findsOneWidget);
    await tester.tap(sessionItem);
    await tester.pumpAndSettle();

    // Verify the SelectableText.rich widget rendering the AI message is LTR and TextAlign.left
    final selectableTexts = tester.widgetList<SelectableText>(find.byType(SelectableText));
    expect(selectableTexts, isNotEmpty);

    final aiMessageText = selectableTexts.firstWhere(
      (widget) => widget.textSpan?.toPlainText().contains('Welcome to Artist Dubai') ?? false,
    );

    expect(aiMessageText.textDirection, TextDirection.ltr);
    expect(aiMessageText.textAlign, TextAlign.left);
  });

  testWidgets('AiArtGuideView dynamically translates Arabic chat messages when switching language to English', (tester) async {
    final now = DateTime.now();
    final arabicSession = {
      'id': 'chat_test_ar_to_en',
      'title': 'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
      'updatedAt': now.toIso8601String(),
      'messages': [
        {
          'text': 'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
          'isUser': true,
          'timestamp': now.toIso8601String(),
        },
      ],
    };

    final storage = sl<StorageService>();
    await storage.setString('ai_chat_sessions_v1', jsonEncode([arabicSession]));

    final localeProvider = LocaleProvider(); // Defaults to 'en'

    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>.value(
        value: localeProvider,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AiArtGuideView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open drawer and load the session
    final historyBtn = find.byTooltip('Your chats');
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Tap on the session title in drawer (which is translated to English)
    final sessionTitle = find.text('Which Art Districts Can I Visit in Dubai?');
    expect(sessionTitle, findsOneWidget);
    await tester.tap(sessionTitle);
    await tester.pumpAndSettle();

    // In English mode, the Arabic prompt in the chat bubble should also be translated to English
    final selectableTexts = tester.widgetList<SelectableText>(find.byType(SelectableText));
    expect(selectableTexts, isNotEmpty);
    final userMessage = selectableTexts.firstWhere(
      (widget) => widget.textSpan?.toPlainText().contains('Which Art Districts Can I Visit in Dubai?') ?? false,
    );
    expect(userMessage.textDirection, TextDirection.ltr);
  });
}
