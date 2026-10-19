# Audit — 2026-10-19 (rewritten against disk truth)

## Client-write vs Firestore rules audit — 2026-10-19

Verified every reachable client write against `firestore.rules`; fixed writes the rules deny (which previously failed silently and produced false-success UI):

- Instant-refund card now calls the `requestInstantRefund` callable instead of writing `reports` + crediting `wallets` client-side (both denied). Copy no longer promises an automatic refund.
- Removed dead `DriverMatchingService.handleDriverCancel` that wrote denied `driverPenalties` and credited `wallets`; `DriverReliabilityModel` (still used) retained.
- Bookings flow reduced to `reportExtraCashRequested` (callable); removed dead `PriceLockModel`/`createPriceLock`/`submitCustomFareOffer` (`priceLocks`/`fareBids` denied) and deleted the unreachable `offer_your_price_sheet.dart`.
- Removed dead `applyCoupon` (`coupons` writes denied; the live flow uses a server callable).
- `AuthRemoteDataSource.deleteAccount` now calls the `deleteAccount` callable and signs out instead of deleting the `users` doc client-side (denied) then `user.delete()`.
- Confirmed conforming reachable writes: `users` create/update (allowed key set), `drivers` location/online updates, `safetyContacts` create (exact field set), `reports` SOS create (`reporterId`), profile display-name edit.
- Latent (unreachable) denied write left in place: `driver_remote_datasource.updateDriverProfile` can write `vehicleTypeId`/`vehicleNumber`/`vehicleModel` (not in the allowed `drivers` update set); the provider is never watched and driver onboarding uses the `submitDriverKyc` callable, so it is dead code.
- Driver SOS now calls `createSosAlert` (extended to attach the driver's active booking and notify the customer) so it reaches the admin Safety-alerts queue; previously it wrote `reports` type `SOS`, which no admin view displayed.
- Added a read-only "Refund requests" queue to the admin review page (`reports` type `REFUND_REQUEST`, `PENDING_REVIEW`), since the admin only listed `EXTRA_CASH` and `reports` is append-only. No approval/money movement is implied.
- Checks: `flutter analyze` 0 errors / 0 warnings, `flutter test` 7/7, `dart analyze` clean on edited files.

## Follow-up implementation update — 2026-10-19

- Latest follow-up: rejected KYC can be resubmitted through an authenticated callable; the driver sees the rejection reason and vehicle options now come from the live catalog. Scheduled bookings carry up to five map-pinned stops through road pricing, dispatch, per-stop OTPs and trip completion. Chat now uses booking-scoped messages with both-trip-participant authorization. SOS creates a server-side incident, records available GPS, notifies the assigned driver and appears in the admin queue. Referral codes are server-issued, checked at booking, and credit both wallets once after a completed trip. Admin can inspect and edit seeded vehicle prices.
- Public live tracking now uses reusable 256-bit share tokens, callable-scoped responses, owner-triggered revocation, 24-hour expiry and terminal-trip shutdown; the recipient page renders intermediate stops. Customer tracking share actions now use the actual booking ID to mint a token URL.
- KYC submission now checks that the selected vehicle is active and each required document is an owner-scoped Firebase Storage download URL for the expected private object path.
- Extra-cash complaints now use the authenticated callable, validate the customer's active booking/assigned driver and reported amount, and enter an admin review queue; confirmation no longer promises an automatic refund. The customer profile now reads the real account, delivered trip/address counts and wallet balance, and pickup/drop saved-address shortcuts use Firestore data. Safety settings no longer imply local-only switches actually send alerts.
- Latest local checks: Functions TypeScript build and Android debug APK build passed after the current KYC/report/profile/safety changes; existing Flutter tests pass (7/7). `flutter analyze` completed with style/info findings; Firebase emulator/rules and live provider tests have not run. No payment or payout transfer was initiated.
- Release workflow now creates `.env` and the Android Maps resource from repository secrets and fails early when required client configuration is missing. Required CI secret names are documented in `OPERATIONS.md`; workflow execution against GitHub Actions secrets is not verified.
- Live Firebase actions remain pending: the trusted administrator UID is still not supplied; Razorpay server secret, RazorpayX credentials/webhook configuration and Google Routes server key are absent. `.env` contains Firebase project configuration, while Google Maps and Razorpay client values are blank there; `.env.client` contains a sandbox-formatted Razorpay key ID but is not loaded by `main.dart`. Deployment/initialization has not been performed.
- Latest verification after the tracking updates: `npm run build` (Functions) and `flutter build apk --debug --no-pub` pass; `git diff --check` and Firestore index JSON parsing pass. `flutter analyze` completed with 41 lint/info findings across the workspace (mostly curly-brace style; duplicate `EnvConfig` import was removed afterward). Firebase emulator/security and sandbox provider verification are still not complete.

- Added `/admin/review`, gated by a Firebase `role=admin` custom claim, with driver KYC and payout queues. Admin callables approve/reject KYC and approve/reject reserved payouts. Approved payouts use RazorpayX; signed webhooks reconcile final provider states. Uncertain provider results keep funds reserved for reconciliation.
- Added Razorpay wallet order creation, server-side payment verification/capture, signed `payment.captured` webhook reconciliation, idempotent wallet credit/debit ledger, authenticated wallet balance/history, and atomic wallet checkout for bookings.
- Vehicle selection now requires the Firestore catalog; an admin callable seeds starter vehicle rows/config only where absent. Pricing callables use Google Routes road distance/time and reject unavailable routing rather than quoting straight-line estimates.
- Driver earnings and trip history now read `driverLedger`/bookings rather than sample rows.
- Trip detail screen now loads the selected booking instead of demo data. Added pinned intermediate stops (up to five), road-route and configured stop pricing, sequential driver OTP verification, and final-drop blocking until stops are verified. New booking OTPs are stored in customer-only `bookingSecrets`.
- Checks: Functions TypeScript build and Android debug APK build passed; targeted Dart analysis passed with style infos; `git diff --check` and Firestore index JSON parsing passed. Firebase emulator/security tests and live provider tests remain outstanding.
- External setup still required: set the administrator custom claim; configure Razorpay/RazorpayX and Google Routes secrets/webhooks; deploy Functions/rules/indexes; initialize and review live pricing; test with provider credentials. Other user-facing gaps remain and are listed in the current remaining-work section.

## Resume implementation update — 2026-10-19

Changes completed in the current implementation pass (supersedes affected baseline rows below):

- Customer booking creation, Razorpay order creation, payment verification/capture, matching, OTP transitions, scheduled booking, and cancellation use server callables; clients no longer write booking/payment state directly.
- The earlier wallet pass removed fabricated balance/checkout behavior; this follow-up now adds server-created Razorpay top-up orders, verification/capture and signed webhook crediting. Production use still requires provider secrets and deployment.
- Driver offer notifications now send FCM, persist tokens to eligible profiles, and navigate on tap. Android uses the `booking_updates` channel.
- Driver KYC onboarding uploads the selected documents, writes the driver profile, and stores document references/numbers in a private `driverPrivate` record; the customer-readable driver record no longer contains KYC fields.
- Driver dashboard totals and recent delivered trips read Firestore. Customer trip history reads real bookings. Payouts reserve online-settled earnings through the callable and remain `PENDING_REVIEW`; no automatic transfer is claimed.
- Firestore rules/indexes were updated for private KYC and driver payout history. The Functions entry point exports callable/trigger functions only.
- Current pass additions: booking details requests a server fare quote, and `createBooking` rejects a booking if its submitted total differs from the server-calculated total; saved addresses now persist and list/delete per user; trip ratings use a callable that verifies a delivered booking and prevents duplicate ratings, with the driver average updated transactionally.
- Current checks: `npm run build` in `functions/` — pass; `flutter build apk --debug` — pass; `git diff --check` — pass. `flutter analyze --no-pub` stalled without diagnostics during this pass and was stopped. Flutter tests and Firebase emulator/security tests were not run in this pass.

Still required before production: provision/deploy Firebase rules/indexes/Functions; supply restricted Android and server-side Maps keys; configure Razorpay/RazorpayX server credentials and webhooks; initialize and verify live catalog pricing; grant a trusted admin claim; and test provider flows. Other incomplete features remain listed in the current gaps below.

All entries below were verified with direct file reads/greps on 2026-10-19. Feature status:
**Done** (wired end-to-end), **Partial** (works with gaps), **Missing**, **Broken** (code exists but fails at runtime).

## Baseline verification

| Check | Result |
|---|---|
| `flutter pub get` | pass |
| `flutter analyze --no-pub` | prior pass clean; current run stalled without diagnostics |
| `flutter test` | 7 pass in earlier baseline; not rerun in current pass |
| `npm run build` (`functions/`) | pass (current `tsc`) |
| `flutter build apk --debug` | pass (current pass; `build\app\outputs\flutter-apk\app-debug.apk`) |
| Firebase emulator rules tests | Missing (emulators configured in `firebase.json`, no tests) |
| Functions unit tests | Missing (no test framework in `functions/`) |

Git: one commit (`f00eb65`). This working tree contains all Phase-1/2 changes uncommitted.

## Feature completeness

### Auth — mostly Done

| Feature | Status | Evidence |
|---|---|---|
| Phone OTP (Firebase) | Done | `auth_remote_datasource.dart` wired; real `verifyPhoneNumber` |
| Role selection / profile | Done | `role_selection` + `_ensureUserDoc` |
| Logout | Done | Firebase Auth sign-out is called from the customer profile. |
| Account deletion | Missing | Auth datasource attempts a client-side user document delete and Firebase Auth delete; Firestore rules deny user deletion, no UI, and no server retention/anonymization policy. |

Configuration: `.env` has Firebase project values and is loaded by `main.dart`; its Maps and Razorpay client entries are blank. A sandbox-formatted Razorpay key ID appears in ignored `.env.client`, which the app does not load. Google Routes and Razorpay server secrets are not present.

### Customer

| Feature | Status | Evidence |
|---|---|---|
| Pickup/drop selection + map | Partial | Real Google Maps picker; search is hardcoded address list (`pickup_drop_selection_page.dart`) |
| Saved addresses persistence | Partial | Firestore create/list/delete and pickup/drop shortcuts wired per authenticated user; edit remains |
| Vehicle selection | Partial | Reads active ordered Firestore catalog; admin can seed starter rows. Quote at booking details uses server-authoritative road route/fare. |
| Fare estimate | Partial | Google Routes road distance/time quote + server expected-total check; requires `GOOGLE_MAPS_SERVER_KEY`; vehicle cards remain indicative. |
| Book now | Done | `createBooking` callable → AWAITING_PAYMENT → `verifyPayment` (API-verified + capture) → matching |
| Schedule later | Done | `createScheduledBooking`/`cancelScheduledBooking` callables + `dispatchScheduledBookings` cron + reminders |
| Multi-stop | Partial | Up to five map-pinned stops with road-route pricing, dispatch, and sequential OTPs for immediate and scheduled cash bookings. Scheduled add-ons/coupons remain unsupported. |
| Live tracking | Partial | Real booking/driver streams and booking-scoped chat; public web links use high-entropy bearer tokens and return limited trip/driver data. Token revocation/expiry and live validation remain. |
| Status notifications | Partial | Driver offer FCM, token persistence, tap routing, and Android `booking_updates` channel are wired; device/background delivery and broader booking status notifications need validation. |
| Payments (Razorpay) | Partial | Booking payments and wallet top-ups verify/capture server-side; wallet has signed `payment.captured` webhook. A sandbox-formatted client key ID exists only in ignored `.env.client`, which the app does not load; active `.env` and server credentials/webhooks are missing. Refunds remain manual. |
| Ratings | Partial | Callable validates delivered customer booking, enforces one rating per trip, updates driver average; live submission requires deployed Functions |
| Order history | Partial | Customer history and booking detail read Firestore; refresh/rebook and richer driver/customer identity remain. |
| Rebook | Missing | — |
| SOS / safety | Partial | Owner-only emergency contacts; SOS records an incident, includes GPS when permitted, alerts the assigned driver, and is visible to admins. It still calls 112 directly; outbound SMS to stored emergency contacts needs a configured messaging provider. |
| Promo codes | Partial | `coupons` page reads real collection; server validates on `createBooking` |
| Referral | Done | Server-owned referral codes, self-referral/duplicate protection, and one-time ₹50 credits to both wallets after the referred user completes a delivery. |
| Web tracking (share link) | Partial | Owner creates/reuses a high-entropy bearer token, can revoke it, and gets 24-hour expiry; public callable returns limited trip/driver data and route stops. Live deployment validation remains. |

### Driver

| Feature | Status | Evidence |
|---|---|---|
| KYC/onboarding upload | Done | Private document upload and review; rejected drivers see the reason and can resubmit through an authenticated server callable. |
| Online/offline toggle | Done | `driver_home_providers.dart` gate on `isVerified`, writes `isOnline` |
| Location broadcast | Done | `location_service.dart` writes `currentLocation` + `geohash` (rules allow) |
| Incoming request | Done | Subscribes `driverOffers/{bookingId}_{uid}`; `acceptOffer`/`rejectOffer` callables; navigates with `bookingId` |
| FCM-driven request wake-up | Partial | Driver offer push and tap routing implemented; needs physical-device/background validation. |
| Active trip OTP flow | Done | `verifyPickupOtp`/`verifyDropOtp` callables in `active_trip_page.dart` |
| Earnings | Partial | Totals, chart and rows read `driverLedger`; incentive goals remain illustrative. |
| Payouts | Partial | Callable reserves balance; admin approval submits RazorpayX transfer and signed webhook reconciles final status. Requires live provider setup and testing. |
| Trip history | Partial | Driver bookings and ledger data replace sample rows; detail/customer identity and refresh are limited. |

### Backend (Functions/rules)

| Area | Status | Evidence |
|---|---|---|
| Fare engine | Done | Server-side `calculateFare`; pricing from `vehicleTypes` DB rows |
| Dispatch | Done | Geohash cascade + reliability ranking + GPS/mock-location validation at assign (`matching.ts:240-258`); offer window with timeout |
| Booking state machine | Done | SEARCHING / AWAITING_PAYMENT / DRIVER_ASSIGNED / PICKED_UP / DELIVERED / CANCELLED / NO_DRIVER_FOUND; transitions server-owned, client writes denied |
| Payment verification | Done | `verifyPayment` verifies capture against Razorpay API (not client callback) |
| Razorpay webhook | Partial | Signed wallet `payment.captured` webhook credits the ledger; booking payment still reconciles through verified callable. |
| Commission/ledger | Done | `settleDeliveredTrip` idempotent ledger + driver earnings counters; first-20-trips commission-free (`trust.ts` `commissionFor`) |
| Payout processing | Partial | Admin approval submits through RazorpayX, signed webhook marks terminal state, failed payouts release held funds, uncertain results retain reserve for reconciliation. |
| Scheduled dispatch | Partial | Cron dispatch/reminders, multi-stop routing and stop OTPs are wired. Scheduled bookings currently accept cash only and no add-ons/coupons. |
| Firestore rules | Partial | Default-deny and server-managed wallet/booking secrets; deploy and emulator validation remain. |
| Storage rules | Done | KYC docs owner-only; references `role == 'admin'` custom claim which nothing sets yet |
| Admin operations | Partial | KYC/payout review and catalog seeding UI/callables exist; trusted claims are provisioned out-of-band; no general config editor. |
| Emulators | Partial | Configured in `firebase.json`; `USE_FIREBASE_EMULATORS` flag exists in `.env`/`env_config.dart` but `main.dart` never switches SDKs |
| CI | Partial | analyze/test/AAB pinned to Flutter 3.47.1; no functions build/test step |
| Tests | Broken coverage | 7 Flutter tests (chat text, startup); zero rules/functions coverage; no fare/state-machine tests |

### Android / platform

| Area | Status | Evidence |
|---|---|---|
| Permissions | Done | Location, notifications, foreground service, exact alarm declared |
| Release signing | Done (fail-closed) | Requires `android/key.properties`; no debug fallback |
| Debug build | Done | APK built successfully |
| Notification channel | Done | Manifest and app use `booking_updates`; release/device delivery still needs validation. |
| Maps key | Missing | Android maps resource and active `.env` server/client config are empty or placeholder; ignored `.env.client` is not loaded by `main.dart`. |
| Background location runtime request | Partial | Manifest declares permissions; driver page requests foreground only |

## Remaining work and launch gates

- User-facing gaps still in scope: account deletion, rebooking, outbound emergency-contact notifications, complete localization, driver incentive accuracy, and richer trip/driver history. Scheduled multi-stop bookings currently exclude add-ons/coupons and use cash only.
- Shared tracking now uses bearer tokens and a public callable. Add owner revoke/expiry controls before broad launch; keep shared response limited to route/status/driver details.
- The admin custom claim and live catalog initialization require a trusted administrator UID and fresh Firebase Admin credentials. Provider and Maps secrets are absent, so sandbox payment, payout, routing, and webhook tests cannot run yet.
- Firestore emulator/rules validation, device testing, and release build/signing remain outstanding. Debug APK and Functions compilation pass; successful compilation does not establish live Firebase/provider readiness.
- Do not initiate live payouts during any validation. Use sandbox credentials and provider test beneficiaries only.
