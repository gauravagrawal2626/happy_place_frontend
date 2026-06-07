/// Typed chat API errors mapped from HTTP status codes.

class ChatAccessDeniedException implements Exception {
  final String message;

  const ChatAccessDeniedException([this.message = 'You do not have access to this conversation.']);

  @override
  String toString() => message;
}

class ChatNotFoundException implements Exception {
  final String message;

  const ChatNotFoundException([this.message = 'Conversation not found.']);

  @override
  String toString() => message;
}
