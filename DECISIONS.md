# Decisions

## 2026-10-18 — Fail closed, not demo-success
Firebase placeholder values and broad bootstrap catches were removed. Real Firebase Phone Auth is the default. Release builds fail if owner signing config is absent. App must be honest about bootstrap failures.

## 2026-10-18 — Server owns money and booking state
Booking/payment client writes are denied. Razorpay order amount derived from authoritative booking fare; `verifyPayment` verifies capture against Razorpay API. **Decision updated 2026-10-19:** No webhook yet — client-triggered API-verified capture is acceptable only for this iteration; payout movement must never auto-complete.

## 2026-10-18 — Bengaluru pilot boundary
Start intra-city small-goods, 2W/3W/mini-trucks; measured supply coverage. GST, transport, insurance, worker classification, KYC/privacy need qualified Indian legal/tax review.

## 2026-10-18 — App Check
Enable in monitor, then enforce Firestore/Storage/callables once legitimate traffic verified.

## 2026-10-18 — CI/toolchain and rules boundary
CI pinned to Flutter 3.47.1 (matching local). Release signing fails closed. Default-deny for operational/financial collections.

## 2026-10-19 — Simplified platform decisions
- Standardize env bootstrap on `.env` (not `.env.client`).
- Strip non-CloudFunction exports from `index.ts` (deploy blocker).
- FCM channel id must match manifest default and client-created channel (no silently dropped notifications).
- Driver onboarding: use real Storage upload + `createDriverProfile` callable-wired path; rules require strict keys + `isVerified=false, rating=0, totalTrips=0`.
- Ratings: persist via `ratings` (server-owned later); at least client call or direct create if permitted — allow create for participant flow; will guard with server-side callable after.
- Web tracking page: participant-only read means public share links will 404/deny; acceptable now (server can expose a signed public read if needed).
- `PHONE_AUTH_MODE=any` in `.env` is dead; remove or sync with env config.
- No auto-PAID for payouts: `settlePayouts` must never mark payouts complete without payout provider success.

## 2026-10-19 — Data model & UI constraints
- `DriverModel.rating` defaults to 5.0 in fromJson — onboarding callers must write 0 on create; do not rely on default.
- Trips history: replace mocks with Firestore queries filtered to `customerId/driverId`.
- Vehicle selection must read `vehicleTypes` (server-pricing source of truth).
- Avoid shipping `hi` locale if `strings_hi.dart` absent; either remove `hi` from supported locales or add strings file.
- Driver payout read restricted to owner; write only via `requestPayout` callable.


## 2026-10-19 - English-only UI for now
The `hi`/`kn` locales were non-functional and the Kannada strings file was corrupted (mixed Korean/garbled text). Shipped English-only: removed the corrupted strings file, trimmed supported locales to `en`, and the language page shows one option plus a coming-soon note. Re-add languages only with complete, reviewed translations.

## 2026-10-19 - Webhook reconciles booking payments
`razorpayPaymentWebhook` now settles booking payments (idempotent `settleBookingPayment`) as well as wallet top-ups, so a closed app still settles. Payouts still never auto-complete.

## 2026-10-19 - Account deletion
`deleteAccount` callable refuses while an active trip, pending payout, or processing top-up exists; deletes personal docs, anonymizes the users doc, and deletes the Auth user. Financial records are retained for accounting.