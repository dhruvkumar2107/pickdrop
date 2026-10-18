import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/router/route_names.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/inputs/inputs.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/colors.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = _phoneController.text.trim();
    final result = await ref.read(sendOtpUseCaseProvider).call(phoneNumber);

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
          context.go('${RouteNames.otpVerify}?phone=$phoneNumber&verificationId=$verificationId');
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                        Icons.local_shipping_rounded,
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
                      AppStrings.welcomeBack,
                      style: AppTextStyles.displayMedium.copyWith(color: colors.onPrimary),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.25, end: 0),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      AppStrings.enterPhoneNumber,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.9),
                      ),
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
                      padding: const EdgeInsets.all(AppDimensions.spacingXl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                                ),
                                child: Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 20,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingMd),
                              Expanded(
                                child: Text(
                                  AppStrings.phoneNumberHint,
                                  style: AppTextStyles.titleLarge.copyWith(color: colors.onSurface),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingLg),
                          PhoneInputField(
                            controller: _phoneController,
                            label: AppStrings.phoneNumberHint,
                            hint: '9876543210',
                            validator: Validators.phone,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _sendOtp(),
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),
                          Text(
                            'We will send a 4-digit code to verify your number',
                            style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppDimensions.spacingXl),
                    GradientButton(
                      text: _isLoading ? AppStrings.sendingOtp : AppStrings.continueButton,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _sendOtp,
                      leadingIcon: Icons.arrow_forward_rounded,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppDimensions.spacingXl),
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
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
