import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../../../../core/widgets/loaders/loaders.dart';

/// Result returned to the caller once the user confirms a location.
typedef MapPickerResult = ({double lat, double lng, String address});

/// Full-screen map with a fixed center pin, glass search bar and a
/// draggable glass panel used to confirm the picked location.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with SingleTickerProviderStateMixin {
  static const LatLng _initialPosition = LatLng(12.9716, 77.5946);
  static const String _initialAddress = 'MG Road, Bengaluru, Karnataka';
  static const double _panelTravel = 40.0;
  static const double _panelHeight = 176.0;

  static const List<_SuggestedPlace> _suggestedPlaces = [
    _SuggestedPlace(
      title: 'MG Road',
      address: 'MG Road, Bengaluru, Karnataka',
      lat: 12.9756,
      lng: 77.6068,
    ),
    _SuggestedPlace(
      title: 'Indiranagar',
      address: '100 Feet Road, Indiranagar, Bengaluru',
      lat: 12.9719,
      lng: 77.6412,
    ),
    _SuggestedPlace(
      title: 'Koramangala',
      address: '5th Block, Koramangala, Bengaluru',
      lat: 12.9352,
      lng: 77.6245,
    ),
    _SuggestedPlace(
      title: 'Whitefield',
      address: 'ITPL Main Road, Whitefield, Bengaluru',
      lat: 12.9698,
      lng: 77.75,
    ),
    _SuggestedPlace(
      title: 'City Railway Station',
      address: 'Bengaluru City Junction, Bengaluru',
      lat: 12.9767,
      lng: 77.5713,
    ),
    _SuggestedPlace(
      title: 'Cubbon Park',
      address: 'Kasturba Road, Bengaluru, Karnataka',
      lat: 12.9763,
      lng: 77.5929,
    ),
  ];

  GoogleMapController? _mapController;
  late final TextEditingController _searchController;
  late final AnimationController _panelController;
  LatLng _pickedPosition = _initialPosition;
  String _pickedAddress = _initialAddress;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _initialAddress);
    _panelController = AnimationController(
      vsync: this,
      duration: AppConstants.shortAnimation,
      reverseDuration: AppConstants.instantAnimation,
      value: 1,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Lightweight reverse geocode against the mock place list.
  static String _addressFor(LatLng position) {
    _SuggestedPlace? closest;
    var bestDistance = double.infinity;
    for (final place in _suggestedPlaces) {
      final delta =
          (place.lat - position.latitude).abs() +
          (place.lng - position.longitude).abs();
      if (delta < bestDistance) {
        bestDistance = delta;
        closest = place;
      }
    }
    if (closest != null && bestDistance < 0.03) return closest.address;
    return 'Pinned near ${position.latitude.toStringAsFixed(4)}, '
        '${position.longitude.toStringAsFixed(4)}';
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _pickedPosition = position.target;
  }

  void _onCameraIdle() {
    if (!mounted) return;
    final address = _addressFor(_pickedPosition);
    setState(() {
      _pickedAddress = address;
      _searchController.text = address;
    });
  }

  void _animateTo(LatLng target, {double zoom = AppConstants.defaultMapZoom}) {
    if (!mounted) return;
    final controller = _mapController;
    if (controller == null) return;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _selectPlace(_SuggestedPlace place) {
    final target = LatLng(place.lat, place.lng);
    setState(() {
      _pickedPosition = target;
      _pickedAddress = place.address;
      _searchController.text = place.address;
    });
    _animateTo(target, zoom: 16);
  }

  Future<void> _openSearchSheet() async {
    final selected = await showAppBottomSheet<_SuggestedPlace>(
      context: context,
      title: AppStrings.searchLocation,
      isScrollable: true,
      builder: (sheetContext) => ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _suggestedPlaces.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppDimensions.spacingXs),
        itemBuilder: (context, index) {
          final place = _suggestedPlaces[index];
          return _PlaceTile(
            place: place,
            onTap: () => Navigator.of(context).maybePop(place),
          );
        },
      ),
    );
    if (selected == null || !mounted) return;
    _selectPlace(selected);
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        AppToast.info(context, AppStrings.enableLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedPosition = target;
        _pickedAddress = _addressFor(target);
        _searchController.text = _pickedAddress;
      });
      _animateTo(target, zoom: 16);
    } catch (_) {
      if (!mounted) return;
      AppToast.info(context, AppStrings.enableLocation);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onPanelDragUpdate(DragUpdateDetails details) {
    final next = _panelController.value - details.delta.dy / _panelTravel;
    _panelController.value = next.clamp(0.0, 1.0).toDouble();
  }

  void _onPanelDragEnd(DragEndDetails details) {
    if (_panelController.value > 0.5) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  void _confirmLocation() {
    if (!mounted) return;
    final MapPickerResult result = (
      lat: _pickedPosition.latitude,
      lng: _pickedPosition.longitude,
      address: _pickedAddress,
    );
    if (context.canPop()) {
      context.pop(result);
    }
  }

  void _goBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: AppConstants.defaultMapZoom,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          Positioned.fill(child: IgnorePointer(child: _CenterPin())),

          SafeArea(
            child:
                Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.spacingLg,
                        AppDimensions.spacingMd,
                        AppDimensions.spacingLg,
                        0,
                      ),
                      child: Row(
                        children: [
                          GlassCard(
                            padding: const EdgeInsets.all(
                              AppDimensions.spacingXs,
                            ),
                            showShadow: true,
                            child: IconButton(
                              onPressed: _goBack,
                              tooltip: AppStrings.back,
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: AppDimensions.iconSm,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingSm),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingSm,
                                vertical: AppDimensions.spacingXs,
                              ),
                              showShadow: true,
                              child: SearchField(
                                controller: _searchController,
                                readOnly: true,
                                hint: AppStrings.searchLocation,
                                onTap: _openSearchSheet,
                                leadingIcon: Icon(
                                  Icons.search_rounded,
                                  size: AppDimensions.iconMd,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: AppConstants.mediumAnimation)
                    .slideY(begin: -0.4, end: 0),
          ),

          Positioned(
            right: AppDimensions.spacingLg,
            bottom:
                bottomInset +
                AppDimensions.spacingLg +
                _panelHeight +
                AppDimensions.spacingMd,
            child: _buildCurrentLocationFab(),
          ),

          Positioned(
            left: AppDimensions.spacingLg,
            right: AppDimensions.spacingLg,
            bottom: bottomInset + AppDimensions.spacingLg,
            child: AnimatedBuilder(
              animation: _panelController,
              builder: (context, child) {
                final progress = _panelController.value;
                return Transform.translate(
                  offset: Offset(0, (1 - progress) * _panelTravel),
                  child: Opacity(opacity: 0.6 + 0.4 * progress, child: child),
                );
              },
              child: GlassCard(
                radius: AppDimensions.radiusXl,
                showShadow: true,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingLg,
                  AppDimensions.spacingSm,
                  AppDimensions.spacingLg,
                  AppDimensions.spacingLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _onPanelDragUpdate,
                      onVerticalDragEnd: _onPanelDragEnd,
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outline,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppDimensions.radiusFull),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(
                            AppDimensions.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppDimensions.radiusMd),
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: AppDimensions.iconMd,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected location',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingXxs),
                              Text(
                                _pickedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingXxs),
                              Text(
                                '${_pickedPosition.latitude.toStringAsFixed(5)}, '
                                '${_pickedPosition.longitude.toStringAsFixed(5)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    GradientButton(
                      text: 'Confirm location',
                      trailingIcon: Icons.check_rounded,
                      onPressed: _confirmLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationFab() {
    final colors = context.colors;

    return Material(
          color: colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isLocating ? null : _goToCurrentLocation,
            child: Ink(
              width: AppDimensions.minTouchTarget + 4,
              height: AppDimensions.minTouchTarget + 4,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isLocating
                  ? const AppLoader(
                      size: AppDimensions.iconSm,
                      color: Colors.white,
                      strokeWidth: 2.5,
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      size: AppDimensions.iconMd,
                      color: Colors.white,
                    ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.mediumAnimation)
        .slideX(begin: 0.5, end: 0, curve: AppConstants.sharpCurve);
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: AppDimensions.iconMd,
                  color: Colors.white,
                ),
              )
              .animate()
              .fadeIn(duration: AppConstants.mediumAnimation)
              .slideY(
                begin: -1.8,
                end: 0,
                duration: AppConstants.dramaticAnimation,
                curve: AppConstants.bounceCurve,
              ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Container(
            width: 22,
            height: 6,
            decoration: BoxDecoration(
              color: colors.shadow.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.radiusFull),
              ),
            ),
          ).animate().fadeIn(
            delay: 200.ms,
            duration: AppConstants.mediumAnimation,
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final _SuggestedPlace place;
  final VoidCallback onTap;

  const _PlaceTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXs,
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppDimensions.radiusSm),
                  ),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: AppDimensions.iconSm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxs),
                    Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Icon(
                Icons.north_east_rounded,
                size: AppDimensions.iconSm,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedPlace {
  final String title;
  final String address;
  final double lat;
  final double lng;

  const _SuggestedPlace({
    required this.title,
    required this.address,
    required this.lat,
    required this.lng,
  });
}
