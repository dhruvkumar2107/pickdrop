import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { Firestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getConfig, AppConfig } from './config';
import {
  calculateFare,
  GeoPoint,
} from './fare';
import { encodeGeohash } from './geohash';
import { generateOtp, verifyOtp } from './otp';
import { runDriverMatching } from './matching';
import { calculateRoadRoute, googleMapsServerKey } from './routing';

interface CreateBookingRequest {
  pickup: GeoPoint;
  drop: GeoPoint;
  vehicleTypeId: string;
  paymentMethod: 'razorpay' | 'cod' | 'wallet';
  notes?: string;
  pickupAddress?: string;
  dropAddress?: string;
  goodsType?: string;
  loadingHelper?: boolean;
  couponCode?: string;
  helperLocations?: string[];
  returnTrip?: boolean;
  transitInsurance?: boolean;
  referralCode?: string;
  expectedTotal?: number;
  stops?: Array<{ address: string; lat: number; lng: number }>;
}

interface BookingStatusData {
  status: string;
  customerId: string;
  driverId?: string;
  assignedAt?: Timestamp;
  [key: string]: unknown;
}

const requireAuth = (request: { auth?: { uid: string } }): string => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return request.auth.uid;
};

/**
 * Accepts a driver-uploaded goods photo only at the booking's expected
 * Storage path (Storage rules restrict that path to the assigned driver).
 */
async function verifiedProofPath(bookingId: string, kind: 'pickup' | 'drop', provided: unknown): Promise<string | null> {
  if (provided === undefined || provided === null || provided === '') return null;
  const expected = `bookingProofs/${bookingId}/${kind}.jpg`;
  if (provided !== expected) throw new HttpsError('invalid-argument', 'Unexpected proof photo location.');
  const [exists] = await getStorage().bucket().file(expected).exists();
  if (!exists) throw new HttpsError('failed-precondition', 'Proof photo upload did not complete. Retake the photo.');
  return expected;
}

/** Loads pricing for a vehicle type from `vehicleTypes/{id}`. */
export async function getVehiclePricing(
  db: Firestore,
  vehicleTypeId: string,
): Promise<{ id: string; name: string; baseFare: number; perKmRate: number; perMinuteRate: number; minimumFare: number; surgeMultiplier?: number }> {
  const snap = await db.collection('vehicleTypes').doc(vehicleTypeId).get();
  const data = snap.data();
  if (!snap.exists || !data) {
    throw new HttpsError('invalid-argument', 'Unknown vehicle type.');
  }
  return {
    id: snap.id,
    name: String(data.name ?? ''),
    baseFare: Number(data.baseFare ?? 0),
    perKmRate: Number(data.perKmRate ?? 0),
    perMinuteRate: Number(data.perMinuteRate ?? 0),
    minimumFare: Number(data.minimumFare ?? 0),
    surgeMultiplier: Number(data.surgeMultiplier ?? 1),
  };
}

/**
 * Creates a booking document (status SEARCHING), computes the fare
 * server-side, generates pickup/drop OTPs, and kicks off driver matching
 * via the onCreate trigger.
 */
