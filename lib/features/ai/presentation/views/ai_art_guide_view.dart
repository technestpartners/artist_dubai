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

  String get _currentStorageKey {
    final storage = sl<StorageService>();
    final email = storage.getString('user_email')?.trim().toLowerCase();
    final userId = storage.getString('user_id')?.trim();
    if (email != null && email.isNotEmpty) {
      return 'ai_chat_sessions_${email}_v1';
    }
    if (userId != null && userId.isNotEmpty) {
      return 'ai_chat_sessions_uid_${userId}_v1';
    }
    return 'ai_chat_sessions_v1';
  }

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


  @override
  void initState() {
    super.initState();
    _loadSavedSessions();
    _fetchBackendSessions();
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onInputChanged() {
    // Retained as a safe no-op for hot reload compatibility with previous state instances
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    try {
      _inputController.removeListener(_onInputChanged);
    } catch (_) {}
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadSavedSessions() {
    try {
      final storage = sl<StorageService>();
      final raw = storage.getString(_currentStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _savedSessions.clear();
          for (final item in decoded) {
            _savedSessions.add(_ChatSession.fromJson(item as Map<String, dynamic>));
          }
          _savedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
      } else {
        setState(() {
          _savedSessions.clear();
        });
      }
    } catch (_) {}
  }

  void _saveSessionsToDisk() {
    try {
      final storage = sl<StorageService>();
      final encoded = jsonEncode(_savedSessions.map((s) => s.toJson()).toList());
      storage.setString(_currentStorageKey, encoded);
    } catch (_) {}
  }

  Future<void> _fetchBackendSessions() async {
    try {
      final storage = sl<StorageService>();
      final email = storage.getString('user_email')?.trim();
      final userId = storage.getString('user_id')?.trim();

      // If neither email nor userId is set, don't query remote user sessions
      if ((email == null || email.isEmpty) && (userId == null || userId.isEmpty)) {
        return;
      }

      final api = sl<ApiService>();
      final backendList = await api.getAiChatSessions(userEmail: email, userId: userId);
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

    // Sync latest messages from database
    try {
      final api = sl<ApiService>();
      final rawMsgs = await api.getAiChatMessages(session.id);
      if (rawMsgs.isNotEmpty && mounted && _currentSessionId == session.id) {
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
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: replyText,
            isUser: false,
            relatedQuestions: relatedQuestions,
          ));
        });
        _syncCurrentSession(isFirstMsg ? query : _safeCurrentSessionTitle(query));
        _scrollToBottom();
        return;
      }
    } catch (e) {
      debugPrint('Backend AI request error: $e');
    }

    // Honest network / service error if Gemini was unreachable (no hardcoded canned responses)
    if (mounted) {
      final errorText = isArabic
          ? 'عذراً، تعذر الاتصال بمحرك الذكاء الاصطناعي (Google Gemini) في الوقت الحالي. يرجى التحقق من اتصال الإنترنت والمحاولة مجدداً.'
          : 'Unable to connect to Google Gemini AI service at the moment. Please check your internet connection and try again.';
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: errorText,
          isUser: false,
          relatedQuestions: const [],
        ));
      });
      _syncCurrentSession(isFirstMsg ? query : _safeCurrentSessionTitle(query));
      _scrollToBottom();
    }
  }

  String _safeCurrentSessionTitle(String defaultTitle) {
    try {
      final match = _savedSessions.where((s) => s.id == _currentSessionId);
      if (match.isNotEmpty) return match.first.title;
    } catch (_) {}
    return defaultTitle;
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
    final latestQuestions = _latestRelatedQuestions;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF420E62),
      appBar: const AppTopBar(),
      drawer: _buildChatsDrawer(context, isArabic),
      resizeToAvoidBottomInset: true,
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
          bottom: true,
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
                  latestQuestions.isNotEmpty)
                _buildRelatedQuestionsSection(latestQuestions, rh, isArabic),

              // 4. Bottom Prompt Input
              _buildInputArea(rh, isArabic),
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
                            final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(displayTitle).length;
                            final latinChars = RegExp(r'[a-zA-Z]').allMatches(displayTitle).length;
                            final isTitleArabic = isArabic ? (latinChars == 0 || arabicChars >= latinChars) : (arabicChars > 0 && latinChars == 0);

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
                                  textAlign: isTitleArabic ? TextAlign.right : TextAlign.left,
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
                Flexible(
                  child: Text(
                    isArabic ? 'مرشد الفن الذكي' : 'AI ART GUIDE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentSessionId == null
                        ? (isArabic ? 'جديدة' : 'New')
                        : (isArabic ? 'نشط' : 'Active'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.0,
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
              _fetchBackendSessions();
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
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(trimmed).length;
    final latinChars = RegExp(r'[a-zA-Z]').allMatches(trimmed).length;
    final isTextArabic = arabicChars > latinChars;
    if (hasArabicTitleMatch(isTextArabic, isArabic)) return trimmed;
    final tr = DataTranslator.translate(trimmed, isArabic: isArabic);
    return tr.isNotEmpty ? tr : trimmed;
  }

  bool hasArabicTitleMatch(bool isTextArabic, bool isArabic) => isTextArabic == isArabic;


  String _translateQuestion(String q, {required bool isArabic}) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return trimmed;
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(trimmed).length;
    final latinChars = RegExp(r'[a-zA-Z]').allMatches(trimmed).length;
    final isTextArabic = arabicChars > latinChars;
    if (isArabic == isTextArabic) return trimmed;
    final tr = DataTranslator.translate(trimmed, isArabic: isArabic);
    return tr.isNotEmpty ? tr : trimmed;
  }

  String _getLocalizedMessageText(
    String text, {
    required bool isArabic,
    required bool isUser,
  }) {
    if (text.trim().isEmpty) return text;
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    final latinChars = RegExp(r'[a-zA-Z]').allMatches(text).length;
    final isTextArabic = arabicChars > latinChars;
    if (isTextArabic == isArabic) return text;

    // Direct dictionary or cache translation
    final tr = DataTranslator.translate(text, isArabic: isArabic);
    if (tr.isNotEmpty && tr != text) return tr;

    // For multi-line text (e.g. AI formatted answers), translate each line
    if (text.contains('\n')) {
      final lines = text.split('\n');
      final translatedLines = lines.map((line) {
        if (line.trim().isEmpty) return line;
        final trLine = DataTranslator.translate(line, isArabic: isArabic);
        return trLine.isNotEmpty ? trLine : line;
      }).toList();
      return translatedLines.join('\n');
    }

    return text;
  }

  Widget _buildFormattedText(
    String text, {
    required bool isArabic,
    required bool isUser,
  }) {
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    final latinChars = RegExp(r'[a-zA-Z]').allMatches(text).length;

    // A message is considered RTL only if:
    // 1) The user is explicitly in Arabic mode AND it's not overwhelmingly Latin English, OR
    // 2) The text is predominantly Arabic (> Latin characters and substantial Arabic text)
    final bool isRtlText;
    if (isArabic) {
      isRtlText = latinChars == 0 || arabicChars >= latinChars;
    } else {
      isRtlText = arabicChars > 0 && latinChars == 0;
    }

    final textDirection = isRtlText ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRtlText
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
    bool isArabic,
  ) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _inputController,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E0749).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasText
                          ? const Color(0xFFD03BF7).withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
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
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          enabled: !_isTyping,
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
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
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
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.65),
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
                                  : Colors.white.withValues(alpha: 0.12),
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
          ),
        );
      },
    );
  }
}
