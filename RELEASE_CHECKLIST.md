# Release checklist

- [ ] Pin a Flutter SDK compatible with Dart 3.13.1 in CI and local setup.
- [ ] Run `flutter build apk --debug` and `flutter build appbundle --release` with owner signing configuration; release must not use debug signing.
- [ ] Run `flutter analyze`, `flutter test`, Functions build/tests, and Firebase Emulator rules tests.
- [ ] Configure Firebase project, Phone Auth, FCM, Crashlytics/Analytics/Performance, backups/budget alerts, and App Check.
- [ ] Set the server-only `GOOGLE_MAPS_SERVER_KEY` Functions secret with Routes API enabled and billing active; restrict it to Routes API. Configure/restrict the Android Maps key separately.
- [ ] Restrict Maps API keys by Android package/SHA-1 and API; configure Places billing.
- [ ] Configure Razorpay server secrets, signed webhook, capture/refund/reconciliation path; test mode first.
- [ ] Set Firebase custom claim `role=admin` for a trusted administrator using Admin SDK in a protected environment; admin review UI is `/admin/review`.
- [ ] Configure Functions secrets `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `RAZORPAYX_KEY_ID`, `RAZORPAYX_KEY_SECRET`, `RAZORPAYX_ACCOUNT_NUMBER`, and `RAZORPAYX_WEBHOOK_SECRET`. Register `razorpayPaymentWebhook` for `payment.captured` and `razorpayXPayoutWebhook` for `payout.processed`, `payout.failed`, and `payout.reversed`.
- [ ] Deploy Functions, Firestore rules/indexes, and Storage rules before enabling admin review, wallet top-ups, or driver payouts. In `/admin/review`, initialize the starter vehicle catalog, then review market pricing and tax settings before accepting bookings.
- [ ] Test wallet top-ups and payouts with provider test credentials, including webhook replay, duplicate callbacks, rejection, insufficient funds, and timeout/reconciliation cases. Confirm RazorpayX payout activation and account number with the account owner.
- [ ] Complete privacy policy, consent/retention, GST/insurance/legal review, support/SOS escalation, Play declarations and staged rollout.