export const createBooking = onCall<CreateBookingRequest>({ secrets: [googleMapsServerKey] }, async (request) => {
  const uid = requireAuth(request);
  const data = request.data;
  if (!data?.pickup || !data?.drop || !data.vehicleTypeId) {
    throw new HttpsError('invalid-argument', 'pickup, drop and vehicleTypeId are required.');
  }
  const validPoint = (point: GeoPoint) =>
    Number.isFinite(point?.lat) && Number.isFinite(point?.lng) &&
    point.lat >= -90 && point.lat <= 90 && point.lng >= -180 && point.lng <= 180;
  if (!validPoint(data.pickup) || !validPoint(data.drop)) {
    throw new HttpsError('invalid-argument', 'Pickup and drop coordinates are invalid.');
  }
  if (!['razorpay', 'cod', 'wallet'].includes(data.paymentMethod)) {
    throw new HttpsError('invalid-argument', 'Unsupported payment method.');
  }
  if (typeof data.notes === 'string' && data.notes.length > 1000) {
    throw new HttpsError('invalid-argument', 'Notes must be 1000 characters or fewer.');
  }

  const db = getFirestore();
  const config = await getConfig(db);
  const vehicle = await getVehiclePricing(db, data.vehicleTypeId);

  const stops = Array.isArray(data.stops) ? data.stops : [];
  if (stops.length > 5 || stops.some((p) => !validPoint(p) || typeof p.address !== 'string' || !p.address.trim())) {
    throw new HttpsError('invalid-argument', 'Use up to five stops with a label and valid map position.');
  }
  const roadRoute = await calculateRoadRoute([data.pickup, ...stops, data.drop]);
  const distanceKm = roadRoute.distanceKm;
  if (distanceKm < 0.05) {
    throw new HttpsError('failed-precondition', 'Pickup and drop are too close.');
  }

  const durationMinutes = roadRoute.durationMinutes;
  const fare = calculateFare({
    vehicle,
    distanceKm,
    durationMinutes,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    gstPercent: config.gstPercent,
  });

  const helpers = Array.isArray(data.helperLocations)
    ? [...new Set(data.helperLocations.filter((x) => x === 'pickup' || x === 'drop'))]
    : [];
  const helperFee = helpers.length === 2 ? 149 : helpers.length === 1 ? 79 : 0;
  const returnTripFee = data.returnTrip === true ? fare.distanceFare : 0;
  if (data.transitInsurance === true && config.transitInsuranceEnabled !== true) {
    throw new HttpsError('failed-precondition', 'Transit insurance is not available yet.');
  }
  const insuranceFee = data.transitInsurance === true ? 29 : 0;
  const stopFee = stops.length * config.multiStopFee;
  const pricingSubtotal = fare.subtotal + stopFee;
  const stopGst = Math.round((stopFee * config.gstPercent) / 100 * 100) / 100;

  let couponRef: FirebaseFirestore.DocumentReference | undefined;
  let couponDiscount = 0;
  const couponCode = String(data.couponCode ?? '').trim().toUpperCase();
  if (couponCode) {
    const couponQuery = await db.collection('coupons').where('code', '==', couponCode).limit(1).get();
    const couponDoc = couponQuery.docs[0];
    const coupon = couponDoc?.data();
    const now = Date.now();
    if (!couponDoc || !coupon || coupon.isActive !== true ||
        !(coupon.validFrom?.toMillis?.() <= now) || !(coupon.validUntil?.toMillis?.() >= now) ||
        Number(coupon.usedCount ?? 0) >= Number(coupon.usageLimit ?? 0) ||
        pricingSubtotal < Number(coupon.minOrderValue ?? 0) ||
        (Array.isArray(coupon.applicableVehicleTypes) && coupon.applicableVehicleTypes.length > 0 &&
         !coupon.applicableVehicleTypes.includes(data.vehicleTypeId))) {
      throw new HttpsError('failed-precondition', 'Coupon is invalid or no longer available.');
    }
    const rawDiscount = coupon.type === 'percentage'
      ? pricingSubtotal * Number(coupon.value ?? 0) / 100
      : Number(coupon.value ?? 0);
    couponDiscount = Math.min(rawDiscount, Number(coupon.maxDiscount ?? rawDiscount), pricingSubtotal);
    couponRef = couponDoc.ref;
  }
  const additionalCharges = helperFee + returnTripFee + insuranceFee + stopFee;
  const total = Math.max(0, Math.round((fare.total + additionalCharges + stopGst - couponDiscount) * 100) / 100);
  if (!Number.isFinite(data.expectedTotal) || Math.abs(Number(data.expectedTotal) - total) > 0.01) {
    throw new HttpsError('failed-precondition', 'The fare changed. Review the updated quote before booking.');
  }
  const authoritativeFare = {
    ...fare,
    subtotal: pricingSubtotal,
    gst: Math.round((fare.gst + stopGst) * 100) / 100,
    helperFee,
    returnTripFee,
    insuranceFee,
    stopFee,
    discount: couponDiscount,
    couponCode: couponCode || null,
    total,
  };

  const bookingRef = db.collection('bookings').doc();
  const referralCode = String(data.referralCode ?? '').trim().toUpperCase();
  const referralCodeRef = referralCode ? db.collection('referralCodes').doc(referralCode) : null;
  const referralCodeSnap = referralCodeRef ? await referralCodeRef.get() : null;
  const referrerId = referralCodeSnap?.data()?.ownerId as string | undefined;
  if (referralCode && (!referrerId || referrerId === uid)) {
    throw new HttpsError('failed-precondition', 'That referral code is invalid or belongs to your account.');
  }
  const referralClaimRef = referrerId ? db.collection('referralClaims').doc(uid) : null;
  const pickupOtp = generateOtp();
  const dropOtp = generateOtp();
  const stopOtps = stops.map(() => generateOtp());
  const bookingSecretsRef = db.collection('bookingSecrets').doc(bookingRef.id);
  const walletRef = data.paymentMethod === 'wallet' ? db.collection('wallets').doc(uid) : null;
  const walletTxnRef = data.paymentMethod === 'wallet' ? db.collection('walletTransactions').doc(`booking_${bookingRef.id}`) : null;
  const customerProfile = await db.collection('users').doc(uid).get();
  // First name only: drivers see who to meet without receiving more personal data.
  const customerName = String(customerProfile.data()?.displayName ?? '').trim().split(/\s+/)[0].slice(0, 40);
  const bookingData = {
    customerId: uid,
    customerName,
    driverId: null,
    status: data.paymentMethod === 'razorpay' ? 'AWAITING_PAYMENT' : 'SEARCHING',
    vehicleTypeId: data.vehicleTypeId,
    pickup: {
      address: data.pickupAddress ?? '',
      lat: data.pickup.lat,
      lng: data.pickup.lng,
      geohash: encodeGeohash(data.pickup.lat, data.pickup.lng),
    },
    drop: {
      address: data.dropAddress ?? '',
      lat: data.drop.lat,
      lng: data.drop.lng,
      geohash: encodeGeohash(data.drop.lat, data.drop.lng),
    },
    intermediateStops: stops.map((stop, index) => ({
      sequence: index + 1,
      address: stop.address.trim().slice(0, 300),
      lat: stop.lat,
      lng: stop.lng,
      geohash: encodeGeohash(stop.lat, stop.lng),
      otpVerified: false,
    })),
    distanceKm,
    estimatedDurationMin: durationMinutes,
    fareBreakdown: { ...authoritativeFare, gst: Math.round((fare.gst + stopGst) * 100) / 100 },
    paymentMethod: data.paymentMethod ?? 'razorpay',
    paymentStatus: data.paymentMethod === 'wallet' ? 'paid' : 'pending',
    goodsType: String(data.goodsType ?? '').slice(0, 120),
    notes: data.notes ?? '',
    loadingHelper: data.loadingHelper === true,
    helperLocations: helpers,
    returnTrip: data.returnTrip === true,
    transitInsurance: data.transitInsurance === true,
    cancellationFee: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };
  await db.runTransaction(async (tx) => {
    const [walletSnap, referralClaimSnap] = await Promise.all([
      walletRef ? tx.get(walletRef) : Promise.resolve(null),
      referralClaimRef ? tx.get(referralClaimRef) : Promise.resolve(null),
    ]);
    if (referralClaimSnap?.exists && referralClaimSnap.data()?.referrerId !== referrerId) {
      throw new HttpsError('failed-precondition', 'A different referral code has already been applied to your account.');
    }
    if (couponRef) {
      const couponSnap = await tx.get(couponRef);
      const current = couponSnap.data();
      if (!current || current.isActive !== true ||
          Number(current.usedCount ?? 0) >= Number(current.usageLimit ?? 0)) {
        throw new HttpsError('failed-precondition', 'Coupon has just reached its usage limit.');
      }
      tx.update(couponRef, { usedCount: Number(current.usedCount ?? 0) + 1 });
    }
    if (walletRef && walletTxnRef) {
      const balance = Number(walletSnap?.data()?.balance ?? 0);
      if (balance < total) throw new HttpsError('failed-precondition', 'Your wallet balance is too low for this delivery. Add funds or choose another payment method.');
      tx.set(walletRef, { userId: uid, balance: Math.round((balance - total) * 100) / 100, updatedAt: Timestamp.now() }, { merge: true });
      tx.create(walletTxnRef, { userId: uid, type: 'DEBIT', amount: total, status: 'SUCCESS', bookingId: bookingRef.id, createdAt: Timestamp.now() });
    }
    tx.create(bookingRef, bookingData);
    if (referralClaimRef && !referralClaimSnap?.exists) {
      tx.create(referralClaimRef, { userId: uid, referrerId, code: referralCode, status: 'PENDING', createdAt: Timestamp.now() });
    }
    tx.create(bookingSecretsRef, {
      customerId: uid,
      pickupOtp,
      dropOtp,
      intermediateStopOtps: Object.fromEntries(stopOtps.map((code, index) => [String(index + 1), code])),
      createdAt: Timestamp.now(),
    });
  });

  return { bookingId: bookingRef.id, fare: authoritativeFare };
});

