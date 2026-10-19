import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/gradient_button.dart';

/// Legacy route. Payment orders are created only from a server-priced booking.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: colors.primary),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                'Payments are started from a confirmed booking so the server can verify the fare.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GradientButton(
                text: 'Return to booking',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.customerHome);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
