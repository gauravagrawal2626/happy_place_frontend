import 'package:flutter_test/flutter_test.dart';
import 'package:happy_place_frontend/features/chat/model/message_model.dart';
import 'package:happy_place_frontend/features/chat/utils/message_merge.dart';

Message _msg(String id, String body, {int minute = 0}) => Message(
      id: id,
      conversationId: 'c1',
      senderId: 'u1',
      body: body,
      createdAt: DateTime.utc(2026, 1, 1, 12, minute),
    );

void main() {
  group('mergeMessages', () {
    test('appends new message by id', () {
      final existing = [_msg('1', 'Hi')];
      final incoming = [_msg('2', 'Hello')];

      final result = mergeMessages(existing, incoming);

      expect(result.map((m) => m.id), ['1', '2']);
    });

    test('dedupes duplicate id from Ably echo', () {
      final existing = [_msg('1', 'Hi'), _msg('2', 'Sent')];
      final incoming = [_msg('2', 'Sent')];

      final result = mergeMessages(existing, incoming);

      expect(result.length, 2);
      expect(result.map((m) => m.id), ['1', '2']);
    });

    test('merges older page when paginating', () {
      final existing = [_msg('2', 'B', minute: 1), _msg('3', 'C', minute: 2)];
      final incoming = [_msg('1', 'A', minute: 0)];

      final result = mergeMessages(existing, incoming);

      expect(result.map((m) => m.id), ['1', '2', '3']);
    });
  });
}
