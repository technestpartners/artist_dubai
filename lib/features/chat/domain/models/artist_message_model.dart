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
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? json['senderName']?.toString() ?? 'User',
      senderEmail: json['sender_email']?.toString() ?? json['senderEmail']?.toString() ?? '',
      senderAvatarUrl: json['sender_avatar_url']?.toString() ?? json['senderAvatarUrl']?.toString(),
      recipientId: json['recipient_id']?.toString() ?? json['recipientId']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? json['recipientName']?.toString() ?? 'Artist',
      recipientCategory: json['recipient_category']?.toString() ?? json['recipientCategory']?.toString() ?? 'Artist',
      recipientAvatarUrl: json['recipient_avatar_url']?.toString() ?? json['recipientAvatarUrl']?.toString(),
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      flyerUrl: json['flyer_url']?.toString() ?? json['flyerUrl']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['isRead'] == true,
    );
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
      'created_at': createdAt.toIso8601String(),
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
