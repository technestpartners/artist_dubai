import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../domain/models/artist_message_model.dart';

class ChatService {
  final StorageService _storage;
  final ApiClient _apiClient;

  static const String _keyAllowanceMonth = 'chat_allowance_month';
  static const String _keyAllowanceUsed = 'chat_allowance_used';
  static const String _keyMaxAllowance = 'chat_allowance_max';
  static const String _keyChatPlanName = 'chat_plan_name';
  static const String _keyLocalMessages = 'artist_chat_messages';

  static const int defaultMonthlyAllowance = 10;

  final _messagesController =
      StreamController<List<ArtistMessageModel>>.broadcast();
  Stream<List<ArtistMessageModel>> get messagesStream =>
      _messagesController.stream;

  final _allowanceController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get allowanceStream =>
      _allowanceController.stream;

  ChatService({StorageService? storage, ApiClient? apiClient})
    : _storage = storage ?? sl<StorageService>(),
      _apiClient = apiClient ?? sl<ApiClient>();

  /// Returns current calendar month as string, e.g. "2026-10"
  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Ensure allowance is reset if month rolled over
  void _checkAndResetMonthlyAllowance() {
    final currentMonth = _currentMonthKey();
    final storedMonth = _storage.getString(_keyAllowanceMonth);
    if (storedMonth != currentMonth) {
      _storage.setString(_keyAllowanceMonth, currentMonth);
      _storage.setString(_keyAllowanceUsed, '0');
    }
  }

  /// Get total monthly allowance
  int getMaxMonthlyAllowance() {
    final plan = getChatPlanName().toLowerCase();
    if (plan.contains('unlimited') || plan.contains('vip')) {
      return 9999;
    }
    if (plan.contains('pro')) {
      return 50;
    }
    if (plan.contains('free') ||
        plan.contains('basic') ||
        plan.contains('starter') ||
        plan.isEmpty) {
      return defaultMonthlyAllowance;
    }
    final maxStr = _storage.getString(_keyMaxAllowance);
    if (maxStr != null && maxStr.isNotEmpty) {
      final parsed = int.tryParse(maxStr);
      if (parsed != null) {
        if (parsed >= 9000) return 9999;
        return parsed;
      }
    }
    return defaultMonthlyAllowance;
  }

  /// Get active chat plan name
  String getChatPlanName() {
    final localPlan = _storage.getString('active_plan_chat') ??
        _storage.getString('chat_plan') ??
        _storage.getString(_keyChatPlanName);
    if (localPlan != null && localPlan.isNotEmpty) {
      final lower = localPlan.toLowerCase();
      if (!lower.contains('gallery') &&
          !lower.contains('event') &&
          !lower.contains('centre') &&
          !lower.contains('center') &&
          !lower.contains('portfolio')) {
        return localPlan;
      }
    }
    return 'Basic (Free)';
  }

  /// Set higher allowance (e.g., when upgrading via Plans)
  Future<void> setMaxMonthlyAllowance(int max, {String? planName}) async {
    await _storage.setString(_keyMaxAllowance, max.toString());
    if (planName != null && planName.isNotEmpty) {
      await _storage.setString(_keyChatPlanName, planName);
      await _storage.setString('active_plan_chat', planName);
      await _storage.setString('chat_plan', planName);
    } else if (max >= 9000) {
      await _storage.setString(_keyChatPlanName, 'Unlimited VIP');
      await _storage.setString('active_plan_chat', 'Unlimited VIP');
      await _storage.setString('chat_plan', 'Unlimited VIP');
    } else if (max > defaultMonthlyAllowance) {
      await _storage.setString(_keyChatPlanName, 'Chat & Messaging Pro');
      await _storage.setString('active_plan_chat', 'Chat & Messaging Pro');
      await _storage.setString('chat_plan', 'Chat & Messaging Pro');
    } else {
      await _storage.setString(_keyChatPlanName, 'Basic (Free)');
      await _storage.remove('active_plan_chat');
      await _storage.remove('chat_plan');
    }
    _notifyAllowanceChanged();
  }

