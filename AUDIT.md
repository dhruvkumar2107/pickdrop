# Audit — 2026-10-19 (rewritten against disk truth)

All entries below were verified with direct file reads/greps on 2026-10-19. Feature status:
**Done** (wired end-to-end), **Partial** (works with gaps), **Missing**, **Broken** (code exists but fails at runtime).

## Baseline verification

| Check | Result |
|---|---|
| `flutter pub get` | pass |
| `flutter analyze` | 1 warning (unused import `env_config.dart` in `lib/main.dart`) |
| `flutter test` | 7 pass |
| `npm --prefix functions run build` | pass (clean `tsc`) |
| `flutter build apk --debug` | pass (prior session; `build\app\outputs\flutter-apk\app-debug.apk`) |
| Firebase emulator rules tests | Missing (emulators configured in `firebase.json`, no tests) |
| Functions unit tests | Missing (no test framework in `functions/`) |

Git: one commit (`f00eb65`). This working tree contains all Phase-1/2 changes uncommitted.

## Feature completeness

### Auth — mostly Done

| Feature | Status | Evidence |
|---|---|---|
| Phone OTP (Firebase) | Done | `auth_remote_datasource.dart` wired; real `verifyPhoneNumber` |
| Role selection / profile | Done | `role_selection` + `_ensureUserDoc` |
| Logout | Done | sign-out wired |
| Account deletion | Missing | `firestore.rules` `users.delete: false`; no callable, no UI |

Dead config: `.env` has `PHONE_AUTH_MODE=any`; `env_config.dart` defaults to `firebase` and nothing reads the value. Align `.env` to `firebase`.

### Customer

| Feature | Status | Evidence |
|---|---|---|
| Pickup/drop selection + map | Partial | Real Google Maps picker; search is hardcoded address list (`pickup_drop_selection_page.dart`) |
| Saved addresses persistence | Broken | UI only; never reads/writes `savedAddresses` (rules allow owner writes) |
| Vehicle selection | Broken | 3 hardcoded vehicles (`lib/features/common/vehicle_selection/presentation/pages/vehicle_selection_page.dart:90,101`); `vehicleTypes` collection readable but unused |
| Fare estimate | Broken | Client-side fake fallback `249 * 0.45` (`booking_details_page.dart:110-113`); server `createPriceLock` callable exists, unused by this page |
| Book now | Done | `createBooking` callable → AWAITING_PAYMENT → `verifyPayment` (API-verified + capture) → matching |
| Schedule later | Done | `createScheduledBooking`/`cancelScheduledBooking` callables + `dispatchScheduledBookings` cron + reminders |
| Multi-stop | Broken | `stops_editor_widget.dart` exists; confirm blocked; `createBooking` ignores stops |
| Live tracking | Partial | Real booking/driver streams; ETA hardcoded `0`; driver rating hardcoded; `call` = raw `tel:`; chat unusable (rules deny `chatMessages`) |
| Status notifications | Partial | Server writes `notifications` docs (`trust.ts:389`); FCM push no-op (`matching.ts:270-274`); client token save stub (`notification_service.dart:161`); data-only messages dropped (`:110`); navigation stub (`:156`); manifest default channel `high_importance_channel` vs code-created `booking_updates` (`AndroidManifest.xml:66` vs `notification_service.dart:96`) |
| Payments (Razorpay) | Partial | Order + API-verified capture done; no webhook; no refunds; `RAZORPAY_KEY_ID` empty in `.env` |
| Ratings | Broken | `trip_complete_page.dart:94-100` shows success toast, writes nothing (rules now allow `ratings` create) |
| Order history | Broken | `my_trips_page.dart:25` mock list; `trip_detail_page.dart` fully static |
| Rebook | Missing | — |
| SOS / safety | Broken | `safetyContacts` default-denied by rules; safety page cannot persist contacts |
| Promo codes | Partial | `coupons` page reads real collection; server validates on `createBooking` |
| Referral | Missing | Banner UI only, no attribution or reward logic |
| Web tracking (share link) | Broken | Page reads `bookings`; rules allow participant-only read, so recipients cannot open the link |

### Driver

| Feature | Status | Evidence |
|---|---|---|
| KYC/onboarding upload | Broken | `driver_onboarding_page.dart:247-250` is `Future.delayed(2s)`; documents discarded. But `driver_remote_datasource.createDriverProfile` exists and `firestore.rules` allows a strict-key driver create — wiring is the only gap |
| Online/offline toggle | Done | `driver_home_providers.dart` gate on `isVerified`, writes `isOnline` |
| Location broadcast | Done | `location_service.dart` writes `currentLocation` + `geohash` (rules allow) |
| Incoming request | Done | Subscribes `driverOffers/{bookingId}_{uid}`; `acceptOffer`/`rejectOffer` callables; navigates with `bookingId` |
| FCM-driven request wake-up | Missing | `notifyDriver` no-op → driver only sees requests while app open |
| Active trip OTP flow | Done | `verifyPickupOtp`/`verifyDropOtp` callables in `active_trip_page.dart` |
| Earnings | Partial | Commission transparency reads real `config`; dashboard totals mock; `driverLedger` populated server-side by `settleDeliveredTrip` but UI hardcoded |
| Payouts | Broken | `driver_payouts_page.dart:52,92` direct read/write of `driverPayouts` (default-denied → runtime error); `requestPayout` callable exists, unused |
| Trip history | Broken | Mock data |

