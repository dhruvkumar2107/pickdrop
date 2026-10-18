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
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_providers.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _continueWithRole() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);
    final role = _selectedRole!;

    final result = await ref.read(updateProfileUseCaseProvider).call(role: role);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      },
      (user) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyUserRole, role);
        } catch (_) {}

        if (!mounted) return;
        if (user.displayName == null || user.displayName!.isEmpty) {
          context.go(RouteNames.profileCreation);
        } else if (role == AppConstants.roleDriver) {
          context.go(RouteNames.driverOnboarding);
        } else {
          context.go(RouteNames.customerHome);
        }
      },
    );
  }

  String get _buttonLabel {
    if (_selectedRole == null) return AppStrings.continueButton;
    final label = _selectedRole == AppConstants.roleDriver
        ? AppStrings.roleDriver
        : AppStrings.roleCustomer;
    return '${AppStrings.continueAs} $label';
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
                        Icons.swap_horiz_rounded,
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
                      AppStrings.selectRole,
                      style: AppTextStyles.headlineLarge.copyWith(color: colors.onPrimary),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.25, end: 0),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Pick a role to get started',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RoleCard(
                    title: AppStrings.roleCustomer,
                    description: AppStrings.roleCustomerDesc,
                    icon: Icons.person_outline,
                    accentColor: colors.customerAccent,
                    isSelected: _selectedRole == AppConstants.roleCustomer,
                    onTap: () => setState(() => _selectedRole = AppConstants.roleCustomer),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.15, end: 0),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _RoleCard(
                    title: AppStrings.roleDriver,
                    description: AppStrings.roleDriverDesc,
                    icon: Icons.local_shipping_outlined,
                    accentColor: colors.driverAccent,
                    isSelected: _selectedRole == AppConstants.roleDriver,
                    onTap: () => setState(() => _selectedRole = AppConstants.roleDriver),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: 0.15, end: 0),
                  const SizedBox(height: AppDimensions.spacingXl),
                  GradientButton(
                    text: _isLoading ? AppStrings.pleaseWait : _buttonLabel,
                    isLoading: _isLoading,
                    onPressed: _selectedRole != null && !_isLoading ? _continueWithRole : null,
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    'You can switch roles later from your profile',
                    style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: AppDimensions.spacingSm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.07) : colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected ? accentColor : colors.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            isSelected
                ? BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                : BoxShadow(
                    color: colors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.14)
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? accentColor : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            isSelected
                ? Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingSm),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outline, width: 2),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