interface CreateScheduledBookingRequest extends CreateBookingRequest {
  vehicleType?: string;
  scheduledAt: number;
}

export const createScheduledBooking = onCall<CreateScheduledBookingRequest>({ secrets: [googleMapsServerKey] }, async (request) => {
  const uid = requireAuth(request);
  const data = request.data;
  if (!data?.pickup || !data?.drop || !data.vehicleTypeId || !Number.isFinite(data.scheduledAt)) {
    throw new HttpsError('invalid-argument', 'Pickup, drop, vehicle type and scheduled time are required.');
  }
  const validPoint = (point: GeoPoint) => Number.isFinite(point?.lat) && Number.isFinite(point?.lng) &&
    point.lat >= -90 && point.lat <= 90 && point.lng >= -180 && point.lng <= 180;
  if (!validPoint(data.pickup) || !validPoint(data.drop)) {
    throw new HttpsError('invalid-argument', 'Pickup and drop coordinates are invalid.');
  }
  const scheduledAt = Timestamp.fromMillis(data.scheduledAt);
  if (scheduledAt.toMillis() < Date.now() + 45 * 60 * 1000 || scheduledAt.toMillis() > Date.now() + 30 * 24 * 60 * 60 * 1000) {
    throw new HttpsError('failed-precondition', 'Choose a pickup at least 45 minutes and no more than 30 days from now.');
  }
  const db = getFirestore();
  const vehicle = await getVehiclePricing(db, data.vehicleTypeId);
  const stops = Array.isArray(data.stops) ? data.stops : [];
  if (stops.length > 5 || stops.some((stop) => !validPoint(stop) || typeof stop.address !== 'string' || !stop.address.trim())) {
    throw new HttpsError('invalid-argument', 'Use up to five stops with a label and valid map position.');
  }
  const roadRoute = await calculateRoadRoute([data.pickup, ...stops, data.drop]);
  const distanceKm = roadRoute.distanceKm;
  if (distanceKm < 0.05) throw new HttpsError('failed-precondition', 'Pickup and drop are too close.');
  const config = await getConfig(db);
  const baseFare = calculateFare({
    vehicle,
    distanceKm,
    durationMinutes: roadRoute.durationMinutes,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    gstPercent: config.gstPercent,
  });
  const stopFee = stops.length * config.multiStopFee;
  const stopGst = Math.round(stopFee * config.gstPercent) / 100;
  const fare = { ...baseFare, stopFee, subtotal: baseFare.subtotal + stopFee, gst: Math.round((baseFare.gst + stopGst) * 100) / 100, total: Math.round((baseFare.total + stopFee + stopGst) * 100) / 100 };
  const ref = db.collection('scheduledBookings').doc();
  const code = String(data.referralCode ?? '').trim().toUpperCase();
  const codeSnap = code ? await db.collection('referralCodes').doc(code).get() : null;
  const referrerId = codeSnap?.data()?.ownerId as string | undefined;
  if (code && (!referrerId || referrerId === uid)) throw new HttpsError('failed-precondition', 'That referral code is invalid or belongs to your account.');
  const claimRef = referrerId ? db.collection('referralClaims').doc(uid) : null;
  const scheduledData = {
    customerId: uid,
    scheduledAt,
    pickupLat: data.pickup.lat,
    pickupLng: data.pickup.lng,
    pickupAddress: data.pickupAddress ?? '',
    dropLat: data.drop.lat,
    dropLng: data.drop.lng,
    dropAddress: data.dropAddress ?? '',
    vehicleTypeId: data.vehicleTypeId,
    vehicleType: data.vehicleType ?? vehicle.name,
    intermediateStops: stops.map((stop, index) => ({
      sequence: index + 1,
      address: stop.address.trim().slice(0, 300),
      lat: stop.lat,
      lng: stop.lng,
      geohash: encodeGeohash(stop.lat, stop.lng),
      otpVerified: false,
    })),
    distanceKm,
    estimatedDurationMin: roadRoute.durationMinutes,
    goodsType: String(data.goodsType ?? '').slice(0, 120),
    estimatedFare: fare.total,
    fareBreakdown: fare,
    status: 'SCHEDULED',
    assignedDriverId: '',
    createdAt: Timestamp.now(),
  };
  await db.runTransaction(async (tx) => {
    const claim = claimRef ? await tx.get(claimRef) : null;
    if (claim?.exists && claim.data()?.referrerId !== referrerId) {
      throw new HttpsError('failed-precondition', 'A different referral code has already been applied to your account.');
    }
    tx.create(ref, scheduledData);
    if (claimRef && !claim?.exists) tx.create(claimRef, { userId: uid, referrerId, code, status: 'PENDING', createdAt: Timestamp.now() });
  });
  return { scheduledBookingId: ref.id, customerId: uid, estimatedFare: fare.total };
});

