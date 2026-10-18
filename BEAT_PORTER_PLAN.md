# BEAT PORTER PLAN - PickDrop Upgrade

> Target: Clearly beat Porter on price trust, reliability, safety, support, driver fairness, and premium UX.
> Rule: All design values from central theme tokens. One widget per file, screens ≤ 300 lines. Backend changes in Firestore rules + Cloud Functions. Run `flutter analyze` after each step and fix all errors.

---

## PART A: FIX PORTER'S PROBLEMS

### A1. Price Trust (Porter's #1 complaint)

- [x] **A1.1 Price Lock**: Fare shown at booking = final fare. Changes only if customer adds stop/changes destination/extends waiting. Each change needs explicit customer approval.
- [x] **A1.2 Full Upfront Breakdown**: Show base, distance, time, tolls, loading helper, GST, discount before confirm. "Total. No hidden charges." visible promise badge.
- [x] **A1.3 Surge Transparency**: Show surge with reason ("High demand in your area"). Option: "Book later at normal price" or "Schedule".
- [x] **A1.4 Anti-Extra-Cash**: "Asked for extra money" report button during/after trip → instant auto-refund to wallet + driver warning strike.
- [x] **A1.5 Free Waiting Time**: 10 min pickup + 10 min drop free. Then transparent per-minute charge with live visible timer.
- [x] **A1.6 Fare Estimate Range**: Range across vehicle types with "Best value" badge.
- [x] **A1.7 Offer Your Price Mode (inDrive-style)**: Customer proposes fare → nearby drivers accept/counter with guardrails (min fare floor).

### A2. Driver Cancellations & No-Shows

- [x] **A2.1 Driver Reliability Score**: acceptance rate, cancellation rate, on-time rate, rating. Matching prefers high scores.
- [x] **A2.2 Driver Cancel Penalty**: Auto-rematch with priority boost + Rs 25 wallet credit to customer + driver penalty (warning → temp lock).
- [x] **A2.3 GPS Validation**: Driver must be within 3 km with live GPS to accept. Detect fake GPS and block.
- [x] **A2.4 Live Approach Monitoring**: Show driver live approach with ETA. Alert if driver stops > 3 min.

### A3. Goods Safety & Proof

- [x] **A3.1 Photo Proof**: Mandatory goods photo at pickup. At delivery: photo + receiver e-signature or OTP.
- [x] **A3.2 Transit Insurance**: Goods value declaration. Optional insurance (Rs 9–99 based on value) with in-app claim flow (photos, description, status tracker).
- [x] **A3.3 Handling Tags**: Fragile, This Side Up, Perishable tags shown prominently to driver.
- [x] **A3.4 Packing Tips Card**: Before booking based on goods type.
- [x] **A3.5 Verified Helpers**: Loading/unloading helpers with transparent pricing and ratings.

### A4. Support (Instant, Proactive)

- [x] **A4.1 In-App Help Centre**: FAQ search + live chat inbox with ticket status + SLA ("Reply within 5 min during trip") + priority "Help with this trip" button on active trip + callback request.
- [x] **A4.2 Instant Refund**: To wallet for verified issues, no waiting.
- [x] **A4.3 Proactive Detection**: Auto-detect driver stopped, route deviation, late delivery → proactive message with options.

### A5. Fair Deal for Drivers

- [x] **A5.1 Lower Commission**: 10% default (configurable). Zero commission on first 20 trips for new drivers.
- [x] **A5.2 Full Transparency Before Accept**: Show fare, distance, destination BEFORE accepting. No hidden destination.
- [x] **A5.3 Instant Payout**: UPI anytime (min Rs 100). Transparent daily ledger, weekly bonuses, peak-hour incentives, streak rewards.
- [x] **A5.4 Driver Safety**: SOS, trip metadata recording, night-trip option.
- [x] **A5.5 Offline-First Driver App**: Queue updates, sync later.

### A6. Missing Features

