import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/common.dart';
import 'package:pickdrop/features/common/map/presentation/pages/map_picker_page.dart';

class PickupDropSelectionPage extends ConsumerStatefulWidget {
  final String? initialLabel;
  final double? initialLat;
  final double? initialLng;
  final String? initialDropLabel;
  final double? initialDropLat;
  final double? initialDropLng;
  final int initialStep;

  const PickupDropSelectionPage({
    super.key,
    this.initialLabel,
    this.initialLat,
    this.initialLng,
    this.initialDropLabel,
    this.initialDropLat,
    this.initialDropLng,
    this.initialStep = 0,
  });

  @override
  ConsumerState<PickupDropSelectionPage> createState() => _PickupDropSelectionPageState();
}

class _PickupDropSelectionPageState extends ConsumerState<PickupDropSelectionPage> {
  late final PageController _pageController;
  late int _currentStep;
  String? _pickupLabel;
  String? _dropLabel;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);
    _pickupLabel = widget.initialLabel;
    _pickupLat = widget.initialLat;
    _pickupLng = widget.initialLng;
    _dropLabel = widget.initialDropLabel;
    _dropLat = widget.initialDropLat;
    _dropLng = widget.initialDropLng;
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => AppToast.error(context, 'Speech recognition error: $error'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          // listening stopped
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_pickupLabel == null || _pickupLat == null) {
        AppToast.warning(context, 'Please select a pickup location');
        return;
      }
      _pageController.nextPage(
        duration: DesignTokens.durationNormal,
        curve: DesignTokens.springSmooth,
      );
    }
  }

  void _confirmLocations() {
    if (_dropLabel == null || _dropLat == null) {
      AppToast.warning(context, 'Please select a drop location');
      return;
    }

    context.go(
      '${RouteNames.vehicleSelection}?'
      'pickupLat=$_pickupLat&pickupLng=$_pickupLng&pickupAddress=${Uri.encodeComponent(_pickupLabel!)}'
      '&dropLat=$_dropLat&dropLng=$_dropLng&dropAddress=${Uri.encodeComponent(_dropLabel!)}',
    );
  }

  Future<void> _startVoiceSearch(bool isPickup) async {
    if (!_speechEnabled) {
      AppToast.warning(context, 'Speech recognition not available');
      return;
    }
    String recognizedText = '';
    // Finish as soon as the recogniser reports a final result instead of
    // always waiting out the full listening window.
    final done = Completer<void>();
    AppToast.info(context, 'Listening... say the address');
    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        if (result.finalResult && !done.isCompleted) done.complete();
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 5),
        localeId: 'en_IN',
      ),
    );
    await done.future.timeout(
      const Duration(seconds: 16),
      onTimeout: () => _speech.stop(),
    );
    if (!mounted) return;
    if (recognizedText.trim().isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Voice Search Result'),
          content: Text('Did you say: "$recognizedText"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Use this')),
          ],
        ),
      );
      if (confirmed == true) {
        if (!mounted) return;
        setState(() {
          if (isPickup) {
            _pickupLabel = recognizedText;
            _pickupLat = null;
            _pickupLng = null;
          } else {
            _dropLabel = recognizedText;
            _dropLat = null;
            _dropLng = null;
          }
        });
        AppToast.success(context, 'Location set. Tap map to pin exact location.');
      }
    } else {
      AppToast.info(context, 'No speech detected. Try again.');
    }
  }

  Future<void> _pickLocation(bool isPickup) async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerPage(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupLabel = result.address;
          _pickupLat = result.lat;
          _pickupLng = result.lng;
        } else {
          _dropLabel = result.address;
          _dropLat = result.lat;
          _dropLng = result.lng;
        }
      });
    }
  }

  void _swapLocations() {
    setState(() {
      final tempLabel = _pickupLabel;
      final tempLat = _pickupLat;
      final tempLng = _pickupLng;

      _pickupLabel = _dropLabel;
      _pickupLat = _dropLat;
      _pickupLng = _dropLng;

      _dropLabel = tempLabel;
      _dropLat = tempLat;
      _dropLng = tempLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // Top bar with progress
          Container(
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.black800 : DesignTokens.white,
              boxShadow: [
                BoxShadow(
                  color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.spacingLg,
                  DesignTokens.spacingMd,
                  DesignTokens.spacingLg,
                  DesignTokens.spacingMd,
                ),
                child: Column(
                  children: [
                    // Progress indicator
                    PDStepIndicator(
                      currentStep: _currentStep,
                      totalSteps: 2,
                      labels: ['Pickup', 'Drop'],
                      activeColor: colors.primary,
                      completedColor: colors.success,
                    ),
                    SizedBox(height: DesignTokens.spacingMd),
                    // Step title
                    Text(
                      _currentStep == 0
                          ? 'Where should we pick up from?'
                          : 'Where should we deliver to?',
                      style: TokenTextStyles.headlineSmall(
                        color: colors.onSurface,
                        weight: DesignTokens.wSemiBold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildLocationStep(
                  isPickup: true,
                  label: _pickupLabel,
                  hint: 'Enter pickup address',
                  onTap: () => _pickLocation(true),
                ),
                _buildLocationStep(
                  isPickup: false,
                  label: _dropLabel,
                  hint: 'Enter drop address',
                  onTap: () => _pickLocation(false),
                ),
              ],
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacingLg,
              DesignTokens.spacingMd,
              DesignTokens.spacingLg,
              MediaQuery.of(context).padding.bottom + DesignTokens.spacingLg,
            ),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.black800 : DesignTokens.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXl),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowMedium,
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: PDButton(
                      text: 'Back',
                      leadingIcon: Icons.arrow_back_rounded,
                      variant: PDButtonVariant.outline,
                      size: PDButtonSize.md,
                      onPressed: () => _pageController.previousPage(
                        duration: DesignTokens.durationNormal,
                        curve: DesignTokens.springSmooth,
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: PDButton(
                    label: _currentStep == 0 ? 'Next' : 'Continue',
                    trailingIcon: _currentStep == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                    variant: PDButtonVariant.primary,
                    size: PDButtonSize.lg,
                    onPressed: _currentStep == 0 ? _nextStep : _confirmLocations,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep({
    required bool isPickup,
    required String? label,
    required String hint,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected location card
          PDCard(
            variant: PDCardVariant.filled,
            padding: EdgeInsets.all(DesignTokens.spacingLg),
            radius: DesignTokens.radiusLg,
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPickup
                        ? colors.success.withValues(alpha: 0.15)
                        : colors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPickup ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                    color: isPickup ? colors.success : colors.error,
                    size: DesignTokens.iconMd,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPickup ? 'Pickup Location' : 'Drop Location',
                        style: TokenTextStyles.labelMedium(
                          color: colors.onSurfaceVariant,
                          weight: DesignTokens.wMedium,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        label ?? hint,
                        style: label != null
                            ? TokenTextStyles.titleMedium(color: colors.onSurface)
                            : TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (label != null)
                  Icon(
                    Icons.edit_rounded,
                    color: colors.primary,
                    size: DesignTokens.iconMd,
                  ),
              ],
            ),
          ),

          SizedBox(height: DesignTokens.spacingXl),

          // Quick actions
          Text(
            'Quick Select',
            style: TokenTextStyles.titleMedium(
              color: colors.onSurface,
              weight: DesignTokens.wSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingMd),

          Row(
            children: [
              Expanded(
                child: PDCard(
                  variant: PDCardVariant.outlined,
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  radius: DesignTokens.radiusLg,
                  onTap: () => _pickLocation(isPickup),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          color: colors.primary,
                          size: DesignTokens.iconMd,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingSm),
                      Text(
                        'Select on Map',
                        style: TokenTextStyles.titleSmall(color: colors.onSurface),
                      ),
                      SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        'Pin exact location',
                        style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: PDCard(
                  variant: PDCardVariant.outlined,
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  radius: DesignTokens.radiusLg,
                  onTap: () => _startVoiceSearch(true),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: colors.warning,
                          size: DesignTokens.iconMd,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingSm),
                      Text(
                        'Voice Search',
                        style: TokenTextStyles.titleSmall(color: colors.onSurface),
                      ),
                      SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        'Speak the address',
                        style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.spacingLg),

          // Saved addresses
          Text(
            'Saved Locations',
            style: TokenTextStyles.titleMedium(
              color: colors.onSurface,
              weight: DesignTokens.wSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingMd),

          _savedLocations(isPickup, colors),

          // Swap button (only on drop step)
          if (!isPickup && _pickupLabel != null && _dropLabel != null) ...[
            SizedBox(height: DesignTokens.spacingXl),
            PDButton(
              text: 'Swap Pickup & Drop',
              leadingIcon: Icons.swap_vert_rounded,
              variant: PDButtonVariant.ghost,
              size: PDButtonSize.md,
              onPressed: _swapLocations,
            ),
          ],
        ],
      ),
    );
  }

  Widget _savedLocations(bool isPickup, AppColorsExtension colors) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Sign in to use saved addresses.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('savedAddresses')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Could not load saved addresses.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return TextButton.icon(
            onPressed: () => context.push(RouteNames.savedAddresses),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add a saved address'),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final type = (data['type'] ?? '').toString();
            final label = (data['label'] ?? type).toString();
            final latitude = (data['latitude'] as num?)?.toDouble();
            final longitude = (data['longitude'] as num?)?.toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingSm),
              child: _SavedLocationTile(
                label: label,
                address: (data['address'] ?? '').toString(),
                icon: type == 'Home' ? Icons.home : type == 'Work' ? Icons.work_outline : Icons.location_on_outlined,
                color: type == 'Work' ? colors.info : colors.primary,
                onTap: latitude == null || longitude == null
                    ? null
                    : () {
                        setState(() {
                          if (isPickup) {
                            _pickupLabel = label;
                            _pickupLat = latitude;
                            _pickupLng = longitude;
                          } else {
                            _dropLabel = label;
                            _dropLat = latitude;
                            _dropLng = longitude;
                          }
                        });
                      },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SavedLocationTile extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SavedLocationTile({
    required this.label,
    required this.address,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: PDCard(
          variant: PDCardVariant.elevated,
          padding: EdgeInsets.all(DesignTokens.spacingMd),
          radius: DesignTokens.radiusMd,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon, color: color, size: DesignTokens.iconSm),
              ),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TokenTextStyles.titleSmall(color: colors.onSurface)),
                    SizedBox(height: DesignTokens.spacingXxs),
                    Text(address, style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry point for selecting the pickup location.
class PickupSelectionPage extends StatelessWidget {
  final String? initialLabel;
  final double? initialLat;
  final double? initialLng;

  const PickupSelectionPage({
    super.key,
    this.initialLabel,
    this.initialLat,
    this.initialLng,
  });

  @override
  Widget build(BuildContext context) {
    return PickupDropSelectionPage(
      initialLabel: initialLabel,
      initialLat: initialLat,
      initialLng: initialLng,
    );
  }
}

/// Entry point for selecting the drop location with a known pickup.
class DropSelectionPage extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;

  const DropSelectionPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
  });

  @override
  Widget build(BuildContext context) {
    return PickupDropSelectionPage(
      initialLabel: pickupAddress,
      initialLat: pickupLat,
      initialLng: pickupLng,
      initialStep: 1,
    );
  }
}
