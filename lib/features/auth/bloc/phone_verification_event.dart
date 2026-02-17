/// Phone Verification Events
/// 
/// Events for phone number verification flow

abstract class PhoneVerificationEvent {
  const PhoneVerificationEvent();
}

/// Send OTP to phone number
class SendOTPEvent extends PhoneVerificationEvent {
  final String phoneNumber;

  const SendOTPEvent(this.phoneNumber);
}

/// Verify OTP code
class VerifyOTPEvent extends PhoneVerificationEvent {
  final String phoneNumber;
  final String otp;
  final String sessionId;

  const VerifyOTPEvent({
    required this.phoneNumber,
    required this.otp,
    required this.sessionId,
  });
}

/// Resend OTP (same as SendOTP but with different UI state)
class ResendOTPEvent extends PhoneVerificationEvent {
  final String phoneNumber;
  final String sessionId;

  const ResendOTPEvent({
    required this.phoneNumber,
    required this.sessionId,
  });
}

/// Reset phone verification state
class ResetPhoneVerificationEvent extends PhoneVerificationEvent {
  const ResetPhoneVerificationEvent();
}