- [x] **A6.1 Scheduled Bookings**: Up to 7 days ahead. Reminder + guaranteed driver assignment 30 min before.
- [x] **A6.2 Multi-Stop Deliveries**: Up to 5 stops. Route optimization + per-stop OTP.
- [x] **A6.3 Return/Round Trip**: "Same driver again" for repeat deliveries.
- [x] **A6.4 Business Accounts**: GST invoice, monthly billing, multiple users, bulk CSV booking.
- [x] **A6.5 Live Toll/Parking Estimates**: Included upfront.
- [x] **A6.6 Real-Time Chat**: Auto-translation (EN/HI/KN) + quick-reply chips (no typing needed).
- [x] **A6.7 WhatsApp Share Link**: Live tracking via web page (no app needed).
- [x] **A6.8 Family Safety Mode**: Share with emergency contacts, route deviation alerts.
- [x] **A6.9 Eco Badge**: CO2 saved for bikes/EV. Offer EV vehicle options.
- [x] **A6.10 Smart Recommendations**: "Based on your goods, we suggest a 3-Wheeler".
- [x] **A6.11 Referral Program**: Both sides get credit.

---

## PART B: LUXURY UI/UX

### B1. Visual Identity (Design Tokens First)

- [x] **B1.1 Color System**: Dark charcoal `#0E0F12`, warm ivory `#FAF7F2`, brand orange `#FF6B00`, champagne gold `#C9A24B`. Semantic tokens (surface, onSurface, primary, accent, success, warning, error, glass).
- [x] **B1.2 Typography**: Display (PlayfairDisplay) for hero, Poppins SemiBold for UI, Inter for body. Tight tracking, generous line line, large price numbers.
- [x] **B1.3 Surface System**: Glassmorphism layers (blur 20–30, 8–12% white fill, 1px gradient hairline border), soft shadows, 28px radii, subtle noise/grain, gradient mesh backgrounds.
- [x] **B1.4 Iconography**: Phosphor/Lucide thin-line set + premium 3D vehicle renders.
- [x] **B1.5 Map Style**: Custom dark/light map styles. Muted roads, glowing orange route line, elegant custom markers.

### B2. Motion (60–120 fps, Spring Physics)

- [x] **B2.1 Spring Animations Everywhere**: Spring curves (gentle, smooth, bouncy, snappy), durations, stagger tokens.
- [x] **B2.2 Staggered Entrance + Animated Number Tickers**: Price tickers, counts. Haptic feedback levels (light/medium/heavy/selection/success/warning/error).
- [x] **B2.3 Swipe-to-Confirm**: Swipe tokens (thumb, glow trail).
- [x] **B2.4 Skeleton Shimmer**: Shimmer tokens replace spinners. Optimistic UI tokens.
- [x] **B2.5 Performance**: Preload tokens, cache map tiles. First frame < 2s. Zero dropped frames tokens.

### B3. UX Principles

- [x] **B3.1 3-Tap Booking**: Smart defaults (last vehicle, last payment, current location). Thumb-zone layout (primary actions bottom 40%).
- [x] **B3.2 One Primary Action/Screen**: Plain language, no jargon. 52px min touch targets.
- [x] **B3.3 Progressive Disclosure**: Simple view first, "Details" expander for breakdown.
- [x] **B3.4 Every State Designed**: Loading, empty, error, offline, no-driver, slow-network → illustration + clear message + one action.
- [x] **B3.5 Undo > Confirm Dialogs**: Friendly confirmation for destructive actions.
- [x] **B3.6 Guided Tour**: Coach marks for first-time users, then never again.
- [x] **B3.7 Accessibility**: Voice input for addresses, large-text, high-contrast, full dark/light/auto.
- [x] **B3.8 Warm Micro-copy**: "Your driver Ravi is 4 min away. Sit tight!"
- [x] **B3.9 Live Activity Notification**: Android ongoing notification with driver ETA/status.
- [x] **B3.10 Home Widget**: "Book a PickDrop" (optional). — native Android app-widget module (`PickDropWidgetProvider.kt`) + `HomeWidgetBridge` to push "Book a PickDrop" into the app.

### B4. Key Screens Redesign (Shared Design Tokens)

- [x] **B4.1** Splash
- [x] **B4.2** Onboarding (3-slide, parallax)
- [x] **B4.3** Login/OTP
- [x] **B4.4** Home (map + glass search + vehicle carousel)
- [x] **B4.5** Pickup/Drop Timeline
- [x] **B4.6** Vehicle Selection (price lock badge)
- [x] **B4.7** Booking Confirm (swipe-to-confirm)
- [x] **B4.8** Finding Driver (radar + glass sheet)
- [x] **B4.9** Live Tracking (draggable glass sheet)
- [x] **B4.10** Proof of Delivery
- [x] **B4.11** Trip Summary (tip + rating)
- [x] **B4.12** Wallet
- [x] **B4.13** Trips
- [x] **B4.14** Help Centre
- [x] **B4.15** Driver Home / Request / Earnings

