import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/booking_remote_datasource.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSource(),
);
