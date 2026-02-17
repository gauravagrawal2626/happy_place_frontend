/// Phone Verification BLoC
/// 
/// Manages phone number verification flow:
/// - Send OTP
/// - Verify OTP
/// - Resend OTP

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/phone_verification_repository.dart';
import 'phone_verification_event.dart';
import 'phone_verification_state.dart';

class PhoneVerificationBloc extends Bloc<PhoneVerificationEvent, PhoneVerificationState> {
  final PhoneVerificationRepository _repository;

  PhoneVerificationBloc({
    PhoneVerificationRepository? repository,
  })  : _repository = repository ?? PhoneVerificationRepository(),
        super(const PhoneVerificationInitial()) {
    on<SendOTPEvent>(_onSendOTP);
    on<VerifyOTPEvent>(_onVerifyOTP);
    on<ResendOTPEvent>(_onResendOTP);
    on<ResetPhoneVerificationEvent>(_onReset);
  }

  /// Send OTP to phone number
  Future<void> _onSendOTP(
    SendOTPEvent event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    emit(const SendingOTP());

    final result = await _repository.sendOTP(event.phoneNumber);

    if (result.success && result.sessionId != null) {
      emit(OTPSent(
        phoneNumber: event.phoneNumber,
        sessionId: result.sessionId!,
        sentAt: DateTime.now(),
      ));
    } else {
      emit(PhoneVerificationError(
        message: result.message,
        phoneNumber: event.phoneNumber,
      ));
    }
  }

  /// Verify OTP code
  Future<void> _onVerifyOTP(
    VerifyOTPEvent event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    emit(VerifyingOTP(
      phoneNumber: event.phoneNumber,
      sessionId: event.sessionId,
    ));

    final result = await _repository.verifyOTP(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
      sessionId: event.sessionId,
    );

    if (result.success && result.phoneVerified) {
      emit(PhoneVerified(phoneNumber: event.phoneNumber));
    } else {
      emit(PhoneVerificationError(
        message: result.message,
        phoneNumber: event.phoneNumber,
        sessionId: event.sessionId,
      ));
    }
  }

  /// Resend OTP (same as SendOTP but keeps current state)
  Future<void> _onResendOTP(
    ResendOTPEvent event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    emit(const SendingOTP());

    final result = await _repository.sendOTP(event.phoneNumber);

    if (result.success && result.sessionId != null) {
      emit(OTPSent(
        phoneNumber: event.phoneNumber,
        sessionId: result.sessionId!,
        sentAt: DateTime.now(),
      ));
    } else {
      // On resend error, go back to OTP sent state with error
      emit(PhoneVerificationError(
        message: result.message,
        phoneNumber: event.phoneNumber,
        sessionId: event.sessionId,
      ));
    }
  }

  /// Reset to initial state
  void _onReset(
    ResetPhoneVerificationEvent event,
    Emitter<PhoneVerificationState> emit,
  ) {
    emit(const PhoneVerificationInitial());
  }
}
