/// Phone Input Screen - Frame 54
/// 
/// Screen for entering WhatsApp/phone number before OTP verification
/// Design: Light blue background, phone input field, "Send OTP" button

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/theme/app_colors.dart';
import '../bloc/phone_verification_bloc.dart';
import '../bloc/phone_verification_event.dart';
import '../bloc/phone_verification_state.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    // Basic validation: at least 10 digits
    final isValid = phone.length >= 10 && RegExp(r'^[0-9+\s-]+$').hasMatch(phone);
    setState(() {
      _isValid = isValid;
    });
  }

  void _handleSendOTP() {
    if (!_isValid) return;

    unawaited(
      context.read<AnalyticsFacade>().button(
            AnalyticsButtonNames.phoneSendOtp,
            screenName: AnalyticsScreenNames.phoneInput,
          ),
    );

    final phoneNumber = _phoneController.text.trim();
    // Ensure phone number is in E.164 format (+country code)
    // If user enters without +, assume India (+91)
    final formattedPhone = phoneNumber.startsWith('+') 
        ? phoneNumber 
        : '+91$phoneNumber';

    // Validate E.164 format: ^\+?[1-9]\d{1,14}$
    final e164Pattern = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!e164Pattern.hasMatch(formattedPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number with country code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<PhoneVerificationBloc>().add(SendOTPEvent(formattedPhone));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocListener<PhoneVerificationBloc, PhoneVerificationState>(
        listener: (context, state) {
          if (state is OTPSent) {
            // Navigate to OTP verification screen
            context.go('/phone-verify', extra: {
              'phoneNumber': state.phoneNumber,
              'sessionId': state.sessionId,
            });
          } else if (state is PhoneVerificationError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PhoneVerificationBloc, PhoneVerificationState>(
          builder: (context, state) {
            final isLoading = state is SendingOTP;

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
                              'What is your WhatsApp number?',
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
                            
                            // Phone input field
                            TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                hintText: 'Add your number here......',
                                hintStyle: TextStyle(
                                  color: AppColors.textDark.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.textDark.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.textDark,
                                    width: 2,
                                  ),
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.textDark.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Send OTP button
                            AppButton.auth(
                              label: 'Send OTP',
                              isLoading: isLoading,
                              onTap: _isValid && !isLoading ? _handleSendOTP : () {},
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
    );
  }
}
