/// Chat Repository — REST calls for conversations and messages.

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/conversation_model.dart';
import '../model/message_model.dart';
import 'chat_exceptions.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ConversationsListResponse> listConversations() async {
    final response = await _apiClient.get(ApiConfig.conversations);
    _throwOnError(response);
    if (response.data == null) {
      return const ConversationsListResponse(conversations: [], total: 0);
    }
    return ConversationsListResponse.fromDynamic(response.data);
  }

  Future<Conversation> getByRequestId(String requestId) async {
    final response = await _apiClient.get(ApiConfig.conversationByRequest(requestId));
    _throwOnError(response);
    if (response.data == null) {
      throw const ChatNotFoundException();
    }
    return Conversation.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<MessagesListResponse> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (before != null && before.isNotEmpty) 'before': before,
    };
    final response = await _apiClient.get(
      ApiConfig.conversationMessages(conversationId),
      queryParams: queryParams,
    );
    _throwOnError(response);
    return MessagesListResponse.fromJson(response.data);
  }

  Future<Message> sendMessage(String conversationId, String body) async {
    final response = await _apiClient.post(
      ApiConfig.conversationMessages(conversationId),
      body: {'body': body},
    );
    _throwOnError(response);
    if (response.data == null) {
      throw Exception('No message data in response');
    }
    return Message.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Map<String, dynamic>> getAblyToken(String conversationId) async {
    final response = await _apiClient.get(ApiConfig.conversationAblyToken(conversationId));
    _throwOnError(response);
    if (response.data == null || response.data is! Map) {
      throw Exception('Invalid Ably token response');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  void _throwOnError(ApiResponse response) {
    if (response.isSuccess) return;
    final code = response.statusCode;
    if (code == 403) {
      throw ChatAccessDeniedException(response.errorMessage ?? 'Access denied');
    }
    if (code == 404) {
      throw ChatNotFoundException(response.errorMessage ?? 'Not found');
    }
    throw Exception(response.errorMessage ?? 'Chat request failed');
  }
}