export const cancelScheduledBooking = onCall<{ scheduledBookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const id = request.data?.scheduledBookingId;
  if (!id) throw new HttpsError('invalid-argument', 'scheduledBookingId is required.');
  const ref = getFirestore().collection('scheduledBookings').doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Scheduled booking not found.');
    const data = snap.data()!;
    if (data.customerId !== uid) throw new HttpsError('permission-denied', 'Not your scheduled booking.');
    if (data.status !== 'SCHEDULED') throw new HttpsError('failed-precondition', 'This booking can no longer be cancelled here.');
    tx.update(ref, { status: 'CANCELLED', cancelledAt: Timestamp.now() });
  });
  return { cancelled: true };
});

/** Firestore trigger: starts cascade matching when a booking appears. */
export const onBookingCreated = onDocumentCreated(
  'bookings/{bookingId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as BookingStatusData;
    if (data.status !== 'SEARCHING') return;

    const db = getFirestore();
    const config = await getConfig(db);
    const pickup = snap.data().pickup as { lat: number; lng: number };
    await runDriverMatching(
      db,
      { id: event.params.bookingId, pickup: { lat: pickup.lat, lng: pickup.lng } },
      config,
    );
  },
);

/** Online bookings enter dispatch only after the verified payment succeeds. */
export const onBookingPaymentReady = onDocumentUpdated(
  'bookings/{bookingId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status || after.status !== 'SEARCHING') return;
    const paidOnlineBooking = before.status === 'AWAITING_PAYMENT' && after.paymentStatus === 'paid';
    const driverRematch = after.rematchBoost === true;
    if (!paidOnlineBooking && !driverRematch) return;
    const pickup = after.pickup as { lat: number; lng: number } | undefined;
    if (!pickup) return;
    const db = getFirestore();
    const config = await getConfig(db);
    await runDriverMatching(db, {
      id: event.params.bookingId,
      pickup: { lat: pickup.lat, lng: pickup.lng },
    }, config);
  },
);

