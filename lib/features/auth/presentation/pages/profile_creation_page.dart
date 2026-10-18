import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/inputs/inputs.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class ProfileCreationPage extends ConsumerStatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  ConsumerState<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends ConsumerState<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
    if (firebaseUser == null) {
      _showError('Session expired. Please log in again.');
      setState(() => _isLoading = false);
      return;
    }

    final role = await _resolveRole();
    String phone = firebaseUser.phoneNumber ?? '';

    final fresh = await ref.read(getCurrentUserUseCaseProvider).call();
    fresh.fold((_) {}, (u) {
      if (phone.isEmpty) phone = u.phoneNumber;
    });

    final result = await ref.read(createProfileUseCaseProvider).call(
      uid: firebaseUser.uid,
      phoneNumber: phone,
      displayName: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      role: role,
    );

    result.fold(
      (failure) {
        if (mounted) {
          _showError(failure.message);
        }
      },
      (user) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully'), backgroundColor: Colors.green),
          );
          context.go(
            user.role == AppConstants.roleDriver
                ? RouteNames.driverOnboarding
                : RouteNames.customerHome,
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Resolves the role the user picked at role selection. Prefers the value
  /// persisted in Firestore, falls back to the locally cached selection, then
  /// to `customer`.
  Future<String> _resolveRole() async {
    String role = 'customer';
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(AppConstants.keyUserRole);
      if (cached != null && cached.isNotEmpty) role = cached;
    } catch (_) {}

    final fresh = await ref.read(getCurrentUserUseCaseProvider).call();
    fresh.fold((_) {}, (u) {
      if (u.role.isNotEmpty) role = u.role;
    });
    return role;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.spacingXl),

                // Title
                Text(
                  AppStrings.completeProfile,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Help us personalize your experience',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppDimensions.spacingXxl),

                // Name Field
                CustomTextField(
                  controller: _nameController,
                  label: AppStrings.fullName,
                  hint: AppStrings.fullNameHint,
                  validator: (value) => Validators.name(value),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: AppDimensions.spacingMd),

                // Email Field (Optional)
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailOptional,
                  hint: AppStrings.emailHint,
                  validator: (value) => Validators.email(value),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveProfile(),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: 0.2, end: 0),

                const Spacer(),

                // Save Button
                PrimaryButton(
                  text: _isLoading ? AppStrings.pleaseWait : AppStrings.saveProfile,
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                  leadingIcon: Icons.save_outlined,
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppDimensions.spacingMd),

                // Skip for now
                TextButtonWidget(
                  text: 'Skip for now',
                  onPressed: () async {
                    final role = await _resolveRole();
                    if (!context.mounted) return;
                    context.go(
                      role == AppConstants.roleDriver
                          ? RouteNames.driverOnboarding
                          : RouteNames.customerHome,
                    );
                  },
                  textColor: AppColors.onSurfaceVariant,
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: AppDimensions.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}