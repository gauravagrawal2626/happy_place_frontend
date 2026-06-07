import '../model/message_model.dart';

/// Merges [incoming] into [existing], deduping by message [Message.id].
List<Message> mergeMessages(
  List<Message> existing,
  List<Message> incoming,
) {
  final byId = {for (final m in existing) m.id: m};
  for (final m in incoming) {
    byId[m.id] = m;
  }
  final merged = byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return merged;
}
