/// Message model for chat API responses and Ably new_message payloads.

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] as String?;
    return Message(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: createdRaw != null
          ? DateTime.parse(createdRaw)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

class MessagesListResponse {
  final List<Message> messages;

  const MessagesListResponse({required this.messages});

  factory MessagesListResponse.fromJson(dynamic json) {
    if (json is List) {
      return MessagesListResponse(
        messages: json
            .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final list = map['messages'] as List<dynamic>? ?? [];
      return MessagesListResponse(
        messages: list
            .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }
    return const MessagesListResponse(messages: []);
  }
}
