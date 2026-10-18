import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../config/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerifyPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
      });
      if (_resendTimer <= 0) {
        _canResend = true;
        return false;
      }
      return true;
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();
    final result =
        await ref.read(verifyOtpUseCaseProvider).call(_verificationId, widget.phoneNumber, otp);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
          );
        }
      },
      (user) {
        if (mounted) {
          if (user.displayName == null || user.displayName!.isEmpty) {
            context.go(RouteNames.roleSelection);
          } else if (user.role == AppConstants.roleDriver) {
            context.go(RouteNames.driverHome);
          } else {
            context.go(RouteNames.customerHome);
          }
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    final result = await ref.read(sendOtpUseCaseProvider).call(widget.phoneNumber);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
          );
        }
      },
      (verificationId) {
        if (mounted) {
          setState(() => _verificationId = verificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent successfully'), backgroundColor: Colors.green),
          );
          _startResendTimer();
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primaryEnd],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppDimensions.radiusXl),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingXl,
                  AppDimensions.spacingLg,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.onPrimary,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 26,
                        color: colors.primary,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    Text(
                      AppStrings.enterOtp,
                      style: AppTextStyles.displayMedium.copyWith(color: colors.onPrimary),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.25, end: 0),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${AppStrings.otpSent} ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: colors.onPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                          TextSpan(
                            text: '+91 ${widget.phoneNumber}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    )
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.25, end: 0),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      showShadow: true,
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.spacingLg,
                        AppDimensions.spacingXl,
                        AppDimensions.spacingLg,
                        AppDimensions.spacingXl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.otpHint,
                            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppDimensions.spacingLg),
                          PinCodeTextField(
                            appContext: context,
                            length: AppConstants.otpLength,
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              fieldHeight: 60,
                              fieldWidth: 54,
                              activeFillColor: colors.surfaceElevated,
                              inactiveFillColor: colors.surfaceElevated,
                              selectedFillColor: colors.surfaceElevated,
                              activeColor: colors.primary,
                              inactiveColor: colors.outline,
                              selectedColor: colors.primary,
                              borderWidth: 2,
                            ),
                            animationDuration: AppConstants.mediumAnimation,
                            enableActiveFill: true,
                            onCompleted: (value) => _verifyOtp(),
                            onChanged: (value) {},
                            validator: (value) => Validators.otp(value),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppDimensions.spacingXl),
                    GradientButton(
                      text: _isLoading ? AppStrings.verifyingOtp : AppStrings.verifyAndContinue,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _verifyOtp,
                      leadingIcon: Icons.verified_user_outlined,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _canResend
                              ? AppStrings.didntReceiveOtp
                              : '${AppStrings.resendIn} $_resendTimer ${AppStrings.seconds}',
                          style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (_canResend) ...[
                          const SizedBox(width: AppDimensions.spacingSm),
                          TextButtonWidget(
                            text: AppStrings.resendOtp,
                            onPressed: _resendOtp,
                            textColor: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ],
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: AppDimensions.spacingXl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Wrong number? ',
                          style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                        ),
                        TextButtonWidget(
                          text: 'Change',
                          onPressed: () => context.pop(),
                          textColor: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: AppDimensions.spacingMd),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
