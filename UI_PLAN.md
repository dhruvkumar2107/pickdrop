# PickDrop — Premium UI Upgrade Plan

## Overview
Upgrade every screen to Uber/Rapido/Porter "wow" level. Light + dark mode, glassmorphism, Lottie animations, haptics, smooth 60fps.

---

## 1. DESIGN SYSTEM TOKENS

### 1A. Colors (`lib/core/constants/colors.dart`)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | `#FF6B00` | `#FF8A33` | CTAs, brand accent |
| `primaryEnd` | `#FF9A3C` | `#FFBC80` | Gradient end |
| `surface` | `#F7F7FA` | `#14161A` | Page background |
| `surfaceCard` | `#FFFFFF` | `#1E2028` | Cards, sheets |
| `surfaceElevated` | `#FFFFFF` | `#252830` | Elevated cards |
| `onSurface` | `#14161A` | `#F0F0F5` | Primary text |
| `onSurfaceVariant` | `#6B7280` | `#9CA3AF` | Secondary text |
| `outline` | `#E5E7EB` | `#2D3038` | Borders |
| `success` | `#16A34A` | `#22C55E` | Completed, online |
| `error` | `#DC2626` | `#EF4444` | Cancelled, danger |
| `warning` | `#F59E0B` | `#FBBF24` | Pending states |
| `info` | `#2563EB` | `#3B82F6` | Informational |
| `glass` | `white.withOpacity(0.7)` | `#14161A.withOpacity(0.7)` | Glass cards |
| `glassBorder` | `white.withOpacity(0.2)` | `white.withOpacity(0.1)` | Glass borders |
| `shadow` | `#14161A.withOpacity(0.08)` | `#000000.withOpacity(0.4)` | Shadows |

**Gradients:**
- `brandGradient`: `#FF6B00` → `#FF9A3C` (top-left → bottom-right)
- `darkGradient`: `#14161A` → `#1E2028` (top → bottom)
- `successGradient`: `#16A34A` → `#22C55E`

### 1B. Typography

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `displayLg` | Poppins | 36 | 700 | Hero headings |
| `displayMd` | Poppins | 28 | 700 | Section headers |
| `displaySm` | Poppins | 24 | 600 | Card titles |
| `headlineLg` | Poppins | 22 | 600 | Page titles |
| `headlineMd` | Poppins | 20 | 600 | Sub-headings |
| `headlineSm` | Poppins | 18 | 600 | Widget titles |
| `titleLg` | Inter | 16 | 600 | Card headers |
| `titleMd` | Inter | 14 | 500 | Labels |
| `bodyLg` | Inter | 16 | 400 | Body text |
| `bodyMd` | Inter | 14 | 400 | Descriptions |
| `bodySm` | Inter | 12 | 400 | Captions |
| `labelLg` | Inter | 14 | 600 | Buttons |
| `labelMd` | Inter | 12 | 500 | Chips, badges |
| `labelSm` | Inter | 10 | 500 | Overlines |
| `priceLg` | Poppins | 32 | 700 | Main fare display |
| `priceMd` | Poppins | 24 | 700 | Vehicle price |
| `priceSm` | Poppins | 18 | 600 | Secondary price |

### 1C. Spacing (4-point grid)

| Token | Value |
|---|---|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 48 |
| `huge` | 64 |

### 1D. Border Radius

| Token | Value | Usage |
|---|---|---|
| `xs` | 8 | Small chips |
| `sm` | 12 | Inputs, buttons |
| `md` | 16 | Cards |
| `lg` | 24 | Sheets, modals |
| `xl` | 32 | Hero cards |
| `full` | 999 | Avatars, pills |

### 1E. Shadows

| Token | Light | Dark |
|---|---|---|
| `sm` | `0 1px 3px shadow` | `0 1px 3px shadow` |
| `md` | `0 4px 12px shadow` | `0 4px 12px shadow` |
| `lg` | `0 8px 24px shadow` | `0 8px 24px shadow` |
| `xl` | `0 16px 48px shadow` | `0 16px 48px shadow` |
| `glow` | `0 0 24px primary.withOpacity(0.25)` | same |

### 1F. Animation Tokens

| Token | Duration | Curve |
|---|---|---|
| `instant` | 100ms | `easeOut` |
| `fast` | 200ms | `easeInOut` |
| `normal` | 300ms | `easeInOutCubic` |
| `slow` | 500ms | `easeInOutCubic` |
| `dramatic` | 800ms | `easeInOutQuint` |
| `spring` | 600ms | `Curves.elasticOut` |

