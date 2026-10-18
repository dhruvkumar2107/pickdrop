import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/common.dart';
import '../../data/datasources/price_lock_remote_datasource.dart';
import '../../data/datasources/scheduled_booking_remote_datasource.dart';
import '../providers/booking_providers.dart';
import '../../../home/presentation/widgets/eco_badge.dart';
import '../widgets/goods_handling_tags_widget.dart';
import '../widgets/transit_insurance_card.dart';
import '../widgets/packing_tips_card.dart';
import '../widgets/price_lock_badge.dart';
import '../widgets/return_trip_widget.dart';
import '../widgets/schedule_picker_sheet.dart';
import '../widgets/stops_editor_widget.dart';
import '../widgets/surge_transparency_card.dart';
import '../widgets/toll_estimate_card.dart';
import '../widgets/verified_helpers_card.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  const BookingDetailsPage({
    super.key,
    this.pickupAddress = '',
    this.dropAddress = '',
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.dropLat = 0,
    this.dropLng = 0,
    this.vehicleTypeId = '',
    this.vehicleType = 'Bike',
    this.distanceKm = 0,
    this.durationMin = 0,
    this.baseFare = 0,
    this.distanceFare = 0,
    this.timeFare = 0,
    this.surgeMultiplier = 1,
    this.subtotal = 0,
    this.gst = 0,
    this.total = 0,
  });

  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String vehicleTypeId;
  final String vehicleType;
  final double distanceKm;
  final double durationMin;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double subtotal;
  final double gst;
  final double total;

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  final TextEditingController _goodsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  bool _bookingInProgress = false;
  bool _payOnline = false;
  bool _scheduleForLater = false;
  bool _familySafetyMode = true;
  bool _multiStopDelivery = false;
  bool _returnTrip = false;
  bool _isInsured = false;
  final double _goodsValue = 5000;
  DateTime? _scheduledAt;
  List<DeliveryStop> _stops = [];
  final List<String> _selectedHandlingTags = ['fragile'];
  final List<String> _selectedHelpers = [];
  double _discount = 0;
  String _couponCode = '';

  bool get _loadingHelp => _selectedHelpers.isNotEmpty;

  double get _helperFee {
    final pickup = _selectedHelpers.any((id) => id.startsWith('helper_pickup_'));
    final drop = _selectedHelpers.any((id) => id.startsWith('helper_drop_'));
    if (pickup && drop) return 149;
    if (pickup || drop) return 79;
    return 0;
  }

  bool get _hasRealFare => widget.total > 0;

  double get _baseFare => _hasRealFare ? widget.baseFare : 249 * 0.45;
  double get _distanceFare => _hasRealFare ? widget.distanceFare : 249 * 0.30;
  double get _timeFare => _hasRealFare ? widget.timeFare : 249 * 0.15;
  double get _surgeFare => _hasRealFare
      ? widget.subtotal - widget.baseFare - widget.distanceFare - widget.timeFare
      : 249 * 0.10;

  String get _pickupLabel =>
      widget.pickupAddress.isEmpty ? 'Select pickup on map' : widget.pickupAddress;
  String get _dropLabel =>
      widget.dropAddress.isEmpty ? 'Select drop on map' : widget.dropAddress;

  double get _subtotal =>
      _hasRealFare ? widget.subtotal : _baseFare + _distanceFare + _timeFare + _surgeFare;
  double get _gst =>
      _hasRealFare ? widget.gst : _subtotal * (AppConstants.defaultGstPercent / 100);
  double get _total =>
      (_hasRealFare ? widget.subtotal + widget.gst : _subtotal + _gst) -
      _discount +
      _helperFee +
      _returnTripFee +
      _insurancePremium;

  double get _insurancePremium => _isInsured ? 29.0 : 0;

  double get _returnTripFee => _returnTrip ? _distanceFare : 0;

  @override
  void dispose() {
    _goodsController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _openCouponSheet() async {
    final result = await showAppBottomSheet<String>(
      context: context,
      title: AppStrings.applyCouponCode,
      builder: (sheetContext) => _CouponSheet(
        controller: _couponController,
        onApply: (code) => Navigator.of(sheetContext).pop(code),
      ),
    );
    if (!mounted || result == null) return;
    final code = result.trim().toUpperCase();
    if (code == 'PICK50') {
      setState(() {
        _couponCode = code;
        _discount = 50;
      });
      AppToast.success(context, AppStrings.couponApplied);
    } else {
      AppToast.error(context, AppStrings.invalidCoupon);
    }
  }

  Future<void> _onScheduleToggle(bool enable) async {
    if (!enable) {
      setState(() {
        _scheduleForLater = false;
        _scheduledAt = null;
      });
      return;
    }
    final picked = await SchedulePickerSheet.show(
      context,
      estimatedFare: _total,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduleForLater = true;
      _scheduledAt = picked;
    });
  }

  String _formatSlot(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} • $hh:$mm';
  }

  Widget _scheduledSlotChip(AppColorsExtension colors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.successLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: colors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, size: DesignTokens.iconSm, color: colors.success),
          SizedBox(width: DesignTokens.spacingSm),
          Expanded(
            child: Text(
              'Scheduled for ${_formatSlot(_scheduledAt!)} • driver assigned 30 min before',
              style: TokenTextStyles.labelSmall(color: colors.success, weight: DesignTokens.wBold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_bookingInProgress) return;
    setState(() => _bookingInProgress = true);

    final notes = [
      if (_goodsController.text.trim().isNotEmpty) _goodsController.text.trim(),
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
      if (_scheduledAt != null) 'Scheduled: ${_formatSlot(_scheduledAt!)}',
      if (_stops.isNotEmpty)
        'Stops: ${_stops.map((s) => s.label.isEmpty ? 'Stop' : s.label).join(' → ')}',
      if (_returnTrip) 'Return trip requested',
      if (_isInsured) 'Transit insurance opted (\u20B929, cover up to \u20B950,000)',
    ].join('\n');

    String? bookingId;
    try {
      final result = await ref.read(bookingRemoteDataSourceProvider).createBooking(
            pickupLat: widget.pickupLat,
            pickupLng: widget.pickupLng,
            pickupAddress: widget.pickupAddress,
            dropLat: widget.dropLat,
            dropLng: widget.dropLng,
            dropAddress: widget.dropAddress,
            vehicleTypeId: widget.vehicleTypeId,
            paymentMethod: _payOnline ? 'razorpay' : 'cod',
            notes: notes,
            distanceKm: widget.distanceKm,
            durationMin: widget.durationMin,
            baseFare: _baseFare,
            distanceFare: _distanceFare,
            timeFare: _timeFare,
            surgeMultiplier: widget.surgeMultiplier,
            gst: _gst,
            total: _total,
          );
      bookingId = result.bookingId;
    } catch (e) {
      debugPrint('createBooking failed: $e');
      if (mounted) {
        AppToast.info(context, 'Backend unavailable — continuing in demo mode');
      }
    }

    final activeBookingId = bookingId ?? 'PD${DateTime.now().millisecondsSinceEpoch % 100000}';
    try {
      await PriceLockRemoteDataSource().createPriceLock(
        bookingId: activeBookingId,
        vehicleTypeId: widget.vehicleTypeId,
        baseFare: _baseFare,
        distanceFare: _distanceFare,
        timeFare: _timeFare,
        surgeMultiplier: widget.surgeMultiplier,
        gst: _gst,
        total: _total,
      );
    } catch (_) {}

    if (_scheduledAt != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) AppToast.error(context, 'Sign in to schedule a delivery');
        if (mounted) setState(() => _bookingInProgress = false);
        return;
      }
      try {
        await ScheduledBookingRemoteDataSource().create(
          customerId: uid,
          scheduledAt: _scheduledAt!,
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          pickupAddress: widget.pickupAddress,
          dropLat: widget.dropLat,
          dropLng: widget.dropLng,
          dropAddress: widget.dropAddress,
          vehicleType: widget.vehicleType,
          goodsType: _goodsController.text.trim(),
          estimatedFare: _total,
        );
        if (mounted) {
          AppToast.success(
            context,
            'Scheduled — a driver is guaranteed 30 minutes before pickup',
          );
          context.go(RouteNames.scheduledBookings);
        }
      } catch (e) {
        debugPrint('schedule failed: $e');
        if (mounted) AppToast.error(context, 'Could not schedule. Try again.');
      }
      if (mounted) setState(() => _bookingInProgress = false);
      return;
    }

    if (_stops.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('multiStopBookings').add({
          'bookingId': activeBookingId,
          'customerId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'driverId': null,
          'stops': _stops
              .map((s) => {'id': s.id, 'label': s.label, 'otp': s.otp})
              .toList(),
          'status': 'CREATED',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('multi-stop persist failed: $e');
      }
    }

    if (!mounted) return;
    final q = <String, String>{
      'fare': _total.toStringAsFixed(0),
      'pickupAddress': _pickupLabel,
      'dropAddress': _dropLabel,
      'pickupLat': widget.pickupLat.toString(),
      'pickupLng': widget.pickupLng.toString(),
      'dropLat': widget.dropLat.toString(),
      'dropLng': widget.dropLng.toString(),
      'vehicleTypeId': widget.vehicleTypeId,
      'vehicleType': widget.vehicleType,
      'distanceKm': widget.distanceKm.toString(),
      'durationMin': widget.durationMin.toString(),
      'paymentMethod': _payOnline ? 'razorpay' : 'cod',
      'goodsType': _goodsController.text.trim(),
      'loadingHelper': _loadingHelp.toString(),
      if (_couponCode.isNotEmpty) 'couponCode': _couponCode,
      if (_discount > 0) 'discount': _discount.toString(),
      'bookingId': bookingId ?? '',
    };
    final encoded = q.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    if (mounted) context.go('${RouteNames.findingDriver}?$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Container(
            height: safeTop + 120,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colors),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.spacingXl,
                      DesignTokens.spacingSm,
                      DesignTokens.spacingXl,
                      DesignTokens.spacingXxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PriceLockBadge(lockedFare: _total),
                        SizedBox(height: DesignTokens.spacingLg),
                        SurgeTransparencyCard(
                          surgeMultiplier: widget.surgeMultiplier,
                          onBookLater: () => _onScheduleToggle(true),
                        ),
                        if (widget.surgeMultiplier > 1.0)
                          SizedBox(height: DesignTokens.spacingLg),
                        _buildRouteCard(colors),
                        SizedBox(height: DesignTokens.spacingLg),
                        TollEstimateCard(distanceKm: widget.distanceKm),
                        SizedBox(height: DesignTokens.spacingLg),
                        ReturnTripWidget(
                          value: _returnTrip,
                          distanceKm: widget.distanceKm,
                          distanceFare: _distanceFare,
                          onChanged: (v) => setState(() => _returnTrip = v),
                        ),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildGoodsSection(),
                        SizedBox(height: DesignTokens.spacingLg),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _goodsController,
                          builder: (context, value, _) => PackingTipsCard(
                            goodsType: value.text.trim().isEmpty
                                ? 'General goods'
                                : value.text.trim(),
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingLg),
                        GoodsHandlingTagsWidget(
                          selectedTags: _selectedHandlingTags,
                          onTagsChanged: (tags) => setState(() => _selectedHandlingTags
                            ..clear()
                            ..addAll(tags)),
                        ),
                        SizedBox(height: DesignTokens.spacingLg),
                        TransitInsuranceCard(
                          isInsured: _isInsured,
                          goodsValue: _goodsValue,
                          onToggleInsurance: (v) => setState(() => _isInsured = v),
                        ),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildSmartBookingOptions(colors),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildNotesSection(),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildLoadingHelpCard(colors),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildCouponCard(colors),
                        SizedBox(height: DesignTokens.spacingLg),
                        _buildPaymentSection(colors),
                        SizedBox(height: DesignTokens.spacingXxl),
                      ],
                    ),
                  ),
                ),
                _buildFareSheet(context, colors, safeBottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingXl,
        DesignTokens.spacingXs,
        DesignTokens.spacingXl,
        DesignTokens.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: colors.onPrimary,
          ),
          SizedBox(width: DesignTokens.spacingXs),
          Expanded(
            child: Text(
              AppStrings.bookingDetails,
              style: TokenTextStyles.headlineSmall(color: colors.onPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(AppColorsExtension colors) {
    return PDCard(
      variant: PDCardVariant.glass,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildRouteRow(
            icon: Icons.trip_origin_rounded,
            iconColor: colors.primary,
            title: AppStrings.pickupLocation,
            subtitle: _pickupLabel,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: DesignTokens.iconMd + DesignTokens.spacingMd + 4,
              top: DesignTokens.spacingXxs,
              bottom: DesignTokens.spacingXxs,
            ),
            child: Container(
              width: 2,
              height: 28,
              color: colors.outline,
            ),
          ),
          _buildRouteRow(
            icon: Icons.location_on_rounded,
            iconColor: colors.secondary,
            title: AppStrings.dropLocation,
            subtitle: _dropLabel,
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  color: colors.primary,
                  size: 18,
                ),
                SizedBox(width: DesignTokens.spacingXs),
                Text(
                  widget.vehicleType,
                  style: TokenTextStyles.labelMedium(color: colors.primary),
                ),
              ],
            ),
          ),
          if (widget.distanceKm > 0) ...[
            SizedBox(height: DesignTokens.spacingSm),
            Align(
              alignment: Alignment.centerLeft,
              child: EcoBadge(
                vehicleType: widget.vehicleType,
                distanceKm: widget.distanceKm,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant)),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TokenTextStyles.bodyMedium(color: colors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoodsSection() {
    const suggestions = ['Documents', 'Groceries', 'Electronics', 'Food'];
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.goodsType, style: TokenTextStyles.titleSmall(color: colors.onSurface)),
        SizedBox(height: DesignTokens.spacingMd),
        PDInput(
          controller: _goodsController,
          hint: AppStrings.goodsTypeHint,
          prefixIcon: Icon(Icons.inventory_2_outlined, size: DesignTokens.iconMd),
        ),
        SizedBox(height: DesignTokens.spacingMd),
        Wrap(
          spacing: DesignTokens.spacingSm,
          runSpacing: DesignTokens.spacingSm,
          children: suggestions
              .map(
                (s) => ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _goodsController.text = s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSmartBookingOptions(AppColorsExtension colors) {
    return PDCard(
      variant: PDCardVariant.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart delivery options',
            style: TokenTextStyles.titleSmall(
              weight: DesignTokens.wBold,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          _smartSwitchRow(
            colors,
            label: 'Schedule for later',
            subtitle: 'Book up to 7 days ahead',
            value: _scheduleForLater,
            onChanged: _onScheduleToggle,
            icon: Icons.schedule_rounded,
          ),
          if (_scheduledAt != null) ...[
            SizedBox(height: DesignTokens.spacingSm),
            _scheduledSlotChip(colors),
          ],
          SizedBox(height: DesignTokens.spacingSm),
          _smartSwitchRow(
            colors,
            label: 'Multi-stop route',
            subtitle: 'Add up to 5 stops with per-stop OTP',
            value: _multiStopDelivery,
            onChanged: (value) => setState(() => _multiStopDelivery = value),
            icon: Icons.route_rounded,
          ),
          if (_multiStopDelivery) ...[
            SizedBox(height: DesignTokens.spacingSm),
            StopsEditorWidget(
              value: _stops,
              baseDistanceKm: widget.distanceKm,
              onChanged: (stops) => setState(() => _stops = stops),
            ),
          ],
          SizedBox(height: DesignTokens.spacingSm),
          _smartSwitchRow(
            colors,
            label: 'Family safety mode',
            subtitle: 'Share live trip with emergency contact',
            value: _familySafetyMode,
            onChanged: (value) => setState(() => _familySafetyMode = value),
            icon: Icons.shield_rounded,
          ),
        ],
      ),
    );
  }

  Widget _smartSwitchRow(
    AppColorsExtension colors, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TokenTextStyles.labelLarge(color: colors.onSurface)),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: colors.primary),
      ],
    );
  }

  Widget _buildNotesSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.notesOptional, style: TokenTextStyles.titleSmall(color: colors.onSurface)),
        SizedBox(height: DesignTokens.spacingMd),
        PDInput(
          controller: _notesController,
          hint: AppStrings.notesHint,
          maxLines: 3,
          minLines: 3,
        ),
      ],
    );
  }

  Widget _buildLoadingHelpCard(AppColorsExtension colors) {
    return VerifiedHelpersCard(
      onChanged: (ids) => setState(() => _selectedHelpers
        ..clear()
        ..addAll(ids)),
    );
  }

  Widget _buildCouponCard(AppColorsExtension colors) {
    final applied = _couponCode.isNotEmpty;
    return PDCard(
      variant: PDCardVariant.glass,
      onTap: applied ? null : _openCouponSheet,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (applied ? colors.success : colors.primary)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              applied
                  ? Icons.check_circle_rounded
                  : Icons.local_offer_outlined,
              color: applied ? colors.success : colors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applied ? _couponCode : AppStrings.applyCouponCode,
                  style: TokenTextStyles.labelLarge(color: colors.onSurface),
                ),
                SizedBox(height: 2),
                Text(
                  applied
                      ? '- ₹${_discount.toStringAsFixed(0)} applied'
                      : AppStrings.couponCodeHint,
                  style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!applied)
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.paymentMethod, style: TokenTextStyles.titleSmall(color: colors.onSurface)),
        SizedBox(height: DesignTokens.spacingMd),
        _buildPaymentTile(
          colors,
          selected: !_payOnline,
          icon: Icons.payments_outlined,
          title: AppStrings.payCash,
          subtitle: 'Pay the driver directly',
          onTap: () => setState(() => _payOnline = false),
        ),
        SizedBox(height: DesignTokens.spacingSm),
        _buildPaymentTile(
          colors,
          selected: _payOnline,
          icon: Icons.account_balance_wallet_outlined,
          title: AppStrings.payOnline,
          subtitle: 'UPI, cards and wallet',
          onTap: () => setState(() => _payOnline = true),
        ),
      ],
    );
  }

  Widget _buildPaymentTile(
    AppColorsExtension colors, {
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PDCard(
      variant: PDCardVariant.glass,
      onTap: onTap,
      borderColor: selected ? colors.primary : colors.outline,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (selected ? colors.primary : colors.onSurfaceVariant)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TokenTextStyles.labelLarge(color: colors.onSurface)),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? colors.primary : colors.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFareSheet(
    BuildContext context,
    AppColorsExtension colors,
    double safeBottom,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingXl,
        DesignTokens.spacingLg,
        DesignTokens.spacingXl,
        DesignTokens.spacingLg + safeBottom,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.fareBreakdown,
                style: TokenTextStyles.titleSmall(color: colors.onSurface),
              ),
              PDPrice(
                amount: _total,
                size: PDPriceSize.md,
                color: colors.primary,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingMd),
          if (_hasRealFare) ...[
            PDFareRow(label: AppStrings.baseFare, amount: _baseFare),
            SizedBox(height: DesignTokens.spacingXs),
          ],
          PDFareRow(label: AppStrings.distanceFare, amount: _distanceFare),
          SizedBox(height: DesignTokens.spacingXs),
          if (_returnTrip) ...[
            PDFareRow(label: 'Return trip', amount: _returnTripFee),
            SizedBox(height: DesignTokens.spacingXs),
          ],
          PDFareRow(label: AppStrings.timeFare, amount: _timeFare),
          SizedBox(height: DesignTokens.spacingXs),
          PDFareRow(label: AppStrings.surgeCharges, amount: _surgeFare),
          SizedBox(height: DesignTokens.spacingXs),
          PDFareRow(label: AppStrings.gst, amount: _gst),
          if (_discount > 0) ...[
            SizedBox(height: DesignTokens.spacingXs),
            PDFareRow(label: AppStrings.discount, amount: -_discount, isNegative: true),
          ],
          if (_helperFee > 0) ...[
            SizedBox(height: DesignTokens.spacingXs),
            PDFareRow(label: AppStrings.loadingHelper, amount: _helperFee),
          ],
          SizedBox(height: DesignTokens.spacingMd),
          PDButton(
            text: AppStrings.confirmBooking,
            variant: PDButtonVariant.primary,
            size: PDButtonSize.lg,
            isLoading: _bookingInProgress,
            onPressed: _confirmBooking,
          ),
        ],
      ),
    );
  }
}

class _CouponSheet extends StatelessWidget {
  const _CouponSheet({
    required this.controller,
    required this.onApply,
  });

  final TextEditingController controller;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PDInput(
            controller: controller,
            hint: AppStrings.couponCodeHint,
            prefixIcon: Icon(Icons.local_offer_outlined, size: DesignTokens.iconMd),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: DesignTokens.spacingLg),
          PDButton(
            text: AppStrings.applyCoupon,
            variant: PDButtonVariant.primary,
            size: PDButtonSize.lg,
            isFullWidth: true,
            onPressed: () => onApply(controller.text),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Center(
            child: Text(
              'Try PICK50 for ₹50 off',
              style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
