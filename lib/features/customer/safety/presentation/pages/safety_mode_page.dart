import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/env/env_config.dart';
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
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> _dialEmergency() async {
    var alertRecorded = false;
    try {
      Position? position;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 4),
        );
      }
      final payload = <String, dynamic>{};
      if (position != null) {
        payload['latitude'] = position.latitude;
        payload['longitude'] = position.longitude;
      }
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('createSosAlert')
          .call(payload)
          .timeout(const Duration(seconds: 5));
      alertRecorded = true;
    } catch (_) {
      // The emergency call must still proceed if connectivity or location fails.
    }
    final uri = Uri(scheme: 'tel', path: '112');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    AppToast.warning(
      context,
      alertRecorded
          ? 'Safety alert recorded. Calling 112 now.'
          : 'Calling 112 now. Network alert could not be recorded.',
    );
  }

  Future<void> _notifyContacts() async {
    try {
      final contacts = await FirebaseFirestore.instance
          .collection('safetyContacts')
          .where('userId', isEqualTo: _userId)
          .get();
      final phones = contacts.docs
          .map((doc) => (doc.data()['phone'] as String? ?? '').trim())
          .where((phone) => phone.isNotEmpty)
          .toList();
      if (phones.isEmpty) {
        if (mounted) {
          AppToast.warning(context, 'Add an emergency contact first.');
        }
        return;
      }
      var locationLine = '';
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 4),
          );
          locationLine =
              ' My live location: https://maps.google.com/?q=${position.latitude},${position.longitude}';
        }
      } catch (_) {}
      final body =
          'SOS from my PickDrop trip. I need help.$locationLine Please try to reach me now.';
      final uri = Uri(
        scheme: 'sms',
        path: phones.join(','),
        queryParameters: {'body': body},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        AppToast.error(context, 'Could not open your messaging app.');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not open your messaging app.');
      }
    }
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colors.primary),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Text(
                    'Share a live tracking link from an active trip. SOS records an alert for PickDrop and opens your phone to call 112; emergency contacts are not texted automatically.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
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
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addContact,
                icon: Icon(
                  Icons.add_rounded,
                  size: AppDimensions.iconSm,
                  color: colors.primary,
                ),
                label: Text(
                  'Add',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.primary,
                  ),
                ),
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
          const SizedBox(height: AppDimensions.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _notifyContacts,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Text emergency contacts'),
            ),
          ),
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
          Icon(
            Icons.visibility_outlined,
            size: AppDimensions.iconMd,
            color: colors.primary,
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who can see my trip',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXxs),
                Text(
                  'Emergency contacts are saved to your account and can be called or texted from this screen. They are not notified automatically. Live tracking is shared only when you create a trip share link.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
