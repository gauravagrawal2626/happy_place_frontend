/// Request models for POST /api/requests and related endpoints

/// Payload for SEEKER (request to flat)
class CreateRequestPayloadSeeker {
  final String flatId;
  final String message;
  final double? matchScore;

  const CreateRequestPayloadSeeker({
    required this.flatId,
    required this.message,
    this.matchScore,
  });

  Map<String, dynamic> toJson() => {
        'flat_id': flatId,
        'message': message,
        if (matchScore != null) 'match_score': matchScore,
      };
}

/// Payload for LISTER (invite seeker)
class CreateRequestPayloadLister {
  final String flatId;
  final String seekerId;
  final String message;
  final double? matchScore;

  const CreateRequestPayloadLister({
    required this.flatId,
    required this.seekerId,
    required this.message,
    this.matchScore,
  });

  Map<String, dynamic> toJson() => {
        'flat_id': flatId,
        'seeker_id': seekerId,
        'message': message,
        if (matchScore != null) 'match_score': matchScore,
      };
}

/// Created request response (minimal)
class CreateRequestResponse {
  final String id;
  final String status;

  const CreateRequestResponse({required this.id, required this.status});

  factory CreateRequestResponse.fromJson(Map<String, dynamic> json) {
    return CreateRequestResponse(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

/// Person details in GET /api/requests items (user_id, full_name)
class RequestPersonDetails {
  final String userId;
  final String fullName;

  const RequestPersonDetails({required this.userId, required this.fullName});

  factory RequestPersonDetails.fromJson(Map<String, dynamic> json) {
    return RequestPersonDetails(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
    );
  }
}

/// Button info in GET /api/requests items (text, action, enabled)
class RequestButtonInfo {
  final String text;
  final String? action;
  final bool enabled;

  const RequestButtonInfo({
    required this.text,
    this.action,
    required this.enabled,
  });

  factory RequestButtonInfo.fromJson(Map<String, dynamic> json) {
    return RequestButtonInfo(
      text: json['text'] as String? ?? '',
      action: json['action'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}

/// Single item in GET /api/requests sent or received list
class RequestListItem {
  final String id;
  final String flatId;
  final String status;
  final RequestPersonDetails personDetails;
  final RequestButtonInfo buttonInfo;

  const RequestListItem({
    required this.id,
    required this.flatId,
    required this.status,
    required this.personDetails,
    required this.buttonInfo,
  });

  factory RequestListItem.fromJson(Map<String, dynamic> json) {
    final person = json['person_details'];
    final button = json['button_info'];
    return RequestListItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      flatId: json['flat_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      personDetails: person is Map
          ? RequestPersonDetails.fromJson(Map<String, dynamic>.from(person as Map))
          : const RequestPersonDetails(userId: '', fullName: ''),
      buttonInfo: button is Map
          ? RequestButtonInfo.fromJson(Map<String, dynamic>.from(button as Map))
          : const RequestButtonInfo(text: '', enabled: false),
    );
  }
}

/// Response from GET /api/requests
class GetRequestsResponse {
  final List<RequestListItem> sent;
  final List<RequestListItem> received;
  final int sentTotal;
  final int receivedTotal;
  final int total;

  const GetRequestsResponse({
    required this.sent,
    required this.received,
    required this.sentTotal,
    required this.receivedTotal,
    required this.total,
  });

  factory GetRequestsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json;
    // Unwrap if backend nests under "data" or "result" (same as ProfileRepository)
    final data = raw.containsKey('data') && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw.containsKey('result') && raw['result'] is Map
            ? Map<String, dynamic>.from(raw['result'] as Map)
            : raw;
    final sentList = data['sent'] as List<dynamic>? ?? [];
    final receivedList = data['received'] as List<dynamic>? ?? [];
    return GetRequestsResponse(
      sent: sentList
          .map((e) => RequestListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      received: receivedList
          .map((e) => RequestListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      sentTotal: data['sent_total'] as int? ?? data['sentTotal'] as int? ?? sentList.length,
      receivedTotal: data['received_total'] as int? ?? data['receivedTotal'] as int? ?? receivedList.length,
      total: data['total'] as int? ?? 0,
    );
  }
}
