import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_place_frontend/core/network/api_client.dart';
import 'package:happy_place_frontend/features/chat/repository/chat_exceptions.dart';
import 'package:happy_place_frontend/features/chat/repository/chat_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ChatRepository', () {
    test('listConversations returns parsed list', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'id': 'c1',
                'request_id': 'r1',
                'flat_id': 'f1',
                'other_person': {'user_id': 'u2', 'full_name': 'Priya'},
              },
            ]),
            200,
          );
        }),
      );
      final repo = ChatRepository(apiClient: client);

      final result = await repo.listConversations();

      expect(result.total, 1);
      expect(result.conversations.first.otherPerson.fullName, 'Priya');
    });

    test('throws ChatAccessDeniedException on 403', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Forbidden'}), 403);
        }),
      );
      final repo = ChatRepository(apiClient: client);

      expect(
        () => repo.getByRequestId('r1'),
        throwsA(isA<ChatAccessDeniedException>()),
      );
    });

    test('throws ChatNotFoundException on 404', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Not found'}), 404);
        }),
      );
      final repo = ChatRepository(apiClient: client);

      expect(
        () => repo.getByRequestId('missing'),
        throwsA(isA<ChatNotFoundException>()),
      );
    });
  });
}
