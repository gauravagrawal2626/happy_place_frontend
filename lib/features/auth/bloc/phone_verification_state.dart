/// Phone Verification States
/// 
/// States for phone number verification flow

abstract class PhoneVerificationState {
  const PhoneVerificationState();
}

/// Initial state - phone input screen
class PhoneVerificationInitial extends PhoneVerificationState {
  const PhoneVerificationInitial();
}

/// Sending OTP
class SendingOTP extends PhoneVerificationState {
  const SendingOTP();
}

/// OTP sent successfully - show OTP input screen
class OTPSent extends PhoneVerificationState {
  final String phoneNumber;
  final String sessionId;
  final DateTime sentAt;

  const OTPSent({
    required this.phoneNumber,
    required this.sessionId,
    required this.sentAt,
  });
}

/// Verifying OTP
class VerifyingOTP extends PhoneVerificationState {
  final String phoneNumber;
  final String sessionId;

  const VerifyingOTP({
    required this.phoneNumber,
    required this.sessionId,
  });
}

/// OTP verified successfully
class PhoneVerified extends PhoneVerificationState {
  final String phoneNumber;

  const PhoneVerified({required this.phoneNumber});
}

/// Error state
class PhoneVerificationError extends PhoneVerificationState {
  final String message;
  final String? phoneNumber;
  final String? sessionId;

  const PhoneVerificationError({
    required this.message,
    this.phoneNumber,
    this.sessionId,
  });
}
