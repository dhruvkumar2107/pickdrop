import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure(this.message, {this.code, this.originalError});

  @override
  List<Object?> get props => [message, code, originalError];
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.originalError});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.originalError});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.originalError});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.originalError});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.originalError});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.originalError});
}

class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.code, super.originalError});
}

class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code, super.originalError});
}

class BookingFailure extends Failure {
  const BookingFailure(super.message, {super.code, super.originalError});
}

class DriverMatchingFailure extends Failure {
  const DriverMatchingFailure(super.message, {super.code, super.originalError});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.originalError});
}

// Specific Failure Types
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure({super.originalError})
      : super('User not found', code: 'user-not-found');
}

class InvalidPhoneNumberFailure extends AuthFailure {
  const InvalidPhoneNumberFailure({super.originalError})
      : super('Invalid phone number', code: 'invalid-phone-number');
}

class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure({super.originalError})
      : super('Invalid OTP. Please try again.', code: 'invalid-otp');
}

class OtpExpiredFailure extends AuthFailure {
  const OtpExpiredFailure({super.originalError})
      : super('OTP has expired. Please request a new one.', code: 'otp-expired');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure({super.originalError})
      : super('Too many requests. Please try again later.', code: 'too-many-requests');
}

class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure({super.originalError})
      : super('An account with this phone number already exists', code: 'user-already-exists');
}

class ProfileIncompleteFailure extends AuthFailure {
  const ProfileIncompleteFailure({super.originalError})
      : super('Please complete your profile first', code: 'profile-incomplete');
}

class DriverNotVerifiedFailure extends AuthFailure {
  const DriverNotVerifiedFailure({super.originalError})
      : super('Driver verification pending. Please wait for approval.', code: 'driver-not-verified');
}

class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure({super.originalError})
      : super('No internet connection. Please check your connection.', code: 'no-internet');
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({super.originalError})
      : super('Request timed out. Please try again.', code: 'timeout');
}

class InsufficientBalanceFailure extends PaymentFailure {
  const InsufficientBalanceFailure({super.originalError})
      : super('Insufficient wallet balance', code: 'insufficient-balance');
}

class PaymentCancelledFailure extends PaymentFailure {
  const PaymentCancelledFailure({super.originalError})
      : super('Payment was cancelled', code: 'payment-cancelled');
}

class PaymentVerificationFailure extends PaymentFailure {
  const PaymentVerificationFailure({super.originalError})
      : super('Payment verification failed', code: 'payment-verification-failed');
}

class NoDriversAvailableFailure extends DriverMatchingFailure {
  const NoDriversAvailableFailure({super.originalError})
      : super('No drivers available at the moment. Please try again later.', code: 'no-drivers-available');
}

class BookingCancelledFailure extends BookingFailure {
  const BookingCancelledFailure({super.originalError})
      : super('Booking was cancelled', code: 'booking-cancelled');
}

class BookingNotFoundFailure extends BookingFailure {
  const BookingNotFoundFailure({super.originalError})
      : super('Booking not found', code: 'booking-not-found');
}

class InvalidBookingStateFailure extends BookingFailure {
  const InvalidBookingStateFailure({super.originalError})
      : super('Invalid booking state for this action', code: 'invalid-booking-state');
}

class LocationPermissionDeniedFailure extends PermissionFailure {
  const LocationPermissionDeniedFailure({super.originalError})
      : super('Location permission is required for this feature', code: 'location-permission-denied');
}

class NotificationPermissionDeniedFailure extends PermissionFailure {
  const NotificationPermissionDeniedFailure({super.originalError})
      : super('Notification permission is required for this feature', code: 'notification-permission-denied');
}