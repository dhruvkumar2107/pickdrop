import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../../../../config/env/env_config.dart';
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
  static const double _panelTravel = 40.0;
  static const double _panelHeight = 176.0;

  GoogleMapController? _mapController;
  late final TextEditingController _searchController;
  late final AnimationController _panelController;
  LatLng _pickedPosition = _initialPosition;
  String _pickedAddress = '';
  bool _hasExplicitSelection = false;
  bool _programmaticCameraMove = false;
  bool _userMovedMap = false;
  bool _hasLocationPermission = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMoveStarted() {
    if (!_programmaticCameraMove) _userMovedMap = true;
  }

  void _onCameraMove(CameraPosition position) {
    _pickedPosition = position.target;
  }

  void _onCameraIdle() {
    if (!mounted) return;
    if (_programmaticCameraMove) {
      _userMovedMap = false;
      _programmaticCameraMove = false;
      return;
    }
    if (!_userMovedMap) return;
    _userMovedMap = false;
    setState(() {
      _hasExplicitSelection = true;
      _pickedAddress = 'Pinned location';
      _searchController.text = _pickedAddress;
    });
  }

  Future<void> _animateTo(
    LatLng target, {
    double zoom = AppConstants.defaultMapZoom,
  }) async {
    if (!mounted) return;
    final controller = _mapController;
    if (controller == null) return;
    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } finally {
      _programmaticCameraMove = false;
      _userMovedMap = false;
    }
  }

  void _selectPlace(_SuggestedPlace place) {
    final target = LatLng(place.lat, place.lng);
    setState(() {
      _pickedPosition = target;
      _pickedAddress = place.address;
      _searchController.text = place.address;
      _hasExplicitSelection = true;
    });
    unawaited(_animateTo(target, zoom: 16));
  }

  Future<void> _openSearchSheet() async {
    final selected = await showAppBottomSheet<_SuggestedPlace>(
      context: context,
      title: AppStrings.searchLocation,
      builder: (_) => _PlaceSearchSheet(center: _pickedPosition),
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
      if (!_hasLocationPermission) {
        setState(() => _hasLocationPermission = true);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedPosition = target;
        _pickedAddress = 'Current location';
        _hasExplicitSelection = true;
        _searchController.text = _pickedAddress;
      });
      unawaited(_animateTo(target, zoom: 16));
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
    if (!_hasExplicitSelection || _pickedAddress.trim().isEmpty) {
      AppToast.info(
        context,
        'Search for a place, move the pin, or use your current location.',
      );
      return;
    }
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
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: _hasLocationPermission,
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

class _SuggestedPlace {
  final String placeId;
  final String title;
  final String address;
  final double lat;
  final double lng;

  const _SuggestedPlace({
    required this.placeId,
    required this.title,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class _PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  const _PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.center});

  final LatLng center;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  final String _sessionToken = const Uuid().v4();
  final List<_PlacePrediction> _predictions = [];
  Timer? _debounce;
  bool _loading = false;
  bool _loadingDetails = false;
  String? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final requestId = ++_requestId;
    if (query.length < 3) {
      setState(() {
        _predictions.clear();
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _predictions.clear();
    });
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query, requestId);
    });
  }

  Future<void> _search(String query, int requestId) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
              .httpsCallable('searchPlaces')
              .call({
                'query': query,
                'sessionToken': _sessionToken,
                'center': {
                  'lat': widget.center.latitude,
                  'lng': widget.center.longitude,
                },
              });
      final data = Map<String, dynamic>.from(result.data as Map);
      final suggestions = (data['suggestions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => _PlacePrediction(
              placeId: item['placeId'] as String,
              mainText: item['mainText'] as String? ?? '',
              secondaryText: item['secondaryText'] as String? ?? '',
              description: item['description'] as String? ?? '',
            ),
          )
          .toList(growable: false);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _predictions
          ..clear()
          ..addAll(suggestions);
        _loading = false;
      });
    } on FirebaseFunctionsException catch (exception) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = exception.code == 'failed-precondition'
            ? 'Place search is not configured yet. You can still move the map pin.'
            : 'Place search is unavailable. Check your connection and try again.';
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error =
            'Place search is unavailable. Check your connection and try again.';
      });
    }
  }

  Future<void> _selectPrediction(_PlacePrediction prediction) async {
    setState(() {
      _loadingDetails = true;
      _error = null;
    });
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
              .httpsCallable('getPlaceDetails')
              .call({
                'placeId': prediction.placeId,
                'sessionToken': _sessionToken,
              });
      final data = Map<String, dynamic>.from(result.data as Map);
      final place = _SuggestedPlace(
        placeId: data['placeId'] as String? ?? prediction.placeId,
        title: prediction.mainText.isEmpty
            ? prediction.description
            : prediction.mainText,
        address: data['address'] as String,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
      );
      if (mounted) Navigator.of(context).pop(place);
    } on FirebaseFunctionsException catch (exception) {
      if (mounted) {
        setState(() {
          _loadingDetails = false;
          _error =
              exception.message ??
              'Could not load this place. Choose another result.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingDetails = false;
          _error = 'Could not load this place. Choose another result.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final usableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom)
            .clamp(240.0, 720.0)
            .toDouble();
    final listHeight = usableHeight * 0.42;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _queryController,
          autofocus: true,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Search an address or place',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        SizedBox(
          height: listHeight,
          child: _loadingDetails
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _predictions.isEmpty
              ? Center(
                  child: Text(
                    _queryController.text.trim().length < 3
                        ? 'Type at least 3 characters to search.'
                        : 'No matching places found.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        prediction.mainText.isEmpty
                            ? prediction.description
                            : prediction.mainText,
                      ),
                      subtitle: prediction.secondaryText.isEmpty
                          ? null
                          : Text(prediction.secondaryText),
                      onTap: _loadingDetails
                          ? null
                          : () => _selectPrediction(prediction),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_google.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              'Powered by Google',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
