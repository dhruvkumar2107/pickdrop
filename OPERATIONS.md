# Project setup and first-run operations

Project target: `pickdrop-dk2107` (verify the selected Google Cloud/Firebase project before changing remote state).

## Release build configuration

The Android release workflow creates the ignored `.env` asset and `google_maps_key` resource from GitHub Actions secrets, then fails early when any client setting is missing. Configure `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`, a package/SHA-1-restricted `GOOGLE_MAPS_API_KEY`, and `RAZORPAY_KEY_ID` in repository Actions secrets. Keep all Razorpay secrets and webhook secrets in Firebase Secret Manager; never add them to GitHub Actions client configuration.

## Grant the first administrator claim

Use the trusted Firebase Auth UID, not an email address. Authenticate the Firebase Admin SDK with Application Default Credentials or a service account that has Firebase Authentication administrator permissions. Keep service-account JSON outside this repository and never commit it.

PowerShell example:

```powershell
$env:PICKDROP_FIREBASE_PROJECT_ID = 'pickdrop-dk2107'
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\secure\pickdrop-admin-service-account.json'
Set-Location functions
npm run grant-admin -- '<trusted-firebase-auth-uid>'
```

The script preserves existing custom claims and adds `role=admin`. The user must refresh their Firebase ID token before opening `/admin/review`.

## Configure sandbox Functions secrets

Add secrets through Firebase Secret Manager, not `.env` or source control. Configure the Razorpay sandbox key ID/secret and webhook secret, the RazorpayX sandbox credentials/account number/webhook secret if payout testing is enabled, the restricted server-side Google Routes key, and a separate server-side `GOOGLE_PLACES_SERVER_KEY` restricted to Places API (New). Deploy the Functions that declare each secret before exercising the flow. Register signed webhook endpoints for captured wallet payments and payout processed/failed/reversed events. Place Autocomplete uses a per-search session token that is also passed to Place Details to group billing for that search session, following Google's current Places API guidance ([Autocomplete session tokens](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete#session-tokens)).

## Initialize and review vehicle prices

After deploying callable Functions and granting the admin claim, open `/admin/review`, select **Initialize catalog**, and inspect every rate in **Starter vehicle prices (INR)**. The seed operation only creates missing vehicle rows; it does not overwrite existing prices. Edit existing rows in the admin screen after agreeing the city-specific fare card, driver payout economics, taxes, stop charges, and commission.

Current defaults are provisional. [Porter’s public two-wheeler page](https://porter.in/two-wheelers) lists a ₹48 starting fare inclusive of 1 km and 25 minutes, with locality-based variation. PickDrop’s current formula charges per-kilometre and per-minute from the first unit and adds GST, so it is not a like-for-like quote. The bike starter time rate was reduced to ₹0.25/min as a provisional calibration; validate it with local driver costs and actual test quotes before accepting bookings.

## Payment validation

Use only sandbox credentials for wallet top-up, COD/online booking transitions, payout review, and webhook replay. Validate idempotency and failure/reconciliation cases. Do not approve any payout against live credentials during sandbox testing.
