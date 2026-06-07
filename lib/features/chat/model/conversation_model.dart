/// Conversation models for GET /api/conversations and by-request responses.

class OtherPerson {
  final String userId;
  final String fullName;
  final String? profilePicture;

  const OtherPerson({
    required this.userId,
    required this.fullName,
    this.profilePicture,
  });

  factory OtherPerson.fromJson(Map<String, dynamic> json) {
    return OtherPerson(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

class Conversation {
  final String id;
  final String requestId;
  final String flatId;
  final OtherPerson otherPerson;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const Conversation({
    required this.id,
    required this.requestId,
    required this.flatId,
    required this.otherPerson,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final other = json['other_person'];
    return Conversation(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      flatId: json['flat_id'] as String? ?? '',
      otherPerson: other is Map
          ? OtherPerson.fromJson(Map<String, dynamic>.from(other))
          : const OtherPerson(userId: '', fullName: ''),
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: _parseDate(json['last_message_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ConversationsListResponse {
  final List<Conversation> conversations;
  final int total;

  const ConversationsListResponse({
    required this.conversations,
    required this.total,
  });

  factory ConversationsListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json;
    final data = raw.containsKey('data') && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    final list = data['conversations'] as List<dynamic>? ?? [];
    return ConversationsListResponse(
      conversations: list
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: data['total'] as int? ?? list.length,
    );
  }

  /// Backend may return a bare JSON array or `{ conversations, total }`.
  factory ConversationsListResponse.fromDynamic(dynamic data) {
    if (data is List) {
      final conversations = data
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return ConversationsListResponse(
        conversations: conversations,
        total: conversations.length,
      );
    }
    if (data is Map) {
      return ConversationsListResponse.fromJson(Map<String, dynamic>.from(data));
    }
    return const ConversationsListResponse(conversations: [], total: 0);
  }
}
