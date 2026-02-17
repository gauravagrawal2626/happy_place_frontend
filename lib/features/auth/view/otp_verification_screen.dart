/// OTP Verification Screen - Frames 55-57
/// 
/// Screen for entering and verifying OTP code
/// Design: Light blue background, 4 OTP input boxes, "Verify OTP" button, loading state

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/bloc/app_state.dart';
import '../bloc/phone_verification_bloc.dart';
import '../bloc/phone_verification_event.dart';
import '../bloc/phone_verification_state.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String sessionId;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.sessionId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _waitingForNavigation = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _canResend = false;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleOTPChange(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 3) { // 0-3 for 4 fields
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field (index 3) - verify automatically
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handlePaste(String value) {
    // Handle paste - fill all fields if 4 digits
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 4) {
      for (int i = 0; i < 4; i++) {
        _otpControllers[i].text = digits[i];
      }
      _focusNodes[3].unfocus();
      _verifyOTP();
    }
  }

  String _getOTP() {
    return _otpControllers.map((c) => c.text).join();
  }

  bool _isOTPComplete() {
    return _getOTP().length == 4;
  }

  void _verifyOTP() {
    if (!_isOTPComplete()) return;

    final otp = _getOTP();
    context.read<PhoneVerificationBloc>().add(
          VerifyOTPEvent(
            phoneNumber: widget.phoneNumber,
            otp: otp,
            sessionId: widget.sessionId,
          ),
        );
  }

  void _handleResend() {
    if (!_canResend) return;

    context.read<PhoneVerificationBloc>().add(
          ResendOTPEvent(
            phoneNumber: widget.phoneNumber,
            sessionId: widget.sessionId,
          ),
        );
    _startResendTimer();
    // Clear OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocListener<AppBloc, AppState>(
        listener: (context, appState) {
          // After phone verification, check onboarding status and navigate accordingly
          // Only navigate if we're waiting for navigation (phone was just verified)
          if (_waitingForNavigation && appState is AppAuthenticated && appState.authResponse.phoneVerified) {
            _waitingForNavigation = false; // Reset flag
            final onboardingCompleted = appState.onboardingCompleted;
            if (onboardingCompleted) {
              // Onboarding already done, go to main screen
              final role = appState.authResponse.role;
              final targetRoute = role == 'LISTER' ? '/list/lister' : '/map/seeker';
              context.go(targetRoute);
            } else {
              // Navigate to onboarding
              context.go('/onboarding');
            }
          }
        },
        child: BlocListener<PhoneVerificationBloc, PhoneVerificationState>(
          listener: (context, state) {
            if (state is PhoneVerified) {
              // Set flag to wait for navigation
              _waitingForNavigation = true;
              // Update AppBloc with phone verified status
              // Navigation will happen in AppBloc listener above when state updates
              context.read<AppBloc>().add(const AppPhoneVerified());
            } else if (state is PhoneVerificationError) {
              // Reset flag on error
              _waitingForNavigation = false;
              // Show error and clear OTP fields
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            // Clear OTP fields on error
            for (var controller in _otpControllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          } else if (state is OTPSent) {
            // OTP resent - update session ID if needed
            // Clear fields and restart timer
            _startResendTimer();
            for (var controller in _otpControllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
        },
        child: BlocBuilder<PhoneVerificationBloc, PhoneVerificationState>(
          builder: (context, state) {
            final isVerifying = state is VerifyingOTP;
            final isSending = state is SendingOTP;
            final isVerified = state is PhoneVerified;

            // Show loading state while verifying or after verification (waiting for navigation)
            if (isVerifying || (isVerified && _waitingForNavigation)) {
              return SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verifying',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextButton(
                        onPressed: () => context.go('/onboarding'),
                        child: const Text(
                          'Not now',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top spacing
                            SizedBox(height: constraints.maxHeight * 0.28),
                            
                            // Title
                            const Text(
                              'Verify your WhatsApp number',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Subtitle
                            const Text(
                              'This is for potential flatmates to contact you.',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // OTP input fields (4 boxes)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    enabled: !isSending,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.textDark.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.textDark.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.textDark,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.textDark.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                    onChanged: (value) => _handleOTPChange(index, value),
                                    onTap: () {
                                      // Select all text when tapping
                                      _otpControllers[index].selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _otpControllers[index].text.length,
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                            
                            // Resend OTP option
                            Center(
                              child: _canResend
                                  ? TextButton(
                                      onPressed: _handleResend,
                                      child: const Text(
                                        'Resend OTP',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Resend OTP in $_resendCountdown seconds',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textDark.withOpacity(0.6),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Verify OTP button
                            AppButton.auth(
                              label: 'Verify OTP',
                              isLoading: isSending,
                              onTap: _isOTPComplete() && !isSending ? _verifyOTP : () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
