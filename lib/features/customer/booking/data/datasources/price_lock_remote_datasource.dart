import 'package:cloud_functions/cloud_functions.dart';

import '../../../../../config/env/env_config.dart';

class PriceLockRemoteDataSource {
  const PriceLockRemoteDataSource();

  /// Reports driver asking for extra money (Anti-Extra-Cash Guarantee).
  Future<bool> reportExtraCashRequested({
    required String bookingId,
    required double extraCashAmount,
    required String reason,
  }) async {
    await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
        .httpsCallable('reportExtraCash')
        .call({
          'bookingId': bookingId,
          'extraCashAmount': extraCashAmount,
          'reason': reason,
        });
    return true;
  }
}
