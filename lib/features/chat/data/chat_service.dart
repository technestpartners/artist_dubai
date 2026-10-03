import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../domain/models/artist_message_model.dart';

class ChatService {
  final StorageService _storage;
  final ApiClient _apiClient;

  static const String _keyAllowanceMonth = 'chat_allowance_month';
  static const String _keyAllowanceUsed = 'chat_allowance_used';
  static const String _keyMaxAllowance = 'chat_allowance_max';
  static const String _keyLocalMessages = 'artist_chat_messages';

  static const int defaultMonthlyAllowance = 10;

  final _messagesController = StreamController<List<ArtistMessageModel>>.broadcast();
  Stream<List<ArtistMessageModel>> get messagesStream => _messagesController.stream;

  ChatService({
    StorageService? storage,
    ApiClient? apiClient,
  })  : _storage = storage ?? sl<StorageService>(),
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
    final maxStr = _storage.getString(_keyMaxAllowance);
    if (maxStr != null && maxStr.isNotEmpty) {
      return int.tryParse(maxStr) ?? defaultMonthlyAllowance;
    }
    return defaultMonthlyAllowance;
  }

  /// Set higher allowance (e.g., when upgrading via Listing Plans)
  Future<void> setMaxMonthlyAllowance(int max) async {
    await _storage.setString(_keyMaxAllowance, max.toString());
  }

  /// Get count of messages left for this month
  int getRemainingAllowance() {
    _checkAndResetMonthlyAllowance();
    final usedStr = _storage.getString(_keyAllowanceUsed) ?? '0';
    final used = int.tryParse(usedStr) ?? 0;
    final max = getMaxMonthlyAllowance();
    final remaining = max - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Check if user can send a message
  bool canSendMessage() {
    return getRemainingAllowance() > 0;
  }

  /// Decrement allowance after sending a message
  Future<void> _consumeOneMessage() async {
    _checkAndResetMonthlyAllowance();
    final usedStr = _storage.getString(_keyAllowanceUsed) ?? '0';
    final used = int.tryParse(usedStr) ?? 0;
    await _storage.setString(_keyAllowanceUsed, (used + 1).toString());
  }

  /// Retrieve all sent / received messages
  Future<List<ArtistMessageModel>> getMessages() async {
    try {
      // 1. First read from local cache
      final raw = _storage.getString(_keyLocalMessages);
      List<ArtistMessageModel> messages = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        messages = decoded
            .map((e) => ArtistMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      // 2. Try fetching from remote API
      try {
        final res = await _apiClient.get('api.php?resource=messages');
        if (res.data is Map && res.data['data'] is List) {
          final serverList = (res.data['data'] as List)
              .map((e) => ArtistMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (serverList.isNotEmpty) {
            messages = serverList;
            await _storage.setString(
              _keyLocalMessages,
              jsonEncode(messages.map((m) => m.toJson()).toList()),
            );
          }
        }
      } catch (_) {
        // Fall back to local messages seamlessly
      }

      // Sort newest first
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _messagesController.add(messages);
      return messages;
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
      throw Exception('Monthly message limit reached. Upgrade your plan for more.');
    }

    // Determine sender information
    String senderName = _storage.getString('user_name') ?? 'Guest Artist';
    String senderEmail = _storage.getString('user_email') ?? 'artist@artistdubai.com';
    String senderId = _storage.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    final newMessage = ArtistMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
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

    // Save to local cache
    final currentList = await getMessages();
    final updatedList = [newMessage, ...currentList];
    await _storage.setString(
      _keyLocalMessages,
      jsonEncode(updatedList.map((m) => m.toJson()).toList()),
    );

    // Consume allowance
    await _consumeOneMessage();

    // Fire stream update
    _messagesController.add(updatedList);

    // Attempt remote save in background
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
  }
}
