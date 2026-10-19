import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/common.dart';
import '../../../shared/widgets/commission_transparency_card.dart';
import '../../../shared/widgets/sos_button.dart';
import '../providers/driver_home_providers.dart';

/// Readable foreground colour for a given accent (adapts to light/dark themes).
Color _onAccent(Color accent) =>
    accent.computeLuminance() > 0.45 ? const Color(0xFF062B2E) : Colors.white;

/// Darker companion colour used to finish driver accent gradients.
Color _accentEnd(Color accent) => Color.lerp(accent, Colors.black, 0.32)!;

class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  Map<String, dynamic> _driverData = const {};
  String get _driverName => FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
      ? FirebaseAuth.instance.currentUser!.displayName!.trim()
      : 'Driver';
  String get _vehicleLabel {
    final model = (_driverData['vehicleModel'] as String?)?.trim();
    final number = (_driverData['vehicleNumber'] as String?)?.trim();
    return [if (model != null && model.isNotEmpty) model, if (number != null && number.isNotEmpty) number]
        .join(' • ');
  }
  double get _totalEarnings => (_driverData['totalEarnings'] as num?)?.toDouble() ?? 0;
  int get _totalTrips => (_driverData['totalTrips'] as num?)?.toInt() ?? 0;
  double get _rating => (_driverData['rating'] as num?)?.toDouble() ?? 0;

  final List<_DriverTrip> _recentTrips = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _offersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tripsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;
  String? _shownOfferId;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _driverSub = FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots().listen((snapshot) {
        if (!mounted) return;
        setState(() => _driverData = snapshot.data() ?? const {});
      });
      _tripsSub = FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        final trips = snapshot.docs
            .where((doc) => doc.data()['status'] == 'DELIVERED')
            .map((doc) {
          final data = doc.data();
          final pickup = data['pickup'] as Map<String, dynamic>? ?? const {};
          final drop = data['drop'] as Map<String, dynamic>? ?? const {};
          final fare = data['fareBreakdown'] as Map<String, dynamic>? ?? const {};
          final createdAt = data['createdAt'];
          return _DriverTrip(
            id: doc.id,
            status: AppConstants.statusDelivered,
            pickup: pickup['address'] as String? ?? 'Pickup location',
            drop: drop['address'] as String? ?? 'Drop location',
            fare: (fare['total'] as num?)?.toDouble() ?? 0,
            dateTime: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
            vehicleType: data['vehicleTypeId'] as String? ?? 'Delivery',
            rating: null,
          );
        }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        setState(() => _recentTrips
          ..clear()
          ..addAll(trips.take(3)));
      });
      _offersSub = FirebaseFirestore.instance
          .collection('driverOffers')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: 'PENDING')
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            if (snapshot.docs.isEmpty) {
              _shownOfferId = null;
              return;
            }
            final offer = snapshot.docs.first;
            final bookingId = offer.data()['bookingId'] as String?;
            if (bookingId == null || bookingId == _shownOfferId) return;
            _shownOfferId = bookingId;
            context.go('${RouteNames.incomingRequest}?bookingId=${Uri.encodeComponent(bookingId)}');
          });
    }
  }

  @override
  void dispose() {
    _offersSub?.cancel();
    _tripsSub?.cancel();
    _driverSub?.cancel();
    super.dispose();
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
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                0,
              ),
              child: _buildStats(colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingMd,
                DesignTokens.spacingLg,
                0,
              ),
              child: CommissionTransparencyCard(
                gross: _totalEarnings,
                completedTrips: _totalTrips,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingXl,
                DesignTokens.spacingLg,
                0,
              ),
              child: _buildQuickLinks(context, colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingMd,
                DesignTokens.spacingLg,
                0,
              ),
              child: const SosButton(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingXl,
                DesignTokens.spacingLg,
                0,
              ),
              child: _SectionTitle(
                title: AppStrings.recentTrips,
                action: PDButton(
                  text: AppStrings.tripHistory,
                  variant: PDButtonVariant.ghost,
                  size: PDButtonSize.sm,
                  onPressed: () {
                    if (!mounted) return;
                    context.go(RouteNames.driverTripHistory);
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacingLg,
              0,
              DesignTokens.spacingLg,
              DesignTokens.spacingSm,
            ),
            sliver: SliverList.separated(
              itemCount: _recentTrips.isEmpty ? 1 : _recentTrips.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.spacingMd),
              itemBuilder: (context, index) {
                if (_recentTrips.isEmpty) {
                  return const PDCard(
                    child: Text('Completed trips will appear here.'),
                  );
                }
                final trip = _recentTrips[index];
                return _DriverTripTile(trip: trip)
                    .animate()
                    .fadeIn(duration: DesignTokens.durationNormal)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: DesignTokens.durationNormal,
                      delay: Duration(milliseconds: 60 * index),
                    );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingMd,
                DesignTokens.spacingLg,
                DesignTokens.spacingXxl,
              ),
              child: _buildOfflineHint(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension colors) {
    final onAccent = _onAccent(colors.driverAccent);
    final isOnline = ref.watch(driverOnlineProvider);
    final notifier = ref.read(driverOnlineProvider.notifier);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        MediaQuery.of(context).padding.top + DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingXl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.driverAccent, _accentEnd(colors.driverAccent)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PDCard(
                variant: PDCardVariant.glass,
                padding: EdgeInsets.all(DesignTokens.spacingSm),
                radius: DesignTokens.radiusFull,
                child: Text(
                  _driverName.split(' ').map((e) => e[0]).take(2).join(),
                  style: TokenTextStyles.titleMedium(
                    color: onAccent,
                    weight: DesignTokens.wBold,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: DesignTokens.durationNormal)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: DesignTokens.durationNormal,
                    curve: Curves.easeOutBack,
                  ),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning! Ready to earn?',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onAccent.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _driverName,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                        color: onAccent,
                      ),
                    ),
                    Text(
                      _vehicleLabel,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: onAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              PDCard(
                variant: PDCardVariant.glass,
                padding: EdgeInsets.all(DesignTokens.spacingXs),
                radius: DesignTokens.radiusFull,
                onTap: () {
                  if (!mounted) return;
                  AppToast.info(context, 'No new notifications');
                },
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: DesignTokens.iconMd,
                  color: onAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingLg),
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.all(DesignTokens.spacingLg),
            radius: DesignTokens.radiusLg,
            color: onAccent.withValues(alpha: 0.12),
            borderColor: onAccent.withValues(alpha: 0.28),
            child: Column(
              children: [
                Row(
                  children: [
                    _PulsingDot(
                      color: isOnline ? colors.success : colors.warning,
                    ),
                    SizedBox(width: DesignTokens.spacingSm),
                    Expanded(
                      child: Text(
                        isOnline ? AppStrings.youAreOnline : AppStrings.youAreOffline,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontUI,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onAccent,
                        ),
                      ),
                    ),
                    PDBadge(
                      label: isOnline ? 'ONLINE' : 'OFFLINE',
                      variant: isOnline ? PDBadgeVariant.success : PDBadgeVariant.warning,
                      size: PDBadgeSize.sm,
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingMd),
                Center(
                  child: PDButton(
                    text: isOnline ? AppStrings.goOffline : AppStrings.goOnline,
                    leadingIcon: isOnline ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    variant: isOnline ? PDButtonVariant.destructive : PDButtonVariant.success,
                    size: PDButtonSize.lg,
                    isFullWidth: false,
                    onPressed: () async {
                      final ctx = context;
                      try {
                        await notifier.setOnline(!isOnline);
                        if (!mounted || !ctx.mounted) return;
                        AppToast.success(ctx, !isOnline ? 'You are now online' : 'You are now offline');
                      } catch (e) {
                        if (!mounted || !ctx.mounted) return;
                        AppToast.error(ctx, 'Failed to change status: $e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppColorsExtension colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                color: colors.driverAccent,
                value: '₹${_totalEarnings.toStringAsFixed(0)}',
                label: 'Total earnings',
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.local_shipping_outlined,
                color: colors.info,
                value: '$_totalTrips',
                label: AppStrings.totalTrips,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.insights_outlined,
                color: colors.warning,
                value: _rating > 0 ? _rating.toStringAsFixed(1) : '—',
                label: 'Driver rating',
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingMd),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_view_week_outlined,
                color: colors.success,
                value: _driverData['isVerified'] == true ? 'Verified' : 'Pending',
                label: 'Verification',
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                color: colors.primary,
                value: _driverData['isOnline'] == true ? 'Online' : 'Offline',
                label: 'Availability',
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                color: colors.secondary,
                value: _vehicleLabel.isEmpty ? '—' : 'Set',
                label: 'Vehicle',
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(duration: DesignTokens.durationNormal, delay: 150.ms)
        .slideY(begin: 0.1, end: 0, duration: DesignTokens.durationNormal);
  }

  Widget _buildQuickLinks(BuildContext context, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Quick Actions'),
        SizedBox(height: DesignTokens.spacingMd),
        Row(
          children: [
            Expanded(
              child: PDButton(
                text: AppStrings.earnings,
                leadingIcon: Icons.account_balance_wallet_outlined,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.driverEarnings);
                },
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: PDButton(
                text: AppStrings.tripHistory,
                leadingIcon: Icons.history_outlined,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.driverTripHistory);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingMd),
        Row(
          children: [
            Expanded(
              child: PDButton(
                text: 'Profile',
                leadingIcon: Icons.person_outline,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.driverProfile);
                },
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: PDButton(
                text: AppStrings.helpSupport,
                leadingIcon: Icons.help_outline,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.helpSupport);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingMd),
        PDButton(
          text: 'Payouts',
          leadingIcon: Icons.account_balance_outlined,
          variant: PDButtonVariant.outline,
          size: PDButtonSize.md,
          isFullWidth: true,
          onPressed: () {
            if (!mounted) return;
            context.go(RouteNames.driverPayouts);
          },
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: DesignTokens.durationNormal,
          delay: 450.ms,
        )
        .slideY(begin: 0.1, end: 0, duration: DesignTokens.durationNormal);
  }

  Widget _buildOfflineHint(AppColorsExtension colors) {
    final isOnline = ref.watch(driverOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    return PDCard(
      variant: PDCardVariant.filled,
      color: colors.warningLight,
      borderColor: colors.warning.withValues(alpha: 0.35),
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.warning,
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              'You are offline — go online to start receiving delivery requests',
              style: TextStyle(
                fontFamily: DesignTokens.fontUI,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: DesignTokens.durationNormal);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PDCard(
      variant: PDCardVariant.filled,
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSm),
          SizedBox(height: DesignTokens.spacingSm),
          Text(value, style: TextStyle(fontFamily: DesignTokens.fontUI, fontSize: 16,
              fontWeight: FontWeight.w700, color: colors.onSurface)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: DesignTokens.fontUI, fontSize: 10,
                  fontWeight: FontWeight.w500, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: DesignTokens.fontUI,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        ?action,
      ],
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.3, 1.3),
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .fade(begin: 1, end: 0.4, duration: 900.ms);
  }
}

class _DriverTrip {
  const _DriverTrip({
    required this.id,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.dateTime,
    required this.vehicleType,
    required this.rating,
  });

  final String id;
  final String status;
  final String pickup;
  final String drop;
  final double fare;
  final DateTime dateTime;
  final String vehicleType;
  final double? rating;
}

class _DriverTripTile extends StatelessWidget {
  const _DriverTripTile({required this.trip});

  final _DriverTrip trip;

  String get _formattedDate {
    final date = trip.dateTime;
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.elevated,
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trip #${trip.id}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              PDBadge(
                label: trip.status,
                variant: _getBadgeVariant(trip.status),
                size: PDBadgeSize.sm,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingMd),
          _RouteRow(
            icon: Icons.radio_button_checked,
            iconColor: colors.success,
            label: 'Pickup',
            address: trip.pickup,
            colors: colors,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: DesignTokens.iconMd + DesignTokens.spacingMd - 2,
            ),
            child: Container(
              width: 2,
              height: DesignTokens.spacingMd,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
            ),
          ),
          _RouteRow(
            icon: Icons.location_on_rounded,
            iconColor: colors.driverAccent,
            label: 'Drop',
            address: trip.drop,
            colors: colors,
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Divider(color: colors.outlineVariant, height: 1),
          SizedBox(height: DesignTokens.spacingSm),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: DesignTokens.iconXs,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: DesignTokens.spacingXs),
              Expanded(
                child: Text(
                  _formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (trip.rating != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: DesignTokens.iconXs,
                  color: colors.warning,
                ),
                SizedBox(width: DesignTokens.spacingXxs),
                Text(
                  trip.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
              ],
              PDPrice(
                amount: trip.fare,
                size: PDPriceSize.sm,
                color: colors.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PDBadgeVariant _getBadgeVariant(String status) {
    switch (status) {
      case 'DELIVERED':
        return PDBadgeVariant.success;
      case 'CANCELLED':
        return PDBadgeVariant.error;
      case 'IN_TRANSIT':
      case 'PICKED_UP':
      case 'ARRIVED':
      case 'DRIVER_ASSIGNED':
        return PDBadgeVariant.info;
      default:
        return PDBadgeVariant.neutral;
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
        Icon(icon, size: DesignTokens.iconSm, color: iconColor),
        SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: DesignTokens.fontUI,
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
                  fontFamily: DesignTokens.fontUI,
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
