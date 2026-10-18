import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/common/common.dart';
import '../../../../../../core/widgets/dialogs/dialogs.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  static const String _name = 'Aarav Sharma';
  static const String _phone = '+91 98765 43210';
  static const int _totalTrips = 48;
  static const int _savedAddresses = 4;
  static const double _rating = 4.8;

  Future<void> _logout() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: AppStrings.logout,
      message: AppStrings.confirmLogout,
      confirmText: AppStrings.logout,
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;
    context.go(RouteNames.splash);
  }

  void _toggleTheme() {
    ref.read(themeModeProvider.notifier).toggleTheme();
  }

  void _showComingSoon(String feature) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feature),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGradientHeader(context, colors)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingSm,
              ),
              child: _buildStatsRow(context, colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingSm,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                context: context,
                colors: colors,
                title: 'Account',
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Info',
                    onTap: () => _showComingSoon('Personal info coming soon'),
                  ),
                  _SettingsItem(
                    icon: Icons.bookmark_outline_rounded,
                    title: AppStrings.savedAddresses,
                    onTap: () => context.go(RouteNames.savedAddresses),
                  ),
                  _SettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AppStrings.wallet,
                    onTap: () => context.go(RouteNames.wallet),
                  ),
                  _SettingsItem(
                    icon: Icons.schedule_rounded,
                    title: 'Scheduled deliveries',
                    onTap: () => context.push(RouteNames.scheduledBookings),
                  ),
                  _SettingsItem(
                    icon: Icons.business_outlined,
                    title: 'Business account',
                    onTap: () => context.push(RouteNames.businessAccount),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                context: context,
                colors: colors,
                title: 'Preferences',
                items: [
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => context.go(RouteNames.notifications),
                  ),
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    onTap: () => context.go(RouteNames.language),
                  ),
                  _SettingsItem(
                    icon: themeMode == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark mode',
                    trailing: Switch.adaptive(
                      value: themeMode == ThemeMode.dark,
                      activeThumbColor: colors.primary,
                      onChanged: (_) => _toggleTheme(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                context: context,
                colors: colors,
                title: AppStrings.helpSupport,
                items: [
                  _SettingsItem(
                    icon: Icons.support_agent_rounded,
                    title: AppStrings.helpSupport,
                    onTap: () => context.go(RouteNames.helpSupport),
                  ),
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: AppStrings.faqs,
                    onTap: () => context.go(RouteNames.helpSupport),
                  ),
                  _SettingsItem(
                    icon: Icons.mail_outline_rounded,
                    title: AppStrings.contactUs,
                    onTap: () => _showComingSoon('Contact us coming soon'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                context: context,
                colors: colors,
                title: 'Legal',
                items: [
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    title: AppStrings.termsConditions,
                    onTap: () => _showComingSoon('Terms & Conditions coming soon'),
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.privacyPolicy,
                    onTap: () => _showComingSoon('Privacy Policy coming soon'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
                AppDimensions.spacingLg,
                AppDimensions.spacingXxl,
              ),
              child: _buildLogoutTile(context, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.top + AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingXxl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButtonWidget(
                icon: Icons.arrow_back_rounded,
                color: colors.onPrimary,
                onPressed: () {
                  if (!mounted) return;
                  context.pop();
                },
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  'Profile',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              TextButtonWidget(
                text: AppStrings.edit,
                textColor: Colors.white,
                fontWeight: FontWeight.w600,
                onPressed: () => _showComingSoon('Edit profile coming soon'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Stack(
            children: [
              AvatarWidget(
                name: _name,
                radius: AppDimensions.avatarXl / 2,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                textColor: Colors.white,
              ).animate().fadeIn(duration: AppConstants.mediumAnimation).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: AppConstants.mediumAnimation,
                    curve: Curves.easeOutBack,
                  ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingXs),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            _name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            _phone,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.route_rounded,
              value: '$_totalTrips',
              label: 'Trips',
              colors: colors,
            ),
          ),
          _StatDivider(colors: colors),
          Expanded(
            child: _StatItem(
              icon: Icons.bookmark_border_rounded,
              value: '$_savedAddresses',
              label: 'Saved',
              colors: colors,
            ),
          ),
          _StatDivider(colors: colors),
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              value: _rating.toStringAsFixed(1),
              label: 'Rating',
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required AppColorsExtension colors,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingXxl + AppDimensions.spacingMd,
                    ),
                    child: Container(
                      height: 1,
                      color: colors.outlineVariant,
                    ),
                  ),
                _SettingsItemWidget(item: items[i], colors: colors),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutTile(BuildContext context, AppColorsExtension colors) {
    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          decoration: BoxDecoration(
            color: colors.errorLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: colors.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: AppDimensions.iconSm,
                  color: colors.error,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Text(
                  AppStrings.logout,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppDimensions.iconMd,
                color: colors.error.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SettingsItemWidget extends StatelessWidget {
  const _SettingsItemWidget({
    required this.item,
    required this.colors,
  });

  final _SettingsItem item;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingMd,
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  item.icon,
                  size: AppDimensions.iconMd,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (item.trailing != null)
                item.trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppDimensions.iconMd,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String value;
  final String label;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingSm),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.colors});

  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppDimensions.iconXl,
      color: colors.outlineVariant,
    );
  }
}
