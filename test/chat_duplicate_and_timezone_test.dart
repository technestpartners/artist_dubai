import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/chat/domain/models/artist_message_model.dart';

void main() {
  group('ArtistMessageModel Timezone & Deduplication Tests', () {
    test('Parses MySQL UTC date string and converts to local DateTime', () {
      final json = {
        'id': '101',
        'sender_id': '1',
        'sender_name': 'My User',
        'sender_email': 'test@example.com',
        'recipient_id': '28',
        'recipient_name': 'Dubai Art Administrator',
        'subject': 'Re: test',
        'message': 'Hi',
        'created_at': '2026-10-22 05:40:00',
        'is_read': 0,
      };

      final msg = ArtistMessageModel.fromJson(json);

      // The parsed DateTime should represent the exact instant of 2026-10-22 05:40:00 UTC
      expect(msg.createdAt.toUtc().year, 2026);
      expect(msg.createdAt.toUtc().month, 10);
      expect(msg.createdAt.toUtc().day, 22);
      expect(msg.createdAt.toUtc().hour, 5);
      expect(msg.createdAt.toUtc().minute, 40);

      // Verify that toJson serializes to ISO UTC string
      final serialized = msg.toJson();
      expect(serialized['created_at'], contains('2026-10-22T05:40:00'));
    });

    test('Optimistic message with local timestamp and server message with UTC timestamp match within 30 min window', () {
      // Server returned message stored in UTC at 05:40:00
      final serverMsg = ArtistMessageModel.fromJson({
        'id': '200',
        'sender_id': 'user_123',
        'sender_name': 'Test User',
        'recipient_id': '28',
        'recipient_name': 'Dubai Art Administrator',
        'subject': 'Re: test',
        'message': 'Hi',
        'created_at': '2026-10-22 05:40:00',
      });

      // Optimistic client message created at device local time (equivalent to UTC 05:40:05)
      final optimisticMsg = ArtistMessageModel(
        id: 'msg_1729575605000',
        senderId: 'user_123',
        senderName: 'Test User',
        senderEmail: 'test@example.com',
        recipientId: '28',
        recipientName: 'Dubai Art Administrator',
        subject: 'Re: test',
        message: 'Hi',
        createdAt: DateTime.utc(2026, 10, 22, 5, 40, 5).toLocal(),
      );

      // Check difference in UTC
      final diffMinutes = serverMsg.createdAt.toUtc().difference(optimisticMsg.createdAt.toUtc()).abs().inMinutes;
      expect(diffMinutes < 30, isTrue);

      // Deduplication condition test
      final isDuplicate = serverMsg.message.trim() == optimisticMsg.message.trim() &&
          serverMsg.subject.trim().toLowerCase() == optimisticMsg.subject.trim().toLowerCase() &&
          serverMsg.recipientId.trim() == optimisticMsg.recipientId.trim() &&
          serverMsg.createdAt.toUtc().difference(optimisticMsg.createdAt.toUtc()).abs().inMinutes < 30;

      expect(isDuplicate, isTrue);
    });
  });
}
