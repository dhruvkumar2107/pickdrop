import 'package:flutter_test/flutter_test.dart';
import 'package:pickdrop/features/customer/booking/data/datasources/business_account_remote_datasource.dart';

void main() {
  test('GSTIN pattern accepts valid numbers and rejects malformed ones', () {
    final pattern = BusinessAccountRemoteDataSource.gstinPattern;
    expect(pattern.hasMatch('29ABCDE1234F1Z5'), isTrue);
    expect(pattern.hasMatch('29ABCDE1234F1Y5'), isFalse);
    expect(pattern.hasMatch('29abcde1234f1z5'), isFalse);
    expect(pattern.hasMatch('29ABCDE1234F1Z'), isFalse);
  });

  test('statement CSV quotes addresses and includes company header', () {
    final csv = BusinessAccountRemoteDataSource.statementCsv(
      const BusinessProfile(companyName: 'Acme', gstin: '29ABCDE1234F1Z5'),
      [
        StatementTrip(
          bookingId: 'b1',
          completedAt: DateTime(2026, 10, 3),
          pickup: '12, MG Road, "Gate 2"',
          drop: 'Whitefield',
          total: 315.5,
          gst: 15,
          paymentMethod: 'cod',
        ),
      ],
    );
    final lines = csv.trim().split('\n');
    expect(lines[0], '"Company: Acme"');
    expect(lines[1], '"GSTIN: 29ABCDE1234F1Z5"');
    expect(lines.last,
        '"2026-10-03","b1","12, MG Road, ""Gate 2""","Whitefield","cod","15.00","315.50"');
  });
}
