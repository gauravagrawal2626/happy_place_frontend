import 'package:flutter_test/flutter_test.dart';
import 'package:happy_place_frontend/features/chat/model/conversation_model.dart';

void main() {
  test('ConversationsListResponse parses wrapper', () {
    final json = {
      'conversations': [
        {
          'id': 'conv1',
          'request_id': 'req1',
          'flat_id': 'flat1',
          'other_person': {
            'user_id': 'u2',
            'full_name': 'Rahul Kumar',
          },
          'last_message_preview': 'Hi!',
          'last_message_at': '2026-06-01T10:00:00Z',
          'created_at': '2026-06-01T09:00:00Z',
        },
      ],
      'total': 1,
    };

    final result = ConversationsListResponse.fromJson(json);

    expect(result.total, 1);
    expect(result.conversations.length, 1);
    expect(result.conversations.first.id, 'conv1');
    expect(result.conversations.first.otherPerson.fullName, 'Rahul Kumar');
    expect(result.conversations.first.lastMessagePreview, 'Hi!');
  });

  test('ConversationsListResponse.fromDynamic parses bare array', () {
    final result = ConversationsListResponse.fromDynamic([
      {
        'id': 'c1',
        'request_id': 'r1',
        'flat_id': 'f1',
        'other_person': {'user_id': 'u2', 'full_name': 'Priya'},
      },
    ]);

    expect(result.total, 1);
    expect(result.conversations.first.id, 'c1');
  });
}
