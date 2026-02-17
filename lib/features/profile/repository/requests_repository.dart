/// Requests Repository
///
/// Handles POST /api/requests (send request/invite) per Frontend API Guide:
/// - SEEKER: body = { flat_id, message }
/// - LISTER: body = { flat_id, seeker_id, message }

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/request_model.dart';

class RequestsRepository {
  final ApiClient _apiClient;

  RequestsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Send request (SEEKER) or invite (LISTER)
  Future<CreateRequestResponse> sendRequest({
    required String role, // 'SEEKER' or 'LISTER'
    required String flatId,
    String? seekerId, // Required for LISTER
    String message = 'Hi! I\'m interested in connecting.',
    double? matchScore,
  }) async {
    final Map<String, dynamic> body;
    if (role == 'LISTER') {
      if (seekerId == null) throw ArgumentError('seekerId required for LISTER');
      body = CreateRequestPayloadLister(
        flatId: flatId,
        seekerId: seekerId,
        message: message,
        matchScore: matchScore,
      ).toJson();
    } else {
      body = CreateRequestPayloadSeeker(
        flatId: flatId,
        message: message,
        matchScore: matchScore,
      ).toJson();
    }

    final response = await _apiClient.post(ApiConfig.requests, body: body);

    if (!response.isSuccess) {
      throw Exception(response.errorMessage ?? 'Failed to send request');
    }
    if (response.data == null) {
      throw Exception('No response data');
    }

    return CreateRequestResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Call an action from request_status.buttons (e.g. /api/requests or /api/requests/{id}/accept).
  /// Uses POST for create, PUT for accept/reject/cancel/complete.
  Future<void> callAction(String actionPath, {Map<String, dynamic>? body}) async {
    final path = actionPath.startsWith('/') ? actionPath : '/$actionPath';
    final isPut = path.contains('/accept') ||
        path.contains('/reject') ||
        path.contains('/cancel') ||
        path.contains('/complete');
    final response = isPut
        ? await _apiClient.put(path, body: body ?? {})
        : await _apiClient.post(path, body: body ?? {});

    if (!response.isSuccess) {
      throw Exception(response.errorMessage ?? 'Request failed');
    }
  }

  /// Get all requests (sent and received). GET /api/requests
  Future<GetRequestsResponse> getRequests({String? status}) async {
    final queryParams = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _apiClient.get(
      ApiConfig.requests,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (!response.isSuccess) {
      throw Exception(response.errorMessage ?? 'Failed to load requests');
    }
    if (response.data == null) {
      throw Exception('No data');
    }

    return GetRequestsResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
