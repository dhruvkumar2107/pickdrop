import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/status_chip.dart';

class PayoutHistoryList extends StatelessWidget {
  const PayoutHistoryList({super.key, required this.stream});

  final Stream<QuerySnapshot<Map<String, dynamic>>>? stream;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = stream;
    if (history == null) return _EmptyState(colors: colors);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: history,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load payout history.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(DesignTokens.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = [...snapshot.data!.docs]..sort(_newestFirst);
        if (docs.isEmpty) return _EmptyState(colors: colors);
        return Column(
          children: [
            for (final doc in docs)
              _PayoutRow(data: doc.data()).animate().fadeIn(),
          ],
        );
      },
    );
  }

  static int _newestFirst(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final first = a.data()['createdAt'];
    final second = b.data()['createdAt'];
    if (first is Timestamp && second is Timestamp) {
      return second.compareTo(first);
    }
    return 0;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Text(
        'No payouts yet. Your first instant withdrawal can start from ₹100.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.data});

  final Map<String, dynamic> data;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(Object? value) {
    if (value is! Timestamp) return 'Requested just now';
    final date = value.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final upiId = data['upiId'];
    final status = data['status'];
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(0)} → ${upiId is String ? upiId : 'UPI'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  _formatDate(data['createdAt']),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (status is String) StatusChip.fromStatus(status, dense: true),
        ],
      ),
    );
  }
}
