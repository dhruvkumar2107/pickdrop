import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/common/common.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headlineSmall),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: () {},
            icon: const Icon(Icons.done_all_rounded,
                color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.only(top: AppDimensions.spacingXxl),
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No notifications',
          message: 'Booking updates and offers will show up here',
        ),
      ),
    );
  }
}
