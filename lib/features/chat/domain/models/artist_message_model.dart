class ArtistMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderAvatarUrl;
  final String recipientId;
  final String recipientName;
  final String recipientCategory;
  final String? recipientAvatarUrl;
  final String subject;
  final String message;
  final String? flyerUrl;
  final DateTime createdAt;
  final bool isRead;

  const ArtistMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderAvatarUrl,
    required this.recipientId,
    required this.recipientName,
    this.recipientCategory = 'Artist',
    this.recipientAvatarUrl,
    required this.subject,
    required this.message,
    this.flyerUrl,
    required this.createdAt,
    this.isRead = false,
  });

  factory ArtistMessageModel.fromJson(Map<String, dynamic> json) {
    return ArtistMessageModel(
      id: json['id']?.toString() ?? '',
      senderId:
          json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName:
          json['sender_name']?.toString() ??
          json['senderName']?.toString() ??
          'User',
      senderEmail:
          json['sender_email']?.toString() ??
          json['senderEmail']?.toString() ??
          '',
      senderAvatarUrl:
          json['sender_avatar_url']?.toString() ??
          json['senderAvatarUrl']?.toString(),
      recipientId:
          json['recipient_id']?.toString() ??
          json['recipientId']?.toString() ??
          '',
      recipientName:
          json['recipient_name']?.toString() ??
          json['recipientName']?.toString() ??
          'Artist',
      recipientCategory:
          json['recipient_category']?.toString() ??
          json['recipientCategory']?.toString() ??
          'Artist',
      recipientAvatarUrl:
          json['recipient_avatar_url']?.toString() ??
          json['recipientAvatarUrl']?.toString(),
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      flyerUrl: json['flyer_url']?.toString() ?? json['flyerUrl']?.toString(),
      createdAt: parseDateTime(json['created_at'] ?? json['createdAt']),
      isRead:
          json['is_read'] == true ||
          json['is_read'] == 1 ||
          json['isRead'] == true,
    );
  }

  /// Parses MySQL datetime string (UTC) or ISO-8601 string and converts it to local device timezone.
  static DateTime parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw.toLocal();
    final str = raw.toString().trim();
    if (str.isEmpty) return DateTime.now();

    // If it already contains timezone indicators (Z, +, or negative timezone offset)
    if (str.endsWith('Z') ||
        str.contains('+') ||
        RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed.toLocal();
    }

    // Standard MySQL DATETIME 'YYYY-MM-DD HH:MM:SS' without offset is stored in UTC
    final iso = str.contains('T') ? str : str.replaceFirst(' ', 'T');
    final utc = DateTime.tryParse('${iso}Z');
    if (utc != null) {
      return utc.toLocal();
    }

    final fallback = DateTime.tryParse(iso);
    return fallback != null ? fallback.toLocal() : DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_email': senderEmail,
      'sender_avatar_url': senderAvatarUrl,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'recipient_category': recipientCategory,
      'recipient_avatar_url': recipientAvatarUrl,
      'subject': subject,
      'message': message,
      'flyer_url': flyerUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  ArtistMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderAvatarUrl,
    String? recipientId,
    String? recipientName,
    String? recipientCategory,
    String? recipientAvatarUrl,
    String? subject,
    String? message,
    String? flyerUrl,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ArtistMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientCategory: recipientCategory ?? this.recipientCategory,
      recipientAvatarUrl: recipientAvatarUrl ?? this.recipientAvatarUrl,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      flyerUrl: flyerUrl ?? this.flyerUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
