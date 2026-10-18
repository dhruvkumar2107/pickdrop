import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'extensions.dart';

class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? otp(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != length) {
      return 'Enter a valid $length-digit OTP';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  static String? name(String? value, {int minLength = 2, int maxLength = 50}) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return 'Name must be less than $maxLength characters';
    }
    if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(trimmed)) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  static String? vehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    final cleaned = value.toUpperCase().replaceAll(' ', '');
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$').hasMatch(cleaned)) {
      return 'Enter a valid vehicle number (e.g., MH12AB1234)';
    }
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    // Indian driving license format varies by state, basic validation
    if (value.length < 5 || value.length > 20) {
      return 'Enter a valid license number';
    }
    return null;
  }

  static String? aadhaarNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 12) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Aadhaar must contain only numbers';
    }
    // Verhoeff algorithm validation could be added here
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    if (value.length != 6) {
      return 'Enter a valid 6-digit pincode';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Pincode must contain only numbers';
    }
    return null;
  }

  static String? address(String? value, {int minLength = 10, int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Address is too short (minimum $minLength characters)';
    }
    if (trimmed.length > maxLength) {
      return 'Address is too long (maximum $maxLength characters)';
    }
    return null;
  }

  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (min != null && amount < min) {
      return 'Amount must be at least ${min.currencyINR}';
    }
    if (max != null && amount > max) {
      return 'Amount must not exceed ${max.currencyINR}';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (!Uri.tryParse(value)!.hasAbsolutePath) {
      return 'Enter a valid URL';
    }
    return null;
  }

  static String? age(String? value, {int minAge = 18, int maxAge = 100}) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Enter a valid age';
    }
    if (age < minAge) {
      return 'Minimum age is $minAge';
    }
    if (age > maxAge) {
      return 'Maximum age is $maxAge';
    }
    return null;
  }

  static String? dateOfBirth(String? value, {int minAge = 18}) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      final age = now.year - date.year -
          (now.month > date.month || (now.month == date.month && now.day >= date.day) ? 0 : 1);
      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }
      if (date.isAfter(now)) {
        return 'Date cannot be in the future';
      }
    } catch (e) {
      return 'Enter a valid date (YYYY-MM-DD)';
    }
    return null;
  }

  static String? gstNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    // GST format: 22AAAAA0000A1Z5
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(value)) {
      return 'Enter a valid GST number';
    }
    return null;
  }

  static String? panNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Enter a valid PAN number';
    }
    return null;
  }

  static FormFieldValidator<String> compose(List<FormFieldValidator<String>> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

class InputFormatters {
  static List<TextInputFormatter> get phone => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];

  static List<TextInputFormatter> get otp => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ];

  static List<TextInputFormatter> get aadhaar => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ];

  static List<TextInputFormatter> get pincode => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ];

  static List<TextInputFormatter> get amount => [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ];

  static List<TextInputFormatter> get positiveInteger => [
        FilteringTextInputFormatter.digitsOnly,
      ];

  static List<TextInputFormatter> get alphanumeric => [
        FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]*$')),
      ];

  static List<TextInputFormatter> get name => [
        FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z\s\.\-]*$')),
      ];

  static List<TextInputFormatter> vehicleNumber() => [
        FilteringTextInputFormatter.allow(RegExp(r'^[A-Z0-9]*$')),
        LengthLimitingTextInputFormatter(12),
        _VehicleNumberFormatter(),
      ];

  static List<TextInputFormatter> maxLength(int length) => [
        LengthLimitingTextInputFormatter(length),
      ];
}

class _VehicleNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase().replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}