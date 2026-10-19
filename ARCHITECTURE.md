# Architecture

Flutter is a presentation client only. Firebase Authentication identifies the caller. Callable Cloud Functions are authoritative for fare calculation, booking creation, booking transitions, dispatch, and payment initiation. Firestore is the read model; clients must not write bookings or payments directly. Cloud Functions use Admin SDK writes.

```text
Customer/Driver app -> Firebase Auth + App Check -> Callable Function
Callable Function -> Firestore transaction -> booking/payment read model
Booking create -> dispatch worker -> driver offer -> authenticated accept
Razorpay order/webhook -> server verification -> payment record/status
Admin operations -> privileged server/admin panel only
```

Current implementation gaps: App Check is not initialized/enforced; payment webhook is not implemented; several non-booking collections retain unsafe client writes. Do not launch before resolving these gaps.