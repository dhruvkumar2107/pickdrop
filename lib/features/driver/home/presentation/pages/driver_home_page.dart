import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../shared/services/offline_action_queue.dart';
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
  static const String _driverName = 'Rajesh Kumar';
  static const String _vehicleLabel = 'Tata Ace • KA 01 AB 1234';
  static const double _todayEarnings = 2840;
  static const int _todayTrips = 12;
  static const double _acceptanceRate = 94;
  static const double _rating = 4.9;
  static const double _weekEarnings = 17420;
  static const double _monthEarnings = 62850;

  final List<_DriverTrip> _recentTrips = [
    _DriverTrip(
      id: 'PD1048',
      status: AppConstants.statusDelivered,
      pickup: 'Phoenix Marketcity, Viman Nagar',
      drop: 'Blueridge Phase 2, Hinjewadi',
      fare: 320,
      dateTime: DateTime(2026, 10, 6, 14, 20),
      vehicleType: 'Pickup',
      rating: 5,
    ),
    _DriverTrip(
      id: 'PD1047',
      status: AppConstants.statusDelivered,
      pickup: 'Koregaon Park, Pune',
      drop: 'Baner Road, Pune',
      fare: 465,
      dateTime: DateTime(2026, 10, 6, 11, 5),
      vehicleType: 'Pickup',
      rating: 4.8,
    ),
    _DriverTrip(
      id: 'PD1046',
      status: AppConstants.statusCancelled,
      pickup: 'Shivaji Nagar, Pune',
      drop: 'Aundh Gaon, Pune',
      fare: 50,
      dateTime: DateTime(2026, 10, 5, 18, 40),
      vehicleType: 'Pickup',
      rating: null,
    ),
  ];

  void _showIncomingRequest() {
    if (!mounted) return;
    context.go(RouteNames.incomingRequest);
  }

  @override
  void initState() {
    super.initState();
    OfflineActionQueue.refresh();
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
              child: const _OfflineSyncBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                0,
              ),
              child: _buildReliabilityAndPayoutPanel(colors),
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
                gross: _recentTrips.first.fare,
                completedTrips: _todayTrips,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
                0,
              ),
              child: _buildNewRequestCard(colors),
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
              child: _buildAvailabilityCard(colors),
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
              itemCount: _recentTrips.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.spacingMd),
              itemBuilder: (context, index) {
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
                value: '₹${_todayEarnings.toStringAsFixed(0)}',
                label: AppStrings.todaysEarnings,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.local_shipping_outlined,
                color: colors.info,
                value: '$_todayTrips',
                label: AppStrings.totalTrips,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.insights_outlined,
                color: colors.warning,
                value: '${_acceptanceRate.toStringAsFixed(0)}%',
                label: 'Acceptance',
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
                value: '₹${_weekEarnings.toStringAsFixed(0)}',
                label: 'This Week',
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                color: colors.primary,
                value: '₹${_monthEarnings.toStringAsFixed(0)}',
                label: 'This Month',
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                color: colors.secondary,
                value: _rating.toStringAsFixed(1),
                label: 'Driver rating',
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

  Widget _buildReliabilityAndPayoutPanel(AppColorsExtension colors) {
    return Column(
      children: [
        PDCard(
          variant: PDCardVariant.elevated,
          padding: EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PDCard(
                    variant: PDCardVariant.glass,
                    padding: EdgeInsets.all(DesignTokens.spacingSm),
                    radius: DesignTokens.radiusMd,
                    child: Icon(Icons.shield_rounded, color: colors.primary, size: DesignTokens.iconSm),
                  ),
                  SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: Text(
                      'Reliability & GPS check',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  PDBadge(
                    label: 'SAFE',
                    variant: PDBadgeVariant.success,
                    size: PDBadgeSize.sm,
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(label: 'Acceptance', value: '96%'),
                  ),
                  SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: _MiniMetric(label: 'On-time', value: '98%'),
                  ),
                  SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: _MiniMetric(label: 'GPS', value: '3 km'),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingSm),
              Text(
                'Fake GPS is blocked, cancellation risk is low, and a priority match is kept for nearby accepted trips.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontUI,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: DesignTokens.spacingMd),
        PDCard(
          variant: PDCardVariant.gradient,
          padding: EdgeInsets.all(DesignTokens.spacingLg),
          gradientColors: [colors.success.withValues(alpha: 0.12), colors.primary.withValues(alpha: 0.06)],
          child: Row(
            children: [
              PDCard(
                variant: PDCardVariant.glass,
                padding: EdgeInsets.all(DesignTokens.spacingSm),
                radius: DesignTokens.radiusMd,
                child: Icon(Icons.account_balance_wallet_rounded, color: colors.success, size: DesignTokens.iconSm),
              ),
              SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant payout ready',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      '₹640 available • UPI anytime • Min ₹100',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PDButton(
                text: 'Request payout',
                variant: PDButtonVariant.ghost,
                size: PDButtonSize.sm,
                onPressed: () => AppToast.success(context, 'UPI payout request sent. Funds will arrive in 30 minutes.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewRequestCard(AppColorsExtension colors) {
    final accent = colors.driverAccent;
    final onAccent = _onAccent(accent);

    return PDCard(
      variant: PDCardVariant.gradient,
      gradientColors: [accent, _accentEnd(accent)],
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      onTap: _showIncomingRequest,
      showShadow: true,
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.all(DesignTokens.spacingMd),
            radius: DesignTokens.radiusMd,
            child: Icon(
              Icons.bolt_rounded,
              size: DesignTokens.iconLg,
              color: onAccent,
            ),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PulsingDot(color: onAccent, size: 8),
                    SizedBox(width: DesignTokens.spacingSm),
                    Text(
                      'New delivery request nearby',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontUI,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingXs),
                Text(
                  '3.2 km away • ₹485 + ₹40 tip • Offer ends in 30s',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: onAccent.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: DesignTokens.iconLg,
            color: onAccent,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: DesignTokens.durationNormal,
          delay: 250.ms,
        )
        .slideY(begin: 0.1, end: 0, duration: DesignTokens.durationNormal);
  }

  Widget _buildAvailabilityCard(AppColorsExtension colors) {
    final accent = colors.driverAccent;

    return PDCard(
      variant: PDCardVariant.elevated,
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      showShadow: true,
      child: Row(
        children: [
          SizedBox(
            width: DesignTokens.avatarLg + DesignTokens.spacingMd,
            height: DesignTokens.avatarLg + DesignTokens.spacingMd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RadarRing(color: accent, delay: 0),
                _RadarRing(color: accent, delay: 700),
                PDCard(
                  variant: PDCardVariant.gradient,
                  gradientColors: [accent, _accentEnd(accent)],
                  radius: DesignTokens.avatarMd / 2,
                  child: Icon(
                    Icons.navigation_rounded,
                    size: DesignTokens.iconSm,
                    color: _onAccent(accent),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: DesignTokens.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High demand near you',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXs),
                Text(
                  '3 requests within 2 km • Surge 1.2x',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingSm),
                PDBadge(
                  label: 'Zone active',
                  variant: PDBadgeVariant.success,
                  size: PDBadgeSize.sm,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: DesignTokens.iconMd,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: DesignTokens.durationNormal,
          delay: 350.ms,
        )
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

class _OfflineSyncBanner extends StatelessWidget {
  const _OfflineSyncBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<int>(
      valueListenable: OfflineActionQueue.pendingCountNotifier,
      builder: (context, pending, _) {
        final synced = pending == 0;
        return PDCard(
          variant: synced ? PDCardVariant.success : PDCardVariant.warning,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          child: Row(
            children: [
              Icon(
                synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: DesignTokens.iconSm,
                color: synced ? colors.success : colors.warning,
              ),
              SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Text(
                  synced
                      ? 'Offline queue clear — all updates synced'
                      : '$pending update${pending == 1 ? '' : 's'} waiting to sync',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: synced ? colors.success : colors.warning,
                  ),
                ),
              ),
              if (!synced)
                PDButton(
                  text: 'Sync now',
                  variant: PDButtonVariant.ghost,
                  size: PDButtonSize.xs,
                  onPressed: () async {
                    final before = OfflineActionQueue.pendingCount;
                    await OfflineActionQueue.flush(FirebaseFirestore.instance);
                    if (!context.mounted) return;
                    final after = OfflineActionQueue.pendingCount;
                    if (after == 0) {
                      AppToast.success(context, 'Offline updates synced');
                    } else {
                      AppToast.warning(
                        context,
                        '$after of $before updates still waiting — will retry when online',
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.filled,
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingSm,
        horizontal: DesignTokens.spacingXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontUI,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXxs),
          Text(
            value,
            style: TextStyle(
              fontFamily: DesignTokens.fontUI,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
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
  const _PulsingDot({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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

class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.color, required this.delay});

  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.45, 0.45),
          end: const Offset(1.0, 1.0),
          duration: 1800.ms,
          delay: delay.ms,
          curve: Curves.easeOut,
        )
        .fade(begin: 0.9, end: 0, duration: 1800.ms, delay: delay.ms);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.elevated,
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.all(DesignTokens.spacingSm),
            radius: DesignTokens.radiusSm,
            child: Icon(icon, size: DesignTokens.iconSm, color: color),
          ),
          SizedBox(height: DesignTokens.spacingSm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DesignTokens.fontUI,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DesignTokens.fontUI,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
