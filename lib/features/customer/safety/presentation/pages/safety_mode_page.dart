import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../widgets/hold_to_call_sos_button.dart';
import '../widgets/safety_contacts_list.dart';

class SafetyModePage extends StatefulWidget {
  const SafetyModePage({super.key});

  @override
  State<SafetyModePage> createState() => _SafetyModePageState();
}

class _SafetyModePageState extends State<SafetyModePage> {
  static const String _keyShareLocation = 'safety_share_location';
  static const String _keyRouteAlerts = 'safety_route_deviation_alerts';

  bool _shareLocation = false;
  bool _routeAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _shareLocation = prefs.getBool(_keyShareLocation) ?? false;
      _routeAlerts = prefs.getBool(_keyRouteAlerts) ?? true;
    });
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _dialEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    if (!mounted) return;
    AppToast.warning(context, 'Calling 112. Stay calm, help is on the way.');
  }

  Future<void> _addContact() async {
    final name = await AppDialog.showInput(
      context: context,
      title: 'Add emergency contact',
      hint: 'Name',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final phone = await AppDialog.showInput(
      context: context,
      title: 'Contact number',
      hint: 'Phone number',
      keyboardType: TextInputType.phone,
    );
    if (phone == null || phone.trim().isEmpty || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('safetyContacts').add({
        'userId': _userId,
        'name': name.trim(),
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) AppToast.success(context, 'Emergency contact added');
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not save the contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AppDimensions.iconSm,
            color: colors.onSurface,
          ),
        ),
        title: Text(
          'Family Safety Mode',
          style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        children: [
          _buildExplainer(colors),
          const SizedBox(height: AppDimensions.spacingMd),
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingXs,
            ),
            child: Column(
              children: [
                _switchRow(
                  colors,
                  icon: Icons.location_on_outlined,
                  title: 'Share my live location with contacts',
                  subtitle: 'Contacts can follow your trip until it ends',
                  value: _shareLocation,
                  onChanged: (value) {
                    setState(() => _shareLocation = value);
                    _setPreference(_keyShareLocation, value);
                  },
                ),
                Divider(height: AppDimensions.spacingMd, color: colors.outline),
                _switchRow(
                  colors,
                  icon: Icons.route_outlined,
                  title: 'Route deviation alerts',
                  subtitle: 'Get alerted if the driver leaves the route',
                  value: _routeAlerts,
                  onChanged: (value) {
                    setState(() => _routeAlerts = value);
                    _setPreference(_keyRouteAlerts, value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emergency contacts',
                  style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: _addContact,
                icon: Icon(Icons.add_rounded, size: AppDimensions.iconSm, color: colors.primary),
                label: Text('Add', style: AppTextStyles.labelLarge.copyWith(color: colors.primary)),
              ),
            ],
          ),
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: SafetyContactsList(userId: _userId),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'Emergency SOS',
            style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          HoldToCallSosButton(onComplete: _dialEmergency),
        ],
      ),
    );
  }

  Widget _buildExplainer(AppColorsExtension colors) {
    return GlassCard(
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: AppDimensions.iconMd, color: colors.primary),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who can see my trip',
                  style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppDimensions.spacingXxs),
                Text(
                  'Only the emergency contacts you add. Your live location stays private during normal use, is shared only while a trip is active when the switch is on, and is never shown to other drivers or strangers.',
                  style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    AppColorsExtension colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface)),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
          inactiveTrackColor: colors.surfaceVariant,
        ),
      ],
    );
  }
}
