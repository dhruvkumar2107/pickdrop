# Progress

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