---

## 2. REUSABLE WIDGETS TO BUILD

### Core Widgets (one per file)
```
lib/core/widgets/
├── buttons/
│   ├── gradient_button.dart       — gradient bg, press-scale, haptic, loading state
│   ├── outline_button.dart        — outlined variant
│   ├── icon_action_button.dart    — circular icon button with optional badge
│   ├── toggle_switch.dart         — animated iOS-style toggle
│   └── swipe_button.dart          — swipe-to-confirm (driver actions)
├── cards/
│   ├── glass_card.dart            — frosted glass with blur + translucent bg
│   ├── gradient_card.dart         — gradient background card
│   ├── vehicle_card.dart          — redesigned with illustration, badge, glow
│   └── trip_card.dart             — timeline-style trip summary
├── inputs/
│   ├── app_text_field.dart        — rounded, animated label, prefix/suffix
│   ├── otp_field.dart             — auto-reading boxes with shake + checkmark
│   ├── phone_field.dart           — country code chip + flag
│   └── search_field.dart          — glass-style search bar
├── feedback/
│   ├── app_toast.dart             — custom top toast (replaces snackbar)
│   ├── skeleton_loader.dart       — shimmer skeleton for any shape
│   ├── rating_stars.dart          — interactive stars with emoji reactions
│   └── status_chip.dart           — color-coded pill badge
├── layout/
│   ├── app_bottom_sheet.dart      — rounded 24px, drag handle, glass option
│   ├── section_header.dart        — title + "See All" action
│   └── app_scaffold.dart          — scaffold with gradient app bar option
├── animations/
│   ├── animated_counter.dart      — smooth number counting
│   ├── pulse_dot.dart             — pulsing indicator
│   ├── radar_pulse.dart           — expanding radar rings
│   └── confetti_overlay.dart      — confetti on trip complete
└── common/
    ├── empty_state.dart           — Lottie + message + CTA
    ├── error_state.dart           — Lottie + message + retry
    ├── avatar_widget.dart         — circular avatar with online indicator
    └── stepper_widget.dart        — vertical stepper with animated progress
```

### Theme Provider
```
lib/core/theme/
├── app_colors.dart        — AppColors with light/dark switching via ThemeExtension
├── app_typography.dart    — Poppins headings + Inter body
├── app_shadows.dart       — BoxShadow presets
├── app_theme.dart         — ThemeData.light() and ThemeData.dark()
└── theme_provider.dart    — Riverpod: system/light/dark toggle, persisted
```

---

## 3. PACKAGES TO ADD

| Package | Purpose |
|---|---|
| `confetti_widget: ^0.4.0` | Trip complete confetti |
| `fl_chart: ^0.69.0` | Driver earnings charts |
| `flutter_haptic: ^0.0.1` OR `vibration: ^1.8.3` | Haptic feedback (use HapticFeedback from services) |
| `animations: ^2.0.8` | Page transitions (shared-axis, fade-through) |
| `flutter_native_splash` (dev) | Native splash screen |
| `flutter_launcher_icons` (dev) | App icon generation |

Already present: `flutter_animate`, `lottie`, `shimmer`, `google_fonts`, `flutter_svg`.

---

## 4. ASSETS REQUIRED

### Lottie Animations (`assets/animations/`)
Source: LottieFiles.com (free tier)

| File | Usage | Suggested search |
|---|---|---|
| `splash_logo.json` | Splash screen logo reveal | "delivery truck animation" |
| `onboarding_1.json` | Booking slide | "package delivery" |
| `onboarding_2.json` | Tracking slide | "location tracking" |
| `onboarding_3.json` | Pricing slide | "payment secure" |
| `searching_driver.json` | Finding driver radar | "radar pulse search" |
| `no_driver.json` | No drivers found | "empty search sad" |
| `payment_success.json` | Payment successful | "payment success checkmark" |
| `trip_complete.json` | Trip completed | "delivery complete celebration" |
| `empty_trips.json` | No trips | "empty box" |
| `empty_wallet.json` | Empty wallet | "empty wallet" |
| `loading.json` | Generic loader | "loading dots orange" |
| `error.json` | Error state | "error warning" |
| `location_pin.json` | Map pin bounce | "location pin bounce" |
| `confetti.json` | Celebration | "confetti party" |