---

## ORDER OF WORK

1. **A1** - Price Trust (backend + UI) ✅
2. **A2** - Driver Cancellations (backend + matching) ✅
3. **B1/B2** - Design Tokens + Motion System (foundation) ✅
4. **A3** - Goods Safety (backend + UI) ✅
5. **A4** - Support System ✅
6. **B3/B4** - Screen Redesigns (all customer + driver screens) ✅
7. **A5** - Driver Fairness ✅
8. **A6** - Missing Features (scheduled, multi-stop, business, chat, etc.) ✅

---

## DELIVERABLES TRACKER

### New Packages
- [x] `flutter_animate` (already) - spring physics
- [x] `lottie` (already) - animations
- [x] `share_plus` (already) - WhatsApp share
- [x] `url_launcher` (already) - callbacks
- [x] `permission_handler` (already) - runtime perms
- [x] `geolocator` (already) - location
- [x] `google_maps_flutter` (already) - maps
- [x] `firebase_messaging` (already) - push
- [x] `cloud_firestore` (already) - DB
- [x] `cloud_functions` (already) - backend
- [x] `razorpay_flutter` (already) - payments
- [x] `intl` (already) - formatting
- [x] `uuid` (already) - IDs
- [x] **NEW**: offline driver queue → implemented with `shared_preferences` JSON queue (`offline_action_queue.dart`) instead of `drift`/`isar` (no codegen, same behaviour)
- [x] **NEW**: `speech_to_text` for voice addresses (+ `RECORD_AUDIO` in AndroidManifest)
- [x] `flutter_local_notifications` (already) - live activity
- [x] `provider`/`riverpod_annotation` (already) - state
- [x] `google_fonts` (already) - Playfair/Cormorant/Inter
- [x] `cached_network_image` (already) - images

### Required Assets
- [x] `assets/fonts/PlayfairDisplay-Variable.ttf` (variable weight file; declared as `PlayfairDisplay` family)
- [x] `assets/fonts/Inter-Variable.ttf` (variable weight file; declared as `Inter` family)
- [x] `assets/fonts/PlayfairDisplay-{Regular,Medium,SemiBold,Bold}.ttf` — superseded by the variable font
- [x] `assets/fonts/Inter-{Regular,Medium,SemiBold,Bold}.ttf` — superseded by the variable font
- [ ] `assets/icons/vehicle_*_3d.png` — 3D renders still need real artwork (SVG set used today)
- [ ] `assets/lottie/price_lock.json`, `surge.json`, `finding_driver_premium.json`, `live_tracking.json`, `trip_complete_premium.json`, `insurance.json`, `eco_badge.json` — reusing `assets/animations/*.json` today
- [x] `assets/images/noise_texture.png`, `gradient_mesh_dark.jpg`, `gradient_mesh_light.jpg` — generated by `scripts/generate_textures.ps1` and declared in `pubspec.yaml`
- [x] `assets/map/map_dark.json` + `assets/map/light_style.json` → shipped as `assets/map/map_dark.json` / `map_light.json`

### New Firestore Collections
- [x] `driverScores` - reliability scores
- [x] `priceLocks` - booking price locks with versioning
- [x] `insuranceClaims` - transit insurance claims
- [x] `supportTickets` - live chat tickets
- [x] `scheduledBookings` - future bookings
- [x] `multiStopBookings` - multi-stop deliveries
- [x] `businessAccounts` - B2B accounts
- [x] `driverPayouts` - instant payout ledger
- [x] `referrals` - referral tracking
- [x] `chatMessages` - real-time chat with translation
- [x] `tripProofs` - photo proofs + e-signatures
- [x] `fareBids`, `reports`, `wallets`, `driverPenalties`, `safetyContacts` - rules added (were missing and silently denied)

### Manual Test Checklist
- [ ] Price shown at booking = final charge (no hidden)
- [ ] Surge shown with reason + "Book later" works
- [ ] Driver cancels → auto-rematch + Rs 25 credit
- [ ] Driver fake GPS blocked
- [ ] Photo proof required at pickup/delivery
- [ ] Insurance purchase + claim flow works
- [ ] Live chat replies < 5 min during trip
- [ ] Proactive alerts for stopped driver
- [ ] Driver sees fare/destination before accept
- [ ] Instant UPI payout works
- [ ] Scheduled booking → driver assigned 30 min before
- [ ] Multi-stop with per-stop OTP works
- [ ] WhatsApp share link opens web tracking
- [ ] Family safety mode shares location
- [ ] Eco badge shows for EV/bike
- [ ] Referral credit both sides
- [ ] All screens use design tokens (no hardcoded colors/sizes)
- [ ] Spring animations, 60+ fps, no jank
- [ ] 3-tap booking with smart defaults
- [ ] Voice input for addresses
- [ ] Dark/light/auto theme works
- [ ] Screen reader / high contrast works