  /// Get count of messages left for this month
  int getRemainingAllowance() {
    _checkAndResetMonthlyAllowance();
    final usedStr = _storage.getString(_keyAllowanceUsed) ?? '0';
    final used = int.tryParse(usedStr) ?? 0;
    final max = getMaxMonthlyAllowance();
    if (max >= 9000) return 9999;
    final remaining = max - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Check if user can send a message
  bool canSendMessage() {
    final max = getMaxMonthlyAllowance();
    if (max >= 9000) return true;
    return getRemainingAllowance() > 0;
  }

  /// Decrement allowance after sending a message
  Future<void> _consumeOneMessage() async {
    _checkAndResetMonthlyAllowance();
    final usedStr = _storage.getString(_keyAllowanceUsed) ?? '0';
    final used = int.tryParse(usedStr) ?? 0;
    await _storage.setString(_keyAllowanceUsed, (used + 1).toString());
    _notifyAllowanceChanged();
  }

  void _notifyAllowanceChanged() {
    _allowanceController.add({
      'remaining': getRemainingAllowance(),
      'max': getMaxMonthlyAllowance(),
      'planName': getChatPlanName(),
    });
  }

  String _userLocalMessagesKey() {
    final email = (_storage.getString('user_email') ?? '').trim().toLowerCase();
    final artistId = (_storage.getString('artist_profile_id') ?? '').trim();
    final userId = (_storage.getString('user_id') ?? '').trim();
    if (email.isNotEmpty) return '${_keyLocalMessages}_$email';
    if (artistId.isNotEmpty) return '${_keyLocalMessages}_art_$artistId';
    if (userId.isNotEmpty) return '${_keyLocalMessages}_usr_$userId';
    return _keyLocalMessages;
  }

  dynamic _extractData(dynamic res) {
    if (res is Map) return res;
    try {
      return (res as dynamic).data;
    } catch (_) {
      return null;
    }
  }

  /// Sync allowance and active plan from MySQL backend
  Future<void> syncAllowanceFromBackend() async {
    try {
      final email = (_storage.getString('user_email') ?? '').trim();

      // Clean up legacy non-chat plans mistakenly cached in chat keys
      final storedChat = _storage.getString('chat_plan') ?? '';
      final storedActiveChat = _storage.getString('active_plan_chat') ?? '';
      final storedKeyName = _storage.getString(_keyChatPlanName) ?? '';
      final combinedStored = '$storedChat $storedActiveChat $storedKeyName'.toLowerCase();
      if (combinedStored.contains('gallery') ||
          combinedStored.contains('event') ||
          combinedStored.contains('centre') ||
          combinedStored.contains('center') ||
          combinedStored.contains('portfolio')) {
        await _storage.remove('active_plan_chat');
        await _storage.remove('chat_plan');
        await _storage.setString(_keyChatPlanName, 'Basic (Free)');
        await _storage.setString(_keyMaxAllowance, '10');
      }

      // Check for active purchased chat plan first
      try {
        final activeChat = await sl<ApiService>().getActivePlanForType('chat', email: email);
        if (activeChat != null) {
          final pName = activeChat['plan_name']?.toString() ?? 'Chat & Messaging Pro';
          final pLower = pName.toLowerCase();
          if (!pLower.contains('gallery') && !pLower.contains('event') && !pLower.contains('centre') && !pLower.contains('center') && !pLower.contains('portfolio')) {
            await _storage.setString(_keyChatPlanName, pName);
            await _storage.setString('active_plan_chat', pName);
            await _storage.setString('chat_plan', pName);
            final allowance = (pLower.contains('pro') && !pLower.contains('vip') && !pLower.contains('unlimited')) ? '50' : '9999';
            await _storage.setString(_keyMaxAllowance, allowance);
            _notifyAllowanceChanged();
            return;
          }
        }
      } catch (_) {}

      final res = await _apiClient.get(
        'api.php?resource=messages',
        queryParameters: {
          'action': 'allowance',
          if (email.isNotEmpty) 'user_email': email,
        },
      );
      final dynamic body = _extractData(res);
      final dynamic data = (body is Map) ? body['data'] : null;
      if (data is Map) {
        final maxAllowance =
            int.tryParse(data['max_allowance']?.toString() ?? '') ?? 10;
        final usedMessages =
            int.tryParse(data['used_messages']?.toString() ?? '') ?? 0;
        final planName = data['plan_name']?.toString() ?? 'Basic (Free)';

        await _storage.setString(_keyMaxAllowance, maxAllowance.toString());
        await _storage.setString(_keyAllowanceUsed, usedMessages.toString());
        await _storage.setString(_keyChatPlanName, planName);
        await _storage.setString(_keyAllowanceMonth, _currentMonthKey());

        _notifyAllowanceChanged();
      }
    } catch (e) {
      if (kDebugMode) print('ChatService.syncAllowanceFromBackend error: $e');
    }
  }

  /// Upgrade user's chat allowance plan
  Future<bool> upgradePlan({
    required String planName,
    required int maxAllowance,
  }) async {
    try {
      await _storage.setString(_keyMaxAllowance, maxAllowance.toString());
      await _storage.setString(_keyChatPlanName, planName);
      await _storage.setString('active_plan_chat', planName);
      await _storage.setString('chat_plan', planName);
      _notifyAllowanceChanged();

      final email = _storage.getString('user_email') ?? '';
      if (email.isNotEmpty) {
        await _apiClient.post(
          'api.php?resource=messages&action=upgrade_plan',
          data: {
            'user_email': email,
            'plan_name': planName,
            'max_allowance': maxAllowance,
          },
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('ChatService.upgradePlan error: $e');
      return true; // Local upgrade succeeded
    }
  }

  /// Retrieve all sent / received messages
  Future<List<ArtistMessageModel>> getMessages() async {
    try {
      final cacheKey = _userLocalMessagesKey();
      // 1. First read from local cache (user-scoped or fallback to legacy global key)
      final raw =
          _storage.getString(cacheKey) ?? _storage.getString(_keyLocalMessages);
      List<ArtistMessageModel> messages = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          messages =
              decoded
                  .map(
                    (e) => ArtistMessageModel.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();
        } catch (_) {}
      }

      // 2. Try fetching from remote API
      try {
        final email = (_storage.getString('user_email') ?? '').trim();
        var artistId = (_storage.getString('artist_profile_id') ?? '').trim();
        final userId = (_storage.getString('user_id') ?? '').trim();
        final role = (_storage.getString('user_role') ?? '').trim().toLowerCase();
        final profileName = (_storage.getString('artist_profile_name') ?? '').trim().toLowerCase();
        final isAdminStored = _storage.getBool('is_admin') ?? false;
        final isAdmin =
            isAdminStored ||
            role == 'admin' ||
            profileName.contains('dubai art administrator') ||
            [
              'admin@artistdubai.com',
              'admin@dubaiart.ae',
              'admin@admin.com',
              'admin@technestpartners.com',
            ].contains(email.toLowerCase());

        final Map<String, dynamic> queryParams = {};
        if (email.isNotEmpty) queryParams['user_email'] = email;
        if (artistId.isNotEmpty) queryParams['artist_id'] = artistId;
        if (userId.isNotEmpty) queryParams['user_id'] = userId;
        if (isAdmin) {
          queryParams['is_admin'] = '1';
          if (artistId.isEmpty) {
            queryParams['artist_id'] = '28';
          }
        }

        final res = await _apiClient.get(
          'api.php?resource=messages',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final dynamic body = _extractData(res);
        final dynamic rawList = (body is Map) ? body['data'] : null;
        if (rawList is List) {
          final serverList =
              rawList
                  .map(
                    (e) => ArtistMessageModel.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();

          // Merge: server records are authoritative, keep only pending optimistic messages that haven't been saved yet
          final now = DateTime.now();
          final localOnly =
              messages.where((m) {
                if (!m.id.startsWith('msg_')) return false;
                // Purge optimistic messages older than 10 minutes so orphaned ones never linger forever
                if (now.difference(m.createdAt).inMinutes >= 10) return false;

                // Check if this optimistic message has already been received from server
                final isAlreadyOnServer = serverList.any((s) {
                  final sameSender =
                      s.senderEmail.trim().toLowerCase() ==
                          m.senderEmail.trim().toLowerCase() ||
                      (s.senderId.isNotEmpty && s.senderId == m.senderId);
                  final sameRecipient =
                      s.recipientId.trim() == m.recipientId.trim() ||
                      s.recipientName.trim().toLowerCase() ==
                          m.recipientName.trim().toLowerCase();
                  final sameSubject =
                      s.subject.trim().toLowerCase() ==
                      m.subject.trim().toLowerCase();
                  final sameMessage = s.message.trim() == m.message.trim();
                  final closeInTime =
                      s.createdAt.difference(m.createdAt).abs().inMinutes < 5;

                  return sameSender &&
                      sameRecipient &&
                      sameSubject &&
                      sameMessage &&
                      closeInTime;
                });

                return !isAlreadyOnServer;
              }).toList();

          messages = [...serverList, ...localOnly];
          await _storage.setString(
            cacheKey,
            jsonEncode(messages.map((m) => m.toJson()).toList()),
          );
        }
      } catch (e) {
        if (kDebugMode) print('ChatService.getMessages remote error: $e');
      }

      // Deduplicate messages by id first, then by (senderEmail, recipientId, subject, message, approximate time)
      final seenIds = <String>{};
      final uniqueMessages = <ArtistMessageModel>[];
      for (final m in messages) {
        if (m.id.isNotEmpty && seenIds.contains(m.id)) continue;
        if (m.id.isNotEmpty) seenIds.add(m.id);

        final isDuplicateContent = uniqueMessages.any((u) {
          final sameSender =
              u.senderEmail.trim().toLowerCase() ==
              m.senderEmail.trim().toLowerCase();
          final sameRecipient = u.recipientId.trim() == m.recipientId.trim();
          final sameSubject =
              u.subject.trim().toLowerCase() == m.subject.trim().toLowerCase();
          final sameMessage = u.message.trim() == m.message.trim();
          final closeInTime =
              u.createdAt.difference(m.createdAt).abs().inMinutes < 2;
          return sameSender &&
              sameRecipient &&
              sameSubject &&
              sameMessage &&
              closeInTime;
        });

        if (!isDuplicateContent) {
          uniqueMessages.add(m);
        }
      }

      // Sort newest first
      uniqueMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _messagesController.add(uniqueMessages);
      return uniqueMessages;
    } catch (e) {
      if (kDebugMode) print('ChatService.getMessages error: $e');
      return [];
    }
  }

  /// Send a private message to an artist
  Future<ArtistMessageModel> sendMessage({
    required String recipientId,
    required String recipientName,
    required String recipientCategory,
    String? recipientAvatarUrl,
    required String subject,
    required String message,
    String? flyerUrl,
  }) async {
    if (!canSendMessage()) {
      throw Exception(
        'Monthly message limit reached. Upgrade your plan for more.',
      );
    }

    // Determine sender information
    String senderName =
        _storage.getString('artist_profile_name') ??
        _storage.getString('user_name') ??
        'Guest Artist';
    String senderEmail =
        _storage.getString('user_email') ?? 'artist@artistdubai.com';
    String senderId =
        _storage.getString('artist_profile_id') ??
        _storage.getString('user_id') ??
        'user_${DateTime.now().millisecondsSinceEpoch}';
    String? senderAvatar =
        _storage.getString('user_avatar') ??
        _storage.getString('artist_profile_avatar');

    final newMessage = ArtistMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      senderAvatarUrl: senderAvatar,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientCategory: recipientCategory,
      recipientAvatarUrl: recipientAvatarUrl,
      subject: subject.trim(),
      message: message.trim(),
      flyerUrl: flyerUrl,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // Save to local cache — read raw cache directly to avoid triggering a
    // network fetch (which can race with the POST below and cause duplicates).
    final cacheKey = _userLocalMessagesKey();
    final rawCached = _storage.getString(cacheKey) ?? _storage.getString(_keyLocalMessages);
    List<ArtistMessageModel> currentList = [];
    if (rawCached != null && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as List<dynamic>;
        currentList = decoded
            .map((e) => ArtistMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    final updatedList = [newMessage, ...currentList];
    await _storage.setString(
      cacheKey,
      jsonEncode(updatedList.map((m) => m.toJson()).toList()),
    );

    // Consume allowance
    await _consumeOneMessage();

    // Fire stream update
    _messagesController.add(updatedList);

    // Attempt remote save — do NOT re-fetch after posting; the view will
    // call getMessages() separately, which will deduplicate correctly.
    try {
      await _apiClient.post(
        'api.php?resource=messages',
        data: newMessage.toJson(),
      );
    } catch (_) {
      // Safely stored locally
    }

    return newMessage;
  }

  void dispose() {
    _messagesController.close();
    _allowanceController.close();
  }
}
