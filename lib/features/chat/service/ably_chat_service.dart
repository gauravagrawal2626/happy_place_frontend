import 'dart:async';
import 'dart:convert';

import 'package:ably_flutter/ably_flutter.dart' as ably;

import '../model/message_model.dart';
import '../repository/chat_repository.dart';

/// Subscribe-only Ably lifecycle for a single open chat screen.
abstract class AblyChatService {
  Future<void> connect({
    required String conversationId,
    required void Function(Message message) onMessage,
  });

  Future<void> disconnect();
}

class AblyChatServiceImpl implements AblyChatService {
  final ChatRepository _repository;

  ably.Realtime? _realtime;
  StreamSubscription<ably.Message>? _subscription;

  AblyChatServiceImpl(this._repository);

  @override
  Future<void> connect({
    required String conversationId,
    required void Function(Message message) onMessage,
  }) async {
    await disconnect();

    _realtime = ably.Realtime(
      options: ably.ClientOptions(
        authCallback: (ably.TokenParams tokenParams) async {
          final tokenMap = await _repository.getAblyToken(conversationId);
          return _parseTokenRequest(tokenMap);
        },
      ),
    );

    final channel = _realtime!.channels.get('conversation:$conversationId');
    _subscription = channel.subscribe(name: 'new_message').listen((event) {
      final data = event.data;
      if (data is Map) {
        onMessage(Message.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _realtime?.close();
    _realtime = null;
  }

  String? _normalizeCapability(dynamic capability) {
    if (capability == null) return null;
    if (capability is String) return capability;
    return jsonEncode(capability);
  }

  ably.TokenRequest _parseTokenRequest(Map<String, dynamic> map) {
    final normalized = <String, dynamic>{
      'keyName': map['keyName'] ?? map['key_name'],
      'clientId': map['clientId'] ?? map['client_id'],
      'capability': _normalizeCapability(map['capability']),
      'mac': map['mac'],
      'nonce': map['nonce'],
      'ttl': map['ttl'],
      'timestamp': map['timestamp'],
    };
    normalized.removeWhere((_, value) => value == null);
    return ably.TokenRequest.fromMap(normalized);
  }
}

AblyChatService createAblyChatService(ChatRepository repository) {
  return AblyChatServiceImpl(repository);
}
