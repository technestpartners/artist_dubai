import 'package:flutter/foundation.dart';
import '../di/injection_container.dart';
import 'storage_service.dart';
import '../../features/events/domain/models/event_draft_model.dart';

/// Central service that manages local drafts for events pending payment.
/// Ensures users never lose their event data if they navigate back, close
/// the payment modal, or experience interruptions during checkout.
class EventDraftService {
  static const String _keyPrefix = 'artist_dubai_event_draft_';
  static const String _activeKey = 'artist_dubai_event_draft_active';

  /// ValueNotifier to trigger UI updates in MyEventsView or CreateArtEventView when drafts change
  static final ValueNotifier<EventDraftModel?> activeDraftNotifier =
      ValueNotifier<EventDraftModel?>(null);

  static String _getUserKey([String? email]) {
    String cleanEmail = (email ?? '').trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      try {
        cleanEmail =
            (sl<StorageService>().getString('user_email') ?? '').trim().toLowerCase();
      } catch (_) {}
    }
    return cleanEmail.isNotEmpty ? '$_keyPrefix$cleanEmail' : _activeKey;
  }

  /// Saves or updates the current event draft in persistent storage.
  static Future<void> saveDraft({
    required String title,
    String? subtitle,
    required String planId,
    required String planName,
    required String planAmount,
    required Map<String, dynamic> formData,
    String? userEmail,
  }) async {
    try {
      final draft = EventDraftModel(
        title: title,
        subtitle: subtitle,
        description: formData['description']?.toString(),
        category: formData['category']?.toString(),
        eventDate: formData['event_date']?.toString(),
        endDate: formData['end_date']?.toString(),
        location: formData['location']?.toString(),
        venue: formData['venue']?.toString(),
        isFree: formData['is_free'] == true,
        price: formData['price']?.toString(),
        maxAttendees: int.tryParse(formData['max_attendees']?.toString() ?? '100') ?? 100,
        organizerName: formData['organizer_name']?.toString(),
        contactEmail: formData['contact_email']?.toString() ?? userEmail,
        contactPhone: formData['contact_phone']?.toString(),
        tags: formData['tags']?.toString(),
        imageUrl: formData['image_url']?.toString(),
        planId: planId,
        planName: planName,
        planAmount: planAmount,
        createdAt: DateTime.now(),
        rawFormData: formData,
      );

      final encoded = draft.encode();
      final storage = sl<StorageService>();

      // Save both to user-specific key and global active key
      final userKey = _getUserKey(userEmail ?? draft.contactEmail);
      await storage.setString(userKey, encoded);
      await storage.setString(_activeKey, encoded);

      activeDraftNotifier.value = draft;
      debugPrint('[EventDraftService] Event draft saved for title: "${draft.title}"');
    } catch (e) {
      debugPrint('[EventDraftService] Error saving draft: $e');
    }
  }

  /// Retrieves the current active draft for the logged-in user or device.
  static EventDraftModel? getDraft([String? email]) {
    try {
      final storage = sl<StorageService>();
      final userKey = _getUserKey(email);
      String? raw = storage.getString(userKey);

      // Fallback to active key if userKey not found
      if (raw == null || raw.trim().isEmpty) {
        raw = storage.getString(_activeKey);
      }

      final draft = EventDraftModel.decode(raw);
      activeDraftNotifier.value = draft;
      return draft;
    } catch (e) {
      debugPrint('[EventDraftService] Error reading draft: $e');
      return null;
    }
  }

  /// Checks whether an event draft currently exists.
  static bool hasDraft([String? email]) {
    return getDraft(email) != null;
  }

  /// Clears the saved event draft after successful publication or explicit user deletion.
  static Future<void> clearDraft([String? email]) async {
    try {
      final storage = sl<StorageService>();
      final userKey = _getUserKey(email);
      await storage.remove(userKey);
      await storage.remove(_activeKey);
      activeDraftNotifier.value = null;
      debugPrint('[EventDraftService] Event draft cleared.');
    } catch (e) {
      debugPrint('[EventDraftService] Error clearing draft: $e');
    }
  }
}
