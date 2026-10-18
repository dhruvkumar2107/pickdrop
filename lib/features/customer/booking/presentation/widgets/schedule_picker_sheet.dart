import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';

class SchedulePickerSheet extends StatefulWidget {
  const SchedulePickerSheet({super.key, required this.estimatedFare});

  final double estimatedFare;

  static Future<DateTime?> show(
    BuildContext context, {
    required double estimatedFare,
  }) {
    return showAppBottomSheet<DateTime>(
      context: context,
      title: 'Schedule your delivery',
      isScrollable: true,
      builder: (_) => SchedulePickerSheet(estimatedFare: estimatedFare),
    );
  }

  @override
  State<SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<SchedulePickerSheet> {
  static const int _maxDaysAhead = 7;
  static const int _slotStartHour = 8;
  static const int _slotEndHour = 21;

  DateTime _selectedDate = _dateOnly(DateTime.now());
  TimeOfDay? _selectedTime;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<DateTime> get _days => List.generate(
        _maxDaysAhead + 1,
        (i) => _dateOnly(DateTime.now()).add(Duration(days: i)),
      );

  List<TimeOfDay> get _slots => [
        for (var h = _slotStartHour; h <= _slotEndHour; h++) ...[
          TimeOfDay(hour: h, minute: 0),
          if (h < _slotEndHour) TimeOfDay(hour: h, minute: 30),
        ],
      ];

  DateTime? get _candidate {
    final time = _selectedTime;
    if (time == null) return null;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  String? get _validationError {
    final candidate = _candidate;
    final now = DateTime.now();
    if (candidate == null) return 'Pick a time slot to continue';
    if (!candidate.isAfter(now)) return 'That slot is already in the past';
    if (candidate.isAfter(now.add(const Duration(days: _maxDaysAhead)))) {
      return 'You can schedule up to 7 days ahead';
    }
    return null;
  }

  bool _isSlotDisabled(TimeOfDay slot) {
    final candidate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      slot.hour,
      slot.minute,
    );
    final now = DateTime.now();
    if (!candidate.isAfter(now.add(const Duration(minutes: 15)))) return true;
    return candidate.isAfter(now.add(const Duration(days: _maxDaysAhead)));
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final suffix = _dateOnly(DateTime.now()) == date
        ? 'Today'
        : _dateOnly(DateTime.now()).add(const Duration(days: 1)) == date
            ? 'Tomorrow'
            : weekdays[date.weekday - 1];
    return '$suffix\n${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = _validationError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick a date', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppDimensions.spacingMd),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.spacingSm),
            itemBuilder: (context, index) {
              final day = _days[index];
              final selected = day == _selectedDate;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = day;
                  _selectedTime = null;
                }),
                child: AnimatedContainer(
                  duration: AppConstants.shortAnimation,
                  width: 76,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.brandGradient : null,
                    color: selected ? null : colors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ),
                  child: Text(
                    _formatDate(day),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.35,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Text('Pick a time', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppDimensions.spacingMd),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: _slots.map((slot) {
            final disabled = _isSlotDisabled(slot);
            final selected = _selectedTime == slot;
            return GestureDetector(
              onTap: disabled
                  ? null
                  : () => setState(() => _selectedTime = slot),
              child: Opacity(
                opacity: disabled ? 0.35 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                    vertical: AppDimensions.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ),
                  child: Text(
                    _formatTime(slot),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: AppDimensions.iconSm,
                  color:
                      _selectedTime == null ? colors.onSurfaceVariant : colors.warning),
              const SizedBox(width: AppDimensions.spacingXs),
              Expanded(
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: _selectedTime == null
                          ? colors.onSurfaceVariant
                          : colors.warning),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppDimensions.spacingLg),
        GlassCard(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          borderColor: colors.success.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    '₹${widget.estimatedFare.toStringAsFixed(0)}',
                    style: AppTextStyles.priceSmall
                        .copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      size: AppDimensions.iconSm, color: colors.success),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      'Guaranteed driver assigned 30 min before your slot. No surge at the scheduled time.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors.onSurface, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        GradientButton(
          text: 'Confirm slot',
          isFullWidth: true,
          onPressed: error == null
              ? () => Navigator.of(context).pop(_candidate)
              : null,
        ),
      ],
    );
  }
}