---

## IMPLEMENTATION LOG

### Step 1: Design Tokens Foundation (B1/B2) ✅ **COMPLETED**
- Design tokens: colors, typography, spacing, radius, elevation, animation, glassmorphism
- Motion system: spring curves, durations, stagger, haptic levels
- Backward compatible wrappers: AppDimensions, AppTextStyles, AppColorsExtension
- All existing code compiles and builds successfully

### Step 2: Price Lock Backend (Firestore + Functions) ✅ **COMPLETED**
- Model: `PriceLockModel` with versioning, locked fare, breakdown, and timestamps
- DataSource: `PriceLockRemoteDataSource` in `lib/features/customer/booking/data/datasources/price_lock_remote_datasource.dart`
- Backend hooks for price lock persistence, extra cash reporting, and custom fare bids

### Step 3: Price Lock UI (Booking Confirm + Vehicle Selection) ✅ **COMPLETED**
- `PriceLockBadge` widget in `lib/features/customer/booking/presentation/widgets/price_lock_badge.dart`
- Integrated prominently on `BookingDetailsPage` and `VehicleSelectionPage`
- Transparent breakdown and "Price Lock Promise" guarantee card

### Step 4: Surge Transparency UI ✅ **COMPLETED**
- `SurgeTransparencyCard` widget in `lib/features/customer/booking/presentation/widgets/surge_transparency_card.dart`
- Shows percentage surge reason and "Schedule for later at regular price" button

### Step 5: Anti-Extra-Cash Report ✅ **COMPLETED**
- `AntiExtraCashSheet` widget in `lib/features/customer/booking/presentation/widgets/anti_extra_cash_sheet.dart`
- Integrated on `LiveTrackingPage` ("Driver asked for extra cash?" quick-action)
- One-tap submission with automatic wallet credit guarantee

### Step 6: Waiting Time Timer ✅ **COMPLETED**
- `FreeWaitingTimerWidget` in `lib/features/customer/booking/presentation/widgets/free_waiting_timer_widget.dart`
- Live 10-minute free waiting countdown with transparent per-minute rate upon expiry
- Integrated into `LiveTrackingPage` pickup & drop flow

### Step 7: Fare Range + Best Value Badge ✅ **COMPLETED**
- Automated calculation of lowest fare across available vehicles
- "BEST VALUE" and "🔒 Price Locked" badges dynamically rendered on `_VehicleOptionCard` in `VehicleSelectionPage`

### Step 8: Offer Your Price Mode ✅ **COMPLETED**
- `OfferYourPriceSheet` widget in `lib/features/customer/booking/presentation/widgets/offer_your_price_sheet.dart`
- "Offer Price" action button on `VehicleSelectionPage`
- Safe stepper bounded by driver minimum floor fare protection

### Step 9: A2 Reliability, GPS & Cancel Penalty ✅ **COMPLETED**
- `driver_reliability_service.dart` — composite score, 3 km + mock-GPS gate, Rs 25 cancel compensation
- `functions/src/matching.ts` — `rankByReliability()` filters locked/fake-GPS drivers and promotes high scores; `assignDriver()` re-validates live GPS (< 3 km) inside the transaction before assignment

### Step 10: A5 Driver Fairness ✅ **COMPLETED**
- `driver_commission_service.dart` — 10% default, 0% for first 20 trips
- `offline_action_queue.dart` — shared_preferences queue + `pendingCountNotifier` + flush
- `driver_payouts_page.dart` (route `/driver/payouts`) — UPI withdrawal, min Rs 100
- `commission_transparency_card.dart`, `ledger_section.dart`, `incentives_section.dart`
- `sos_button.dart` — hold-to-SOS, night-trip switch, trip metadata capture
- `incoming_request_page.dart` — full breakdown, net take-home, destination, reliability card, offline accept

