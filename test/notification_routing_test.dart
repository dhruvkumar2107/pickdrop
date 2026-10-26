import 'package:flutter_test/flutter_test.dart';
import 'package:pickdrop/config/router/route_names.dart';
import 'package:pickdrop/shared/services/notification_service.dart';

void main() {
  test('driver offers open the incoming request', () {
    expect(
      routeForNotification({'type': 'driver_offer', 'bookingId': 'b1'}),
      '${RouteNames.incomingRequest}?bookingId=b1',
    );
  });

  test('active booking updates open live tracking, finished ones the trip', () {
    expect(
      routeForNotification({'type': 'booking_update', 'bookingId': 'b1', 'status': 'PICKED_UP'}),
      '${RouteNames.liveTracking}?bookingId=b1',
    );
    expect(
      routeForNotification({'type': 'booking_update', 'bookingId': 'b1', 'status': 'DELIVERED'}),
      '${RouteNames.tripDetail}?bookingId=b1',
    );
  });

  test('SOS alerts open the recipient side of the trip', () {
    expect(
      routeForNotification({'type': 'sos_alert', 'bookingId': 'b1', 'recipientRole': 'driver'}),
      '${RouteNames.activeTrip}?bookingId=b1',
    );
    expect(
      routeForNotification({'type': 'sos_alert', 'bookingId': 'b1', 'recipientRole': 'customer'}),
      '${RouteNames.liveTracking}?bookingId=b1',
    );
  });

  test('unknown payloads do not navigate', () {
    expect(routeForNotification({}), isNull);
    expect(routeForNotification({'type': 'driver_offer'}), isNull);
  });
}
