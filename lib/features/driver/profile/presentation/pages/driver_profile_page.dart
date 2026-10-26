import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/common/common.dart';
import '../../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../../core/widgets/status_chip.dart';
import '../../../../../../core/utils/legal_links.dart';

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
  bool _loading = true;

  String _name = 'Driver';
  String _phone = '';

  String _vehicleTypeId = '';
  String _vehicleNumber = '';
  String _vehicleModel = '';
  String _verificationStatus = '';
  bool _isVerified = false;
  bool _isAdmin = false;

  double _rating = 0;
  int _totalTrips = 0;
  double _totalEarnings = 0;

  String? _licenseNumber;
  String? _rcNumber;
  DateTime? _licenseExpiry;
  DateTime? _rcExpiry;
  bool _hasKyc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('drivers').doc(uid).get(),
        FirebaseFirestore.instance.collection('driverPrivate').doc(uid).get(),
      ]);
      final user = results[0].data() ?? const {};
      final driver = results[1].data() ?? const {};
      final kyc = results[2].data() ?? const {};
      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();

      DateTime? expiry(dynamic value) =>
          value is Timestamp ? value.toDate().toLocal() : null;

      if (!mounted) return;
      setState(() {
        _name = ((user['displayName'] as String?) ?? '').trim().isEmpty
            ? 'Driver'
            : (user['displayName'] as String).trim();
        _phone = (user['phoneNumber'] as String?) ?? '';
        _vehicleTypeId = (driver['vehicleTypeId'] as String?) ?? '';
        _vehicleNumber = (driver['vehicleNumber'] as String?) ?? '';
        _vehicleModel = (driver['vehicleModel'] as String?) ?? '';
        _verificationStatus = (driver['verificationStatus'] as String?) ?? '';
        _isVerified = driver['isVerified'] == true ||
            _verificationStatus == 'VERIFIED';
        _totalTrips = (driver['totalTrips'] as num?)?.toInt() ?? 0;
        _rating = (driver['rating'] as num?)?.toDouble() ?? 0;
        _totalEarnings = (driver['totalEarnings'] as num?)?.toDouble() ?? 0;
        _licenseNumber = kyc['licenseNumber'] as String?;
        _rcNumber = kyc['rcNumber'] as String?;
        _licenseExpiry = expiry(kyc['licenseExpiry']);
        _rcExpiry = expiry(kyc['rcExpiry']);
        _hasKyc = kyc.isNotEmpty;
        _loading = false;
        _isAdmin = token.claims?['role'] == 'admin';
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _verified => _isVerified;

  String get _verificationLabel {
    if (_verified) return 'Verified';
    switch (_verificationStatus) {
      case 'PENDING_REVIEW':
        return 'In review';
      case 'REJECTED':
        return 'Action needed';
      default:
        return 'Not submitted';
    }
  }

  String get _vehicleTypeLabel {
    if (_vehicleTypeId.isEmpty) return 'Delivery partner';
    return _vehicleTypeId
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _mask(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'On file';
    if (text.length <= 4) return text;
    return '•••• ${text.substring(text.length - 4)}';
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _name == 'Driver' ? '' : _name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (name == null || uid == null || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await user.updateDisplayName(name);
      if (mounted) setState(() => _name = name);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not update your profile. Please try again.');
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: AppStrings.logout,
      message: AppStrings.confirmLogout,
      confirmText: AppStrings.logout,
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) context.go(RouteNames.splash);
  }

  void _openDocuments() {
    if (_verified) {
      AppToast.info(context, 'Your documents are verified.');
      return;
    }
    context.push(RouteNames.driverOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                          onTap: _openDocuments,
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
                          onTap: () => openAppSettings(),
                        ),
                        _MenuRowData(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          onTap: () {
                            if (!mounted) return;
                            context.go(RouteNames.language);
                          },
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
                          onTap: () {
                            if (!mounted) return;
                            context.go(RouteNames.helpSupport);
                          },
                        ),
                        _MenuRowData(
                          icon: Icons.help_outline_rounded,
                          title: AppStrings.faqs,
                          onTap: () {
                            if (!mounted) return;
                            context.go(RouteNames.helpSupport);
                          },
                        ),
                        _MenuRowData(
                          icon: Icons.mail_outline_rounded,
                          title: AppStrings.contactUs,
                          onTap: () {
                            if (!mounted) return;
                            context.go(RouteNames.helpSupport);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isAdmin)
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
                        title: 'Admin',
                        items: [
                          _MenuRowData(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Admin console',
                            onTap: () {
                              if (!mounted) return;
                              context.go(RouteNames.adminReview);
                            },
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
                          onTap: () =>
                              openLegalPage(context, LegalPage.terms),
                        ),
                        _MenuRowData(
                          icon: Icons.privacy_tip_outlined,
                          title: AppStrings.privacyPolicy,
                          onTap: () =>
                              openLegalPage(context, LegalPage.privacy),
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
    final vehicleLine = [
      _vehicleTypeLabel,
      if (_vehicleNumber.isNotEmpty) _vehicleNumber,
    ].join(' • ');

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
                onPressed: _editProfile,
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
                  .fadeIn(duration: const Duration(milliseconds: 250))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                  ),
              if (_verified)
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
          if (vehicleLine.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              vehicleLine,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: onAccent.withValues(alpha: 0.82),
              ),
            ),
          ],
          if (_phone.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              _phone,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: onAccent.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingMd),
          StatusChip.fromStatus(
            _verified
                ? 'APPROVED'
                : (_verificationStatus.isEmpty
                    ? 'PENDING'
                    : _verificationStatus),
            label: _verificationLabel,
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
              value: _rating > 0 ? _rating.toStringAsFixed(1) : 'New',
              label: 'Rating',
              colors: colors,
            ),
          ),
          _StatDivider(colors: colors),
          Expanded(
            child: _StatItem(
              icon: Icons.currency_rupee_rounded,
              value: '₹${_totalEarnings.toStringAsFixed(0)}',
              label: 'Earned',
              colors: colors,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 250), delay: 150.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 250),
        );
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
                            _vehicleModel.isEmpty
                                ? _vehicleTypeLabel
                                : '$_vehicleModel • $_vehicleTypeLabel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _vehicleNumber.isEmpty
                                ? 'Vehicle not added yet'
                                : _vehicleNumber,
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
                    StatusChip(
                      label: _verified ? 'Verified' : 'Pending',
                      status: _verified
                          ? AppChipStatus.success
                          : AppChipStatus.warning,
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
              if (_hasKyc) ...[
                _DocumentRow(
                  item: _DocumentItem(
                    icon: Icons.badge_outlined,
                    title: 'Driving Licence',
                    subtitle: _licenseExpiry == null
                        ? _mask(_licenseNumber)
                        : '${_mask(_licenseNumber)} • valid till ${_licenseExpiry!.year}',
                    status: _verified,
                  ),
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spacingXxl + AppDimensions.spacingMd,
                  ),
                  child: Container(height: 1, color: colors.outlineVariant),
                ),
                _DocumentRow(
                  item: _DocumentItem(
                    icon: Icons.description_outlined,
                    title: 'Vehicle RC',
                    subtitle: _rcExpiry == null
                        ? _mask(_rcNumber)
                        : '${_mask(_rcNumber)} • valid till ${_rcExpiry!.year}',
                    status: _verified,
                  ),
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spacingXxl + AppDimensions.spacingMd,
                  ),
                  child: Container(height: 1, color: colors.outlineVariant),
                ),
                _DocumentRow(
                  item: _DocumentItem(
                    icon: Icons.credit_card_outlined,
                    title: 'Aadhaar',
                    subtitle: 'Uploaded • on file',
                    status: _verified,
                  ),
                  colors: colors,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No documents submitted yet. Complete your onboarding to start accepting trips.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: 250.ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: const Duration(milliseconds: 250),
        );
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
  final bool status;
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
    final isApproved = item.status;
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
          StatusChip(
            label: isApproved ? 'Verified' : 'In review',
            status:
                isApproved ? AppChipStatus.success : AppChipStatus.warning,
            dense: true,
          ),
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
