/// Phone Verification Repository
/// 
/// Handles phone number verification via OTP:
/// - Send OTP to phone number
/// - Verify OTP code
/// - Resend OTP

import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class PhoneVerificationRepository {
  final ApiClient _apiClient;

  PhoneVerificationRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    debugPrint('[PhoneVerificationRepository] $message');
  }

  /// Send OTP to phone number
  /// 
  /// Request body:
  /// ```json
  /// {
  ///   "phone": "+919876543210"
  /// }
  /// ```
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "message": "OTP sent successfully",
  ///   "expires_in": 300
  /// }
  /// ```
  Future<SendOTPResult> sendOTP(String phoneNumber) async {
    _log('Sending OTP to: $phoneNumber');
    
    try {
      final response = await _apiClient.post(
        ApiConfig.sendOTP,
        body: {
          'phone': phoneNumber,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        _log('✅ OTP sent successfully');
        
        return SendOTPResult(
          success: true,
          sessionId: phoneNumber, // Use phone as identifier (no session_id in response)
          message: data['message'] as String? ?? 'OTP sent successfully',
        );
      } else {
        final errorMessage = response.errorMessage ?? 'Failed to send OTP';
        _log('❌ Failed to send OTP: $errorMessage');
        return SendOTPResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      _log('❌ Error sending OTP: $e');
      return SendOTPResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Verify OTP code
  /// 
  /// Request body:
  /// ```json
  /// {
  ///   "phone": "+919876543210",
  ///   "otp": "123456"
  /// }
  /// ```
  /// 
  /// Response (Success):
  /// ```json
  /// {
  ///   "verified": true,
  ///   "message": "Phone number verified successfully",
  ///   "user_id": "693d68239a59ae7dc230b88c"
  /// }
  /// ```
  /// 
  /// Response (Error):
  /// ```json
  /// {
  ///   "detail": "Invalid OTP. 4 attempts remaining."
  /// }
  /// ```
  Future<VerifyOTPResult> verifyOTP({
    required String phoneNumber,
    required String otp,
    required String sessionId, // Not used in API, kept for compatibility
  }) async {
    _log('Verifying OTP for: $phoneNumber');
    
    try {
      final response = await _apiClient.post(
        ApiConfig.verifyOTP,
        body: {
          'phone': phoneNumber,
          'otp': otp,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final verified = data['verified'] as bool? ?? false;
        
        if (verified) {
          _log('✅ Phone number verified successfully');
          return VerifyOTPResult(
            success: true,
            phoneVerified: true,
            message: data['message'] as String? ?? 'Phone number verified successfully',
          );
        } else {
          _log('❌ OTP verification failed');
          return VerifyOTPResult(
            success: false,
            message: data['detail'] as String? ?? data['message'] as String? ?? 'Invalid OTP',
          );
        }
      } else {
        // Handle error response (400 Bad Request with detail message)
        final errorMessage = response.errorMessage ?? 'Failed to verify OTP';
        _log('❌ Failed to verify OTP: $errorMessage');
        return VerifyOTPResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      _log('❌ Error verifying OTP: $e');
      return VerifyOTPResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

/// Result of sending OTP
class SendOTPResult {
  final bool success;
  final String? sessionId;
  final String message;

  SendOTPResult({
    required this.success,
    this.sessionId,
    required this.message,
  });
}

/// Result of verifying OTP
class VerifyOTPResult {
  final bool success;
  final bool phoneVerified;
  final String message;

  VerifyOTPResult({
    required this.success,
    this.phoneVerified = false,
    required this.message,
  });
}
