import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API Client
/// 
/// Centralized HTTP client for making API requests.
/// Handles common headers, JSON parsing, and error handling.
class ApiClient {
  final http.Client _client;
  String? _authToken;
  VoidCallback? onTokenExpired; // Callback for token expiration (401)

  ApiClient({http.Client? client, this.onTokenExpired}) : _client = client ?? http.Client();

  void _log(String message) {
    debugPrint('[ApiClient] $message');
  }

  /// Set the auth token for authenticated requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear the auth token on logout
  void clearAuthToken() {
    _authToken = null;
  }

  /// Common headers for all requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Build full URL from endpoint
  Uri _buildUri(String endpoint) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint');
  }

  /// POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    var uri = _buildUri(endpoint);
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    _log('═══════════════════════════════════════');
    _log('POST $uri');
    _log('Auth token set: ${_authToken != null}');
    if (body != null) {
      _log('Request Body: ${jsonEncode(body)}');
    }
    
    try {
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');
      _log('═══════════════════════════════════════');
      return _parseResponse(response);
    } on SocketException catch (e) {
      _log('❌ SocketException: $e');
      _log('This usually means: backend not running OR wrong URL/port');
      return ApiResponse.error('Cannot connect to server. Is backend running on ${ApiConfig.baseUrl}?');
    } on HttpException catch (e) {
      _log('❌ HttpException: $e');
      return ApiResponse.error('Server error. Please try again later.');
    } catch (e) {
      _log('❌ Unknown error: $e');
      _log('Error type: ${e.runtimeType}');
      return ApiResponse.error('Something went wrong: ${e.toString()}');
    }
  }

  /// GET request
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = _buildUri(endpoint);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      _log('═══════════════════════════════════════');
      _log('GET $uri');
      _log('Auth token set: ${_authToken != null}');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');
      _log('═══════════════════════════════════════');
      return _parseResponse(response);
    } on SocketException catch (e) {
      _log('❌ SocketException: $e');
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      _log('❌ HttpException: $e');
      return ApiResponse.error('Server error. Please try again later.');
    } catch (e) {
      _log('❌ Error: $e');
      return ApiResponse.error('Something went wrong: ${e.toString()}');
    }
  }

  /// PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .put(
            _buildUri(endpoint),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _parseResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException {
      return ApiResponse.error('Server error. Please try again later.');
    } catch (e) {
      return ApiResponse.error('Something went wrong: ${e.toString()}');
    }
  }

  /// Parse HTTP response to ApiResponse
  ApiResponse _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      // Success
      if (response.body.isEmpty) {
        return ApiResponse.success(null);
      }
      try {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } catch (e) {
        return ApiResponse.success(response.body);
      }
    } else {
      // Error
      String errorMessage = 'Request failed with status: $statusCode';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          // Try different error field names
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          } else if (errorData.containsKey('detail')) {
            final detail = errorData['detail'];
            if (detail is String) {
              errorMessage = detail;
            } else if (detail is List && detail.isNotEmpty) {
              // Pydantic validation errors - extract messages
              final errors = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
              errorMessage = errors;
            }
          }
        }
      } catch (_) {}
      
      // Handle 401 Unauthorized (token expired)
      if (statusCode == 401) {
        _log('🔒 Token expired (401) - triggering logout');
        // Clear token immediately
        _authToken = null;
        // Trigger logout callback if set
        onTokenExpired?.call();
      }
      
      _log('❌ Error response: $errorMessage');
      return ApiResponse.error(errorMessage, statusCode: statusCode);
    }
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      isSuccess: false,
      errorMessage: message,
      statusCode: statusCode,
    );
  }
}

