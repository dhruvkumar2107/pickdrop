import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getConfig, AppConfig } from './config';
import {
  calculateFare,
  estimateDurationMinutes,
  haversineKm,
  GeoPoint,
} from './fare';
import { encodeGeohash } from './geohash';
import { generateOtp, verifyOtp } from './otp';
import { runDriverMatching } from './matching';

interface CreateBookingRequest {
  pickup: GeoPoint;
  drop: GeoPoint;
  vehicleTypeId: string;
  paymentMethod: 'razorpay' | 'cod' | 'wallet';
  notes?: string;
  pickupAddress?: string;
  dropAddress?: string;
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
export const createBooking = onCall<CreateBookingRequest>(async (request) => {
  const uid = requireAuth(request);
  const data = request.data;
  if (!data?.pickup || !data?.drop || !data.vehicleTypeId) {
    throw new HttpsError('invalid-argument', 'pickup, drop and vehicleTypeId are required.');
  }

  const db = getFirestore();
  const config = await getConfig(db);
  const vehicle = await getVehiclePricing(db, data.vehicleTypeId);

  const distanceKm = haversineKm(data.pickup, data.drop);
  if (distanceKm < 0.05) {
    throw new HttpsError('failed-precondition', 'Pickup and drop are too close.');
  }

  const durationMinutes = estimateDurationMinutes(distanceKm);
  const fare = calculateFare({
    vehicle,
    distanceKm,
    durationMinutes,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    gstPercent: config.gstPercent,
  });

  const bookingRef = db.collection('bookings').doc();
  await bookingRef.set({
    customerId: uid,
    driverId: null,
    status: 'SEARCHING',
    vehicleTypeId: data.vehicleTypeId,
    pickup: {
      address: data.pickupAddress ?? '',
      lat: data.pickup.lat,
      lng: data.pickup.lng,
      geohash: encodeGeohash(data.pickup.lat, data.pickup.lng),
      otp: generateOtp(),
    },
    drop: {
      address: data.dropAddress ?? '',
      lat: data.drop.lat,
      lng: data.drop.lng,
      geohash: encodeGeohash(data.drop.lat, data.drop.lng),
      otp: generateOtp(),
    },
    distanceKm,
    estimatedDurationMin: durationMinutes,
    fareBreakdown: fare,
    paymentMethod: data.paymentMethod ?? 'razorpay',
    paymentStatus: 'pending',
    goodsType: '',
    notes: data.notes ?? '',
    loadingHelper: false,
    cancellationFee: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  return { bookingId: bookingRef.id, fare };
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

/**
 * Driver taps "Accept" on the offer screen. Marks the offer ACCEPTED —
 * runDriverMatching then finalises DRIVER_ASSIGNED in its transaction.
 */
export const acceptOffer = onCall<{ bookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const bookingId = request.data?.bookingId;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');

  const db = getFirestore();
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
  const offerRef = getFirestore().collection('driverOffers').doc(`${bookingId}_${uid}`);
  await offerRef.update({ status: 'REJECTED', rejectedAt: Timestamp.now() }).catch(() => {});
  return { ok: true };
});

/** Driver enters the customer's pickup OTP → status PICKED_UP. */
export const verifyPickupOtp = onCall<{ bookingId: string; otp: string }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, otp } = request.data ?? {};
  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const snap = await bookingRef.get();

  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
  const booking = snap.data() as BookingStatusData & { pickup?: { otp?: string }; driverId?: string };
  if (booking.driverId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
  if (booking.status !== 'DRIVER_ASSIGNED') {
    throw new HttpsError('failed-precondition', `Cannot pick up from status ${booking.status}.`);
  }
  if (!verifyOtp(String(booking.pickup?.otp ?? ''), String(otp ?? ''))) {
    throw new HttpsError('invalid-argument', 'Incorrect pickup OTP.');
  }

  await bookingRef.update({
    status: 'PICKED_UP',
    pickupOtpVerifiedAt: Timestamp.now(),
    tripStartedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  return { ok: true };
});

/** Driver enters the drop OTP → status DELIVERED (trip complete). */
export const verifyDropOtp = onCall<{ bookingId: string; otp: string }>(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, otp } = request.data ?? {};
  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const snap = await bookingRef.get();

  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
  const booking = snap.data() as BookingStatusData & { drop?: { otp?: string }; driverId?: string };
  if (booking.driverId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
  if (booking.status !== 'PICKED_UP') {
    throw new HttpsError('failed-precondition', `Cannot complete from status ${booking.status}.`);
  }
  if (!verifyOtp(String(booking.drop?.otp ?? ''), String(otp ?? ''))) {
    throw new HttpsError('invalid-argument', 'Incorrect drop OTP.');
  }

  await bookingRef.update({
    status: 'DELIVERED',
    dropOtpVerifiedAt: Timestamp.now(),
    completedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
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
    tx.update(bookingRef, {
      status: 'CANCELLED',
      cancellationReason: reason ?? '',
      cancellationFee,
      cancelledBy: uid,
      updatedAt: Timestamp.now(),
    });
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
