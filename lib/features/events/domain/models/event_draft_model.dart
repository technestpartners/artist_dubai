import 'dart:convert';

/// Represents an unfinished event draft that was initiated but pending payment.
/// Preserves user inputs if the user backs out or closes the app at the payment step.
class EventDraftModel {
  final String title;
  final String? subtitle;
  final String? description;
  final String? category;
  final String? eventDate;
  final String? endDate;
  final String? location;
  final String? venue;
  final bool isFree;
  final String? price;
  final int maxAttendees;
  final String? organizerName;
  final String? contactEmail;
  final String? contactPhone;
  final String? tags;
  final String? imageUrl;
  final String? planId;
  final String? planName;
  final String? planAmount;
  final DateTime createdAt;
  final Map<String, dynamic> rawFormData;

  EventDraftModel({
    required this.title,
    this.subtitle,
    this.description,
    this.category,
    this.eventDate,
    this.endDate,
    this.location,
    this.venue,
    this.isFree = true,
    this.price,
    this.maxAttendees = 100,
    this.organizerName,
    this.contactEmail,
    this.contactPhone,
    this.tags,
    this.imageUrl,
    this.planId,
    this.planName,
    this.planAmount,
    DateTime? createdAt,
    required this.rawFormData,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category,
      'event_date': eventDate,
      'end_date': endDate,
      'location': location,
      'venue': venue,
      'is_free': isFree,
      'price': price,
      'max_attendees': maxAttendees,
      'organizer_name': organizerName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'tags': tags,
      'image_url': imageUrl,
      'plan_id': planId,
      'plan_name': planName,
      'plan_amount': planAmount,
      'created_at': createdAt.toIso8601String(),
      'raw_form_data': rawFormData,
    };
  }

  factory EventDraftModel.fromJson(Map<String, dynamic> json) {
    final rawForm = json['raw_form_data'] is Map
        ? Map<String, dynamic>.from(json['raw_form_data'] as Map)
        : <String, dynamic>{};

    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return EventDraftModel(
      title: (json['title'] ?? rawForm['title'] ?? 'Untitled Event').toString(),
      subtitle: json['subtitle']?.toString() ??
          (rawForm['category'] != null
              ? '${rawForm['category']} • ${rawForm['location'] ?? 'Dubai, UAE'}'
              : null),
      description: (json['description'] ?? rawForm['description'])?.toString(),
      category: (json['category'] ?? rawForm['category'])?.toString(),
      eventDate: (json['event_date'] ?? rawForm['event_date'])?.toString(),
      endDate: (json['end_date'] ?? rawForm['end_date'])?.toString(),
      location: (json['location'] ?? rawForm['location'])?.toString(),
      venue: (json['venue'] ?? rawForm['venue'])?.toString(),
      isFree: json['is_free'] == true || rawForm['is_free'] == true,
      price: (json['price'] ?? rawForm['price'])?.toString(),
      maxAttendees: int.tryParse(
              (json['max_attendees'] ?? rawForm['max_attendees'])?.toString() ??
                  '100') ??
          100,
      organizerName:
          (json['organizer_name'] ?? rawForm['organizer_name'])?.toString(),
      contactEmail:
          (json['contact_email'] ?? rawForm['contact_email'])?.toString(),
      contactPhone:
          (json['contact_phone'] ?? rawForm['contact_phone'])?.toString(),
      tags: (json['tags'] ?? rawForm['tags'])?.toString(),
      imageUrl: (json['image_url'] ?? rawForm['image_url'])?.toString(),
      planId: (json['plan_id'] ?? rawForm['planId'])?.toString(),
      planName: (json['plan_name'] ?? rawForm['planName'])?.toString(),
      planAmount: (json['plan_amount'] ?? rawForm['planAmount'])?.toString(),
      createdAt: parsedDate,
      rawFormData: rawForm.isNotEmpty ? rawForm : json,
    );
  }

  /// Converts this draft directly into the argument map expected by [PlanPaymentView].
  Map<String, dynamic> toPaymentArgs() {
    return {
      'itemType': 'event',
      'title': title,
      'subtitle': subtitle ?? '${category ?? 'Art Exhibition'} • ${location ?? 'Dubai, UAE'}',
      'planId': planId ?? 'one_time',
      'planName': planName ?? 'Listing Plan',
      'planAmount': planAmount ?? 'AED 2,500',
      'formData': rawFormData,
    };
  }

  String encode() => jsonEncode(toJson());

  static EventDraftModel? decode(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) return null;
    try {
      final map = jsonDecode(jsonString);
      if (map is Map<String, dynamic>) {
        return EventDraftModel.fromJson(map);
      } else if (map is Map) {
        return EventDraftModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }
}
