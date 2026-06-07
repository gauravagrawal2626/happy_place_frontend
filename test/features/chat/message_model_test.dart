import 'package:flutter_test/flutter_test.dart';
import 'package:happy_place_frontend/features/chat/model/message_model.dart';

void main() {
  test('Message.fromJson parses POST response shape', () {
    final json = {
      'id': 'msg1',
      'conversation_id': 'conv1',
      'sender_id': 'u1',
      'body': 'Hello',
      'created_at': '2026-06-01T10:00:00Z',
    };

    final message = Message.fromJson(json);

    expect(message.id, 'msg1');
    expect(message.conversationId, 'conv1');
    expect(message.senderId, 'u1');
    expect(message.body, 'Hello');
    expect(message.createdAt.toUtc().toIso8601String(), '2026-06-01T10:00:00.000Z');
  });

  test('Message.fromJson accepts _id alias', () {
    final message = Message.fromJson({
      '_id': 'mongo_id',
      'conversation_id': 'c1',
      'sender_id': 'u1',
      'body': 'Hi',
      'created_at': '2026-06-01T10:00:00Z',
    });

    expect(message.id, 'mongo_id');
  });
}