### Vehicle Icons (`assets/icons/`)
Source: Flaticon or custom SVG

| File | Description |
|---|---|
| `ic_bike.svg` | Delivery bike illustration |
| `ic_three_wheeler.svg` | Tata Ace / 3-wheeler |
| `ic_mini_truck.svg` | Mini truck 8ft |
| `ic_pickup.svg` | Pickup 9ft |
| `ic_logo.svg` | PickDrop logo |
| `ic_google.svg` | Google login (if needed) |

### Map Styles (`assets/map/`)
| File | Description |
|---|---|
| `map_light.json` | Custom light map style |
| `map_dark.json` | Custom dark map style |

---

## 5. EXECUTION STEPS (Sequential)

### Step 1: Design System Foundation ✅ DO FIRST
1. Update `colors.dart` → new palette with ThemeExtension for light/dark
2. Update `dimensions.dart` → new spacing + radius tokens
3. Rewrite `text_styles.dart` → Poppins headings + Inter body
4. Rewrite `app_theme.dart` → full light + dark ThemeData
5. Create `theme_provider.dart` → Riverpod theme mode toggle
6. Update `app_constants.dart` → new animation tokens
7. Add new packages to `pubspec.yaml`
8. Add `confetti_widget`, `fl_chart`, `animations`
9. **Run `flutter analyze`, fix all errors**

### Step 2: Reusable Widgets (Foundation)
1. `GradientButton` — gradient bg, scale animation, haptic, loading spinner
2. `GlassCard` — BackdropFilter + translucent surface
3. `AppBottomSheet` — rounded, drag handle, glass variant
4. `AppTextField` — new rounded style matching design
5. `SkeletonLoader` — shimmer placeholder for any widget shape
6. `StatusChip` — color-coded pill
7. `RatingStars` — interactive + emoji reactions
8. `EmptyState` — Lottie + friendly message + CTA
9. `AppToast` — top overlay toast replacing snackbar
10. `AnimatedCounter` — smooth number counting with currency prefix
11. **Run `flutter analyze`, fix all errors**

### Step 3: Fix Existing Compile Errors
1. Fix `AppLocalizations` import issue
2. Fix `formatDateTime()` extension call
3. Fix `PlacesSearchResult` / `GoogleMapsPlaces` imports
4. Fix `appRouterProvider` code-gen issue
5. Fix `AnimatedBuilder` → `AnimatedBuilder` typo in common.dart
6. Remove unused imports
7. **Run `flutter analyze` — must be 0 errors**

### Step 4: Update main.dart + Theme Toggle
1. Wire dark theme into MaterialApp
2. Add theme mode provider
3. System-follow by default
4. **Run `flutter analyze`**

### Step 5–12: Screen-by-Screen Redesign
Each screen: redesign → analyze → fix → move on.

5. Splash + Onboarding
6. Phone Login + OTP
7. Role Selection + Profile Creation
8. Customer Home (full-screen map, glass card, bottom sheet)
9. Pickup/Drop Selection (timeline inputs, animated pin)
10. Vehicle Selection (large cards, glow, badge, fare expander)
11. Booking Details + Finding Driver + Live Tracking
12. Trip Complete + Rating

### Step 13–15: Missing Screens
13. My Trips, Wallet, Coupons, Saved Addresses, Profile, Help
14. Driver: Onboarding, Home redesign, Incoming Request, Active Trip, Earnings
15. Common: Map Picker, Places Search, Payment, Ratings

### Step 16: Polish
1. Skeleton shimmer everywhere
2. Custom top toasts
3. Pull-to-refresh
4. Haptic feedback
5. Safe-area + tablet responsiveness
6. Accessibility (48px targets, contrast AA)
7. App icon + native splash
8. **Final `flutter analyze` — 0 errors**

---

## 6. FILE SIZE RULE
No screen file over 300 lines. Extract into:
- Private widgets in same directory
- Shared widgets in `core/widgets/`
- Business logic into providers

---

## 7. DEFINITION OF DONE
- [ ] Light + dark mode both polished
- [ ] All screens redesigned with glassmorphism, animations, gradients
- [ ] 60fps, no jank
- [ ] `flutter analyze` = 0 issues
- [ ] Every new package documented
- [ ] Every required asset listed with source
- [ ] No placeholder UI — all screens functional
