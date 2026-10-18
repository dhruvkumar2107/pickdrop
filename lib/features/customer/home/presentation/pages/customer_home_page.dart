import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../config/router/route_names.dart';
import '../widgets/referral_banner.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/common.dart';

import '../widgets/guided_tour_overlay.dart';

/// Premium Customer Home Screen
/// Features:
/// - Hero section with "PICKDROP" branding
/// - Smart booking entry point
/// - Quick categories
/// - Recent trips
/// - Saved locations
/// - Active delivery tracking
/// - Offers/promotions
class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  bool _isLoadingLocation = true;
  String? _locationError;

  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _bookKey = GlobalKey();

  bool _tourScheduled = false;

  // Demo data - in production, these would come from backend
  final List<SavedAddress> _savedAddresses = [
    SavedAddress(
      id: '1',
      label: 'Home',
      address: '123 MG Road, Bangalore, Karnataka 560001',
      lat: 12.9716,
      lng: 77.5946,
      isDefault: true,
    ),
    SavedAddress(
      id: '2',
      label: 'Work',
      address: '456 Koramangala, Bangalore, Karnataka 560034',
      lat: 12.9352,
      lng: 77.6146,
      isDefault: false,
    ),
  ];

  final List<RecentTrip> _recentTrips = [
    RecentTrip(
      id: 'PD-1048',
      pickupAddress: '123 MG Road, Bangalore',
      dropAddress: '456 Koramangala, Bangalore',
      fare: 250.0,
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      vehicleType: 'Bike',
      status: 'DELIVERED',
    ),
    RecentTrip(
      id: 'PD-1047',
      pickupAddress: '789 Indiranagar, Bangalore',
      dropAddress: '321 Whitefield, Bangalore',
      fare: 450.0,
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      vehicleType: '3-Wheeler',
      status: 'DELIVERED',
    ),
    RecentTrip(
      id: 'PD-1046',
      pickupAddress: 'Shivaji Nagar, Pune',
      dropAddress: 'Aundh Gaon, Pune',
      fare: 50.0,
      dateTime: DateTime.now().subtract(const Duration(days: 7)),
      vehicleType: 'Pickup',
      status: 'CANCELLED',
    ),
  ];

  // Categories for quick booking
  static const List<_Category> _categories = [
    _Category(
      id: 'parcel',
      label: 'Parcel',
      icon: Icons.inventory_2_outlined,
      description: 'Documents & small items',
    ),
    _Category(
      id: 'bike',
      label: 'Bike',
      icon: Icons.two_wheeler_outlined,
      description: 'Up to 20 kg',
    ),
    _Category(
      id: 'three_wheeler',
      label: '3-Wheeler',
      icon: Icons.local_shipping_outlined,
      description: 'Up to 500 kg',
    ),
    _Category(
      id: 'mini_truck',
      label: 'Mini Truck',
      icon: Icons.local_shipping_outlined,
      description: 'Up to 750 kg',
    ),
    _Category(
      id: 'pickup',
      label: 'Pickup',
      icon: Icons.local_shipping_outlined,
      description: 'Up to 1.5 ton',
    ),
    _Category(
      id: 'large_truck',
      label: 'Large Truck',
      icon: Icons.local_shipping_outlined,
      description: 'Up to 5 ton',
    ),
    _Category(
      id: 'house_shifting',
      label: 'House Shifting',
      icon: Icons.home_outlined,
      description: 'Full home relocation',
    ),
    _Category(
      id: 'business',
      label: 'Business',
      icon: Icons.business_outlined,
      description: 'Bulk & scheduled',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  List<CoachMark> get _tourMarks => [
        CoachMark(
          key: _searchKey,
          title: 'Where are you sending?',
          message: 'Tap to enter pickup and drop locations, or use voice search.',
        ),
        CoachMark(
          key: _categoriesKey,
          title: 'Choose your vehicle',
          message: 'Swipe through categories or let us recommend the best fit.',
        ),
        CoachMark(
          key: _bookKey,
          title: 'Book in seconds',
          message: 'Your shortcut to instant booking with transparent pricing.',
        ),
      ];

  void _maybeStartTour() {
    if (_tourScheduled || !mounted) return;
    _tourScheduled = true;
    GuidedTour.maybeShow(context, _tourMarks);
  }

  void _onVoiceSearch(String transcript) {
    context.go(
      '${RouteNames.pickupSelection}?label=${Uri.encodeComponent(transcript)}',
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError =
                'Location access is off for PickDrop. Turn it on so we can find drivers near you.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location access is blocked for PickDrop. Allow it in Settings to see nearby drivers.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLatLng!,
              zoom: 15,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'We could not place you on the map just now. Give it another try.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLatLng != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLatLng!,
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _selectSavedAddress(SavedAddress address) {
    context.go(
      '${RouteNames.pickupSelection}?lat=${address.lat}&lng=${address.lng}&label=${Uri.encodeComponent(address.label)}',
    );
  }

  void _onCategoryTap(_Category category) {
    // Navigate to booking flow with pre-selected category
    context.go(
      '${RouteNames.pickupSelection}?category=${category.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Full-screen map background
          Positioned.fill(child: _buildMapBackground()),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacingLg,
                  DesignTokens.spacingMd,
                  DesignTokens.spacingLg,
                  0,
                ),
                child: Row(
                  children: [
                    _buildGlassAppBar(l10n),
                    const Spacer(),
                    _buildNotificationButton(),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal)
                .slideY(begin: -0.4, end: 0),
          ),

          // Bottom sheet panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacingLg,
                  0,
                  DesignTokens.spacingLg,
                  DesignTokens.spacingLg,
                ),
                child: PDCard(
                  variant: PDCardVariant.glass,
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingSm,
                    DesignTokens.spacingLg,
                    DesignTokens.spacingMd,
                  ),
                  showShadow: true,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: context.screenHeight * 0.75,
                    ),
                    child: SingleChildScrollView(
                      child: _buildPanelContent(l10n),
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal, delay: 120.ms)
                .slideY(begin: 0.25, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(AppLocalizations l10n) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.glass,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingXs,
        DesignTokens.spacingXs,
        DesignTokens.spacingMd,
        DesignTokens.spacingXs,
      ),
      radius: DesignTokens.radiusFull,
      showShadow: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.transparent,
            child: InkWell(
              onTap: () => context.go(RouteNames.customerProfile),
              customBorder: const CircleBorder(),
              child: Ink(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: DesignTokens.iconSm,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appName,
                style: TokenTextStyles.titleMedium(
                  color: colors.onSurface,
                  weight: DesignTokens.wBold,
                ),
              ),
              Text(
                l10n.appTagline,
                style: TokenTextStyles.labelSmall(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.glass,
      padding: const EdgeInsets.all(DesignTokens.spacingXs),
      radius: DesignTokens.radiusFull,
      showShadow: true,
      onTap: () => context.go(RouteNames.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.go(RouteNames.notifications),
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              size: DesignTokens.iconMd,
              color: colors.onSurface,
            ),
          ),
          Positioned(
            top: DesignTokens.spacingSm,
            right: DesignTokens.spacingSm,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.glass, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(AppLocalizations l10n) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingMd),

        // Hero Section
        _buildHeroSection(l10n),
        SizedBox(height: DesignTokens.spacingXl),

        // Primary Booking Entry
        _buildBookingEntry(l10n),
        SizedBox(height: DesignTokens.spacingXl),

        // Quick Categories
        _buildQuickCategories(),
        SizedBox(height: DesignTokens.spacingXl),

        // Smart Defaults Card
        _buildSmartDefaultsCard(l10n),
        SizedBox(height: DesignTokens.spacingXl),

        // Referral / invite friends
        const ReferralBanner(),
        SizedBox(height: DesignTokens.spacingXl),

        // Active Delivery (if any)
        // _buildActiveDelivery(), // TODO: Connect to backend
        // SizedBox(height: DesignTokens.spacingXl),

        // Saved Addresses
        if (_savedAddresses.isNotEmpty) ...[
          _buildSectionHeader(
            title: l10n.savedAddresses,
            actionLabel: 'View All',
            onAction: () => context.go(RouteNames.savedAddresses),
          ),
          SizedBox(height: DesignTokens.spacingSm),
          _buildSavedAddresses(),
          SizedBox(height: DesignTokens.spacingXl),
        ],

        // Recent Trips
        _buildSectionHeader(
          title: l10n.recentTrips,
          actionLabel: 'View All',
          onAction: () => context.go(RouteNames.myTrips),
        ),
        SizedBox(height: DesignTokens.spacingSm),
        if (_recentTrips.isEmpty)
          PDEmptyState(
            title: l10n.noRecentTrips,
            message: 'Your completed trips will appear here',
            icon: Icons.history_outlined,
            actionLabel: l10n.bookNow,
            onAction: () => context.go(RouteNames.pickupSelection),
          )
        else
          Column(
            children: [
              for (final trip in _recentTrips) _RecentTripRow(trip: trip),
            ],
          ),

        SizedBox(height: DesignTokens.spacingMd),
        PDButton(
          text: l10n.bookNow,
          leadingIcon: Icons.local_shipping_outlined,
          onPressed: () => context.go(RouteNames.pickupSelection),
          variant: PDButtonVariant.primary,
          size: PDButtonSize.lg,
        ),
        SizedBox(height: DesignTokens.spacingMd),
      ],
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n) {
    return PDCard(
      variant: PDCardVariant.gradient,
      padding: EdgeInsets.all(DesignTokens.spacingXl),
      radius: DesignTokens.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PICKDROP',
            style: TokenTextStyles.displayMedium(
              color: Colors.white,
              weight: DesignTokens.wExtraBold,
              letterSpacing: DesignTokens.lsTight,
            ),
          ),
          SizedBox(height: DesignTokens.spacingSm),
          Text(
            'Move anything. Anywhere. Smarter.',
            style: TokenTextStyles.bodyLarge(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              _HeroStat(
                value: '2.4M+',
                label: 'Deliveries',
              ),
              SizedBox(width: DesignTokens.spacingXl),
              _HeroStat(
                value: '50K+',
                label: 'Drivers',
              ),
              SizedBox(width: DesignTokens.spacingXl),
              _HeroStat(
                value: '4.9★',
                label: 'Rating',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: DesignTokens.durationEnter,
      delay: 200.ms,
    ).slideY(begin: 0.2, end: 0);
  }

  Widget _buildBookingEntry(AppLocalizations l10n) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search/Location Input
        PDCard(
          key: _searchKey,
          variant: PDCardVariant.filled,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingMd,
          ),
          radius: DesignTokens.radiusMd,
          onTap: () => context.go(RouteNames.pickupSelection),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: DesignTokens.iconMd,
                color: colors.primary,
              ),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Text(
                  l10n.searchLocation,
                  style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
                ),
              ),
              // Voice search button
              Material(
                color: colors.transparent,
                child: InkWell(
                  onTap: () => _onVoiceSearch('Voice input'),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingSm),
                    child: Icon(
                      Icons.mic_rounded,
                      size: DesignTokens.iconMd,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingXs),
              Icon(
                Icons.tune_rounded,
                size: DesignTokens.iconSm,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),

        SizedBox(height: DesignTokens.spacingMd),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: PDButton(
                text: 'Schedule',
                leadingIcon: Icons.schedule_rounded,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () => AppToast.info(
                  context,
                  'Schedule a delivery for later',
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: PDButton(
                text: 'Share Ride',
                leadingIcon: Icons.share_rounded,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () => AppToast.info(
                  context,
                  'Share your live trip with family',
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: PDButton(
                text: 'Support',
                leadingIcon: Icons.help_rounded,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () => context.go(RouteNames.helpSupport),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCategories() {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Popular Categories',
              style: TokenTextStyles.titleMedium(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(RouteNames.vehicleSelection),
              child: Text(
                'View All',
                style: TokenTextStyles.labelLarge(color: colors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingMd),
        SizedBox(
          key: _categoriesKey,
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => SizedBox(width: DesignTokens.spacingSm),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _CategoryCard(
                category: category,
                onTap: () => _onCategoryTap(category),
              ).animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn(duration: DesignTokens.durationNormal)
                .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmartDefaultsCard(AppLocalizations l10n) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.elevated,
      borderColor: colors.primary.withValues(alpha: 0.22),
      radius: DesignTokens.radiusLg,
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: DesignTokens.iconSm),
              SizedBox(width: DesignTokens.spacingSm),
              Text(
                'Smart defaults ready',
                style: TokenTextStyles.titleSmall(
                  color: colors.onSurface,
                  weight: DesignTokens.wBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingSm),
          Text(
            'Last vehicle: Bike • Last payment: UPI • Current location: Home',
            style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Wrap(
            spacing: DesignTokens.spacingSm,
            runSpacing: DesignTokens.spacingSm,
            children: [
              _CompactPill(label: 'Bike', icon: Icons.two_wheeler_rounded, accent: colors.primary),
              _CompactPill(label: 'UPI', icon: Icons.payment_rounded, accent: colors.success),
              _CompactPill(label: 'Family safety', icon: Icons.shield_rounded, accent: colors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TokenTextStyles.headlineSmall(
            color: colors.onSurface,
            fontSize: 17,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: TokenTextStyles.labelLarge(color: colors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddresses() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _savedAddresses.length,
        itemBuilder: (context, index) {
          final address = _savedAddresses[index];
          return _SavedAddressCard(
            address: address,
            onTap: () => _selectSavedAddress(address),
          );
        },
      ),
    );
  }

  Widget _buildMapBackground() {
    final colors = context.colors;

    if (_isLoadingLocation) {
      return ColoredBox(
        color: colors.surfaceVariant,
        child: Center(
          child: PDPageLoader(message: 'Finding you on the map'),
        ),
      );
    }

    if (_locationError != null) {
      return ColoredBox(
        color: colors.surfaceVariant,
        child: PDErrorState(
          title: 'We need your location',
          message: _locationError!,
          actionLabel: 'Try again',
          onAction: _getCurrentLocation,
        ),
      );
    }

    if (_currentLatLng == null) {
      return ColoredBox(
        color: colors.surfaceVariant,
        child: PDErrorState(
          title: 'The map is still loading',
          message: 'We could not pin your location. Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _getCurrentLocation,
        ),
      );
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _currentLatLng!,
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      },
      onTap: (LatLng position) {
        // Could be used for manual pin placement
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TokenTextStyles.priceLarge(
            color: Colors.white,
            weight: DesignTokens.wExtraBold,
          ),
        ),
        Text(
          label,
          style: TokenTextStyles.labelMedium(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 100,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: PDCard(
            variant: PDCardVariant.elevated,
            padding: EdgeInsets.all(DesignTokens.spacingMd),
            radius: DesignTokens.radiusLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(
                    category.icon,
                    size: DesignTokens.iconMd,
                    color: colors.primary,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingSm),
                Text(
                  category.label,
                  style: TokenTextStyles.titleSmall(
                    color: colors.onSurface,
                    weight: DesignTokens.wSemiBold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  category.description,
                  style: TokenTextStyles.labelSmall(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const _Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class _CompactPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _CompactPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          SizedBox(width: DesignTokens.spacingXxs),
          Text(
            label,
            style: TokenTextStyles.labelSmall(
              color: accent,
              weight: DesignTokens.wBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onTap;

  const _SavedAddressCard({
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = address.isDefault ? colors.primary : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
      child: Material(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Container(
            width: 210,
            padding: EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                color: address.isDefault
                    ? colors.primary.withValues(alpha: 0.4)
                    : colors.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(DesignTokens.spacingSm),
                      decoration: BoxDecoration(
                        color: address.isDefault
                            ? colors.primaryContainer
                            : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(
                        address.isDefault ? Icons.home : Icons.work_outline,
                        size: DesignTokens.iconSm,
                        color: accent,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingSm),
                    Expanded(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TokenTextStyles.titleMedium(color: colors.onSurface),
                      ),
                    ),
                    if (address.isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(
                          'Default',
                          style: TokenTextStyles.labelSmall(
                            color: colors.primary,
                            weight: DesignTokens.wMedium,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingSm),
                Expanded(
                  child: Text(
                    address.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTripRow extends StatelessWidget {
  final RecentTrip trip;

  const _RecentTripRow({required this.trip});

  IconData get _vehicleIcon =>
      trip.vehicleType == 'Bike' ? Icons.two_wheeler : Icons.local_shipping;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: PDCard(
        variant: PDCardVariant.elevated,
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        radius: DesignTokens.radiusMd,
        onTap: () => context.go('${RouteNames.tripDetail}?id=${trip.id}'),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                _vehicleIcon,
                size: DesignTokens.iconMd,
                color: colors.primary,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TokenTextStyles.titleSmall(color: colors.onSurface),
                  ),
                  SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    trip.dropAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                  ),
                  SizedBox(height: DesignTokens.spacingXs),
                  Text(
                    '${trip.vehicleType} • ${trip.dateTime.formatDateTime()}',
                    style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: DesignTokens.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${trip.fare.toStringAsFixed(0)}',
                  style: TokenTextStyles.titleMedium(
                    color: colors.onSurface,
                    weight: DesignTokens.wBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXs),
                PDBadge(
                  label: trip.status,
                  variant: _getBadgeVariant(trip.status),
                  size: PDBadgeSize.sm,
                ),
              ],
            ),
          ],
        ),
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

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final bool isDefault;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });
}

class RecentTrip {
  final String id;
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final DateTime dateTime;
  final String vehicleType;
  final String status;

  RecentTrip({
    required this.id,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fare,
    required this.dateTime,
    required this.vehicleType,
    required this.status,
  });
}