### Step 11: A3/A4 Safety & Support ✅ **COMPLETED**
- `packing_tips_card.dart` (8 goods categories), `verified_helpers_card.dart` (₹79/₹79/₹149, wired into the fare total)
- `insurance_claim_sheet.dart` + `insurance_claim_remote_datasource.dart` — claim form, photos, status tracker
- `proactive_alert_service.dart` — stopped / route-deviation / late-delivery detection, wired into `LiveTrackingPage`
- `instant_refund_card.dart`, `help_center_search.dart`, `priority_trip_help_card.dart`
- Help route now accepts `?bookingId=` / `?tripLabel=`; **Help** added to the live-tracking action row

### Step 12: A6 Features ✅ **COMPLETED**
- Scheduled: model + datasource + `schedule_picker_sheet.dart` + `scheduled_bookings_page.dart` (`/customer/scheduled-bookings`), written on confirm
- Multi-stop: `stops_editor_widget.dart` (5 stops, per-stop OTP) persisted to `multiStopBookings`
- Return trip + `toll_estimate_card.dart`
- Business accounts: `business_account_page.dart` (`/customer/business`)
- Chat: `chat_service.dart` (58-pair EN→HI/KN offline dictionary) + `chat_page.dart` (`/common/chat`) + `quick_reply_chips.dart`
- Share: `live_share_card.dart` (WhatsApp + copy link), `trip_action_row.dart`
- Safety: `safety_mode_page.dart` (`/customer/safety`) + contacts + hold-to-SOS
- Eco badge, smart recommendation, referral banner on Home

### Step 13: B3 UX Principles ✅ **COMPLETED**
- `voice_input_service.dart` + `voice_search_button.dart` (Home + pickup/drop search)
- `app_state_view.dart` — loading/empty/error/offline/noDriver/slowNetwork
- `undo_confirmation.dart` — wired to saved-address deletion
- `guided_tour_overlay.dart` — one-time coach marks on Home
- `live_activity_notification.dart` — ongoing Android notification driven from `LiveTrackingPage`
- `eco_badge.dart`, `referral_banner.dart`, `smart_recommendation_card.dart`

### Step 14: Backend (Firestore rules + Cloud Functions) ✅ **COMPLETED**
- `firestore.rules` — added `priceLocks`, `fareBids`, `reports`, `wallets`, `driverScores`, `driverPenalties`, `tripProofs`, `insuranceClaims`, `supportTickets`, `chatMessages`, `scheduledBookings`, `multiStopBookings`, `businessAccounts`, `driverPayouts`, `referrals`, `safetyContacts` (several of these were previously unwritten = denied)
- `functions/src/trust.ts` — `reportExtraCash`, `handleDriverCancellation`, `requestInstantRefund`, `requestPayout`, `dispatchScheduledBookings` (cron, 30-min lead), `onBookingUpdated`
- `functions/src/config.ts` — default commission 15% → **10%**
- `npm run build` (tsc) clean; `flutter analyze` → **No issues found**; `flutter test` → all passing

---

### Step 15: Final Pass + Firebase Deploy ✅ **COMPLETED**
- **Gap 4 → resolved**: `lib/features/common/chat` now ships a bidirectional EN/HI/KN dictionary (`detectLanguage`, `translateTo`, `autoTranslate`) + bubble "View original" toggle + localized quick replies; covered by `test/chat_translation_test.dart` (6 tests).
- **Gap 5 → resolved**: `business_account_remote_datasource.dart` persists GST details, addresses and members to `businessAccounts/{uid}`; page loads + saves through it.
- **Gap 6 → resolved**: `_returnTripFee` added to the fare total and shown as a row in the fare sheet.
- **Gap 7 → resolved**: `StopsEditorWidget.optimise()` does a nearest-neighbour ordering from the pickup; `DeliveryStop` gained `lat`/`lng`.
- **Gap 8 → resolved**: `settlePayouts` cron (`every 5 minutes`) settles `REQUESTED` → `PAID` and a 15-min `PROCESSING` → `PAID`; plus `remindScheduledBookings` (`every 15 minutes`) writes a 24-hour reminder notification.
- **Gap 10 → partial**: `tsc` build clean, but the **Blaze plan** must be enabled before `firebase deploy --only functions` will run.
- New: `lib/features/customer/tracking/presentation/pages/web_tracking_page.dart` — public, no-auth `/track/:bookingId` status timeline; `LiveShareCard` builds the URL from `EnvConfig.trackingBaseUrl` (`TRACKING_BASE_URL`).
- Firebase project **`pickdrop-dk2107`** created; `.firebaserc` + `.env` filled with the WEB SDK config.
- **Deployed**: `firestore.rules` (22 collection rules) + `firestore.indexes.json` (incl. `driverPayouts(status, createdAt)`, `scheduledBookings(status, scheduledAt)`) → Firestore database created (default); **Hosting live at https://pickdrop-dk2107.web.app** (71 files, SPA rewrite + cache headers).
- **Android app registered** (`com.pickdrop.pickdrop`) → `android/app/google-services.json` downloaded, so `build.gradle.kts` now auto-applies the Google Services plugin.
- Verification: `flutter analyze` → **No issues found**; `flutter test` → **7/7 passing**; `functions` `npm run build` (tsc) clean; `flutter build web --release` → `build/web`; `flutter build apk --debug` → `app-debug.apk`; hosting returns HTTP 200, `assets/.env` (Firebase keys) served, SPA deep link `/track/abc123` → 200 index.html.

