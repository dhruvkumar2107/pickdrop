import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/common/common.dart';
import '../../../../../core/widgets/status_chip.dart';

class DriverTripHistoryPage extends StatefulWidget {
  const DriverTripHistoryPage({super.key});

  @override
  State<DriverTripHistoryPage> createState() => _DriverTripHistoryPageState();
}

class _DriverTripHistoryPageState extends State<DriverTripHistoryPage> {
  static const List<String> _filters = ['All', 'Today', 'This Week'];
  int _selectedFilter = 0;

  static final List<_HistoryTrip> _trips = [
    _HistoryTrip(
      id: 'PD1004',
      customer: 'Ananya Rao',
      pickup: '55 Electronic City Phase 1',
      drop: '9 HSR Layout Sector 2',
      fare: 520,
      commission: 78,
      dateTime: DateTime(2026, 10, 6, 11, 45),
      status: 'DELIVERED',
    ),
    _HistoryTrip(
      id: 'PD1007',
      customer: 'Karthik Iyer',
      pickup: '12 Jayanagar 4th Block',
      drop: '88 BTM Layout 2nd Stage',
      fare: 199,
      commission: 30,
      dateTime: DateTime(2026, 10, 6, 9, 15),
      status: 'DELIVERED',
    ),
    _HistoryTrip(
      id: 'PD1008',
      customer: 'Priya Nair',
      pickup: '789 Indiranagar',
      drop: '321 Whitefield',
      fare: 450,
      commission: 68,
      dateTime: DateTime(2026, 10, 5, 18, 30),
      status: 'DELIVERED',
    ),
    _HistoryTrip(
      id: 'PD1009',
      customer: 'Rohit Sharma',
      pickup: '15 Yeshwanthpur',
      drop: '63 Hebbal Flyover',
      fare: 275,
      commission: 0,
      dateTime: DateTime(2026, 10, 5, 10, 0),
      status: 'CANCELLED',
    ),
  ];

  String _formatDate(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _trips.where((t) => t.status != 'CANCELLED').toList();
    final totalEarned =
        completed.fold<double>(0, (sum, t) => sum + (t.fare - t.commission));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Trip History', style: AppTextStyles.headlineSmall),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(AppDimensions.spacingXl),
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Earned',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white70),
                      ),
                      Text(
                        '₹${totalEarned.toStringAsFixed(0)}',
                        style: AppTextStyles.priceLarge
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${completed.length} trips',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white70),
                    ),
                    Text(
                      '${_trips.length} total',
                      style: AppTextStyles.titleSmall
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXl),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = _selectedFilter == i;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacingSm),
                  child: ChoiceChip(
                    label: Text(_filters[i]),
                    selected: selected,
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: AppTextStyles.labelLarge.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = i),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Expanded(
            child: _trips.isEmpty
                ? const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No trips yet',
                    message: 'Your completed deliveries will appear here',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.spacingXl),
                    itemCount: _trips.length,
                    itemBuilder: (_, i) {
                      final t = _trips[i];
                      final net = t.fare - t.commission;
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(t.customer,
                                      style: AppTextStyles.titleSmall),
                                ),
                                StatusChip.fromStatus(t.status, dense: true),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingXs),
                            Text(
                              '${t.pickup}  →  ${t.drop}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimensions.spacingSm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDate(t.dateTime),
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.onSurfaceVariant)),
                                Text(
                                  t.status == 'CANCELLED'
                                      ? '₹0'
                                      : '₹${net.toStringAsFixed(0)}',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: t.status == 'CANCELLED'
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate(delay: Duration(milliseconds: i * 70))
                          .fadeIn()
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTrip {
  final String id;
  final String customer;
  final String pickup;
  final String drop;
  final double fare;
  final double commission;
  final DateTime dateTime;
  final String status;

  const _HistoryTrip({
    required this.id,
    required this.customer,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.commission,
    required this.dateTime,
    required this.status,
  });
}
