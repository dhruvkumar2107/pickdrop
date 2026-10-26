# Progress
## Session - 2026-10-27 (continuation: honesty + reliability pass)
- Customers could never see the driver's name or call them: live tracking read `users/{driverId}`, which rules deny. Matching now copies `driverName`/`driverPhone` onto the participant-only booking at assignment; tracking reads them plus the driver's real rating/trip count (removed hardcoded "4.9 / 2,184 trips / PRO").
- Removed fabricated home hero stats ("2.4M+ deliveries / 50K+ drivers / 4.9") in favour of product facts.
- Business account rebuilt: it was pre-filled with a fake company/team, wrote to a collection with no rule (every save failed), billed a hardcoded Rs 18,450 invoice on a non-existent domain, and queued CSV bulk orders nothing processed. Now: validated GST profile (new `businessAccounts` rule + rules test) and a real monthly statement of delivered trips exported as CSV.
- Transit insurance (Rs 29, "cover up to Rs 50,000", "cashless in 24h") had no insurer behind it. Gated behind `config/app.transitInsuranceEnabled` (default false); server rejects the add-on and the app hides the card until a licensed partner exists.
- Removed the non-existent PICK50 coupon hint; removed unbacked "reply in 5 min" / "driver guaranteed" promises. Callback requests now create `CALLBACK` support tickets with the verified phone number for admins.
- Wallet referral shared a code derived from a hardcoded phone number (never registered, so friends' codes failed); it now uses the server-issued code via `ReferralBanner`.
- Trip-complete receipt showed invented numbers for every trip (distance Rs 128, time Rs 46, surge Rs 30, booking PD-2481, driver "Rahul Sharma", vehicle "TVS Jupiter KA 01 HB 2456"); it now renders the booking's real fareBreakdown, driver name and vehicle (matching copies `driverVehicle` onto the booking).
- Loading help listed four invented "verified helpers" with fake ratings/jobs; nobody was ever assigned. It is now "driver loads/unloads" at the same prices (the fee already reaches the driver via settlement), and the driver's active trip shows when paid loading help was booked.
- Live tracking no longer falls back to "123 MG Road"/"456 Koramangala"; it uses the booking's addresses.
- Gates: `flutter analyze` clean, `flutter test` 13/13, Functions build + 20/20, `flutter build apk --debug` passes (manifest merge verified).
- Driver background location: the background isolate never initialised Firebase (all background writes failed) and the manifest lacked the Android 14 `location` foreground-service type. Both fixed; background interval 5s -> 15s.
## Session - 2026-10-27 (launch-readiness pass)
- Customer push + in-app inbox: new `notifyBookingStatus` trigger writes `notifications` and sends FCM on assigned/picked-up/delivered/cancelled/no-driver; drivers hear when a customer cancels an assigned trip. Notifications page now streams the inbox with mark-read.
- Fixed notification tap routing (every tap went to the driver incoming-request screen); `routeForNotification` routes by type/status/recipient role.
- Driver active trip: real pickup/drop/stop addresses from the booking (removed hardcoded MG Road/Whitefield), Google Maps navigation hand-off, chat-with-customer button (was a no-op call), required goods photo at pickup and final drop uploaded to `bookingProofs/{bookingId}/` and verified server-side in the OTP callables.
- Customer "proof of delivery" sheet no longer simulates capture; it shows the driver's real photos.
- Priority support sheet no longer fakes an agent reply/callback; it creates tickets via `createSupportTicket`, lists replies, and admins answer via `respondToSupportTicket` (lands in the customer inbox). Client writes to `supportTickets` are now denied.
- Live-tracking SOS now records a `createSosAlert` incident (with last known location) before dialling 112.
- Voice search returns on the final result instead of always blocking 16s.
- Terms/Privacy open hosted `web/legal/*.html` (placeholders for legal entity, grievance officer, liability terms must be filled and legally reviewed). Driver notification settings open system settings.
- Gates: `flutter analyze` clean, `flutter test` 11/11, Functions build + 20/20 tests. Added 2 rules tests; not run locally (firebase-tools needs Java 21, machine has 17) - CI runs them.
## Session - 2026-10-19 (driver profile + docs)
- Rewrote `driver_profile_page.dart` from fabricated demo data (fake name/phone/vehicle/trips/documents) to real reads from `users` + `drivers` + `driverPrivate`: live name, phone, vehicle model/number/type, verification status, rating, total trips, earnings, and masked licence/RC with expiry. Driver logout now signs out of Firebase, Edit updates `displayName`, Language routes to the language page, and unverified/rejected drivers can reopen onboarding.
- Language page copy now states English-only (matches DECISIONS.md); removed the "coming soon" language tile on the driver profile.
- Refreshed stale `AUDIT.md` rows (emulators now switch SDKs, CI runs functions+rules jobs, rules are emulator-tested, 35 tests total) and the remaining-work bullets.
- Gates: `flutter analyze` clean on changed files.

## Session - 2026-10-19 (latest continuation)
- Real trip history (`my_trips` streams bookings) and trip detail (`tripDetail?bookingId=`) rebuilt on Firestore; router passes bookingId/driverId; trip-complete rating persists to `ratings`. Committed `22468b9`.
- Verified stale claims against disk: saved addresses, safety contacts, driver payouts, wallet, chat, multi-stop server support, referral rewards, admin review page, and Razorpay/RazorpayX webhooks were already implemented in prior sessions.
- Added `deleteAccount` callable (blocks on active trip/pending payout/processing top-up; deletes PII docs, anonymizes `users`, deletes Auth user) + Delete Account tile in customer profile. Exported via `index.ts`.
- Razorpay payment webhook now reconciles booking payments (idempotent `settleBookingPayment`) in addition to wallet top-ups, so a closed app still settles.
- Fixed a real matching bug: `geohashNeighbors` offset by half a cell (stayed in the same cell) - now offsets a full cell and de-dupes; adjacent-cell drivers are actually found.
- Added Functions tests (`node:test`): fare, OTP, geohash, commission - 15 tests, all passing via `npm --prefix functions test`.
- Wired Firebase Emulator Suite behind `USE_FIREBASE_EMULATORS` + `EMULATOR_HOST` (auth 9099, firestore 8080, functions 5001).
- Localization: `hi`/`kn` were non-functional and the Kannada strings file was corrupted (mixed Korean/garbled text). Shipped English-only. See DECISIONS.md.
- Gates green at latest commit: `flutter analyze` 0 errors / 0 warnings (48 info lints), `flutter test` 7/7, `npm --prefix functions run build` pass, `npm --prefix functions test` 15/15.

### Still blocked (owner-supplied)
Firebase console/App Check, Google Maps & Routes keys, Razorpay/RazorpayX keys + webhook secrets, Play Console + upload keystore, admin custom-claim bootstrap, live deployment + rules/indexes.

## Current continuation — 2026-10-19
- Added immediate, owner-only revocation of previously shared tracking links; revocation removes the active token and the sharing sheet closes after success.
- Tightened driver KYC server checks: uploaded documents must use the caller's expected Firebase Storage object paths, and the chosen vehicle must remain active in the catalog. Functions TypeScript build passes after these backend changes.
- The Android rebuild caught a missing closing brace in the live trip stream error handler. Fixed it; the build is running again against the corrected current tree.
- Rewired extra-cash complaints to the authenticated backend callable, validated ownership/state/amount, and exposed pending cases to admins for resolve/dismiss review. The UI now correctly states that no automatic refund occurs.
- Removed local-only safety switches that claimed to send live alerts; now explains the actual SOS/contact behavior. Replaced hardcoded pickup/drop saved addresses and customer profile demo stats with Firebase data; logout now signs out of Firebase.
- Verification: Functions TypeScript build passed; Android debug APK built successfully; existing Flutter tests passed 7/7; Firestore indexes JSON parses and `git diff --check` passes. Sandbox payments/payouts and Firebase rules/emulator validation remain outstanding.
- Hardened release CI configuration so it generates required client `.env` and Android Maps resources from GitHub Actions secrets and stops on missing configuration. Documented the required secrets. Local inspection confirms the active `.env` lacks Maps/Razorpay client values and provider server secrets; an ignored client file has a test-formatted key ID but is not loaded by the app.

## Current resume update — 2026-10-19
- Fixed public live tracking links end-to-end: customer share actions create/reuse a private 256-bit token URL, public access is callable-scoped, and links expire after 24 hours and stop working when a trip ends. The public page displays intermediate stops and limited driver/location info without exposing customer records or OTPs.
- Corrected stale feature audit entries that described completed history, notification, or tracking work as mock/broken. Remaining launch gates and feature gaps are listed in `AUDIT.md` and `OPERATIONS.md`.
- Latest `functions` TypeScript build and Android debug APK build passed before the final tracking refinements. Rebuilding after those refinements now; admin UID, fresh Firebase authentication, provider/Maps credentials and live deployment remain unavailable/pending.

## Latest follow-up — 2026-10-19
- Added `/admin/review` for custom-claim admins to review KYC and reserved driver payouts; RazorpayX payout transfer and signed payout webhook reconciliation are implemented.
- Added Razorpay wallet top-ups with server-created orders, server verification/capture, signed webhook credit, Firestore-backed balance/history, and atomic wallet payment for bookings.
- Switched vehicle selection to the Firestore catalog, added admin-only starter catalog initialization, and use Google Routes server-side distance/time for authoritative quotes.
- Replaced driver earning/history samples and trip-detail sample data with Firestore ledger/booking data.
- Implemented up to five pinned multi-stops with server route pricing, separate customer-only OTP storage, sequential stop verification, and final delivery guard.
- Latest checks: Functions TypeScript build, Android debug APK build, targeted Dart analysis, `git diff --check`, and Firestore index JSON parse passed. Emulator/security tests and live provider tests remain pending.
- Launch still needs Firebase deployment and rules/indexes, Firebase Admin custom claim bootstrap, Google Routes/Razorpay/RazorpayX secrets and webhooks, live price review, provider testing, and rejected-KYC resubmission flow.

## Resume update — 2026-10-19
- Added server-generated fare quotes to booking details and a server-side expected-total check that blocks stale/tampered fare confirmation.
- Connected saved-address create/list/delete to authenticated Firestore records (removed sample addresses and fake add sheet).
- Made trip ratings callable-backed, restricted them to the customer on a delivered booking, prevented duplicates, and updated driver averages transactionally.
- Verified Functions `tsc` build, debug APK build, and `git diff --check`. Full `flutter analyze` stalled without returning diagnostics; Firebase emulators/tests were not run.
- Closed money-integrity gaps: removed auto-PAID payout scheduler, disabled fabricated wallet credits/mock checkout, and made payout requests callable-backed and explicitly pending review.
- Connected driver FCM notifications/token persistence/tap routing and aligned the Android notification channel.
- Replaced fake KYC submit with real Storage uploads and profile creation; isolated KYC records in `driverPrivate` so customers cannot read them.
- Replaced fake customer trip history and driver home earnings/recent trips with Firestore-backed data; stale sample home addresses/trips removed.
- Removed plain utility exports from Functions index for deploy discovery.
- Verified: Flutter analyze clean, Functions TypeScript build passes, debug APK builds, Firestore index JSON parses, and diff whitespace check passes. Flutter/Firebase emulator tests not run.
- Remaining production gates: Firebase config/deployment, Maps/Razorpay credentials, server/admin KYC approval, real payout transfer integration, wallet top-up ledger, emulator/security tests, and remaining demo-only screens/features (vehicle picker, driver earnings/history and some customer home widgets).

## Done
- **Phase 1 audit (rewritten):** AUDIT.md rebuilt from direct disk verification — feature table (Done/Partial/Missing/Broken), 15 top bugs with file:line, P0/P1/P2 priorities.
- **Baseline verification:** `flutter pub get` / `flutter analyze` (1 warning) / `flutter test` (7 pass) / `npm --prefix functions run build` (pass) / `flutter build apk --debug` (pass — APK produced).
- **Functions build clean:** prior-session TS errors (`matching.ts` null-safe pickup coords, `trust.ts` `getConfig` import) confirmed fixed; clean `tsc` passes.
- Prior-session (now committed as baseline): server-owned booking/payment state; callables for create/schedule/cancel/offer/OTP/pay; API-verified Razorpay capture; geohash matching with GPS validation; transactional ledger with commission-free first 20 trips; strict default-deny Firestore rules; fail-closed release signing; driver online toggle + location broadcast; incoming-request page on real `driverOffers`; OTP-gated active trip.

## In progress (this session's P0s)
- `.env` bootstrap fix (main.dart/pubspec `.env.client` → `.env`).
- Strip non-CloudFunction exports from `functions/src/index.ts` (deploy blocker).
- FCM end-to-end: server `notifyDriver` sends, client persists FCM token + handles data messages + booking navigation; manifest channel `high_importance_channel` → `booking_updates`.
- Firestore rules: add `chatMessages`, `safetyContacts`, `driverPayouts` (owner read), `referrals`.
- `settlePayouts` integrity: stop auto-marking payouts PAID; payouts page via `requestPayout` callable.
- Driver onboarding: wire real Storage upload + `createDriverProfile` (datasource already exists).

## Next (P1)
- vehicleTypes-driven vehicle selection + server fare-quote callable (kill `249 * 0.45` fake fallback).
- Real trips history/detail, ratings persistence, wallet real read, ETA computation.
- Account deletion callable, Razorpay webhook, multi-stop server support, referral.
- Admin panel (static hosting page + KYC approval callable + admin claims tooling).
- Emulator wiring (`USE_FIREBASE_EMULATORS`), functions unit tests (node:test), CI extension.
- Docs: README, BUSINESS.md refresh; `hi` locale claim fix.

## Known blockers (owner-supplied)
- Firebase console project, App Check, Google Maps key, Razorpay keys/webhook secret, Play Console + upload keystore, admin custom-claim bootstrap.
