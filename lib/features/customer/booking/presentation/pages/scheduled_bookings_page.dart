import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/common/common.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../data/datasources/scheduled_booking_remote_datasource.dart';
import '../../data/models/scheduled_booking_model.dart';

class ScheduledBookingsPage extends StatefulWidget {
  const ScheduledBookingsPage({super.key});

  @override
  State<ScheduledBookingsPage> createState() => _ScheduledBookingsPageState();
}

class _ScheduledBookingsPageState extends State<ScheduledBookingsPage> {
  final ScheduledBookingRemoteDataSource _dataSource =
      ScheduledBookingRemoteDataSource();

  List<ScheduledBookingModel> _bookings = [];
  bool _loading = true;

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
      final items = await _dataSource.fetchForCustomer(uid);
      final synced = await Future.wait(
        items.map((b) => _dataSource.syncDriverAssignment(b)),
      );
      if (!mounted) return;
      setState(() {
        _bookings = synced;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestCancel(ScheduledBookingModel booking) async {
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index < 0) return;
    setState(() => _bookings = [..._bookings]..removeAt(index));
    var undone = false;
    AppToast.show(
      context,
      'Scheduled delivery cancelled',
      duration: const Duration(seconds: 5),
      actionLabel: 'UNDO',
      onAction: () => undone = true,
    );
    await Future<void>.delayed(const Duration(seconds: 5));
    if (undone || !mounted) return;
    try {
      await _dataSource.cancel(booking.id);
    } catch (_) {}
  }

  String _format(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} • $hh:$mm';
  }

  void _scheduleDelivery() {
    if (!mounted) return;
    context.push(RouteNames.pickupSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final upcoming = _bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = _bookings.where((b) => !b.isUpcoming).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, colors)),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_bookings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'No scheduled deliveries',
                message:
                    'Plan up to 7 days ahead — fare locked when you book.',
                icon: Icons.schedule_rounded,
                actionText: 'Schedule a delivery',
                onAction: _scheduleDelivery,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _sectionTitle(colors, 'Upcoming', upcoming.length),
            ),
            SliverList.builder(
              itemCount: upcoming.length,
              itemBuilder: (_, i) => _card(colors, upcoming[i], showCancel: true),
            ),
            SliverToBoxAdapter(
              child: _sectionTitle(colors, 'Past', past.length),
            ),
            SliverList.builder(
              itemCount: past.length,
              itemBuilder: (_, i) => _card(colors, past[i], showCancel: false),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingLg),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingSm,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
          ),
          child: PrimaryButton(
            text: 'Schedule a delivery',
            leadingIcon: Icons.add_alarm_rounded,
            onPressed: _scheduleDelivery,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.top + AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Scheduled deliveries',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: colors.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Up to 7 days ahead • Matching starts 30 min before',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColorsExtension colors, String title, int count) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(AppDimensions.spacingLg,
            AppDimensions.spacingLg, AppDimensions.spacingLg, AppDimensions.spacingSm),
        child: Text(
          '$title ($count)',
          style: AppTextStyles.labelMedium
              .copyWith(color: colors.onSurfaceVariant),
        ),
      );

  Widget _card(
    AppColorsExtension colors,
    ScheduledBookingModel booking, {
    required bool showCancel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        0,
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _format(booking.scheduledAt),
                    style: AppTextStyles.labelLarge
                        .copyWith(color: colors.onSurface),
                  ),
                ),
                StatusChip.fromStatus(booking.status, dense: true),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              '${booking.pickupAddress} → ${booking.dropAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall
                  .copyWith(color: colors.onSurfaceVariant),
            ),
            if (booking.intermediateStops.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Stops: ${booking.intermediateStops.map((stop) => stop['address'] ?? '').join(' → ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: AppDimensions.iconSm, color: colors.onSurfaceVariant),
                const SizedBox(width: AppDimensions.spacingXs),
                Expanded(
                  child: Text(
                    '${booking.vehicleType} • '
                    '${booking.goodsType.isEmpty ? 'General goods' : booking.goodsType}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                Text(
                  '₹${booking.estimatedFare.toStringAsFixed(0)}',
                  style:
                      AppTextStyles.priceSmall.copyWith(color: colors.onSurface),
                ),
                if (showCancel) ...[
                  const SizedBox(width: AppDimensions.spacingMd),
                  GestureDetector(
                    onTap: () => _requestCancel(booking),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
