import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/utils/helpers.dart';
import '../../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/common.dart';
import '../../models/vehicle_type.dart';

class VehicleSelectionPage extends ConsumerStatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropLat;
  final double dropLng;
  final String dropAddress;

  const VehicleSelectionPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLng,
    required this.dropAddress,
  });

  @override
  ConsumerState<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends ConsumerState<VehicleSelectionPage> {
  String? _selectedVehicleTypeId;
  bool _isLoadingVehicles = true;
  List<VehicleType> _vehicleTypes = [];
  String? _error;

  // Calculated values
  double _distanceKm = 0;
  int _estimatedDurationMin = 0;

  @override
  void initState() {
    super.initState();
    _calculateDistanceAndDuration();
    _loadVehicleTypes();
  }

  void _calculateDistanceAndDuration() {
    _distanceKm = AppHelpers.calculateDistance(
      widget.pickupLat,
      widget.pickupLng,
      widget.dropLat,
      widget.dropLng,
    ) / 1000;

    _estimatedDurationMin = (_distanceKm / 30 * 60).ceil();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() {
      _isLoadingVehicles = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vehicleTypes')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      final loaded = snapshot.docs
          .map((doc) => VehicleType.fromFirestore(doc.id, doc.data()))
          .toList();

      if (!mounted) return;
      setState(() {
        _vehicleTypes = loaded.isNotEmpty ? loaded : VehicleType.defaults;
        _isLoadingVehicles = false;
      });
    } catch (_) {
      // Offline or unseeded catalog: fall back to the built-in defaults so the
      // booking flow stays usable. The server recomputes the authoritative
      // fare on createBooking regardless of the values shown here.
      if (!mounted) return;
      setState(() {
        _vehicleTypes = VehicleType.defaults;
        _isLoadingVehicles = false;
      });
    }
  }

  Map<String, dynamic> _calculateFare(VehicleType vehicle) {
    return AppHelpers.getFareBreakdown(
      baseFare: vehicle.baseFare,
      perKmRate: vehicle.perKmRate,
      perMinuteRate: vehicle.perMinuteRate,
      distanceKm: _distanceKm,
      durationMinutes: _estimatedDurationMin,
      surgeMultiplier: vehicle.surgeMultiplier,
      minimumFare: vehicle.minimumFare,
      gstPercent: 5.0,
    );
  }

  double _totalFare(VehicleType vehicle) {
    final total = _calculateFare(vehicle)['total'];
    if (total is double) return total;
    return (total as num).toDouble();
  }

  VehicleType? get _selectedVehicle {
    final id = _selectedVehicleTypeId;
    if (id == null) return null;
    for (final vehicle in _vehicleTypes) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  double get _barFare {
    final selected = _selectedVehicle;
    if (selected != null) return _totalFare(selected);
    if (_vehicleTypes.isEmpty) return 0;

    var lowest = double.infinity;
    for (final vehicle in _vehicleTypes) {
      final total = _totalFare(vehicle);
      if (total < lowest) lowest = total;
    }
    return lowest;
  }

  VehicleType? get _recommendedVehicle {
    if (_vehicleTypes.isEmpty) return null;

    // Smart recommendation based on distance and capacity needs
    if (_distanceKm <= 5) {
      return _vehicleTypes.firstWhere(
        (vehicle) => vehicle.id == 'bike',
        orElse: () => _vehicleTypes.first,
      );
    }

    if (_distanceKm <= 15) {
      return _vehicleTypes.firstWhere(
        (vehicle) => vehicle.id == 'three_wheeler',
        orElse: () => _vehicleTypes.first,
      );
    }

    if (_distanceKm <= 30) {
      return _vehicleTypes.firstWhere(
        (vehicle) => vehicle.id == 'mini_truck',
        orElse: () => _vehicleTypes.first,
      );
    }

    return _vehicleTypes.firstWhere(
      (vehicle) => vehicle.id == 'pickup',
      orElse: () => _vehicleTypes.first,
    );
  }

  VehicleType? get _bestValueVehicle {
    if (_vehicleTypes.isEmpty) return null;
    
    VehicleType? best;
    double bestRatio = double.infinity;
    
    for (final vehicle in _vehicleTypes) {
      final fare = _totalFare(vehicle);
      final capacity = vehicle.capacityKg.toDouble();
      final ratio = fare / capacity; // Cost per kg
      if (ratio < bestRatio) {
        bestRatio = ratio;
        best = vehicle;
      }
    }
    return best;
  }

  void _selectVehicle(VehicleType vehicle) {
    setState(() {
      _selectedVehicleTypeId = vehicle.id;
    });
  }

  void _confirmSelection() {
    if (_selectedVehicleTypeId == null) {
      AppToast.warning(context, 'Please select a vehicle type');
      return;
    }

    final selectedVehicle = _vehicleTypes.firstWhere((v) => v.id == _selectedVehicleTypeId);
    final fareBreakdown = _calculateFare(selectedVehicle);

    context.go(
      '${RouteNames.bookingDetails}?'
      'pickupLat=${widget.pickupLat}&pickupLng=${widget.pickupLng}&pickupAddress=${Uri.encodeComponent(widget.pickupAddress)}'
      '&dropLat=${widget.dropLat}&dropLng=${widget.dropLng}&dropAddress=${Uri.encodeComponent(widget.dropAddress)}'
      '&vehicleTypeId=${selectedVehicle.id}&vehicleTypeName=${Uri.encodeComponent(selectedVehicle.name)}'
      '&distanceKm=$_distanceKm&durationMin=$_estimatedDurationMin'
      '&baseFare=${fareBreakdown['baseFare']}&distanceFare=${fareBreakdown['distanceFare']}&timeFare=${fareBreakdown['timeFare']}'
      '&surgeMultiplier=${fareBreakdown['surgeMultiplier']}&surgeAmount=${fareBreakdown['surgeAmount']}'
      '&subtotal=${fareBreakdown['subtotal']}&gst=${fareBreakdown['gst']}&total=${fareBreakdown['total']}'
      '&minimumFare=${fareBreakdown['minimumFare']}',
    );
  }

  void _showFareBreakdown(VehicleType vehicle) {
    final fare = _calculateFare(vehicle);
    showAppBottomSheet(
      context: context,
      title: 'Fare Breakdown',
      builder: (_) => _FareBreakdownSheet(
        vehicle: vehicle,
        fare: fare,
        distanceKm: _distanceKm,
        durationMin: _estimatedDurationMin,
      ),
    );
  }

  IconData _vehicleIcon(String id) {
    switch (id) {
      case 'bike':
        return Icons.two_wheeler;
      case 'three_wheeler':
        return Icons.local_shipping;
      case 'mini_truck':
        return Icons.local_shipping;
      case 'pickup':
        return Icons.local_shipping;
      case 'large_truck':
        return Icons.local_shipping;
      case 'house_shifting':
        return Icons.home;
      default:
        return Icons.directions_car;
    }
  }

  void _goBack() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          _buildRouteHeader(),
          if (!_isLoadingVehicles && _vehicleTypes.isNotEmpty) _buildSmartRecommendationCard(),
          Expanded(child: _buildVehicleList()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendationCard() {
    final colors = context.colors;
    final recommended = _recommendedVehicle;
    if (recommended == null) return const SizedBox.shrink();

    final fare = _totalFare(recommended);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingMd,
        DesignTokens.spacingLg,
        0,
      ),
      child: PDCard(
        variant: PDCardVariant.gradient,
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        radius: DesignTokens.radiusLg,
        borderColor: colors.primary.withValues(alpha: 0.25),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: DesignTokens.iconMd,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart recommendation',
                    style: TokenTextStyles.labelMedium(
                      color: colors.onSurfaceVariant,
                      weight: DesignTokens.wBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    '${recommended.name} is the best fit for this route • ₹${fare.toStringAsFixed(0)}',
                    style: TokenTextStyles.bodySmall(color: colors.onSurface),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingSm,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded, size: 12, color: colors.success),
                  const SizedBox(width: 2),
                  Text(
                    'Eco',
                    style: TokenTextStyles.labelSmall(
                      color: colors.success,
                      weight: DesignTokens.wBold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader() {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingXs,
            DesignTokens.spacingSm,
            DesignTokens.spacingLg,
            DesignTokens.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    tooltip: AppStrings.back,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: DesignTokens.iconSm,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    AppStrings.selectVehicle,
                    style: TokenTextStyles.headlineSmall(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingXs),
              _RoutePoint(
                icon: Icons.trip_origin_rounded,
                tint: colors.success,
                label: AppStrings.pickupLocation,
                address: widget.pickupAddress,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Container(
                  width: 2,
                  height: 16,
                  color: colors.outline,
                ),
              ),
              _RoutePoint(
                icon: Icons.location_on_rounded,
                tint: colors.error,
                label: AppStrings.dropLocation,
                address: widget.dropAddress,
              ),
              SizedBox(height: DesignTokens.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: '${_distanceKm.toStringAsFixed(1)} km',
                      tint: colors.info,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.access_time,
                      label: 'Est. Time',
                      value: '$_estimatedDurationMin min',
                      tint: colors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    final colors = context.colors;

    if (_isLoadingVehicles) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PDLoader(size: 48, color: colors.primary),
            SizedBox(height: DesignTokens.spacingMd),
            Text(
              'Finding the best vehicles...',
              style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return PDErrorState(
        title: AppStrings.somethingWentWrong,
        message: _error!,
        actionLabel: AppStrings.retry,
        onAction: _loadVehicleTypes,
      );
    }

    if (_vehicleTypes.isEmpty) {
      return PDEmptyState(
        title: 'No vehicles available',
        message: 'We could not find vehicles for this route right now',
        icon: Icons.local_shipping_outlined,
        actionLabel: AppStrings.retry,
        onAction: _loadVehicleTypes,
      );
    }

    double lowestFare = double.infinity;
    for (final v in _vehicleTypes) {
      final f = _totalFare(v);
      if (f < lowestFare) lowestFare = f;
    }

    final bestValue = _bestValueVehicle;

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      itemCount: _vehicleTypes.length,
      itemBuilder: (itemContext, index) {
        final vehicle = _vehicleTypes[index];
        final isSelected = _selectedVehicleTypeId == vehicle.id;
        final fare = _totalFare(vehicle);
        final isBestValue = bestValue?.id == vehicle.id;
        final isRecommended = _recommendedVehicle?.id == vehicle.id;

        return _VehicleOptionCard(
          vehicle: vehicle,
          icon: _vehicleIcon(vehicle.id),
          etaMinutes: _estimatedDurationMin,
          distanceKm: _distanceKm,
          estimatedFare: fare,
          isSelected: isSelected,
          isRecommended: isRecommended,
          isBestValue: isBestValue,
          onTap: () => _selectVehicle(vehicle),
          onFareBreakdown: () => _showFareBreakdown(vehicle),
        )
            .animate()
            .fadeIn(
              duration: DesignTokens.durationNormal,
              delay: Duration(milliseconds: 80 * index),
            )
            .slideY(begin: 0.15, end: 0);
      },
    );
  }

  Widget _buildBottomBar() {
    final colors = context.colors;
    final selected = _selectedVehicle;
    final fare = _barFare;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingLg,
            DesignTokens.spacingMd,
            DesignTokens.spacingLg,
            DesignTokens.spacingMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.name ?? AppStrings.selectVehicle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TokenTextStyles.labelSmall(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXxs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        PDPrice(
                          amount: fare,
                          size: PDPriceSize.md,
                          color: colors.primary,
                        ),
                        const SizedBox(width: DesignTokens.spacingSm),
                        Flexible(
                          child: Text(
                            selected != null
                                ? AppStrings.estimatedFare
                                : 'Starting at',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (selected != null) ...[
                      SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        '${_distanceKm.toStringAsFixed(1)} km • $_estimatedDurationMin min • incl. ${AppStrings.gst}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: DesignTokens.spacingSm),
              PDButton(
                text: 'Fare Details',
                variant: PDButtonVariant.outline,
                size: PDButtonSize.sm,
                onPressed: selected != null ? () => _showFareBreakdown(selected) : null,
              ),
              SizedBox(width: DesignTokens.spacingSm),
              PDButton(
                text: AppStrings.continueButton,
                trailingIcon: Icons.arrow_forward_rounded,
                variant: PDButtonVariant.primary,
                size: PDButtonSize.md,
                isFullWidth: false,
                onPressed: _selectedVehicleTypeId != null ? _confirmSelection : null,
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: DesignTokens.durationNormal, delay: 80.ms)
      .slideY(begin: 0.2, end: 0);
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String address;

  const _RoutePoint({
    required this.icon,
    required this.tint,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: DesignTokens.iconSm, color: tint),
        ),
        SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TokenTextStyles.labelSmall(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXxs),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TokenTextStyles.titleMedium(color: colors.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: DesignTokens.iconSm, color: tint),
          SizedBox(width: DesignTokens.spacingSm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokenTextStyles.titleSmall(color: tint)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokenTextStyles.labelSmall(color: tint.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  final VehicleType vehicle;
  final IconData icon;
  final int etaMinutes;
  final double distanceKm;
  final double estimatedFare;
  final bool isSelected;
  final bool isRecommended;
  final bool isBestValue;
  final VoidCallback? onTap;
  final VoidCallback? onFareBreakdown;

  const _VehicleOptionCard({
    required this.vehicle,
    required this.icon,
    required this.etaMinutes,
    required this.distanceKm,
    required this.estimatedFare,
    required this.isSelected,
    this.isRecommended = false,
    this.isBestValue = false,
    this.onTap,
    this.onFareBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = DesignTokens.vehicleColors[vehicle.id] ?? colors.primary;

    return PDVehicleCard(
      vehicleType: vehicle.id,
      label: vehicle.name,
      capacityKg: vehicle.capacityKg,
      estimatedFare: estimatedFare,
      etaMinutes: etaMinutes,
      distanceKm: distanceKm,
      isSelected: isSelected,
      isRecommended: isRecommended,
      isBestValue: isBestValue,
      onTap: onTap,
      accentColor: accentColor,
    );
  }
}

class _FareBreakdownSheet extends StatelessWidget {
  final VehicleType vehicle;
  final Map<String, dynamic> fare;
  final double distanceKm;
  final int durationMin;

  const _FareBreakdownSheet({
    required this.vehicle,
    required this.fare,
    required this.distanceKm,
    required this.durationMin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingMd,
        DesignTokens.spacingLg,
        MediaQuery.of(context).padding.bottom + DesignTokens.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown - ${vehicle.name}',
            style: TokenTextStyles.titleLarge(color: colors.onSurface),
          ),
          SizedBox(height: DesignTokens.spacingLg),
          _fareLine(colors, 'Base Fare', fare['baseFare'] ?? 0),
          _fareLine(colors, 'Distance (${distanceKm.toStringAsFixed(1)} km @ ₹${vehicle.perKmRate}/km)', fare['distanceFare'] ?? 0),
          _fareLine(colors, 'Time ($durationMin min @ ₹${vehicle.perMinuteRate}/min)', fare['timeFare'] ?? 0),
          if ((fare['surgeAmount'] ?? 0) > 0)
            _fareLine(colors, 'Surge (${(fare['surgeMultiplier'] ?? 1).toStringAsFixed(1)}x)', fare['surgeAmount'] ?? 0),
          Divider(color: colors.outlineVariant, height: DesignTokens.spacingLg),
          _fareLine(colors, 'Subtotal', fare['subtotal'] ?? 0),
          _fareLine(colors, 'GST (5%)', fare['gst'] ?? 0),
          Divider(color: colors.outlineVariant, height: DesignTokens.spacingLg),
          _fareLine(colors, 'Total', fare['total'] ?? 0, isTotal: true),
          SizedBox(height: DesignTokens.spacingXl),
          PDButton(
            text: 'Got it',
            variant: PDButtonVariant.primary,
            size: PDButtonSize.lg,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _fareLine(AppColorsExtension colors, String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TokenTextStyles.bodySmall(
            color: isTotal ? colors.onSurface : colors.onSurfaceVariant,
            weight: isTotal ? DesignTokens.wSemiBold : DesignTokens.wRegular,
          )),
          PDPrice(
            amount: amount,
            size: isTotal ? PDPriceSize.md : PDPriceSize.sm,
            color: isTotal ? colors.primary : colors.onSurface,
          ),
        ],
      ),
    );
  }
}