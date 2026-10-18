import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/dimensions.dart';

enum AppChipStatus {
  neutral,
  info,
  success,
  warning,
  error,
  active,
  upcoming,
}

/// Pill-shaped status label with optional leading dot.
class StatusChip extends StatelessWidget {
  final String label;
  final AppChipStatus status;
  final bool showDot;
  final bool dense;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const StatusChip({
    super.key,
    required this.label,
    this.status = AppChipStatus.neutral,
    this.showDot = true,
    this.dense = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Maps a raw backend status (e.g. `IN_TRANSIT`) onto a colored chip.
  factory StatusChip.fromStatus(
    String raw, {
    String? label,
    bool showDot = true,
    bool dense = false,
  }) {
    final normalized = raw.trim().toUpperCase();
    AppChipStatus status;

    switch (normalized) {
      case 'COMPLETED':
      case 'DELIVERED':
      case 'PAID':
      case 'APPROVED':
      case 'ONLINE':
        status = AppChipStatus.success;
      case 'CANCELLED':
      case 'FAILED':
      case 'REJECTED':
      case 'OFFLINE':
        status = AppChipStatus.error;
      case 'PENDING':
      case 'SEARCHING':
      case 'PROCESSING':
      case 'REFUNDED':
        status = AppChipStatus.warning;
      case 'DRIVER_ASSIGNED':
      case 'ARRIVED':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'STARTED':
      case 'ACTIVE':
        status = AppChipStatus.active;
      case 'ACCEPTED':
      case 'CONFIRMED':
      case 'SCHEDULED':
        status = AppChipStatus.upcoming;
      case 'INFO':
        status = AppChipStatus.info;
      default:
        status = AppChipStatus.neutral;
    }

    return StatusChip(
      label: label ?? raw.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
            RegExp(r'^[a-z]'),
            (m) => m.group(0)!.toUpperCase(),
          ),
      status: status,
      showDot: showDot,
      dense: dense,
    );
  }

  Color _background(BuildContext context) {
    final colors = context.colors;
    if (backgroundColor != null) return backgroundColor!;
    switch (status) {
      case AppChipStatus.success:
        return colors.successLight;
      case AppChipStatus.error:
        return colors.errorLight;
      case AppChipStatus.warning:
        return colors.warningLight;
      case AppChipStatus.info:
        return colors.infoLight;
      case AppChipStatus.active:
        return colors.primaryContainer;
      case AppChipStatus.upcoming:
        return colors.infoLight;
      case AppChipStatus.neutral:
        return colors.surfaceVariant;
    }
  }

  Color _foreground(BuildContext context) {
    final colors = context.colors;
    if (foregroundColor != null) return foregroundColor!;
    switch (status) {
      case AppChipStatus.success:
        return colors.success;
      case AppChipStatus.error:
        return colors.error;
      case AppChipStatus.warning:
        return colors.warning;
      case AppChipStatus.info:
        return colors.info;
      case AppChipStatus.active:
        return colors.primary;
      case AppChipStatus.upcoming:
        return colors.info;
      case AppChipStatus.neutral:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _background(context);
    final fg = _foreground(context);

    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: 2,
            )
          : const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: 5,
            ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: dense ? 6 : 7,
              height: dense ? 6 : 7,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
          if (showDot) const SizedBox(width: AppDimensions.spacingXs),
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: AppDimensions.spacingXs),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
