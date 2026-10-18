import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/common/common.dart';
import '../../../../../../core/widgets/status_chip.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  static const List<String> _filters = ['All', 'Active', 'Completed'];
  int _selectedFilter = 0;

  static final List<_MockTrip> _mockTrips = [
    _MockTrip(
      id: 'PD1001',
      status: 'IN_TRANSIT',
      pickup: '123 MG Road, Bangalore',
      drop: '456 Koramangala, Bangalore',
      fare: 249,
      dateTime: DateTime(2026, 10, 2, 14, 30),
      vehicleType: 'Bike',
    ),
    _MockTrip(
      id: 'PD1002',
      status: 'DRIVER_ASSIGNED',
      pickup: '789 Indiranagar, Bangalore',
      drop: '321 Whitefield, Bangalore',
      fare: 450,
      dateTime: DateTime(2026, 10, 3, 9, 15),
      vehicleType: '3-Wheeler',
    ),
    _MockTrip(
      id: 'PD1003',
      status: 'ARRIVED',
      pickup: '12 Jayanagar 4th Block',
      drop: '88 BTM Layout 2nd Stage',
      fare: 199,
      dateTime: DateTime(2026, 10, 4, 18, 5),
      vehicleType: 'Mini Truck',
    ),
    _MockTrip(
      id: 'PD1004',
      status: 'COMPLETED',
      pickup: '55 Electronic City Phase 1',
      drop: '9 HSR Layout Sector 2',
      fare: 520,
      dateTime: DateTime(2026, 9, 28, 11, 45),
      vehicleType: 'Pickup',
    ),
    _MockTrip(
      id: 'PD1005',
      status: 'DELIVERED',
      pickup: '22 Rajajinagar Industrial Area',
      drop: '40 Malleshwaram 8th Cross',
      fare: 310,
      dateTime: DateTime(2026, 9, 22, 16, 20),
      vehicleType: '3-Wheeler',
    ),
    _MockTrip(
      id: 'PD1006',
      status: 'CANCELLED',
      pickup: '15 Yeshwanthpur',
      drop: '63 Hebbal Flyover',
      fare: 275,
      dateTime: DateTime(2026, 9, 15, 10, 0),
      vehicleType: 'Bike',
    ),
  ];

  bool _isActiveStatus(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'DRIVER_ASSIGNED' ||
        normalized == 'ARRIVED' ||
        normalized == 'PICKED_UP' ||
        normalized == 'IN_TRANSIT' ||
        normalized == 'STARTED';
  }

  bool _isCompletedStatus(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'COMPLETED' || normalized == 'DELIVERED';
  }

  List<_MockTrip> get _filteredTrips {
    switch (_selectedFilter) {
      case 1:
        return _mockTrips.where((t) => _isActiveStatus(t.status)).toList();
      case 2:
        return _mockTrips.where((t) => _isCompletedStatus(t.status)).toList();
      default:
        return _mockTrips;
    }
  }

  String _formatDate(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • $hh:$mm';
  }

  void _openTripDetail() {
    if (!mounted) return;
    context.push(RouteNames.tripDetail);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trips = _filteredTrips;

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
              child: _buildFilterChips(context, colors),
            ),
          ),
          if (trips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: _selectedFilter == 1
                    ? 'No active trips'
                    : _selectedFilter == 2
                        ? 'No completed trips'
                        : 'No trips yet',
                message: _selectedFilter == 1
                    ? 'Your ongoing deliveries will appear here'
                    : _selectedFilter == 2
                        ? 'Your delivered trips will appear here'
                        : 'Book a trip and it will show up here',
                icon: Icons.route_outlined,
                lottieAsset: 'assets/animations/empty_trips.json',
                actionText: AppStrings.bookNow,
                onAction: () {
                  if (!mounted) return;
                  context.go(RouteNames.customerHome);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingSm,
                AppDimensions.spacingLg,
                AppDimensions.spacingXxl,
              ),
              sliver: SliverList.separated(
                itemCount: trips.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimensions.spacingMd),
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return _PremiumTripCard(
                    trip: trip,
                    formattedDate: _formatDate(trip.dateTime),
                    onTap: _openTripDetail,
                  )
                      .animate()
                      .fadeIn(duration: AppConstants.mediumAnimation)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: AppConstants.mediumAnimation,
                        delay: Duration(milliseconds: 60 * index),
                      );
                },
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
                  'My Trips',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: Text(
                  '${_mockTrips.length} trips',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Track every delivery you book with PickDrop',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXs),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppConstants.shortAnimation,
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingSm,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.brandGradient : null,
                  color: isSelected ? null : colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _filters[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MockTrip {
  const _MockTrip({
    required this.id,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.dateTime,
    required this.vehicleType,
  });

  final String id;
  final String status;
  final String pickup;
  final String drop;
  final double fare;
  final DateTime dateTime;
  final String vehicleType;
}

class _PremiumTripCard extends StatelessWidget {
  const _PremiumTripCard({
    required this.trip,
    required this.formattedDate,
    this.onTap,
  });

  final _MockTrip trip;
  final String formattedDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking #${trip.id}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  StatusChip.fromStatus(trip.status, dense: true),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _RouteRow(
                icon: Icons.radio_button_checked,
                iconColor: colors.success,
                label: 'Pickup',
                address: trip.pickup,
                colors: colors,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spacingMd + 5,
                ),
                child: Container(
                  width: 2,
                  height: AppDimensions.spacingMd,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              _RouteRow(
                icon: Icons.location_on_rounded,
                iconColor: colors.primary,
                label: 'Drop',
                address: trip.drop,
                colors: colors,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                height: 1,
                color: colors.outlineVariant,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                children: [
                  Icon(
                    _vehicleIcon(trip.vehicleType),
                    size: AppDimensions.iconSm,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Expanded(
                    child: Text(
                      trip.vehicleType,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    '₹${trip.fare.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                      color: colors.onSurface,
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

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'Bike':
        return Icons.two_wheeler_outlined;
      case '3-Wheeler':
        return Icons.electric_rickshaw_outlined;
      case 'Pickup':
        return Icons.local_shipping_outlined;
      case 'Mini Truck':
        return Icons.airport_shuttle_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: iconColor),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
