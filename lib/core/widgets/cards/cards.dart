import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../buttons/buttons.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool animate;
  final Duration? animationDuration;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.animate = true,
    this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusLg),
        border: border ?? Border.all(color: AppColors.outlineVariant, width: 1),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusLg),
          child: animate
              ? card.animate().fadeIn(duration: animationDuration ?? AppConstants.mediumAnimation).slideY(
                    begin: 0.1,
                    end: 0,
                    duration: animationDuration ?? AppConstants.mediumAnimation,
                  )
              : card,
        ),
      );
    }

    return animate
        ? card.animate().fadeIn(duration: animationDuration ?? AppConstants.mediumAnimation).slideY(
              begin: 0.1,
              end: 0,
              duration: animationDuration ?? AppConstants.mediumAnimation,
            )
        : card;
  }
}

class _VehicleIcon extends StatelessWidget {
  final String path;
  final double size;
  final Color color;

  const _VehicleIcon({
    required this.path,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      color: color,
      errorBuilder: (_, _, _) => Icon(
        Icons.local_shipping,
        size: size,
        color: color,
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final String vehicleTypeId;
  final String name;
  final String iconPath;
  final int capacityKg;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final double estimatedFare;
  final int etaMinutes;
  final double distanceKm;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showPriceBreakdown;

  const VehicleCard({
    super.key,
    required this.vehicleTypeId,
    required this.name,
    required this.iconPath,
    required this.capacityKg,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.estimatedFare,
    required this.etaMinutes,
    required this.distanceKm,
    this.isSelected = false,
    this.onTap,
    this.showPriceBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Center(
                        child: _VehicleIcon(
                          path: iconPath,
                          size: 32,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Up to $capacityKg kg • ${etaMinutes}min away',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: const Icon(Icons.check, size: 16, color: AppColors.onPrimary),
                      ),
                  ],
                ),
                if (showPriceBreakdown) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceItem('Base', '₹${baseFare.toStringAsFixed(0)}'),
                      ),
                      Expanded(
                        child: _buildPriceItem('Distance', '₹${(perKmRate * distanceKm).toStringAsFixed(0)}'),
                      ),
                      Expanded(
                        child: _buildPriceItem('Time', '₹${(perMinuteRate * etaMinutes).toStringAsFixed(0)}'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Fare',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹${estimatedFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingMd,
                        vertical: AppDimensions.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        'Min ₹${minimumFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.mediumAnimation).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPriceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final bool isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final IconData? icon;

  const AddressCard({
    super.key,
    required this.label,
    required this.address,
    this.isDefault = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              icon ?? Icons.location_on_outlined,
              color: AppColors.primary,
              size: AppDimensions.iconMd,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: AppDimensions.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final String bookingId;
  final String status;
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final DateTime dateTime;
  final String vehicleType;
  final String? driverName;
  final double? rating;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.bookingId,
    required this.status,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fare,
    required this.dateTime,
    required this.vehicleType,
    this.driverName,
    this.rating,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'IN_TRANSIT':
      case 'PICKED_UP':
        return AppColors.primary;
      case 'DRIVER_ASSIGNED':
      case 'ARRIVED':
        return AppColors.info;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking #${bookingId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            _formatDate(dateTime),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.local_shipping, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickupAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    vehicleType,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (driverName != null) ...[
                    const SizedBox(width: AppDimensions.spacingMd),
                    const Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      driverName!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (rating != null) ...[
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                  ],
                  Text(
                    '₹${fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverCard extends StatelessWidget {
  final String driverId;
  final String name;
  final String? photoUrl;
  final String vehicleNumber;
  final String vehicleType;
  final double rating;
  final int totalTrips;
  final String? phoneNumber;
  final VoidCallback? onCall;
  final VoidCallback? onTap;

  const DriverCard({
    super.key,
    required this.driverId,
    required this.name,
    this.photoUrl,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.rating,
    required this.totalTrips,
    this.phoneNumber,
    this.onCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 28, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '$vehicleType • $vehicleNumber',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${rating.toStringAsFixed(1)} • $totalTrips trips',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (phoneNumber != null && onCall != null)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call, color: AppColors.primary),
              tooltip: 'Call Driver',
            ),
        ],
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  final String code;
  final String description;
  final String type; // 'percentage' or 'flat'
  final double value;
  final double? maxDiscount;
  final DateTime expiryDate;
  final bool isApplied;
  final VoidCallback? onApply;
  final VoidCallback? onRemove;

  const CouponCard({
    super.key,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.maxDiscount,
    required this.expiryDate,
    this.isApplied = false,
    this.onApply,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = DateTime.now().isAfter(expiryDate);

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      border: Border.all(
        color: isApplied ? AppColors.primary : (isExpired ? AppColors.outlineVariant : AppColors.primary.withValues(alpha: 0.3)),
        width: isApplied ? 2 : 1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: isApplied ? AppColors.primaryContainer : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  type == 'percentage' ? '${value.toInt()}%' : '₹${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isApplied ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
                Text(
                  type == 'percentage' ? 'OFF' : 'OFF',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isApplied ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: 1,
                      ),
                    ),
                    if (isExpired)
                      Container(
                        margin: const EdgeInsets.only(left: AppDimensions.spacingSm),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: const Text(
                          'EXPIRED',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid till ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (maxDiscount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Max discount: ₹${maxDiscount!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isExpired)
            isApplied
                ? TextButton(
                    onPressed: onRemove,
                    child: const Text('REMOVE'),
                  )
                : PrimaryButton(
                    text: 'APPLY',
                    onPressed: onApply,
                    isFullWidth: false,
                    height: 36,
                    borderRadius: AppDimensions.radiusFull,
                  ),
        ],
      ),
    );
  }
}