### Backend (Functions/rules)

| Area | Status | Evidence |
|---|---|---|
| Fare engine | Done | Server-side `calculateFare`; pricing from `vehicleTypes` DB rows |
| Dispatch | Done | Geohash cascade + reliability ranking + GPS/mock-location validation at assign (`matching.ts:240-258`); offer window with timeout |
| Booking state machine | Done | SEARCHING / AWAITING_PAYMENT / DRIVER_ASSIGNED / PICKED_UP / DELIVERED / CANCELLED / NO_DRIVER_FOUND; transitions server-owned, client writes denied |
| Payment verification | Done | `verifyPayment` verifies capture against Razorpay API (not client callback) |
| Razorpay webhook | Missing | No `onRequest` webhook; reconciliation relies on client-triggered verify |
| Commission/ledger | Done | `settleDeliveredTrip` idempotent ledger + driver earnings counters; first-20-trips commission-free (`trust.ts` `commissionFor`) |
| Payout processing | Broken (integrity) | `settlePayouts` auto-marks REQUESTED → PAID with no real transfer. Must not auto-complete money movement |
| Scheduled dispatch | Done | Cron dispatch + reminders |
| Firestore rules | Partial | Strong default-deny + server-owned money. Missing: `chatMessages`, `safetyContacts`, `driverPayouts` (owner read), `referrals` |
| Storage rules | Done | KYC docs owner-only; references `role == 'admin'` custom claim which nothing sets yet |
| Admin operations | Missing | No KYC approval path (`isVerified` stuck false forever), no config editor, no payout control, no admin claims tooling |
| Emulators | Partial | Configured in `firebase.json`; `USE_FIREBASE_EMULATORS` flag exists in `.env`/`env_config.dart` but `main.dart` never switches SDKs |
| CI | Partial | analyze/test/AAB pinned to Flutter 3.47.1; no functions build/test step |
| Tests | Broken coverage | 7 Flutter tests (chat text, startup); zero rules/functions coverage; no fare/state-machine tests |

### Android / platform

| Area | Status | Evidence |
|---|---|---|
| Permissions | Done | Location, notifications, foreground service, exact alarm declared |
| Release signing | Done (fail-closed) | Requires `android/key.properties`; no debug fallback |
| Debug build | Done | APK built successfully |
| Notification channel | Broken | Manifest default `high_importance_channel` ≠ created `booking_updates` → FCM notifications silently dropped |
| Maps key | Owner-configured | Empty/placeholder in `strings.xml`/`.env` |
| Background location runtime request | Partial | Manifest declares permissions; driver page requests foreground only |

## Top bugs (file:line)

1. `lib/main.dart:23` loads `.env.client` (absent) → app always shows BootstrapFailure; `pubspec.yaml:109` declares missing `.env.client` asset. Fix: standardize on `.env`.
2. `functions/src/index.ts:14-15,40-47` re-exports plain functions (`calculateFare`, `haversineKm`, `generateOtp`, `verifyOtp`, `commissionFor`) → Firebase deploy rejects the package.
3. `functions/src/matching.ts:270-274` `notifyDriver` no-op → drivers never pushed.
4. `lib/shared/services/notification_service.dart:110,156,161` drop data-only messages, stub navigation and token persistence.
5. `android/app/src/main/AndroidManifest.xml:66` channel id mismatch (see above).
6. `functions/src/trust.ts` `settlePayouts` marks payouts PAID automatically (money-integrity violation).
7. `lib/features/driver/onboarding/.../driver_onboarding_page.dart:250` fake KYC submit.
8. `lib/features/customer/tracking/.../trip_complete_page.dart:94-100` ratings not persisted.
9. `lib/features/customer/trips/.../my_trips_page.dart:25` + `trip_detail_page.dart` mock/static history.
10. `lib/features/common/vehicle_selection/.../vehicle_selection_page.dart:90,101` hardcoded vehicles; `booking_details_page.dart:110-113` fake fare fallback.
11. `lib/features/driver/earnings/.../driver_payouts_page.dart:52,92` direct denied writes.
12. `firestore.rules` missing `chatMessages`/`safetyContacts`/`driverPayouts`/`referrals`.
13. `lib/core/localization/app_localizations.dart:270` claims `hi` support; no `strings_hi.dart` exists (silent English fallback).
14. `web_tracking_page.dart` unreadable to share recipients (participant-only booking read).
15. `DriverModel.fromJson` defaults `rating` to `5.0` while driver-create rules require `rating == 0` — onboarding will be rejected unless callers pass 0 explicitly (flagged for the onboarding wiring).

## Priorities fixed by this audit cycle

- **P0 (this session):** `.env` bootstrap; index.ts export cleanup; FCM end-to-end (server send + token persistence + channel fix + navigation); rules additions; `settlePayouts` integrity; real driver onboarding wiring; payouts page via callable.
- **P1:** vehicleTypes + server fare quote; real trips history/detail; ratings persistence; wallet read; ETA; account deletion callable; Razorpay webhook; multi-stop server support; referral; admin panel + KYC approval callable; emulator wiring; functions tests; CI extension.
- **P2 (owner/console):** Firebase console setup, App Check monitor→enforce, Razorpay keys + webhook URL, Play Console + signing, Maps key restriction, Crashlytics enablement.