/**
 * Driver taps "Accept" on the offer screen. Marks the offer ACCEPTED —
 * runDriverMatching then finalises DRIVER_ASSIGNED in its transaction.
 */
export const acceptOffer = onCall<{ bookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const bookingId = request.data?.bookingId;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');

  const db = getFirestore();
  const driverSnap = await db.collection('drivers').doc(uid).get();
  if (!driverSnap.exists || driverSnap.data()?.isVerified !== true || driverSnap.data()?.isOnline !== true) {
    throw new HttpsError('permission-denied', 'A verified online driver account is required.');
  }
  const offerRef = db.collection('driverOffers').doc(`${bookingId}_${uid}`);
  const offer = await offerRef.get();
  if (!offer.exists || offer.data()?.status !== 'PENDING') {
    throw new HttpsError('failed-precondition', 'Offer no longer available.');
  }
  await offerRef.update({ status: 'ACCEPTED', acceptedAt: Timestamp.now() });
  return { ok: true };
});

/** Driver rejects the offer (cascade moves to the next driver). */
export const rejectOffer = onCall<{ bookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const bookingId = request.data?.bookingId;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');
  const db = getFirestore();
  const offerRef = db.collection('driverOffers').doc(`${bookingId}_${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(offerRef);
    if (!snap.exists || snap.data()?.status !== 'PENDING') return;
    tx.update(offerRef, { status: 'REJECTED', rejectedAt: Timestamp.now() });
  });
  return { ok: true };
});

/** Driver enters the customer's pickup OTP → status PICKED_UP. */
export const verifyPickupOtp = onCall<{ bookingId: string; otp: string; proofPath?: string }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, otp } = request.data ?? {};
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');
  const proofPath = await verifiedProofPath(bookingId, 'pickup', request.data?.proofPath);
  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const secretsRef = db.collection('bookingSecrets').doc(bookingId);
  await db.runTransaction(async (tx) => {
    const [snap, secretSnap] = await Promise.all([tx.get(bookingRef), tx.get(secretsRef)]);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = snap.data() as BookingStatusData & { driverId?: string };
    if (booking.driverId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
    if (booking.status !== 'DRIVER_ASSIGNED') {
      throw new HttpsError('failed-precondition', `Cannot pick up from status ${booking.status}.`);
    }
    const storedPickupOtp = secretSnap.data()?.pickupOtp ?? (snap.data()?.pickup as Record<string, any> | undefined)?.otp;
    if (!verifyOtp(String(storedPickupOtp ?? ''), String(otp ?? ''))) {
      throw new HttpsError('invalid-argument', 'Incorrect pickup OTP.');
    }
    tx.update(bookingRef, {
      status: 'PICKED_UP',
      pickupOtpVerifiedAt: Timestamp.now(),
      tripStartedAt: Timestamp.now(),
      ...(proofPath ? { pickupProofPath: proofPath } : {}),
      updatedAt: Timestamp.now(),
    });
  });
  return { ok: true };
});

/** Driver verifies intermediate drop-offs in sequence before final delivery. */
export const verifyIntermediateStopOtp = onCall<{ bookingId: string; otp: string; sequence: number }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, otp, sequence } = request.data ?? {};
  if (!bookingId || !Number.isInteger(sequence) || sequence < 1) throw new HttpsError('invalid-argument', 'bookingId and stop sequence are required.');
  const bookingRef = getFirestore().collection('bookings').doc(bookingId);
  const secretsRef = getFirestore().collection('bookingSecrets').doc(bookingId);
  await getFirestore().runTransaction(async (tx) => {
    const [snap, secretSnap] = await Promise.all([tx.get(bookingRef), tx.get(secretsRef)]);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = snap.data()!;
    if (booking.driverId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
    if (booking.status !== 'PICKED_UP') throw new HttpsError('failed-precondition', 'The trip must be in progress.');
    const stops = Array.isArray(booking.intermediateStops) ? booking.intermediateStops as Array<Record<string, any>> : [];
    const pending = stops.find((stop) => stop.otpVerified !== true);
    if (!pending || pending.sequence !== sequence) throw new HttpsError('failed-precondition', 'Intermediate stops must be completed in order.');
    const stopCodes = secretSnap.data()?.intermediateStopOtps ?? {};
    if (!verifyOtp(String(stopCodes[String(sequence)] ?? pending.otp ?? ''), String(otp ?? ''))) throw new HttpsError('invalid-argument', 'Incorrect stop OTP.');
    const updated = stops.map((stop) => stop.sequence === sequence ? { ...stop, otpVerified: true, otpVerifiedAt: Timestamp.now() } : stop);
    tx.update(bookingRef, { intermediateStops: updated, updatedAt: Timestamp.now() });
  });
  return { ok: true };
});

/** Driver enters the drop OTP → status DELIVERED (trip complete). */
export const verifyDropOtp = onCall<{ bookingId: string; otp: string; proofPath?: string }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, otp } = request.data ?? {};
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');
  const proofPath = await verifiedProofPath(bookingId, 'drop', request.data?.proofPath);
  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const secretsRef = db.collection('bookingSecrets').doc(bookingId);
  const driverRef = db.collection('drivers').doc(uid);
  await db.runTransaction(async (tx) => {
    const [snap, secretSnap] = await Promise.all([tx.get(bookingRef), tx.get(secretsRef)]);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = snap.data() as BookingStatusData & { driverId?: string };
    if (booking.driverId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
    if (booking.status !== 'PICKED_UP') {
      throw new HttpsError('failed-precondition', `Cannot complete from status ${booking.status}.`);
    }
    if (Array.isArray(booking.intermediateStops) && booking.intermediateStops.some((stop: Record<string, any>) => stop.otpVerified !== true)) {
      throw new HttpsError('failed-precondition', 'Verify all intermediate stop codes before final delivery.');
    }
    const storedDropOtp = secretSnap.data()?.dropOtp ?? (snap.data()?.drop as Record<string, any> | undefined)?.otp;
    if (!verifyOtp(String(storedDropOtp ?? ''), String(otp ?? ''))) {
      throw new HttpsError('invalid-argument', 'Incorrect drop OTP.');
    }
    const driverSnap = await tx.get(driverRef);
    if (driverSnap.data()?.activeBookingId === bookingId) {
      tx.update(driverRef, { activeBookingId: FieldValue.delete(), updatedAt: Timestamp.now() });
    }
    tx.update(bookingRef, {
      status: 'DELIVERED',
      dropOtpVerifiedAt: Timestamp.now(),
      completedAt: Timestamp.now(),
      ...(proofPath ? { deliveryProofPath: proofPath } : {}),
      updatedAt: Timestamp.now(),
    });
  });
  return { ok: true };
});

/**
 * Customer (or driver before assignment) cancels. Free within
 * `cancellationFreeWindowMinutes` of assignment; otherwise a fee applies.
 */
export const cancelBooking = onCall<{ bookingId: string; reason?: string }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, reason } = request.data ?? {};
  const db = getFirestore();
  const config: AppConfig = await getConfig(db);
  const bookingRef = db.collection('bookings').doc(bookingId);
  const snap = await bookingRef.get();

  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
  const booking = snap.data() as BookingStatusData;
  if (booking.customerId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
  if (['DELIVERED', 'CANCELLED'].includes(booking.status)) {
    throw new HttpsError('failed-precondition', `Cannot cancel from status ${booking.status}.`);
  }

  let cancellationFee = 0;
  if (booking.status !== 'SEARCHING' && booking.driverAssignedAt instanceof Timestamp) {
    const assignedMs = booking.driverAssignedAt.toMillis();
    const elapsedMin = (Date.now() - assignedMs) / 60000;
    if (elapsedMin > config.cancellationFreeWindowMinutes) {
      cancellationFee = config.cancellationFeeAfterAssignment;
    }
  }

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(bookingRef);
    if (!freshSnap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const fresh = freshSnap.data() as BookingStatusData;
    if (fresh.customerId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
    if (['DELIVERED', 'CANCELLED'].includes(fresh.status)) {
      throw new HttpsError('failed-precondition', `Cannot cancel from status ${fresh.status}.`);
    }
    const assignedDriver = typeof fresh.driverId === 'string' ? fresh.driverId : '';
    const driverRef = assignedDriver ? db.collection('drivers').doc(assignedDriver) : null;
    const driverSnap = driverRef ? await tx.get(driverRef) : null;
    tx.update(bookingRef, {
      status: 'CANCELLED',
      cancellationReason: reason ?? '',
      cancellationFee,
      cancelledBy: uid,
      updatedAt: Timestamp.now(),
    });
    if (driverRef && driverSnap?.data()?.activeBookingId === bookingId) {
      tx.update(driverRef, { activeBookingId: FieldValue.delete(), updatedAt: Timestamp.now() });
    }
  });

  // Expire any live offers so the matcher stops.
  const offers = await db
    .collection('driverOffers')
    .where('bookingId', '==', bookingId)
    .get();
  await Promise.all(
    offers.docs.map((d) => d.ref.update({ status: 'CANCELLED' }).catch(() => {})),
  );

  return { ok: true, cancellationFee };
});
