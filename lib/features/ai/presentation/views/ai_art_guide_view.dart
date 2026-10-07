import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/locale_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class AiArtGuideView extends StatefulWidget {
  const AiArtGuideView({super.key});

  @override
  State<AiArtGuideView> createState() => _AiArtGuideViewState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> relatedQuestions;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.relatedQuestions = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'related_questions': relatedQuestions,
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        relatedQuestions: (json['related_questions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class _ChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  List<_ChatMessage> messages;

  _ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory _ChatSession.fromJson(Map<String, dynamic> json) => _ChatSession(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Chat',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((m) => _ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class _SessionDateGroup {
  final String title;
  final List<_ChatSession> sessions;

  const _SessionDateGroup({
    required this.title,
    required this.sessions,
  });
}

class _AiArtGuideViewState extends State<AiArtGuideView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const String _storageKeySessions = 'ai_chat_sessions_v1';

  final List<_ChatMessage> _messages = [];
  final List<_ChatSession> _savedSessions = [];
  String? _currentSessionId;
  bool _isTyping = false;

  List<String> _getSuggestedPrompts(bool isArabic) {
    if (isArabic) {
      return const [
        'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
        'كيف أسجل كفنان في هذا التطبيق؟',
        'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
      ];
    }
    return const [
      'Which art districts can I visit in Dubai?',
      'How do I register as an artist in this app?',
      'Ideas for a weekend art tour in Dubai',
    ];
  }

  List<String> _getRelatedQuestions(String query, {required bool isArabic}) {
    final q = query.toLowerCase();
    final hasArabicChars = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    final inArabic = isArabic || hasArabicChars;

    if (inArabic) {
      if (q.contains('مجاني') || q.contains('تذاكر') || q.contains('رسوم') || q.contains('دخول')) {
        return const [
          'ما هي أوقات عمل معارض السركال أفنيو؟',
          'كيف أصل إلى السركال أفنيو بالمترو؟',
          'ما هي أفضل المقاهي الفنية في السركال؟',
        ];
      }
      if (q.contains('أوقات') || q.contains('ساعات') || q.contains('مواعيد')) {
        return const [
          'هل الدخول إلى معارض السركال أفنيو مجاني؟',
          'كيف أصل إلى قرية البوابة بمركز دبي المالي بالمترو؟',
          'ما هي أحدث الفعاليات الفنية هذا الأسبوع؟',
        ];
      }
      if (q.contains('مترو') || q.contains('وصول') || q.contains('طريق') || q.contains('مواقف')) {
        return const [
          'ما هي المعارض الفنية الموجودة في مركز دبي المالي؟',
          'هل تتوفر مواقف سيارات في السركال أفنيو؟',
          'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
        ];
      }
      if (q.contains('حجز') || q.contains('توظيف') || q.contains('طلب فنان')) {
        return const [
          'ما هو متوسط سعر حجز الفنانين في دبي؟',
          'كيف يمكنني بيع لوحاتي وأعمالي الفنية هنا؟',
          'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
        ];
      }
      if (q.contains('بيع') || q.contains('شراء') || q.contains('لوحات') || q.contains('أعمال')) {
        return const [
          'كيف أحجز فناناً لعمل لوحة خاصة؟',
          'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
          'ما هي المعارض المتخصصة في الخط العربي المعاصر؟',
        ];
      }
      if (q.contains('خط') || q.contains('خطاط') || q.contains('حروف')) {
        return const [
          'كيف أتواصل مع تشكيل للمشاركة في ورش العمل؟',
          'كيف أحجز خطاطاً لمناسبة خاصة؟',
          'أين تقع أفضل معارض الفن المعاصر في دبي؟',
        ];
      }
      if (q.contains('تشكيل') || q.contains('ورش') || q.contains('مبتدئ')) {
        return const [
          'ما هي المعارض المتخصصة في الخط العربي المعاصر؟',
          'هل تتوفر ورش عمل مجانية للفنانين المبتدئين؟',
          'أين تقع أفضل معارض النحت في دبي؟',
        ];
      }
      if (q.contains('مقهى') || q.contains('مقاهي') || q.contains('إفطار')) {
        return const [
          'هل الدخول إلى معارض السركال أفنيو مجاني؟',
          'ما هي أوقات عمل معارض السركال أفنيو؟',
          'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
        ];
      }
      if (q.contains('منطقة') || q.contains('مناطق') || q.contains('زيارة') || q.contains('السركال') || q.contains('أين')) {
        return const [
          'هل الدخول إلى معارض السركال أفنيو مجاني؟',
          'ما هي أوقات عمل حي دبي للتصميم d3؟',
          'كيف أصل إلى قرية البوابة بمركز دبي المالي بالمترو؟',
        ];
      }
      if (q.contains('تسجيل') || q.contains('سجل') || q.contains('انضمام') || q.contains('فنان') || q.contains('register') || q.contains('artist')) {
        return const [
          'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
          'هل يمكنني بيع لوحاتي وأعمالي الفنية هنا؟',
          'كيف أضيف فعالياتي ومعارضي الخاصة؟',
        ];
      }
      if (q.contains('جولة') || q.contains('عطلة') || q.contains('أسبوع') || q.contains('برنامج') || q.contains('tour') || q.contains('weekend')) {
        return const [
          'ما هي أفضل المقاهي الفنية لتناول الإفطار في السركال؟',
          'هل تتوفر جولات إرشادية فنية في حي الفهيدي؟',
          'ما هي أحدث الفعاليات في نهاية هذا الأسبوع؟',
        ];
      }
      if (q.contains('معرض') || q.contains('معارض') || q.contains('جاليري') || q.contains('gallery') || q.contains('galleries')) {
        return const [
          'ما هي المعارض المتخصصة في الخط العربي المعاصر؟',
          'كيف أتواصل مع تشكيل للمشاركة في ورش العمل؟',
          'أين تقع أفضل معارض النحت في دبي؟',
        ];
      }
      if (q.contains('فعالية') || q.contains('فعاليات') || q.contains('مسابقة') || q.contains('مسابقات') || q.contains('event')) {
        return const [
          'ما هي الجوائز المقدمة في المسابقات الفنية الحالية؟',
          'كيف أشارك في مهرجان سكة للفنون والتصميم؟',
          'هل توجد ورش عمل مجانية للفنانين المبتدئين؟',
        ];
      }
      return const [
        'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
        'كيف أحجز فناناً في هذا التطبيق؟',
        'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
      ];
    }

    // English
    if (q.contains('free') || q.contains('admission') || q.contains('ticket') || q.contains('cost') || q.contains('entry') || q.contains('fee')) {
      return const [
        'What are the opening hours for Alserkal Avenue galleries?',
        'How do I reach DIFC Gate Village by Metro?',
        'What are the best art cafes in Alserkal Avenue?',
      ];
    }
    if (q.contains('hour') || q.contains('timing') || q.contains('open') || q.contains('close')) {
      return const [
        'Is admission free at Alserkal Avenue galleries?',
        'How do I reach DIFC Gate Village by Metro?',
        'What cultural events are happening this weekend?',
      ];
    }
    if (q.contains('metro') || q.contains('reach') || q.contains('direction') || q.contains('get to') || q.contains('taxi')) {
      return const [
        'Which galleries in Dubai feature Arabic calligraphy?',
        'Is admission free at Alserkal Avenue galleries?',
        'Ideas for a weekend art tour in Dubai',
      ];
    }
    if (q.contains('book') || q.contains('hire') || q.contains('commission')) {
      return const [
        'Can I sell my paintings and artworks directly on the app?',
        'What are the requirements to get verified as an artist?',
        'How do I submit an art event or exhibition?',
      ];
    }
    if (q.contains('sell') || q.contains('buy') || q.contains('artwork') || q.contains('painting')) {
      return const [
        'How do I book an artist in this app?',
        'What are the requirements to get verified as an artist?',
        'Which galleries in Dubai feature Arabic calligraphy?',
      ];
    }
    if (q.contains('calligraphy') || q.contains('typography')) {
      return const [
        'How can I join workshops and residencies at Tashkeel?',
        'How do I book an artist in this app?',
        'Where can I find modern sculpture galleries in Dubai?',
      ];
    }
    if (q.contains('tashkeel') || q.contains('workshop') || q.contains('beginner')) {
      return const [
        'Which galleries in Dubai feature Arabic calligraphy?',
        'Are there free beginner art workshops in Dubai?',
        'What are the best art cafes in Alserkal Avenue?',
      ];
    }
    if (q.contains('cafe') || q.contains('coffee') || q.contains('breakfast')) {
      return const [
        'Is admission free at Alserkal Avenue galleries?',
        'What are the opening hours for Alserkal Avenue galleries?',
        'Ideas for a weekend art tour in Dubai',
      ];
    }
    if (q.contains('district') || q.contains('visit') || q.contains('where') || q.contains('alserkal') || q.contains('area')) {
      return const [
        'Is admission free at Alserkal Avenue galleries?',
        'What are the opening hours for Dubai Design District (d3)?',
        'How do I reach DIFC Gate Village by Metro?',
      ];
    }
    if (q.contains('register') || q.contains('join') || q.contains('profile') || q.contains('artist')) {
      return const [
        'What are the requirements to get verified as an artist?',
        'Can I sell my paintings and artworks directly on the app?',
        'How do I submit an art event or exhibition?',
      ];
    }
    if (q.contains('tour') || q.contains('weekend') || q.contains('itinerary') || q.contains('day')) {
      return const [
        'What are the best art cafes in Alserkal Avenue?',
        'Are there guided art tours in Al Fahidi historic district?',
        'What cultural events are happening this weekend?',
      ];
    }
    if (q.contains('gallery') || q.contains('galleries') || q.contains('center')) {
      return const [
        'Which galleries in Dubai feature Arabic calligraphy?',
        'How can I join workshops and residencies at Tashkeel?',
        'Where can I find modern sculpture galleries in Dubai?',
      ];
    }
    if (q.contains('event') || q.contains('competition') || q.contains('exhibition')) {
      return const [
        'What are the active art competitions with cash prizes?',
        'How can I exhibit my work in the Sikka Art Festival?',
        'Are there free beginner art workshops in Dubai?',
      ];
    }
    return const [
      'Which art districts can I visit in Dubai?',
      'How do I book an artist in this app?',
      'Ideas for a weekend art tour in Dubai',
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSessions();
    _fetchBackendSessions();
    _inputController.addListener(_onInputChanged);
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _onTranslationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadSavedSessions() {
    try {
      final storage = sl<StorageService>();
      final raw = storage.getString(_storageKeySessions);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _savedSessions.clear();
          for (final item in decoded) {
            _savedSessions.add(_ChatSession.fromJson(item as Map<String, dynamic>));
          }
          _savedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
      }
    } catch (_) {}
  }

  void _saveSessionsToDisk() {
    try {
      final storage = sl<StorageService>();
      final encoded = jsonEncode(_savedSessions.map((s) => s.toJson()).toList());
      storage.setString(_storageKeySessions, encoded);
    } catch (_) {}
  }

  Future<void> _fetchBackendSessions() async {
    try {
      final storage = sl<StorageService>();
      final email = storage.getString('user_email');
      final api = sl<ApiService>();
      final backendList = await api.getAiChatSessions(userEmail: email);
      if (backendList.isNotEmpty && mounted) {
        setState(() {
          for (final item in backendList) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? 'Chat';
            final updatedAt = DateTime.tryParse(item['updated_at']?.toString() ?? '') ?? DateTime.now();
            final existingIndex = _savedSessions.indexWhere((s) => s.id == id);
            if (existingIndex < 0) {
              _savedSessions.add(_ChatSession(
                id: id,
                title: title,
                updatedAt: updatedAt,
                messages: [],
              ));
            } else {
              _savedSessions[existingIndex].title = title;
              _savedSessions[existingIndex].updatedAt = updatedAt;
            }
          }
          _savedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
        _saveSessionsToDisk();
      }
    } catch (e) {
      debugPrint('Error syncing backend sessions: $e');
    }
  }

  void _syncCurrentSession(String firstUserMessage) {
    if (_currentSessionId == null) {
      _currentSessionId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final newSession = _ChatSession(
        id: _currentSessionId!,
        title: firstUserMessage.length > 40
            ? '${firstUserMessage.substring(0, 37)}...'
            : firstUserMessage,
        updatedAt: DateTime.now(),
        messages: List.from(_messages),
      );
      _savedSessions.insert(0, newSession);
    } else {
      final index = _savedSessions.indexWhere((s) => s.id == _currentSessionId);
      if (index >= 0) {
        _savedSessions[index].messages = List.from(_messages);
        _savedSessions[index].updatedAt = DateTime.now();
      }
    }
    _savedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _saveSessionsToDisk();
  }

  Future<void> _loadSession(_ChatSession session) async {
    setState(() {
      _currentSessionId = session.id;
      _messages.clear();
      _messages.addAll(session.messages);
      _isTyping = false;
    });

    // If session has no cached messages, load from backend
    if (session.messages.isEmpty) {
      try {
        final api = sl<ApiService>();
        final rawMsgs = await api.getAiChatMessages(session.id);
        if (rawMsgs.isNotEmpty && mounted && _currentSessionId == session.id) {
          final isArabic = Provider.of<LocaleProvider>(context, listen: false).isArabic;
          setState(() {
            _messages.clear();
            for (final m in rawMsgs) {
              final isUser = m['sender'] == 'user';
              List<String> related = [];
              if (m['related_questions'] is List) {
                related = (m['related_questions'] as List)
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              } else if (!isUser) {
                related = _getRelatedQuestions(m['message']?.toString() ?? '', isArabic: isArabic);
              }
              _messages.add(_ChatMessage(
                text: m['message']?.toString() ?? '',
                isUser: isUser,
                timestamp: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
                relatedQuestions: related,
              ));
            }
            session.messages = List.from(_messages);
          });
          _saveSessionsToDisk();
          _scrollToBottom();
        }
      } catch (e) {
        debugPrint('Error fetching session messages: $e');
      }
    }
    _scrollToBottom();
  }

  Future<void> _deleteSession(String sessionId) async {
    setState(() {
      _savedSessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
      }
    });
    _saveSessionsToDisk();

    try {
      await sl<ApiService>().deleteAiChatSession(sessionId);
    } catch (e) {
      debugPrint('Error deleting backend session: $e');
    }
  }

  void _clearChat() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _isTyping = false;
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final isFirstMsg = _messages.isEmpty;
    final isArabic = Provider.of<LocaleProvider>(context, listen: false).isArabic;

    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _inputController.clear();
      _isTyping = true;
    });

    _syncCurrentSession(query);
    _scrollToBottom();

    // Call backend API with seamless smart fallback
    try {
      final storage = sl<StorageService>();
      final email = storage.getString('user_email');
      final userId = storage.getString('user_id');
      final api = sl<ApiService>();

      final res = await api.sendAiChatMessage(
        sessionId: _currentSessionId ?? '',
        message: query,
        title: isFirstMsg ? query : null,
        userEmail: email,
        userId: userId,
        locale: isArabic ? 'ar' : 'en',
      );

      if (!mounted) return;

      if (res != null && res['ai_reply'] != null) {
        final replyText = res['ai_reply'].toString();
        List<String> relatedQuestions = [];
        if (res['related_questions'] is List) {
          relatedQuestions = (res['related_questions'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        if (relatedQuestions.isEmpty) {
          relatedQuestions = _getRelatedQuestions(query, isArabic: isArabic);
        }
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: replyText,
            isUser: false,
            relatedQuestions: relatedQuestions,
          ));
        });
        _syncCurrentSession(isFirstMsg ? query : (_savedSessions.firstWhere((s) => s.id == _currentSessionId).title));
        _scrollToBottom();
        return;
      }
    } catch (e) {
      debugPrint('Backend AI request error, using smart fallback: $e');
    }

    // Local knowledge generator fallback
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final fallbackResponse = _generateArtResponse(query, isArabic: isArabic);
      final relatedQuestions = _getRelatedQuestions(query, isArabic: isArabic);
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: fallbackResponse,
          isUser: false,
          relatedQuestions: relatedQuestions,
        ));
      });
      _syncCurrentSession(isFirstMsg ? query : (_savedSessions.firstWhere((s) => s.id == _currentSessionId).title));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatSessionTime(DateTime dt, {bool isArabic = false}) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = dt.hour >= 12;
    final amPm = isArabic ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');
    return '$hour:$minute $amPm';
  }

  String _formatSessionDateTime(DateTime dt, {bool isArabic = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(target).inDays;
    final timeStr = _formatSessionTime(dt, isArabic: isArabic);

    if (diffDays == 0) {
      final label = isArabic ? 'اليوم' : 'Today';
      return '$label • $timeStr';
    } else if (diffDays == 1) {
      final label = isArabic ? 'أمس' : 'Yesterday';
      return '$label • $timeStr';
    } else if (dt.year == now.year) {
      const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      final monthName = isArabic ? monthsAr[dt.month - 1] : monthsEn[dt.month - 1];
      return '${dt.day} $monthName • $timeStr';
    } else {
      final dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      return '$dateLabel • $timeStr';
    }
  }


  List<_SessionDateGroup> _getGroupedSessions(bool isArabic) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
    final thirtyDaysAgo = todayStart.subtract(const Duration(days: 30));

    final List<_ChatSession> todaySessions = [];
    final List<_ChatSession> yesterdaySessions = [];
    final List<_ChatSession> last7DaysSessions = [];
    final List<_ChatSession> last30DaysSessions = [];
    final List<_ChatSession> earlierSessions = [];

    final sorted = List<_ChatSession>.from(_savedSessions)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final s in sorted) {
      if (s.updatedAt.isAfter(todayStart) || s.updatedAt.isAtSameMomentAs(todayStart)) {
        todaySessions.add(s);
      } else if (s.updatedAt.isAfter(yesterdayStart) || s.updatedAt.isAtSameMomentAs(yesterdayStart)) {
        yesterdaySessions.add(s);
      } else if (s.updatedAt.isAfter(sevenDaysAgo) || s.updatedAt.isAtSameMomentAs(sevenDaysAgo)) {
        last7DaysSessions.add(s);
      } else if (s.updatedAt.isAfter(thirtyDaysAgo) || s.updatedAt.isAtSameMomentAs(thirtyDaysAgo)) {
        last30DaysSessions.add(s);
      } else {
        earlierSessions.add(s);
      }
    }

    final List<_SessionDateGroup> groups = [];
    if (todaySessions.isNotEmpty) {
      groups.add(_SessionDateGroup(
        title: isArabic ? 'اليوم' : 'Today',
        sessions: todaySessions,
      ));
    }
    if (yesterdaySessions.isNotEmpty) {
      groups.add(_SessionDateGroup(
        title: isArabic ? 'أمس' : 'Yesterday',
        sessions: yesterdaySessions,
      ));
    }
    if (last7DaysSessions.isNotEmpty) {
      groups.add(_SessionDateGroup(
        title: isArabic ? 'آخر 7 أيام' : 'Previous 7 Days',
        sessions: last7DaysSessions,
      ));
    }
    if (last30DaysSessions.isNotEmpty) {
      groups.add(_SessionDateGroup(
        title: isArabic ? 'آخر 30 يوماً' : 'Previous 30 Days',
        sessions: last30DaysSessions,
      ));
    }
    if (earlierSessions.isNotEmpty) {
      groups.add(_SessionDateGroup(
        title: isArabic ? 'سابقاً' : 'Earlier',
        sessions: earlierSessions,
      ));
    }

    return groups;
  }

  String _generateArtResponse(String query, {required bool isArabic}) {
    final q = query.toLowerCase();
    final hasArabicChars = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    final inArabic = isArabic || hasArabicChars;

    if (inArabic) {
      // Free admission / tickets
      if (q.contains('مجاني') || q.contains('تذاكر') || q.contains('تذكرة') || q.contains('رسوم') || q.contains('دخول') || q.contains('free') || q.contains('admission') || q.contains('ticket')) {
        return 'نعم، الدخول إلى غالبية المعارض الفنية في دبي **مجاني تماماً** ومتاح للجميع:\n\n'
            '• **السركال أفنيو:** الدخول إلى المنطقة وجميع صالات العرض الـ 70 مجاني طوال العام، دون الحاجة إلى تذاكر مسبقة (باستثناء عروض سينما عقيل وبعض ورش العمل المتخصصة).\n'
            '• **قرية البوابة بمركز دبي المالي (DIFC):** زيارة المعارض الفنية المعاصرة والممشى الفني مجانية بالكامل.\n'
            '• **حي دبي للتصميم (d3):** الدخول إلى الصالات والمجسمات النحتية الخارجية مجاني ومفتوح للجمهور.\n'
            '• **مركز جميل للفنون:** الدخول إلى صالات العرض وحديقة المجسمات مجاني مع الترحيب بجميع الزوار.\n'
            '• **مهرجان سكة للفنون والتصميم:** الدخول لجميع فعالياته ومعارضه في حي الفهيدي مجاني سنوياً.';
      }

      // Opening hours / timings
      if (q.contains('أوقات') || q.contains('ساعات') || q.contains('مواعيد') || q.contains('يفتح') || q.contains('يغلق') || q.contains('hours') || q.contains('timing')) {
        if (q.contains('d3') || q.contains('تصميم')) {
          return 'أوقات عمل **حي دبي للتصميم (d3)**:\n\n'
              '• **المساحات العامة والمطاعم والمقاهي:** تفتح يومياً من الساعة 8:00 صباحاً وحتى 11:00 مساءً (وحتى منتصف الليل في عطلة نهاية الأسبوع).\n'
              '• **المكاتب وصالات العرض التجارية:** تعمل عادة من الأحد إلى الخميس من 9:00 صباحاً حتى 6:00 مساءً.\n'
              '• أفضل وقت للزيارة والاستمتاع بالمجسمات والتصوير هو وقت العصر والمساء!';
        }
        if (q.contains('السركال') || q.contains('alserkal')) {
          return 'أوقات عمل **السركال أفنيو (القوز)**:\n\n'
              '• **صالات العرض الفنية:** تفتح عادة من السبت إلى الخميس، من الساعة 10:00 صباحاً حتى 7:00 مساءً (بعض المعارض تغلق أيام الجمعة).\n'
              '• **المقاهي والمساحات الإبداعية:** تفتح يومياً من الساعة 8:00 صباحاً حتى 10:00 مساءً.\n'
              '• **سينما عقيل:** تفتح في أوقات العروض المسائية (غالباً بعد الساعة 5:00 مساءً).';
        }
        return 'مواعيد عمل أبرز المناطق والمعارض الفنية في دبي:\n\n'
            '• **السركال أفنيو:** صالات العرض 10:00 ص - 7:00 م (السبت-الخميس)، والمقاهي حتى 10:00 م.\n'
            '• **حي دبي للتصميم d3:** المرافق والمقاهي 8:00 ص - 11:00 م يومياً.\n'
            '• **قرية البوابة بمركز دبي المالي (DIFC):** المعارض 10:00 ص - 8:00 م (الأحد-الخميس).\n'
            '• **مركز جميل للفنون:** 10:00 ص - 8:00 م (يغلق أيام الثلاثاء).\n'
            '• **حي الفهيدي التاريخي:** 9:00 ص - 8:00 م يومياً.';
      }

      // Metro / Directions / Transport
      if (q.contains('مترو') || q.contains('وصول') || q.contains('كيف أصل') || q.contains('مواصلات') || q.contains('طريق') || q.contains('مواقف') || q.contains('metro') || q.contains('reach')) {
        if (q.contains('difc') || q.contains('المالي') || q.contains('البوابة')) {
          return 'للوصول إلى **قرية البوابة بمركز دبي المالي (DIFC)** بالمترو:\n\n'
              '• اركب **الخط الأحمر لمترو دبي** وانزل في **محطة المركز المالي (Financial Centre Station)** (المخرج 1) أو **محطة أبراج الإمارات (Emirates Towers Station)**.\n'
              '• تقع قرية البوابة على بعد 7 إلى 10 دقائق مشياً عبر ممرات مكيفة ومريحة، أو دقيقة واحدة بسيارة الأجرة.\n'
              '• تتوفر أيضاً مواقف سيارات تحت الأرض وخدمة صف السيارات (Valet) عند بوابات DIFC 1-10.';
        }
        if (q.contains('السركال') || q.contains('alserkal')) {
          return 'للوصول إلى **السركال أفنيو (القوز 1)**:\n\n'
              '• **بالمترو:** خذ الخط الأحمر إلى **محطة أون باسيف (Onpassive)** أو **محطة إكويتي (Equiti)**، ثم استقل سيارة أجرة لمدة 5 دقائق (أو حافلة RTA F25).\n'
              '• **بالسيارة:** تتوفر مواقف مجانية على أطراف الأفنيو ومواقف مأجورة قريبة في القوز 1.';
        }
        return 'طرق الوصول إلى أهم الوجهات الفنية في دبي:\n\n'
            '• **مركز دبي المالي DIFC:** الخط الأحمر للمترو - محطة المركز المالي.\n'
            '• **حي الفهيدي التاريخي:** الخط الأخضر للمترو - محطة شرف دي جي (الفهيدي سابقاً).\n'
            '• **السركال أفنيو:** محطة مترو أون باسيف + 5 دقائق تاكسي.\n'
            '• **حي دبي للتصميم d3:** محطة مترو دبي مول / الخليج التجاري + حافلة d3 أو تاكسي.';
      }

      // Booking / Hiring artists
      if (q.contains('حجز') || q.contains('توظيف') || q.contains('طلب فنان') || q.contains('استئجار') || q.contains('تكليف') || q.contains('book') || q.contains('hire')) {
        return 'حجز وتكليف الفنانين عبر تطبيق **فنان دبي** يتم بسهولة وبشكل موثوق:\n\n'
            '1. افتح تبويب **الفنانون** من الشريط السفلي واستكشف نخبة المبدعين في الإمارات.\n'
            '2. اضغط على ملف الفنان للاطلاع على نبذته وسيرته ومعرض أعماله وسعر الحجز التقديري.\n'
            '3. اضغط على زر **طلب حجز / تواصل مع الفنان**.\n'
            '4. حدد نوع المناسبة (لوحة خاصة، جدارية، ورشة عمل، معرض حي)، والتاريخ، والميزانية المتوقعة.\n'
            '5. سيتم التواصل معك مباشرة لتأكيد التفاصيل وتنفيذ العمل بإشراف المنصة!';
      }

      // Selling & Buying Art
      if (q.contains('بيع') || q.contains('شراء') || q.contains('لوحاتي') || q.contains('أعمالي') || q.contains('سعر') || q.contains('sell') || q.contains('buy')) {
        return 'بيع وشراء اللوحات والأعمال الفنية عبر **فنان دبي**:\n\n'
            '• **للفنانين:** بعد توثيق حسابك كفنان، يمكنك إضافة أعمالك الفنية من لوحة التحكم، وتحديد الأبعاد والخامة والسعر بالدرهم الإماراتي ليراها المقتنون ومصممو الديكور.\n'
            '• **للمقتنين والزوار:** يمكنك استعراض قسم **الأعمال الفنية** في التطبيق، والتواصل مباشرة لاقتناء أي قطعة أصلية أو طلب عمل فني مخصص.\n'
            '• المنصة توفر خيارات دفع آمنة وعروض أسعار واضحة دون أي تعقيد.';
      }

      // Calligraphy
      if (q.contains('خط') || q.contains('خطاط') || q.contains('حروف') || q.contains('calligraphy')) {
        return 'يعد **الخط العربي وفن الحروفية** من أرقى الفنون التي تحظى باهتمام بالغ في دبي:\n\n'
            '• **الأنماط التقليدية:** الثلث، والديواني، والكوفي، والنسخ، والرقعة.\n'
            '• **الحروفية المعاصرة:** دمج التجريد اللوني الحديث مع تشكيلات الحرف العربي.\n'
            '• **أين تكتشفها؟** يمكنك تصفية قسم **الفنانون** في التطبيق حسب فئة **الخط العربي والطباعة** لرؤية أعمال نخبة الخطاطين.\n'
            '• ينظم مركز تشكيل ومعارض السركال ومهرجان سكة ورش عمل ومعارض متخصصة بالخط طوال العام.';
      }

      // Tashkeel & Workshops
      if (q.contains('تشكيل') || q.contains('ورش') || q.contains('مبتدئ') || q.contains('تدريب') || q.contains('tashkeel') || q.contains('workshop')) {
        return 'يقدم المشهد الفني في دبي ورش عمل وبرامج تدريبية لجميع المستويات:\n\n'
            '• **مركز تشكيل (ند الشبا وحي الفهيدي):** يوفر استوديوهات متخصصة للطباعة، وصناعة الفخار، والتصوير، وبرنامج تنوين للتصميم، مع ورش أسبوعية للمبتدئين والمحترفين.\n'
            '• **السركال أفنيو:** مساحات مثل thejamjar تقدم دروساً حرة في الرسم التعبيري والألوان الزيتية والإكريليك للأطفال والكبار.\n'
            '• **مركز جميل للفنون:** برامج مجتمعية وحلقات نقاشية وورش فنية دورية مجانية.\n'
            '• تابع تبويب **الفعاليات** في التطبيق لمعرفة مواعيد ورش العمل القادمة والتسجيل فيها.';
      }

      // Art Cafes & Dining
      if (q.contains('مقهى') || q.contains('مقاهي') || q.contains('مطعم') || q.contains('إفطار') || q.contains('cafe') || q.contains('coffee')) {
        return 'أفضل المقاهي الفنية لتناول القهوة والإفطار وسط الأعمال الإبداعية:\n\n'
            '• **Nightjar Coffee Roasters (السركال):** تحميص حرفي وأطباق إفطار لذيذة في قلب أجواء المستودعات الفنية.\n'
            '• **Wild & The Moon (السركال):** مقهى صحي وعضوي وسط مساحات خضراء مريحة.\n'
            '• **XVA Cafe (حي الفهيدي):** فناء تراثي هادئ تحت أشجار السدر يقدم أشهى المأكولات النباتية والتراثية.\n'
            '• **The Lighthouse (حي دبي للتصميم d3):** مفهوم إبداعي يجمع بين متجر التصاميم والمطعم الراقي.\n'
            '• **A4 Space (السركال):** مساحة عمل مشتركة هادئة مع مكتبة فنية ومقهى مفتوح.';
      }

      // Competitions & Open Calls
      if (q.contains('مسابقة') || q.contains('مسابقات') || q.contains('جوائز') || q.contains('مكافآت') || q.contains('competition') || q.contains('prize')) {
        return 'المسابقات والجوائز الفنية النشطة في دبي:\n\n'
            '• **مهرجان سكة للفنون والتصميم:** يفتح سنوياً دعوة للمبدعين بجوائز دعم وتمويل للمشاريع الفنية الفائزة.\n'
            '• **برنامج تنوين للتصميم (تشكيل):** منحة تدريب وتمويل لإنتاج قطع أثاث وتصميم إماراتية.\n'
            '• **مسابقات الفنون التشكيلية الرقمية والجداريات:** يعلن عنها مجلس دبي للتصميم وهيئة الثقافة والفنون (دبي للثقافة).\n'
            '• تصفح شاشة **الفعاليات / المسابقات** في تطبيقنا للاطلاع على شروط المشاركة والمواعيد النهائية فور صدورها.';
      }

      // Verification & Artist requirements
      if (q.contains('توثيق') || q.contains('متطلبات') || q.contains('شروط') || q.contains('verify') || q.contains('requirement')) {
        return 'متطلبات توثيق واعتماد ملف الفنان في تطبيق **فنان دبي**:\n\n'
            '1. **معلومات شخصية وسيرة فنية:** الاسم الكامل، والمجال الفني الرئيسي، ونبذة مختصرة عن مسيرتك الإبداعية.\n'
            '2. **معرض الأعمال (Portfolio):** رفع ما لا يقل عن 3 إلى 5 صور واضحة وعالية الجودة لأعمالك الفنية الأصلية.\n'
            '3. **بيانات الاتصال والتواصل الاجتماعي:** بريد إلكتروني صالح، ورقم هاتف، وحساب إنستغرام أو موقع إلكتروني لعرض الأعمال.\n'
            '4. **مراجعة سريعة:** يقوم فريق المراجعة بالتحقق من الملف واعتماده خلال 24 ساعة لتظهر كفنان معتمد في المنصة!';
      }

      // Districts
      if (q.contains('منطقة') || q.contains('مناطق') || q.contains('زيارة') || q.contains('أين') || q.contains('مكان') || q.contains('district') || q.contains('visit')) {
        return 'تضم دبي العديد من المراكز الفنية والإبداعية العالمية النابضة بالحياة:\n\n'
            '• **السركال أفنيو (القوز)**\n'
            'الوجهة الرائدة للفن المعاصر في دبي، وتضم أكثر من 70 مساحة إبداعية ومعارض عالمية، ومقاهٍ فنية وسينما مستقلة (سينما عقيل).\n\n'
            '• **حي دبي للتصميم (d3)**\n'
            'مركز الأزياء الراقية، والهندسة المعمارية، والمجسمات النحتية الحديثة، ومهرجانات التصميم العالمية.\n\n'
            '• **قرية البوابة في مركز دبي المالي (DIFC)**\n'
            'معارض تجارية مرموقة (Christie’s, Opera Gallery, Ayyam Gallery) وأرقى المطاعم.\n\n'
            '• **حي الفهيدي التاريخي**\n'
            'حي أبراج الرياح التاريخي، ويستضيف مهرجان سكة للفنون والتصميم، ومعرض XVA، ومشاغل الحرف التراثية.\n\n'
            '• **مركز جميل للفنون (واجهة الجداف البحرية)**\n'
            'مؤسسة مبتكرة تعرض الفن الحديث والمعاصر من الشرق الأوسط وجنوب آسيا في مساحات معمارية بديعة.';
      }

      // Register
      if (q.contains('تسجيل') || q.contains('سجل') || q.contains('انضمام') || q.contains('فنان') || q.contains('register') || q.contains('artist')) {
        return 'التسجيل كفنان على منصة **فنان دبي** سهل وسريع:\n\n'
            '1. انتقل إلى الشاشة الرئيسية.\n'
            '2. اضغط على بطاقة **تسجيل فنان**.\n'
            '3. املأ اسم الفنان، والمجال الفني (الرسم، النحت، التصوير الفوتوغرافي، الفن الرقمي، وغيرها)، والنبذة التعريفية، ومعلومات التواصل.\n'
            '4. ارفع نماذج من أعمالك الفنية ومعارضك السابقة.\n'
            '5. أرسل ملفك الشخصي للاعتماد الفوري وإبرازه عبر شبكة الفنون في دبي.';
      }

      // Tour / Weekend
      if (q.contains('جولة') || q.contains('عطلة') || q.contains('أسبوع') || q.contains('برنامج') || q.contains('tour') || q.contains('weekend')) {
        return 'إليك خطة مقترحة لـ **جولة فنية في عطلة نهاية الأسبوع** في دبي:\n\n'
            '**اليوم 1 (الجمعة - الحداثة والتصميم):**\n'
            '• **الصباح:** جولة في حي دبي للتصميم (d3)، وتناول الإفطار في مقهى إبداعي، واستكشاف أحدث معارض التصميم.\n'
            '• **بعد الظهر:** زيارة قرية البوابة في مركز دبي المالي العالمي (DIFC) لمشاهدة المعارض المعاصرة والممشى الفني النحتي.\n'
            '• **المساء:** الاستمتاع بغروب الشمس في مركز جميل للفنون على واجهة الجداف البحرية الهادئة.\n\n'
            '**اليوم 2 (السبت - الأصالة والتراث والفن المستقل):**\n'
            '• **الصباح:** جولة في أزقة حي الفهيدي التاريخي وزيارة فندق ومعرض XVA الفني.\n'
            '• **بعد الظهر:** الانغماس في أروقة السركال أفنيو — استكشاف مستودعات الفنون، وورش العمل المباشرة، والمتاجر الإبداعية.\n'
            '• **المساء:** حضور عرض سينمائي فني مستقل أو أمسية موسيقية حية في سينما عقيل.';
      }

      // Galleries
      if (q.contains('معرض') || q.contains('معارض') || q.contains('جاليري') || q.contains('gallery') || q.contains('galleries')) {
        return 'تضم دبي نخبة من المعارض الفنية الخاصة والمؤسسية المرموقة:\n\n'
            '• **معرض XVA** (الفهيدي) - متخصص في الفن المعاصر للشرق الأوسط.\n'
            '• **معرض أيام Ayyam Gallery** (السركال أفنيو) - يمثل كبار فناني المنطقة المعاصرين.\n'
            '• **معرض كوستوت Custot Gallery** (السركال أفنيو) - فنون عالمية وغربية حديثة ومعاصرة.\n'
            '• **أوبرا جاليري Opera Gallery** (مركز دبي المالي) - روائع الفن العالمي والمعاصر.\n'
            '• **تشكيل Tashkeel** (ند الشبا) - استوديوهات فنية وبرامج إقامة وورش عمل.\n\n'
            'تصفح قسم **المعارض الفنية** في التطبيق من القائمة الرئيسية للحصول على أرقام التواصل والمواقع مباشرة!';
      }

      // Events
      if (q.contains('فعالية') || q.contains('فعاليات') || q.contains('حدث') || q.contains('event')) {
        return 'يمكنك اكتشاف جميع المسابقات والمعارض والملتقيات الثقافية النشطة مباشرة عبر تطبيقنا!\n\n'
            '• اضغط على **الفعاليات / المسابقات** من الشاشة الرئيسية.\n'
            '• قم بالتصفية حسب التاريخ والموقع ومسابقات الجوائز.\n'
            '• يمكن للفنانين المسجلين أيضاً إضافة فعالياتهم ومعارضهم الخاصة ومشاركتها مع مجتمع الفن.';
      }

      // Greetings
      if (q.contains('مرحبا') || q.contains('أهلا') || q.contains('سلام') || q.contains('صباح') || q.contains('مساء') || q.contains('hello') || q.contains('hi')) {
        return 'أهلاً بك في **مرشد فنان دبي الذكي**! يسعدني مساعدتك في استكشاف المشهد الفني الغني في دبي. يمكنك سؤالي عن:\n\n'
            '• المناطق الفنية الشهيرة (السركال أفنيو، حي دبي للتصميم d3، مركز دبي المالي DIFC)\n'
            '• أوقات العمل والدخول المجاني وطرق الوصول بالمترو\n'
            '• كيفية التسجيل كفنان، وحجز الفنانين، أو عرض وبيع لوحاتك\n'
            '• ورش العمل، والمعارض القادمة، وجولات عطلة نهاية الأسبوع المقترحة\n\n'
            'كيف يمكنني مساعدتك اليوم؟';
      }

      return 'أنا **مرشد فنان دبي الذكي**! يمكنك سؤالي عن أي شيء يخص:\n\n'
          '• المناطق والمعارض الفنية في دبي (السركال، d3، مركز دبي المالي)\n'
          '• مواعيد العمل والدخول المجاني وطرق الوصول بالمترو\n'
          '• كيفية حجز الفنانين أو التسجيل كفنان وعرض أعمالك\n'
          '• الفعاليات والمعارض والمسابقات الثقافية والورش التدريبية\n\n'
          'لا تتردد في كتابة أي سؤال في الأسفل!';
    }

    // ENGLISH LOGIC
    // Free admission / tickets
    if (q.contains('free') || q.contains('admission') || q.contains('ticket') || q.contains('cost') || q.contains('entry') || q.contains('fee') || q.contains('price')) {
      return 'Yes! General admission to major contemporary galleries across Dubai is **completely free** and open to the public:\n\n'
          '• **Alserkal Avenue:** Free entry 365 days a year. All 70+ contemporary galleries (Green Art, Carbon 12, Ayyam) are free to enter with no booking required (only Cinema Akil screenings or ticketed culinary events have fees).\n'
          '• **DIFC Gate Village:** Free entry to all art galleries, exhibitions, and the outdoor sculpture promenade.\n'
          '• **Dubai Design District (d3):** Free public entry to galleries, design pop-ups, and interactive art installations.\n'
          '• **Jameel Arts Centre:** Free admission to all exhibition galleries and the outdoor sculpture park.\n'
          '• **Sikka Art & Design Festival (Al Fahidi):** Free public access to all exhibitions, live music, and installations.';
    }

    // Opening hours & timings
    if (q.contains('hour') || q.contains('timing') || q.contains('open') || q.contains('close') || q.contains('schedule')) {
      if (q.contains('d3') || q.contains('design')) {
        return 'Opening hours for **Dubai Design District (d3)**:\n\n'
            '• **Public outdoor promenades, cafes & restaurants:** Open daily from 8:00 AM to 11:00 PM (and midnight on weekends).\n'
            '• **Commercial design showrooms & art galleries:** Typically open Sunday through Thursday from 9:00 AM to 6:00 PM.\n'
            '• The best visiting time for lighting, outdoor sculpture photography, and dining is late afternoon and evening!';
      }
      if (q.contains('alserkal') || q.contains('quoz')) {
        return 'Opening hours for **Alserkal Avenue (Al Quoz)**:\n\n'
            '• **Contemporary Art Galleries:** Saturday through Thursday, 10:00 AM to 7:00 PM (some galleries are closed on Fridays).\n'
            '• **Artisan Cafes & Concept Spaces:** Daily from 8:00 AM to 10:00 PM.\n'
            '• **Cinema Akil:** Open during scheduled evening screenings (typically 5:00 PM to 11:00 PM).';
      }
      return 'Typical opening hours for Dubai art destinations:\n\n'
          '• **Alserkal Avenue:** Galleries 10:00 AM – 7:00 PM (Sat–Thu), Cafes 8:00 AM – 10:00 PM daily.\n'
          '• **Dubai Design District (d3):** 8:00 AM – 11:00 PM daily.\n'
          '• **DIFC Gate Village:** Galleries 10:00 AM – 8:00 PM (Sun–Thu).\n'
          '• **Jameel Arts Centre:** 10:00 AM – 8:00 PM (Closed on Tuesdays).\n'
          '• **Al Fahidi Historical Neighbourhood:** 9:00 AM – 8:00 PM daily.';
    }

    // Metro / Transport / Directions
    if (q.contains('metro') || q.contains('reach') || q.contains('direction') || q.contains('get to') || q.contains('transport') || q.contains('taxi') || q.contains('parking')) {
      if (q.contains('difc') || q.contains('gate village') || q.contains('financial')) {
        return 'How to reach **DIFC Gate Village by Metro**:\n\n'
            '• Take the **Dubai Metro Red Line** and exit at **Financial Centre Metro Station** (Exit 1) or **Emirates Towers Station**.\n'
            '• From Financial Centre Station, it is a comfortable 7–10 minute air-conditioned walk through the DIFC concourse or a 2-minute taxi ride.\n'
            '• If driving, underground visitor and valet parking is available at Gate Village Buildings 1 to 10.';
      }
      if (q.contains('alserkal') || q.contains('quoz')) {
        return 'How to reach **Alserkal Avenue (Al Quoz 1)**:\n\n'
            '• **By Metro:** Take the Red Line to **Onpassive Metro Station** or **Equiti Metro Station**, then take a 5-minute taxi (approx. AED 12–15) or RTA Feeder Bus F25.\n'
            '• **By Car:** Free and RTA parking spaces are available surrounding Avenue 17 and Streets 8 & 6 in Al Quoz 1.';
      }
      return 'How to reach Dubai\'s top art districts:\n\n'
          '• **DIFC Gate Village:** Metro Red Line to **Financial Centre Station**.\n'
          '• **Al Fahidi Historical District:** Metro Green Line to **Sharaf DG Station** (formerly Al Fahidi).\n'
          '• **Alserkal Avenue:** Metro Red Line to **Onpassive Station** + 5-min taxi.\n'
          '• **Dubai Design District (d3):** Metro Red Line to **Dubai Mall / Business Bay** + RTA Bus d3 or 5-min taxi.';
    }

    // Booking an artist (distinguished from registration!)
    if (q.contains('book') || q.contains('hire') || q.contains('commission') || q.contains('booking') || q.contains('request artist')) {
      return 'Booking or commissioning an artist on **Artist Dubai** is simple and direct:\n\n'
          '1. Tap the **Artists** tab in the bottom navigation bar to browse verified UAE talents.\n'
          '2. Tap any artist profile to review their bio, artistic discipline, portfolio works, and starting booking rate (e.g. AED 1,500+).\n'
          '3. Tap the **Book Artist** or **Contact** button on their profile.\n'
          '4. Enter your project details: event date, location, booking type (Live Painting, Mural Commission, Workshop, Custom Artwork), and budget.\n'
          '5. Submit your request for swift confirmation and coordination directly from the artist and our team!';
    }

    // Selling artworks & prices
    if (q.contains('sell') || q.contains('buy') || q.contains('artwork') || q.contains('painting') || q.contains('price') || q.contains('portfolio')) {
      return 'Buying and selling original art on **Artist Dubai**:\n\n'
          '• **For Artists:** Once verified, you can upload artworks directly through your artist dashboard with high-resolution imagery, dimensions, medium (Oil, Acrylic, Mixed Media), and pricing in AED/USD.\n'
          '• **For Art Collectors & Buyers:** Browse original artworks in the in-app catalog, contact the artists directly, or submit purchase inquiries with transparent pricing.\n'
          '• We connect artists with collectors, corporate offices, luxury hotels, and private art patrons across the UAE.';
    }

    // Arabic Calligraphy & Typography
    if (q.contains('calligraphy') || q.contains('typography') || q.contains('arabic art') || q.contains('lettering')) {
      return 'Arabic Calligraphy is one of the most celebrated art forms in Dubai\'s creative landscape:\n\n'
          '• **Traditional Styles:** Masters specialize in Thuluth, Diwani, Kufic, and Naskh scripts.\n'
          '• **Contemporary Hurufiyya:** Modern regional artists blend abstract expressionism with geometric Arabic typography and sculptural lettering.\n'
          '• **Find Artists:** In the **Artists** tab of our app, filter by **Calligraphy & Typography** to view featured local and regional masters.\n'
          '• **Where to Experience:** Tashkeel (Nad Al Sheba), Sikka Art Festival (Al Fahidi), and specialized exhibitions across DIFC and Alserkal Avenue.';
    }

    // Tashkeel, Workshops & Beginner classes
    if (q.contains('tashkeel') || q.contains('workshop') || q.contains('class') || q.contains('beginner') || q.contains('residency') || q.contains('learn')) {
      return 'Dubai offers dynamic art workshops and learning spaces for all skill levels:\n\n'
          '• **Tashkeel (Nad Al Sheba & Al Fahidi):** Founded by HH Sheikha Lateefa bint Maktoum, offers professional printmaking studios, darkrooms, ceramic facilities, and public workshops.\n'
          '• **thejamjar (Alserkal Avenue):** A community art space offering guided painting classes, DIY canvas sessions, and youth art programs.\n'
          '• **Jameel Arts Centre:** Hosts free community workshops, curatorial talks, and family learning weekends.\n'
          '• Check the in-app **Events** tab regularly for upcoming masterclasses and workshop registrations.';
    }

    // Art Cafes & Dining
    if (q.contains('cafe') || q.contains('coffee') || q.contains('breakfast') || q.contains('dining') || q.contains('food') || q.contains('restaurant')) {
      return 'Top art cafes in Dubai where you can dine surrounded by creativity:\n\n'
          '• **Nightjar Coffee Roasters (Alserkal Avenue):** Renowned artisan cold brews and craft breakfast dishes inside a vibrant warehouse vibe.\n'
          '• **Wild & The Moon (Alserkal Avenue):** 100% plant-based organic food and cold-pressed juices in a sunlit green space.\n'
          '• **XVA Cafe (Al Fahidi):** A secluded historic courtyard shaded by a Frangipani tree, serving gourmet vegetarian Middle Eastern cuisine.\n'
          '• **The Lighthouse (d3):** A design concept store and Mediterranean dining lounge created for the creative community.\n'
          '• **A4 Space (Alserkal Avenue):** Loft-style creative hub with an indie coffee counter, art library, and co-working spaces.';
    }

    // Art Competitions & Open Calls
    if (q.contains('competition') || q.contains('prize') || q.contains('award') || q.contains('open call') || q.contains('cash')) {
      return 'Active art competitions, grants, and open calls in Dubai:\n\n'
          '• **Sikka Art & Design Open Call:** Annual competition by Dubai Culture providing production grants for site-specific installations and exhibitions.\n'
          '• **Tanween Design Programme (Tashkeel):** Annual design cohort with product manufacture and launch at Dubai Design Week.\n'
          '• **Public Art Dubai Commissions:** Open calls by the Dubai government for large-scale outdoor sculptures and mural works.\n'
          '• Browse active competitions and deadlines under our app\'s **EVENTS / COMPETITIONS** section!';
    }

    // Requirements & Verification
    if (q.contains('requirement') || q.contains('verified') || q.contains('verification') || q.contains('criteria')) {
      return 'Requirements to get verified as an artist on **Artist Dubai**:\n\n'
          '1. **Full Name & Discipline:** Clear profile title indicating your creative discipline (e.g. Contemporary Painting, Sculpture, Digital Art).\n'
          '2. **Portfolio Samples:** Upload 3 to 5 high-resolution images of your original artwork.\n'
          '3. **Artist Bio:** A brief artist statement summarizing your artistic journey and themes.\n'
          '4. **Valid Contact:** Phone number, email, and social handle (Instagram or website) for verification.\n'
          '5. **Fast Review:** Our curation team reviews submissions within 24 hours to award verified artist status!';
    }

    // Guided tours & Al Fahidi
    if (q.contains('guided tour') || q.contains('heritage') || q.contains('fahidi') || q.contains('sikka')) {
      return 'Exploring heritage art and guided experiences in **Al Fahidi Historical Neighbourhood**:\n\n'
          '• Wander through traditional coral-stone wind-tower houses dating back to the late 19th century.\n'
          '• Visit **XVA Art Hotel & Gallery**, the **Coffee Museum**, and **Alserkal Cultural Foundation**.\n'
          '• Every February/March, the entire district transforms for the **Sikka Art & Design Festival**.\n'
          '• Guided walking tours can be arranged through the Sheikh Mohammed bin Rashid Al Maktoum Centre for Cultural Understanding (SMCCU) right inside the district.';
    }

    // Sculpture
    if (q.contains('sculpture') || q.contains('installation') || q.contains('3d')) {
      return 'Where to experience monumental modern sculptures in Dubai:\n\n'
          '• **DIFC Sculpture Promenade:** Year-round open-air museum displaying monumental contemporary bronze, steel, and marble sculptures by international masters.\n'
          '• **Custot Gallery (Alserkal):** Frequently showcases monumental sculpture and modern European masters (Dubuffet, Bernar Venet).\n'
          '• **Jameel Arts Centre Sculpture Park:** Outdoor park along Jaddaf Waterfront featuring bespoke commissions.\n'
          '• **d3 Design Installations:** Cutting-edge interactive public art installations throughout Dubai Design District.';
    }

    // Districts general
    if (q.contains('district') || q.contains('visit') || q.contains('where') || q.contains('area') || q.contains('place')) {
      return 'Dubai has several vibrant, world-renowned art and creative hubs:\n\n'
          '• **Alserkal Avenue (Al Quoz)**\n'
          'The premier contemporary art hub of Dubai with over 70 creative spaces, world-class galleries (Green Art Gallery, Carbon 12, Grey Noise), artisan cafes, and indie cinemas.\n\n'
          '• **Dubai Design District (d3)**\n'
          'A hub for high-end fashion, architecture, modern sculpture installations, and design festivals.\n\n'
          '• **DIFC Gate Village**\n'
          'Sophisticated commercial galleries (Christie’s, Opera Gallery, Ayyam Gallery) and fine dining.\n\n'
          '• **Al Fahidi Historical Neighbourhood**\n'
          'Historic wind-tower quarter hosting the Sikka Art & Design Festival, XVA Gallery, and heritage craft studios.\n\n'
          '• **Jameel Arts Centre (Jaddaf Waterfront)**\n'
          'An innovative institution displaying modern Middle Eastern and South Asian art in minimalist architectural spaces.';
    }

    // Register
    if (q.contains('register') || q.contains('join') || q.contains('sign up') || q.contains('profile') || q.contains('artist')) {
      return 'Registering as an artist on **Artist Dubai** is straightforward:\n\n'
          '1. Go to the Home screen.\n'
          '2. Tap on the **ARTIST REGISTRATION** card.\n'
          '3. Fill in your artist name, discipline (Painting, Sculpture, Photography, Digital Art, etc.), bio, and contact information.\n'
          '4. Upload your portfolio artwork samples and exhibitions.\n'
          '5. Submit your profile for immediate feature and verification across the Dubai art network.';
    }

    // Weekend tour
    if (q.contains('tour') || q.contains('weekend') || q.contains('itinerary') || q.contains('day')) {
      return 'Here is a curated **Weekend Art Tour** in Dubai:\n\n'
          '**Day 1 (Friday - Modern & Design):**\n'
          '• **Morning:** Stroll through Dubai Design District (d3), enjoy breakfast at a creative café, and explore cutting-edge design showcases.\n'
          '• **Afternoon:** Visit DIFC Gate Village for prestigious contemporary galleries and sculpture walks.\n'
          '• **Evening:** Sunset visit to Jameel Arts Centre by the serene Jaddaf waterfront.\n\n'
          '**Day 2 (Saturday - Underground & Heritage):**\n'
          '• **Morning:** Wander through the historic Al Fahidi cultural quarters and visit XVA Art Hotel.\n'
          '• **Afternoon:** Dive into Alserkal Avenue — visit warehouse galleries, live artist workshops, and creative concept stores.\n'
          '• **Night:** Catch an independent art cinema screening or live music at Cinema Akil.';
    }

    // Galleries
    if (q.contains('gallery') || q.contains('galleries') || q.contains('center')) {
      return 'Dubai boasts prestigious private and institutional art galleries:\n\n'
          '• **XVA Gallery** (Al Fahidi) - Specializes in contemporary Middle Eastern art.\n'
          '• **Ayyam Gallery** (Alserkal Avenue) - Leading regional contemporary artists.\n'
          '• **Custot Gallery** (Alserkal Avenue) - Modern and contemporary Western and international art.\n'
          '• **Opera Gallery** (DIFC) - Renowned master and contemporary artworks.\n'
          '• **Tashkeel** (Nad Al Sheba) - Studio spaces, residency programs, and workshops.\n\n'
          'Explore our in-app **GALLERIES** directory from the main menu for direct contacts and locations!';
    }

    // Events
    if (q.contains('event') || q.contains('exhibition')) {
      return 'You can discover all active competitions, exhibitions, and cultural gatherings directly inside our app!\n\n'
          '• Tap **EVENTS / COMPETITION** from the home screen.\n'
          '• Filter by dates, locations, and prize competitions.\n'
          '• Registered artists can also submit and showcase their own art events to the community.';
    }

    // Greetings
    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('salam') || q.contains('morning') || q.contains('evening')) {
      return 'Hello! I am your **Artist Dubai Guide**. I am here to help you navigate and enjoy Dubai\'s vibrant cultural ecosystem. You can ask me about:\n\n'
          '• Major art districts (Alserkal Avenue, d3, DIFC Gate Village)\n'
          '• Free admission policies, opening hours, and Metro directions\n'
          '• How to book artists, sell artworks, or register as a creator\n'
          '• Weekend art itineraries, cafes, workshops, and exhibitions\n\n'
          'What would you like to explore today?';
    }

    return 'I am your **Artist Dubai Guide**! You can ask me anything about:\n\n'
        '• Art districts, galleries, and exhibitions across Dubai\n'
        '• Free gallery admissions, opening hours, and transport directions\n'
        '• Booking artists, selling art, or registering as an artist\n'
        '• Curated weekend art tours, creative workshops, and art cafes\n\n'
        'Feel free to type any question below!';
  }

  List<String> get _latestRelatedQuestions {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (!m.isUser && m.relatedQuestions.isNotEmpty) {
        return m.relatedQuestions;
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isArabic = localeProvider.isArabic;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final latestQuestions = _latestRelatedQuestions;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF420E62),
      appBar: const AppTopBar(),
      drawer: _buildChatsDrawer(context, isArabic),
      bottomNavigationBar:
          isKeyboardOpen ? null : const AppBottomNavBar(currentIndex: -1),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5E1788), // Rich Royal Violet
              Color(0xFF501275), // Mid Violet
              Color(0xFF420E62), // Deep Violet base
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: isKeyboardOpen,
          child: Column(
            children: [
              // 1. AI Sub-bar with navigation, history & new chat
              _buildAiSubBar(context, isArabic),

              // 2. Chat / Suggestion Body
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(rh, isArabic)
                    : _buildMessageList(isArabic),
              ),

              // 3. Related Questions docked on top of the text field
              if (_messages.isNotEmpty &&
                  !_isTyping &&
                  !isKeyboardOpen &&
                  latestQuestions.isNotEmpty)
                _buildRelatedQuestionsSection(latestQuestions, rh, isArabic),

              // 4. Bottom Prompt Input
              _buildInputArea(rh, isArabic, isKeyboardOpen: isKeyboardOpen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatsDrawer(BuildContext context, bool isArabic) {
    final drawerWidth = (MediaQuery.of(context).size.width * 0.72).clamp(260.0, 360.0);

    return Drawer(
      backgroundColor: const Color(0xFF5E1788),
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Your chats" + close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'محادثاتك' : 'Your chats',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // New chat button inside drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _clearChat();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'محادثة جديدة' : 'New chat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Chats list grouped date-wise or "No chats yet."
            Expanded(
              child: Builder(
                builder: (context) {
                  final groups = _getGroupedSessions(isArabic);
                  if (groups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Text(
                        isArabic ? 'لا توجد محادثات سابقة بعد.' : 'No chats yet.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    itemCount: groups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = groups[groupIndex];

                      return Column(
                        crossAxisAlignment:
                            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Row(
                              mainAxisAlignment:
                                  isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: isArabic
                                  ? [
                                      Text(
                                        group.title.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: Colors.white.withValues(alpha: 0.50),
                                      ),
                                    ]
                                  : [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: Colors.white.withValues(alpha: 0.50),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        group.title.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                            ),
                          ),
                          ...group.sessions.map((session) {
                            final isSelected = session.id == _currentSessionId;
                            final displayTitle = _translateSessionTitle(session.title, isArabic: isArabic);
                            final isTitleArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(displayTitle);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.40)
                                      : Colors.white.withValues(alpha: 0.10),
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                dense: true,
                                title: Text(
                                  displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: isTitleArabic ? TextDirection.rtl : TextDirection.ltr,
                                  textAlign: isTitleArabic ? TextAlign.right : (isArabic ? TextAlign.right : TextAlign.left),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: isArabic
                                        ? [
                                            Flexible(
                                              child: Text(
                                                _formatSessionDateTime(session.updatedAt, isArabic: isArabic),
                                                textDirection: TextDirection.rtl,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.70),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 11,
                                              color: Colors.white.withValues(alpha: 0.55),
                                            ),
                                          ]
                                        : [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 11,
                                              color: Colors.white.withValues(alpha: 0.55),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _formatSessionDateTime(session.updatedAt, isArabic: isArabic),
                                                textDirection: TextDirection.ltr,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.70),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  tooltip: isArabic ? 'حذف المحادثة' : 'Delete chat',
                                  splashRadius: 18,
                                  onPressed: () => _deleteSession(session.id),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _loadSession(session);
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSubBar(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
            tooltip: isArabic ? 'رجوع' : 'Back',
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'مرشد الفن الذكي' : 'AI ART GUIDE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentSessionId == null
                        ? (isArabic ? 'محادثة جديدة' : 'New chat')
                        : (isArabic ? 'نشط' : 'Active'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // History action -> Opens "Your chats" drawer
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: const Icon(Icons.history, color: Colors.white70, size: 21),
            tooltip: isArabic ? 'محادثاتك' : 'Your chats',
            splashRadius: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),

          // New Chat action
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white70, size: 20),
            tooltip: isArabic ? 'محادثة جديدة' : 'New chat',
            splashRadius: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper rh, bool isArabic) {
    final prompts = _getSuggestedPrompts(isArabic);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth.clamp(320.0, 500.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Central circular logo
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/header_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Main Title
              Text(
                isArabic ? 'مرشد فنان دبي الذكي' : 'ARTIST DUBAI Guide',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  isArabic
                      ? 'اسأل عن الفنانين والفعاليات والمعارض والمراكز الفنية في دبي.'
                      : 'Ask about artists, events, galleries and art centers in Dubai.',
                  textAlign: TextAlign.center,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Suggestion buttons
              ...prompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _sendMessage(prompt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        prompt,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isArabic) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator(isArabic);
        }

        final msg = _messages[index];
        final isUser = msg.isUser;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: EdgeInsets.only(
                    right: isArabic ? 0 : 8,
                    left: isArabic ? 8 : 0,
                    top: 4,
                  ),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/header_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF8A2BE2).withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isUser ? 14 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 14),
                        ),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xFFD03BF7).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: _buildFormattedText(
                        _getLocalizedMessageText(msg.text, isArabic: isArabic, isUser: isUser),
                        isArabic: isArabic,
                        isUser: isUser,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.5, left: 4.0, right: 4.0),
                      child: Text(
                        _formatSessionTime(msg.timestamp, isArabic: isArabic),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }

  String _translateSessionTitle(String title, {required bool isArabic}) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return trimmed;
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed);
    if (hasArabic == isArabic) return trimmed;
    final tr = DataTranslator.translate(trimmed, isArabic: isArabic);
    return tr.isNotEmpty ? tr : trimmed;
  }

  String _translateQuestion(String q, {required bool isArabic}) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return trimmed;
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed);
    if (isArabic == hasArabic) return trimmed;
    final tr = DataTranslator.translate(trimmed, isArabic: isArabic);
    return tr.isNotEmpty ? tr : trimmed;
  }

  String _getLocalizedMessageText(
    String text, {
    required bool isArabic,
    required bool isUser,
  }) {
    if (isUser) {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      if (hasArabic == isArabic) return text;
      final tr = DataTranslator.translate(text, isArabic: isArabic);
      return tr.isNotEmpty ? tr : text;
    }
    return _translateAiResponse(text, isArabic: isArabic);
  }

  String _translateAiResponse(String text, {required bool isArabic}) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (hasArabic == isArabic) {
      return text;
    }
    // Check known curated knowledge base responses:
    // 1. Districts
    if (text.contains('السركال') || text.contains('Alserkal Avenue')) {
      return _generateArtResponse('district', isArabic: isArabic);
    }
    // 2. Register
    if (text.contains('تسجيل فنان') || text.contains('ARTIST REGISTRATION') || text.contains('التسجيل كفنان')) {
      return _generateArtResponse('register', isArabic: isArabic);
    }
    // 3. Tour
    if (text.contains('جولة فنية') || text.contains('Weekend Art Tour') || text.contains('خطة مقترحة')) {
      return _generateArtResponse('tour', isArabic: isArabic);
    }
    // 4. Galleries
    if (text.contains('XVA Gallery') || text.contains('معرض XVA') || text.contains('المعارض الفنية') || text.contains('GALLERIES')) {
      return _generateArtResponse('gallery', isArabic: isArabic);
    }
    // 5. Events & Competition
    if (text.contains('الفعاليات / المسابقات') || text.contains('EVENTS / COMPETITION') || text.contains('اكتشاف جميع المسابقات')) {
      return _generateArtResponse('event', isArabic: isArabic);
    }
    // 6. Welcome / Intro
    if (text.contains('مرشد فنان دبي الذكي') || text.contains('Artist Dubai Guide')) {
      return _generateArtResponse('intro', isArabic: isArabic);
    }
    final tr = DataTranslator.translate(text, isArabic: isArabic);
    return tr.isNotEmpty ? tr : text;
  }

  Widget _buildFormattedText(
    String text, {
    required bool isArabic,
    required bool isUser,
  }) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final textDirection = hasArabic ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = hasArabic
        ? TextAlign.right
        : (isUser && isArabic ? TextAlign.right : TextAlign.left);

    // Parse markdown **bold**
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      final isBold = i.isOdd;
      spans.add(
        TextSpan(
          text: part,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.8,
            height: 1.45,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textDirection: textDirection,
      textAlign: textAlign,
    );
  }

  Widget _buildRelatedQuestionsSection(
    List<String> questions,
    ResponsiveHelper rh,
    bool isArabic,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 4.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
          child: Column(
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: Colors.amberAccent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isArabic ? 'أسئلة مقترحة ذات صلة:' : 'Related questions:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: questions.map((q) {
                    final displayQ = _translateQuestion(q, isArabic: isArabic);
                    final isQArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(displayQ);
                    return Padding(
                      padding: EdgeInsets.only(
                        right: isArabic ? 0 : 8,
                        left: isArabic ? 8 : 0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendMessage(displayQ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayQ,
                                  textDirection:
                                      isQArabic ? TextDirection.rtl : TextDirection.ltr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  isArabic ? Icons.arrow_back : Icons.arrow_forward,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: EdgeInsets.only(
              right: isArabic ? 0 : 8,
              left: isArabic ? 8 : 0,
            ),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'جارٍ التفكير...' : 'Thinking...',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    ResponsiveHelper rh,
    bool isArabic, {
    bool isKeyboardOpen = false,
  }) {
    final hasText = _inputController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, isKeyboardOpen ? 12.0 : 6.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E0749).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasText
                    ? const Color(0xFFD03BF7).withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expandable text field
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'اسأل مرشد الفن...' : 'Ask the art guide...',
                      hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 7.0),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (!_isTyping && val.trim().isNotEmpty) {
                        _sendMessage(val);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Clear button (if text present)
                if (hasText) ...[
                  InkWell(
                    onTap: () {
                      _inputController.clear();
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Send button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (!_isTyping && hasText)
                        ? () => _sendMessage(_inputController.text)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: hasText && !_isTyping
                            ? const LinearGradient(
                                colors: [Color(0xFFB128E6), Color(0xFF6B189D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: (hasText && !_isTyping)
                            ? null
                            : Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                        boxShadow: (hasText && !_isTyping)
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFB128E6).withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Transform.scale(
                          scaleX: isArabic ? -1 : 1,
                          child: Icon(
                            Icons.send_rounded,
                            color: hasText && !_isTyping
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
