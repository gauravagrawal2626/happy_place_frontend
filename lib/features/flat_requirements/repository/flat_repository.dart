/// Flat Repository
/// 
/// Handles API calls for flat requirements (SEEKER) and flat details (LISTER).
/// 
/// Endpoints:
/// - GET /api/questions/flat-listing - Get questions with existing data
/// - POST /api/users/flat-requirements - Submit SEEKER requirements
/// - POST /api/flats - Submit/update LISTER flat details
/// - POST /api/upload/presigned-url - Get S3 upload URL for photos

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/flat_question_model.dart';
import '../model/flat_request_model.dart';

class FlatRepository {
  final ApiClient _apiClient;

  FlatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get flat listing questions with existing data
  /// 
  /// Works for both SEEKER and LISTER:
  /// - SEEKER: Returns questions + existing requirements (flat_id = null)
  /// - LISTER: Returns questions + existing DRAFT flat data + flat_id
  /// 
  /// [isLister] - true for LISTER flow (Add Flat Details), false for SEEKER flow (Modify Preferences)
  Future<FlatQuestionsResponse> getQuestions({required bool isLister}) async {
    try {
      final endpoint = '${ApiConfig.flatListingQuestions}?is_lister=$isLister';
      print('[FlatRepository] Fetching questions from: $endpoint');
      final response = await _apiClient.get(endpoint);
      
      print('[FlatRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to load questions');
      }
      
      if (response.data == null) {
        throw Exception('No data received from server');
      }
      
      print('[FlatRepository] Questions loaded successfully');
      return FlatQuestionsResponse.fromJson(response.data);
    } catch (e) {
      print('[FlatRepository] Error getting questions: $e');
      rethrow;
    }
  }

  /// Submit SEEKER flat requirements
  /// 
  /// POST /api/users/flat-requirements
  Future<FlatRequirementsResponse> saveRequirements(
      FlatRequirementsRequest request) async {
    try {
      print('[FlatRepository] Saving requirements to: ${ApiConfig.flatRequirements}');
      print('[FlatRepository] Request body: ${request.toJson()}');
      
      final response = await _apiClient.post(
        ApiConfig.flatRequirements,
        body: request.toJson(),
      );
      
      print('[FlatRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to save requirements');
      }
      
      if (response.data == null) {
        throw Exception('No response data received');
      }
      
      print('[FlatRepository] Requirements saved successfully');
      return FlatRequirementsResponse.fromJson(response.data);
    } catch (e) {
      print('[FlatRepository] Error saving requirements: $e');
      rethrow;
    }
  }

  /// Submit/update LISTER flat details
  /// 
  /// POST /api/flats
  /// Include flat_id to update existing DRAFT, omit to create new
  Future<FlatDetailsResponse> saveFlatDetails(FlatDetailsRequest request) async {
    try {
      print('[FlatRepository] Saving flat details to: ${ApiConfig.flats}');
      print('[FlatRepository] Request body: ${request.toJson()}');
      
      final response = await _apiClient.post(
        ApiConfig.flats,
        body: request.toJson(),
      );
      
      print('[FlatRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to save flat details');
      }
      
      if (response.data == null) {
        throw Exception('No response data received');
      }
      
      print('[FlatRepository] Flat details saved successfully');
      return FlatDetailsResponse.fromJson(response.data);
    } catch (e) {
      print('[FlatRepository] Error saving flat details: $e');
      rethrow;
    }
  }

  /// Get presigned URL for S3 photo upload (LISTER only)
  /// 
  /// POST /api/upload/presigned-url
  Future<PresignedUrlResponse> getPresignedUrl({
    required String fileName,
    required String contentType,
    String folder = 'happyplaces-user-flat-images',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.uploadPresignedUrl,
        body: {
          'file_name': fileName,
          'content_type': contentType,
          'folder': folder,
        },
      );

      if (!response.isSuccess) {
        print('[FlatRepository] getPresignedUrl failed: isSuccess=false, errorMessage=${response.errorMessage}, statusCode=${response.statusCode}, data=${response.data}');
        throw Exception(response.errorMessage ?? 'Failed to get presigned URL');
      }

      if (response.data == null) {
        print('[FlatRepository] getPresignedUrl: no data in response');
        throw Exception('No presigned URL data received');
      }

      final parsed = PresignedUrlResponse.fromJson(response.data as Map<String, dynamic>);
      print('[FlatRepository] getPresignedUrl success: file_url=${parsed.fileUrl}');
      return parsed;
    } catch (e, stack) {
      print('[FlatRepository] Error getting presigned URL: $e');
      print('[FlatRepository] Stack: $stack');
      rethrow;
    }
  }

  /// Upload file directly to S3 using presigned URL
  /// 
  /// Returns true if upload successful
  Future<bool> uploadToS3({
    required String uploadUrl,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    try {
      print('[FlatRepository] uploadToS3: contentType=$contentType, bodyBytes=${fileBytes.length}, url(truncated)=${uploadUrl.length > 80 ? '${uploadUrl.substring(0, 80)}...' : uploadUrl}');
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );
      if (response.statusCode == 200) {
        print('[FlatRepository] uploadToS3 success: statusCode=200');
        return true;
      }
      // S3 returns 307 Temporary Redirect to the regional endpoint; follow it
      if (response.statusCode == 307) {
        final location = response.headers['location'] ?? response.headers['Location'];
        if (location != null && location.isNotEmpty) {
          print('[FlatRepository] uploadToS3: following 307 redirect to $location');
          final redirectResponse = await http.put(
            Uri.parse(location),
            headers: {'Content-Type': contentType},
            body: fileBytes,
          );
          if (redirectResponse.statusCode == 200) {
            print('[FlatRepository] uploadToS3 success after redirect: statusCode=200');
            return true;
          }
          print('[FlatRepository] uploadToS3 failed after redirect: statusCode=${redirectResponse.statusCode}, body=${redirectResponse.body}');
          return false;
        }
      }
      print('[FlatRepository] uploadToS3 failed: statusCode=${response.statusCode}, body=${response.body}');
      return false;
    } catch (e, stack) {
      print('[FlatRepository] Error uploading to S3: $e');
      print('[FlatRepository] uploadToS3 stack: $stack');
      return false;
    }
  }

  /// Complete photo upload flow (get URL + upload to S3)
  /// 
  /// Returns the final file URL if successful, null otherwise
  Future<String?> uploadPhoto({
    required String fileName,
    required String contentType,
    required Uint8List fileBytes,
  }) async {
    try {
      print('[FlatRepository] uploadPhoto start: fileName=$fileName, contentType=$contentType, bytes=${fileBytes.length}');
      // Step 1: Get presigned URL
      final presignedResponse = await getPresignedUrl(
        fileName: fileName,
        contentType: contentType,
      );
      print('[FlatRepository] uploadPhoto: got presigned URL, uploading to S3...');
      // Step 2: Upload to S3
      final success = await uploadToS3(
        uploadUrl: presignedResponse.uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );
      if (success) {
        print('[FlatRepository] uploadPhoto success');
        print('[FlatRepository] file_url=${presignedResponse.fileUrl}');
        return presignedResponse.fileUrl;
      }
      print('[FlatRepository] uploadPhoto failed: S3 PUT returned non-200');
      return null;
    } catch (e, stack) {
      print('[FlatRepository] Error in photo upload flow: $e');
      print('[FlatRepository] uploadPhoto stack: $stack');
      return null;
    }
  }
}