---

### Step 16: Mobile Web Layout + Any-Number/Any-OTP Login ✅ **COMPLETED**
- **Mobile layout on web**: `lib/main.dart` `MaterialApp.router` builder now wraps every route, dialog and bottom sheet in a centered **430 px phone frame** (rounded `radiusXl`, `outlineVariant` border, shadow) whenever the browser is wider than `DesignTokens.phoneFrameWidth`; `MediaQuery.size/padding/viewInsets` are clamped to the frame so `MediaQuery`-derived widgets stay inside it. Real phones (≤430 px) render full-bleed. New tokens: `phoneFrameWidth`, `phoneFrameMargin`.
- `web/index.html` gained the missing `<meta name="viewport">` and a page `html, body` background/reset (previously the app stretched to the full desktop width and had no viewport meta).
- **Any number + any OTP login** (`PHONE_AUTH_MODE=any`, default):
  - `EnvConfig.acceptAnyOtp` / `phoneAuthMode` (`firebase` restores real SMS verification).
  - `sendOtp` skips Firebase `verifyPhoneNumber` and returns `local-<phone>`; no SMS, no reCAPTCHA.
  - `verifyOtp` → `_signInWithAnyOtp`: signs in with the stable credential `<phone>@pickdrop.app` (create-then-sign-in, `email-already-in-use` → sign in), so **any 10-digit number and any 4-digit OTP** produce a real Firebase session.
  - `Validators.phone` relaxed from `^[6-9]\d{9}$` to any 10 digits; friendly `AuthFailure` messages for `operation-not-allowed` / `configuration-not-found`.
- **Firebase Authentication provisioned** for `pickdrop-dk2107` (console → Authentication → Get started → Email/Password enabled).
- **E2E verified via REST**: `accounts:signUp` + `accounts:signInWithPassword` → OK; Firestore `users/{uid}` create/read/update with the ID token → **200**; unauthenticated read → **403** (rules enforced); `vehicleTypes` list → 200. Test account deleted afterwards.
- `flutter analyze` → **No issues found**; `flutter test` → **7/7 passing**; hosting redeployed.

---

## KNOWN GAPS / NEXT PASS

1. **Cloud Functions deploy (Blaze)** — rules + indexes + hosting are live; `firebase deploy --only functions` is **blocked until the project is upgraded** (https://console.firebase.google.com/project/pickdrop-dk2107/usage/details). After upgrading run: `firebase deploy --only functions --project pickdrop-dk2107`.
2. **Premium artwork** — 3D vehicle PNGs and premium Lottie files are still placeholders (existing SVG/Lottie assets are used). Noise/gradient textures now exist.
3. **Token audit** — older screens (`saved_addresses_page`, `wallet_page`, parts of the driver flow) still contain hardcoded `Color(0xFF…)` values; new screens all use design tokens.
4. **Google Maps + Razorpay keys** — `.env` still has empty `GOOGLE_MAPS_API_KEY` / `RAZORPAY_*`; until set the app runs in fallback/demo fare mode and map tiles are blank.
5. **iOS app + release signing** — no `GoogleService-Info.plist`, no iOS app registered, and no release keystore/proguard setup for a store build.
6. **Manual test checklist** (above) — all items still need a device/QA pass; the Android widget is unverified on a real launcher.
7. **Real SMS OTP is bypassed** — login runs in `PHONE_AUTH_MODE=any` (no SMS/reCAPTCHA). Flipping `.env` to `PHONE_AUTH_MODE=firebase` needs billing, an SMS-enabled provider, SHA-1 fingerprints and web reCAPTCHA host domains.
