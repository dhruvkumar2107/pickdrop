import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/common/common.dart';
import '../../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../../core/widgets/status_chip.dart';

/// Readable foreground colour for a given accent (adapts to light/dark themes).
Color _onAccent(Color accent) =>
    accent.computeLuminance() > 0.45 ? const Color(0xFF062B2E) : Colors.white;

/// Darker companion colour used to finish driver accent gradients.
Color _accentEnd(Color accent) => Color.lerp(accent, Colors.black, 0.32)!;

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  static const String _name = 'Rohan Verma';
  static const String _phone = '+91 98765 43210';
  static const String _vehicleName = 'Tata Intra • Pickup';
  static const String _vehicleNumber = 'MH12 AB 4521';
  static const int _totalTrips = 1248;
  static const double _rating = 4.9;
  static const double _acceptance = 94;
  static const int _years = 4;

  static const List<_DocumentItem> _documents = [
    _DocumentItem(
      icon: Icons.badge_outlined,
      title: 'Driving Licence',
      subtitle: 'MH12 2019 0034567 • Valid till 2032',
      status: AppConstants.verificationApproved,
    ),
    _DocumentItem(
      icon: Icons.description_outlined,
      title: 'Vehicle RC',
      subtitle: 'MH12AB4521 • Valid till 2030',
      status: AppConstants.verificationApproved,
    ),
    _DocumentItem(
      icon: Icons.credit_card_outlined,
      title: 'Aadhaar',
      subtitle: 'XXXX XXXX 4821 • KYC linked',
      status: AppConstants.verificationPending,
    ),
  ];

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

  void _showComingSoon(String feature) {
    if (!mounted) return;
    AppToast.info(context, '$feature is coming soon');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, colors)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildStats(colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildDocumentsSection(colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                colors: colors,
                title: 'Account',
                items: [
                  _MenuRowData(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AppStrings.earnings,
                    onTap: () {
                      if (!mounted) return;
                      context.go(RouteNames.driverEarnings);
                    },
                  ),
                  _MenuRowData(
                    icon: Icons.history_outlined,
                    title: AppStrings.tripHistory,
                    onTap: () {
                      if (!mounted) return;
                      context.go(RouteNames.driverTripHistory);
                    },
                  ),
                  _MenuRowData(
                    icon: Icons.local_shipping_outlined,
                    title: 'Vehicle & documents',
                    onTap: () => _showComingSoon('Vehicle management'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                colors: colors,
                title: 'Preferences',
                items: [
                  _MenuRowData(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => _showComingSoon('Notification settings'),
                  ),
                  _MenuRowData(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    onTap: () => _showComingSoon('Language picker'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                colors: colors,
                title: AppStrings.helpSupport,
                items: [
                  _MenuRowData(
                    icon: Icons.support_agent_rounded,
                    title: AppStrings.helpSupport,
                    onTap: () => _showComingSoon(AppStrings.helpSupport),
                  ),
                  _MenuRowData(
                    icon: Icons.help_outline_rounded,
                    title: AppStrings.faqs,
                    onTap: () => _showComingSoon(AppStrings.faqs),
                  ),
                  _MenuRowData(
                    icon: Icons.mail_outline_rounded,
                    title: AppStrings.contactUs,
                    onTap: () => _showComingSoon(AppStrings.contactUs),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildSection(
                colors: colors,
                title: 'Legal',
                items: [
                  _MenuRowData(
                    icon: Icons.description_outlined,
                    title: AppStrings.termsConditions,
                    onTap: () => _showComingSoon(AppStrings.termsConditions),
                  ),
                  _MenuRowData(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.privacyPolicy,
                    onTap: () => _showComingSoon(AppStrings.privacyPolicy),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                AppDimensions.spacingXxl,
              ),
              child: _buildLogoutTile(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension colors) {
    final accent = colors.driverAccent;
    final onAccent = _onAccent(accent);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.top + AppDimensions.spacingSm,
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, _accentEnd(accent)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButtonWidget(
                icon: Icons.arrow_back_rounded,
                color: onAccent,
                backgroundColor: onAccent.withValues(alpha: 0.14),
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.driverHome);
                },
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: onAccent,
                  ),
                ),
              ),
              TextButtonWidget(
                text: AppStrings.edit,
                textColor: onAccent,
                fontWeight: FontWeight.w600,
                onPressed: () => _showComingSoon('Edit profile'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              AvatarWidget(
                name: _name,
                radius: AppDimensions.avatarXl / 2,
                backgroundColor: onAccent.withValues(alpha: 0.18),
                textColor: onAccent,
              )
                  .animate()
                  .fadeIn(duration: AppConstants.mediumAnimation)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: AppConstants.mediumAnimation,
                    curve: Curves.easeOutBack,
                  ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingXxs),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: onAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    size: AppDimensions.iconSm,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            _name,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
              color: onAccent,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '$_vehicleName • $_vehicleNumber',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: onAccent.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: AppDimensions.iconSm,
                color: Color(0xFFFBBF24),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(
                '${_rating.toStringAsFixed(1)} • $_phone',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: onAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          StatusChip.fromStatus(
            AppConstants.verificationApproved,
            label: AppStrings.verificationApproved,
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppColorsExtension colors) {
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
              label: AppStrings.totalTrips,
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
          _StatDivider(colors: colors),
          Expanded(
            child: _StatItem(
              icon: Icons.insights_outlined,
              value: '${_acceptance.toStringAsFixed(0)}%',
              label: 'Acceptance',
              colors: colors,
            ),
          ),
          _StatDivider(colors: colors),
          Expanded(
            child: _StatItem(
              icon: Icons.workspace_premium_outlined,
              value: '$_years',
              label: 'Years',
              colors: colors,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppConstants.mediumAnimation, delay: 150.ms)
        .slideY(begin: 0.1, end: 0, duration: AppConstants.mediumAnimation);
  }

  Widget _buildDocumentsSection(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(title: 'Vehicle & documents'),
        const SizedBox(height: AppDimensions.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingXs,
          ),
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
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: Row(
                  children: [
                    Container(
                      width: AppDimensions.avatarMd,
                      height: AppDimensions.avatarMd,
                      decoration: BoxDecoration(
                        color: colors.driverAccent.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: AppDimensions.iconMd,
                        color: colors.driverAccent,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _vehicleName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _vehicleNumber,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StatusChip(
                      label: 'Active',
                      status: AppChipStatus.success,
                      dense: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                ),
                child: Container(height: 1, color: colors.outlineVariant),
              ),
              for (var i = 0; i < _documents.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingXxl + AppDimensions.spacingMd,
                    ),
                    child: Container(height: 1, color: colors.outlineVariant),
                  ),
                _DocumentRow(item: _documents[i], colors: colors),
              ],
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: AppConstants.mediumAnimation,
          delay: 250.ms,
        )
        .slideY(begin: 0.08, end: 0, duration: AppConstants.mediumAnimation);
  }

  Widget _buildSection({
    required AppColorsExtension colors,
    required String title,
    required List<_MenuRowData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title),
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
                    child: Container(height: 1, color: colors.outlineVariant),
                  ),
                _MenuRow(item: items[i], colors: colors),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutTile(AppColorsExtension colors) {
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

class _DocumentItem {
  const _DocumentItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
}

class _MenuRowData {
  const _MenuRowData({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.item,
    required this.colors,
  });

  final _DocumentItem item;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final isApproved = item.status == AppConstants.verificationApproved;
    final accent = isApproved ? colors.success : colors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarMd,
            height: AppDimensions.avatarMd,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(item.icon, size: AppDimensions.iconMd, color: accent),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusChip.fromStatus(item.status, dense: true),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.colors,
  });

  final _MenuRowData item;
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
                  color: colors.driverAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  item.icon,
                  size: AppDimensions.iconMd,
                  color: colors.driverAccent,
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
            color: colors.driverAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconSm,
            color: colors.driverAccent,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
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
            fontSize: 10,
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
