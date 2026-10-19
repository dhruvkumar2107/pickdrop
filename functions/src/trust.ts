import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { Firestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { encodeGeohash } from './geohash';
import { generateOtp } from './otp';
import { haversineKm } from './fare';
import { getConfig, DEFAULT_CONFIG } from './config';
import { defineSecret } from 'firebase-functions/params';
import * as crypto from 'crypto';

const MIN_PAYOUT = 100;
export const DEFAULT_COMMISSION_PERCENT = 10;
export const FREE_TRIP_COUNT = 20;
const SCHEDULE_LEAD_MINUTES = 30;
const razorpayXKeyId = defineSecret('RAZORPAYX_KEY_ID');
const razorpayXKeySecret = defineSecret('RAZORPAYX_KEY_SECRET');
const razorpayXAccountNumber = defineSecret('RAZORPAYX_ACCOUNT_NUMBER');
const razorpayXWebhookSecret = defineSecret('RAZORPAYX_WEBHOOK_SECRET');

/** Accepts first-time driver KYC or a correction after an explicit rejection. */
export const submitDriverKyc = onCall(async (request) => {
  const uid = requireAuth(request);
  const data = request.data ?? {};
  const requiredText = ['vehicleTypeId', 'vehicleNumber', 'licenseNumber', 'rcNumber'];
  if (requiredText.some((key) => typeof data[key] !== 'string' || !data[key].trim()) ||
      !Number.isFinite(data.licenseExpiry) || !Number.isFinite(data.rcExpiry)) {
    throw new HttpsError('invalid-argument', 'Vehicle, license and registration details are required.');
  }
  const expectedUploads: Record<string, string> = {
    licenseFrontUrl: 'license_front.jpg',
    licenseBackUrl: 'license_back.jpg',
    rcFrontUrl: 'rc_front.jpg',
    rcBackUrl: 'rc_back.jpg',
    aadhaarFrontUrl: 'aadhaar_front.jpg',
    aadhaarBackUrl: 'aadhaar_back.jpg',
    photoUrl: 'profile.jpg',
  };
  for (const [field, filename] of Object.entries(expectedUploads)) {
    const rawUrl = data[field];
    if (typeof rawUrl !== 'string') throw new HttpsError('invalid-argument', 'Upload all required KYC documents before submission.');
    try {
      const url = new URL(rawUrl);
      const objectPath = decodeURIComponent(url.pathname.split('/o/')[1] ?? '');
      if (url.hostname !== 'firebasestorage.googleapis.com' || !url.searchParams.has('token') ||
          objectPath !== `drivers/${uid}/${filename}`) {
        throw new Error('Unexpected KYC upload location.');
      }
    } catch {
      throw new HttpsError('invalid-argument', 'KYC documents must be uploaded to your private PickDrop folder.');
    }
  }
  if (Number(data.licenseExpiry) <= Date.now() || Number(data.rcExpiry) <= Date.now()) {
    throw new HttpsError('invalid-argument', 'License and registration documents must not be expired.');
  }
  const db = getFirestore();
  const vehicleType = await db.collection('vehicleTypes').doc(String(data.vehicleTypeId)).get();
  if (!vehicleType.exists || vehicleType.data()?.isActive !== true) {
    throw new HttpsError('invalid-argument', 'Choose an active vehicle type from the PickDrop catalog.');
  }
  const driverRef = db.collection('drivers').doc(uid);
  const privateRef = db.collection('driverPrivate').doc(uid);
  const now = Timestamp.now();
  await db.runTransaction(async (tx) => {
    const [driver, kyc] = await Promise.all([tx.get(driverRef), tx.get(privateRef)]);
    if (driver.exists && kyc.data()?.status !== 'REJECTED') {
      throw new HttpsError('failed-precondition', 'Your driver profile is already submitted or verified.');
    }
    const profile = {
      uid, userId: uid,
      vehicleTypeId: String(data.vehicleTypeId).slice(0, 80),
      vehicleNumber: String(data.vehicleNumber).toUpperCase().replace(/\s+/g, '').slice(0, 20),
      vehicleModel: String(data.vehicleModel ?? '').slice(0, 100),
      photoUrl: data.photoUrl,
      isOnline: false,
      isVerified: false,
      verificationStatus: 'PENDING_REVIEW',
      currentLat: driver.data()?.currentLat ?? 0,
      currentLng: driver.data()?.currentLng ?? 0,
      geohash: driver.data()?.geohash ?? encodeGeohash(0, 0),
      rating: driver.data()?.rating ?? 0,
      totalTrips: driver.data()?.totalTrips ?? 0,
      totalEarnings: driver.data()?.totalEarnings ?? 0,
      todayEarnings: driver.data()?.todayEarnings ?? 0,
      weekEarnings: driver.data()?.weekEarnings ?? 0,
      monthEarnings: driver.data()?.monthEarnings ?? 0,
      ...(driver.exists ? {} : { createdAt: now }),
      updatedAt: now,
    };
    const privateData = {
      uid,
      licenseNumber: String(data.licenseNumber).slice(0, 80),
      licenseExpiry: Timestamp.fromMillis(Number(data.licenseExpiry)),
      licenseFrontUrl: data.licenseFrontUrl,
      licenseBackUrl: data.licenseBackUrl,
      rcNumber: String(data.rcNumber).slice(0, 80),
      rcExpiry: Timestamp.fromMillis(Number(data.rcExpiry)),
      rcFrontUrl: data.rcFrontUrl,
      rcBackUrl: data.rcBackUrl,
      aadhaarFrontUrl: data.aadhaarFrontUrl,
      aadhaarBackUrl: data.aadhaarBackUrl,
      status: 'PENDING_REVIEW',
      reviewReason: FieldValue.delete(),
      reviewedBy: FieldValue.delete(),
      reviewedAt: FieldValue.delete(),
      createdAt: kyc.data()?.createdAt ?? now,
      updatedAt: now,
      resubmittedAt: kyc.exists ? now : null,
    };
    tx.set(driverRef, profile, { merge: true });
    tx.set(privateRef, privateData, { merge: true });
  });
  return { submitted: true, status: 'PENDING_REVIEW' };
});

/** Records a safety incident and alerts the assigned driver when a trip is active. */
export const createSosAlert = onCall<{ latitude?: number; longitude?: number; note?: string }>(async (request) => {
  const uid = requireAuth(request);
  const { latitude, longitude, note = '' } = request.data ?? {};
  const hasLocation = Number.isFinite(latitude) && Number.isFinite(longitude) &&
    Number(latitude) >= -90 && Number(latitude) <= 90 && Number(longitude) >= -180 && Number(longitude) <= 180;
  const db = getFirestore();
  const activeStatuses = ['DRIVER_ASSIGNED', 'PICKED_UP'];
  const asCustomer = await db.collection('bookings').where('customerId', '==', uid).limit(50).get();
  let booking = asCustomer.docs.find((doc) => activeStatuses.includes(String(doc.data().status)));
  let role = 'customer';
  let counterpartyId = booking?.data().driverId ? String(booking.data().driverId) : undefined;
  if (!booking) {
    const asDriver = await db.collection('bookings').where('driverId', '==', uid).limit(50).get();
    booking = asDriver.docs.find((doc) => activeStatuses.includes(String(doc.data().status)));
    if (booking) {
      role = 'driver';
      counterpartyId = String(booking.data().customerId);
    }
  }
  const ref = db.collection('sosAlerts').doc();
  await ref.create({
    userId: uid,
    role,
    bookingId: booking?.id ?? null,
    driverId: booking?.data().driverId ?? (role === 'driver' ? uid : null),
    status: 'OPEN',
    note: String(note).slice(0, 300),
    ...(hasLocation ? { location: { latitude, longitude } } : {}),
    createdAt: Timestamp.now(),
  });
  if (counterpartyId) {
    const counterpartyCollection = role === 'customer' ? 'drivers' : 'users';
    const counterparty = await db.collection(counterpartyCollection).doc(counterpartyId).get();
    const token = counterparty.data()?.fcmToken;
    if (typeof token === 'string' && token) {
      try {
        await getMessaging().send({
          token,
          notification: {
            title: 'PickDrop safety alert',
            body: role === 'customer'
              ? 'A customer on your active trip requested emergency help.'
              : 'Your driver requested emergency help. Contact them and support if needed.',
          },
          data: { type: 'sos_alert', bookingId: booking!.id, alertId: ref.id },
          android: { priority: 'high', notification: { channelId: 'booking_updates' } },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      } catch (error) {
        console.warn(`SOS push failed for active booking ${booking!.id}`, error);
      }
    }
  }
  return { alertId: ref.id, recorded: true, activeTrip: Boolean(booking), role };
});

/** Returns a stable account referral code and registers its owner server-side. */
export const getReferralCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const code = `PD${crypto.createHash('sha256').update(uid).digest('hex').slice(0, 8).toUpperCase()}`;
  const ref = getFirestore().collection('referralCodes').doc(code);
  try {
    await ref.create({ ownerId: uid, createdAt: Timestamp.now() });
  } catch (error) {
    const existing = await ref.get();
    if (!existing.exists || existing.data()?.ownerId !== uid) {
      throw new HttpsError('already-exists', 'Could not register a unique referral code.');
    }
  }
  return { code };
});

export const resolveSosAlert = onCall<{ alertId: string }>(async (request) => {
  const adminUid = requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const alertId = request.data?.alertId;
  if (!alertId) throw new HttpsError('invalid-argument', 'alertId is required.');
  const ref = getFirestore().collection('sosAlerts').doc(alertId);
  await getFirestore().runTransaction(async (tx) => {
    const alert = await tx.get(ref);
    if (!alert.exists) throw new HttpsError('not-found', 'Safety alert not found.');
    if (alert.data()?.status !== 'OPEN') throw new HttpsError('failed-precondition', 'Safety alert is already closed.');
    tx.update(ref, { status: 'RESOLVED', resolvedBy: adminUid, resolvedAt: Timestamp.now() });
  });
  return { resolved: true };
});

/** Creates a high-entropy bearer link for a customer-selected trip share. */
export const createPublicTrackingLink = onCall<{ bookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const bookingId = request.data?.bookingId;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId is required.');
  const ref = getFirestore().collection('bookings').doc(bookingId);
  const nextToken = crypto.randomBytes(32).toString('hex');
  const token = await getFirestore().runTransaction(async (tx) => {
    const booking = await tx.get(ref);
    if (!booking.exists || booking.data()?.customerId !== uid) throw new HttpsError('permission-denied', 'You can only share your own delivery.');
    if (['CANCELLED', 'DELIVERED', 'NO_DRIVER_FOUND'].includes(String(booking.data()?.status))) {
      throw new HttpsError('failed-precondition', 'This delivery is no longer live.');
    }
    const data = booking.data()!;
    const expiresAt = data.publicTrackingExpiresAt as Timestamp | undefined;
    if (typeof data.publicTrackingToken === 'string' && expiresAt && expiresAt.toMillis() > Date.now()) {
      return data.publicTrackingToken;
    }
    tx.update(ref, {
      publicTrackingToken: nextToken,
      publicTrackingEnabled: true,
      publicTrackingUpdatedAt: Timestamp.now(),
      publicTrackingExpiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
    });
    return nextToken;
  });
  return { token };
});

/** Lets a customer immediately invalidate a previously shared bearer URL. */
export const revokePublicTrackingLink = onCall<{ bookingId: string }>(async (request) => {
  const uid = requireAuth(request);
  const bookingId = request.data?.bookingId;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId is required.');
  const ref = getFirestore().collection('bookings').doc(bookingId);
  await getFirestore().runTransaction(async (tx) => {
    const booking = await tx.get(ref);
    if (!booking.exists || booking.data()?.customerId !== uid) {
      throw new HttpsError('permission-denied', 'You can only revoke your own delivery link.');
    }
    tx.update(ref, {
      publicTrackingEnabled: false,
      publicTrackingToken: FieldValue.delete(),
      publicTrackingExpiresAt: FieldValue.delete(),
      publicTrackingRevokedAt: Timestamp.now(),
    });
  });
  return { revoked: true };
});

/** Public, token-scoped tracking view. Deliberately returns no customer PII or OTPs. */
export const getPublicTracking = onCall<{ token: string }>(async (request) => {
  const token = String(request.data?.token ?? '');
  if (!/^[a-f0-9]{64}$/.test(token)) throw new HttpsError('invalid-argument', 'Tracking link is invalid.');
  const db = getFirestore();
  const found = await db.collection('bookings').where('publicTrackingToken', '==', token).limit(1).get();
  const doc = found.docs[0];
  if (!doc || doc.data().publicTrackingEnabled !== true) throw new HttpsError('not-found', 'This tracking link is unavailable.');
  const booking = doc.data();
  const expiresAt = booking.publicTrackingExpiresAt as Timestamp | undefined;
  if (!expiresAt || expiresAt.toMillis() <= Date.now() || ['CANCELLED', 'DELIVERED', 'NO_DRIVER_FOUND'].includes(String(booking.status))) {
    throw new HttpsError('not-found', 'This tracking link has expired.');
  }
  const response: Record<string, unknown> = {
    status: booking.status,
    hasDriver: typeof booking.driverId === 'string' && booking.driverId.length > 0,
    pickupAddress: booking.pickup?.address ?? '',
    dropAddress: booking.drop?.address ?? '',
    stops: Array.isArray(booking.intermediateStops) ? booking.intermediateStops.map((stop: Record<string, unknown>) => ({ address: stop.address ?? '' })) : [],
    updatedAt: typeof booking.updatedAt?.toMillis === 'function' ? booking.updatedAt.toMillis() : null,
  };
  if (booking.driverId && ['DRIVER_ASSIGNED', 'PICKED_UP'].includes(String(booking.status))) {
    const driver = await db.collection('drivers').doc(String(booking.driverId)).get();
    const data = driver.data();
    if (data) {
      response.driverName = data.name ?? 'Verified PickDrop partner';
      response.vehicleNumber = data.vehicleNumber ?? '';
      if (Number.isFinite(data.currentLat) && Number.isFinite(data.currentLng)) {
        response.driverLocation = { lat: data.currentLat, lng: data.currentLng };
      }
    }
  }
  return response;
});

/** Initializes editable starter pricing only for catalog/config rows that are absent. */
export const seedBusinessDefaults = onCall(async (request) => {
  requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const db = getFirestore();
  const catalog = [
    { id: 'bike', name: 'Bike', icon: 'assets/icons/ic_bike.svg', capacityKg: 20, baseFare: 30, perKmRate: 12, perMinuteRate: 0.25, minimumFare: 40, surgeMultiplier: 1 },
    { id: 'three_wheeler', name: '3-Wheeler / Tata Ace', icon: 'assets/icons/ic_three_wheeler.svg', capacityKg: 750, baseFare: 80, perKmRate: 22, perMinuteRate: 3, minimumFare: 120, surgeMultiplier: 1 },
    { id: 'mini_truck', name: 'Mini Truck 8ft', icon: 'assets/icons/ic_mini_truck.svg', capacityKg: 1250, baseFare: 150, perKmRate: 35, perMinuteRate: 5, minimumFare: 250, surgeMultiplier: 1 },
    { id: 'pickup', name: 'Pickup 9ft', icon: 'assets/icons/ic_pickup.svg', capacityKg: 1500, baseFare: 200, perKmRate: 45, perMinuteRate: 6, minimumFare: 350, surgeMultiplier: 1 },
  ];
  const batch = db.batch();
  let created = 0;
  for (const item of catalog) {
    const ref = db.collection('vehicleTypes').doc(item.id);
    const existing = await ref.get();
    if (!existing.exists) { batch.set(ref, { ...item, isActive: true, sortOrder: created, createdAt: Timestamp.now(), updatedAt: Timestamp.now() }); created++; }
  }
  const configRef = db.collection('config').doc('app');
  const configSnap = await configRef.get();
  if (!configSnap.exists) batch.set(configRef, { ...DEFAULT_CONFIG, createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
  if (created > 0 || !configSnap.exists) await batch.commit();
  return { vehiclesCreated: created, configCreated: !configSnap.exists };
});

export const updateVehiclePricing = onCall(async (request) => {
  requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const { vehicleTypeId, baseFare, perKmRate, perMinuteRate, minimumFare } = request.data ?? {};
  if (typeof vehicleTypeId !== 'string' || !vehicleTypeId.trim()) throw new HttpsError('invalid-argument', 'vehicleTypeId is required.');
  const prices = { baseFare: Number(baseFare), perKmRate: Number(perKmRate), perMinuteRate: Number(perMinuteRate), minimumFare: Number(minimumFare) };
  if (Object.values(prices).some((value) => !Number.isFinite(value) || value < 0 || value > 100000) || prices.minimumFare === 0) {
    throw new HttpsError('invalid-argument', 'Enter non-negative prices and a positive minimum fare.');
  }
  const ref = getFirestore().collection('vehicleTypes').doc(vehicleTypeId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Vehicle category not found.');
  await ref.update({ ...prices, updatedAt: Timestamp.now() });
  return { updated: true };
});

const requireAuth = (request: { auth?: { uid: string } }): string => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return request.auth.uid;
};

/** 10% by default, zero for a driver's first 20 trips. */
export function commissionFor(
  fare: number,
  completedTrips: number,
  commissionPercent = DEFAULT_COMMISSION_PERCENT,
): number {
  if (completedTrips < FREE_TRIP_COUNT) return 0;
  return Math.round(fare * commissionPercent) / 100;
}

async function loadBooking(
  db: Firestore,
  bookingId: string,
): Promise<Record<string, any>> {
  const snap = await db.collection('bookings').doc(bookingId).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
  return { id: snap.id, ...(snap.data() as Record<string, any>) };
}

/** Records an extra-cash report for support review; it never issues money automatically. */
export const reportExtraCash = onCall(
  async (request) => {
    const uid = requireAuth(request);
    const { bookingId, reason, extraCashAmount } = (request.data ?? {}) as {
      bookingId?: string;
      reason?: string;
      extraCashAmount?: number;
    };
    if (!bookingId || !Number.isFinite(extraCashAmount) || Number(extraCashAmount) <= 0 || Number(extraCashAmount) > 100000) {
      throw new HttpsError('invalid-argument', 'A booking and valid extra-cash amount are required.');
    }

    const db = getFirestore();
    const booking = await loadBooking(db, bookingId);
    if (booking.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Not your booking.');
    }
    if (!booking.driverId || !['DRIVER_ASSIGNED', 'PICKED_UP', 'DELIVERED'].includes(String(booking.status))) {
      throw new HttpsError('failed-precondition', 'A driver must be assigned before reporting an extra-cash request.');
    }

    const reportRef = db.collection('reports').doc(`extra_cash_${bookingId}_${uid}`);
    const penaltyRef = booking.driverId
      ? db.collection('driverPenalties').doc(`extra_cash_${bookingId}_${booking.driverId}`)
      : null;
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(reportRef);
      if (existing.exists) throw new HttpsError('already-exists', 'A report already exists for this booking.');
      tx.create(reportRef, {
      type: 'EXTRA_CASH',
      reporterId: uid,
      bookingId,
      driverId: booking.driverId,
      extraCashAmount: Number(extraCashAmount),
      reason: reason ?? 'Driver asked for extra cash',
      status: 'PENDING_REVIEW',
      createdAt: Timestamp.now(),
      });
      if (penaltyRef) tx.create(penaltyRef, {
        bookingId,
        driverId: booking.driverId,
        customerId: uid,
        type: 'EXTRA_CASH_DEMAND',
        createdAt: Timestamp.now(),
      });
    });
    return { reported: true, status: 'PENDING_REVIEW' };
  },
);

export const reviewCustomerReport = onCall(async (request) => {
  const adminUid = requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const { reportId, decision, note = '' } = request.data ?? {};
  if (typeof reportId !== 'string' || !['RESOLVED', 'DISMISSED'].includes(String(decision))) {
    throw new HttpsError('invalid-argument', 'A report ID and supported decision are required.');
  }
  const ref = getFirestore().collection('reports').doc(reportId);
  await getFirestore().runTransaction(async (tx) => {
    const report = await tx.get(ref);
    if (!report.exists || report.data()?.type !== 'EXTRA_CASH') throw new HttpsError('not-found', 'Extra-cash report not found.');
    if (report.data()?.status !== 'PENDING_REVIEW') throw new HttpsError('failed-precondition', 'This report has already been reviewed.');
    tx.update(ref, {
      status: decision,
      adminNote: String(note).slice(0, 500),
      reviewedBy: adminUid,
      reviewedAt: Timestamp.now(),
    });
  });
  return { status: decision };
});

/** A2.2 — driver cancellation safely releases the assignment for rematching. */
export const handleDriverCancellation = onCall(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, reason } = (request.data ?? {}) as {
    bookingId?: string;
    reason?: string;
  };
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');

  const db = getFirestore();
  const booking = await loadBooking(db, bookingId);
  if (booking.driverId !== uid || booking.status !== 'DRIVER_ASSIGNED') {
    throw new HttpsError('permission-denied', 'Only the assigned driver can cancel before pickup.');
  }
  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef = db.collection('drivers').doc(uid);
  const penaltyRef = db.collection('driverPenalties').doc(`driver_cancel_${bookingId}_${uid}`);
  await db.runTransaction(async (tx) => {
    const [fresh, driver, penalty] = await Promise.all([
      tx.get(bookingRef), tx.get(driverRef), tx.get(penaltyRef),
    ]);
    if (!fresh.exists || fresh.data()?.driverId !== uid || fresh.data()?.status !== 'DRIVER_ASSIGNED') {
      throw new HttpsError('failed-precondition', 'This delivery can no longer be cancelled by this driver.');
    }
    tx.update(bookingRef, {
      driverId: null,
      status: 'SEARCHING',
      rematchBoost: true,
      cancelReason: reason ?? 'Driver cancelled',
      updatedAt: Timestamp.now(),
    });
    if (driver.data()?.activeBookingId === bookingId) {
      tx.update(driverRef, { activeBookingId: FieldValue.delete(), updatedAt: Timestamp.now() });
    }
    if (!penalty.exists) tx.create(penaltyRef, {
      bookingId,
      driverId: uid,
      customerId: booking.customerId,
      type: 'DRIVER_CANCEL',
      priorityRematchBoost: true,
      createdAt: Timestamp.now(),
    });
  });

  return { success: true, priorityBoost: true };
});

/** Creates a refund request for review; clients cannot credit their own wallets. */
export const requestInstantRefund = onCall(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, reason, amount } = (request.data ?? {}) as {
    bookingId?: string;
    reason?: string;
    amount?: number;
  };

  if (typeof reason !== 'string' || reason.trim().length < 5 || reason.length > 500) {
    throw new HttpsError('invalid-argument', 'Describe the issue in 5 to 500 characters.');
  }

  const db = getFirestore();
  if (bookingId) {
    const booking = await loadBooking(db, bookingId);
    if (booking.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Not your booking.');
    }
  }

  const reportRef = db.collection('reports').doc(`refund_${bookingId ?? 'general'}_${uid}`);
  await reportRef.create({
    type: 'REFUND_REQUEST',
    reporterId: uid,
    bookingId: bookingId ?? null,
    reason: reason.trim(),
    requestedAmount: Number.isFinite(Number(amount)) ? Math.max(0, Number(amount)) : null,
    status: 'PENDING_REVIEW',
    createdAt: Timestamp.now(),
  });
  return { requested: true, status: 'PENDING_REVIEW' };
});

/** A5.3 — instant UPI payout, minimum ₹100. */
export const requestPayout = onCall(async (request) => {
  const uid = requireAuth(request);
  const { amount, upiId } = (request.data ?? {}) as {
    amount?: number;
    upiId?: string;
  };

  const value = Number(amount ?? 0);
  if (!Number.isFinite(value) || value <= 0) {
    throw new HttpsError('invalid-argument', 'Enter a valid payout amount.');
  }
  if (!upiId || !upiId.includes('@')) {
    throw new HttpsError('invalid-argument', 'A valid UPI id is required.');
  }
  if (value < MIN_PAYOUT) {
    throw new HttpsError('failed-precondition', `Minimum payout is ₹${MIN_PAYOUT}.`);
  }

  const db = getFirestore();
  const driverRef = db.collection('drivers').doc(uid);
  const driverSnap = await driverRef.get();
  if (!driverSnap.exists || driverSnap.data()?.isVerified !== true) {
    throw new HttpsError('failed-precondition', 'A verified driver profile is required.');
  }
  const balance = Number(driverSnap.data()?.availableBalance ?? 0);
  if (balance < value) {
    throw new HttpsError('failed-precondition', 'Insufficient withdrawable balance.');
  }

  const payoutRef = db.collection('driverPayouts').doc();
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(driverRef);
    const current = Number(fresh.data()?.availableBalance ?? 0);
    if (current < value) {
      throw new HttpsError('failed-precondition', 'Insufficient withdrawable balance.');
    }
    tx.update(driverRef, {
      availableBalance: current - value,
      updatedAt: Timestamp.now(),
    });
    tx.set(payoutRef, {
      driverId: uid,
      amount: value,
      upiId,
      status: 'PENDING_REVIEW',
      createdAt: Timestamp.now(),
    });
  });

  return { payoutId: payoutRef.id, status: 'PENDING_REVIEW', amount: value };
});

/** Admin-only KYC decision. Admin access is granted using Firebase custom claims. */
export const reviewDriverKyc = onCall(async (request) => {
  const adminUid = requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const { driverId, decision, reason = '' } = request.data ?? {};
  if (typeof driverId !== 'string' || !['APPROVED', 'REJECTED'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'driverId and APPROVED/REJECTED decision are required.');
  }
  const db = getFirestore();
  const privateRef = db.collection('driverPrivate').doc(driverId);
  const driverRef = db.collection('drivers').doc(driverId);
  await db.runTransaction(async (tx) => {
    const [kyc, driver] = await Promise.all([tx.get(privateRef), tx.get(driverRef)]);
    if (!kyc.exists || !driver.exists) throw new HttpsError('not-found', 'Driver KYC record not found.');
    if (kyc.data()?.status !== 'PENDING_REVIEW') throw new HttpsError('failed-precondition', 'KYC is not pending review.');
    const approved = decision === 'APPROVED';
    tx.update(privateRef, { status: approved ? 'APPROVED' : 'REJECTED', reviewReason: String(reason).slice(0, 500), reviewedBy: adminUid, reviewedAt: Timestamp.now() });
    tx.update(driverRef, { isVerified: approved, verificationStatus: approved ? 'VERIFIED' : 'REJECTED', updatedAt: Timestamp.now() });
  });
  return { success: true, decision };
});

/** Approve/reject a reserved payout; approved requests are actually sent using RazorpayX. */
export const reviewDriverPayout = onCall({ secrets: [razorpayXKeyId, razorpayXKeySecret, razorpayXAccountNumber] }, async (request) => {
  const adminUid = requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const { payoutId, decision, reason = '' } = request.data ?? {};
  if (typeof payoutId !== 'string' || !['APPROVE', 'REJECT'].includes(decision)) throw new HttpsError('invalid-argument', 'payoutId and APPROVE/REJECT are required.');
  const db = getFirestore();
  const payoutRef = db.collection('driverPayouts').doc(payoutId);
  const payoutSnap = await payoutRef.get();
  if (!payoutSnap.exists || payoutSnap.data()?.status !== 'PENDING_REVIEW') throw new HttpsError('failed-precondition', 'Payout is not pending review.');
  const payout = payoutSnap.data()!;
  if (decision === 'REJECT') {
    const driverRef = db.collection('drivers').doc(String(payout.driverId));
    await db.runTransaction(async (tx) => {
      const [fresh, driver] = await Promise.all([tx.get(payoutRef), tx.get(driverRef)]);
      if (!fresh.exists || fresh.data()?.status !== 'PENDING_REVIEW') throw new HttpsError('failed-precondition', 'Payout is no longer pending.');
      tx.update(payoutRef, { status: 'REJECTED', reviewReason: String(reason).slice(0, 500), reviewedBy: adminUid, reviewedAt: Timestamp.now() });
      tx.update(driverRef, { availableBalance: Number(driver.data()?.availableBalance ?? 0) + Number(payout.amount), updatedAt: Timestamp.now() });
    });
    return { status: 'REJECTED' };
  }

  const keyId = razorpayXKeyId.value();
  const keySecret = razorpayXKeySecret.value();
  const accountNumber = razorpayXAccountNumber.value();
  if (!keyId || !keySecret || !accountNumber) throw new HttpsError('failed-precondition', 'RazorpayX payout credentials are not configured.');
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(payoutRef);
    if (!fresh.exists || fresh.data()?.status !== 'PENDING_REVIEW') throw new HttpsError('failed-precondition', 'Payout is no longer pending.');
    tx.update(payoutRef, { status: 'PROCESSING', reviewedBy: adminUid, reviewedAt: Timestamp.now() });
  });
  let providerResponseReceived = false;
  let providerAccepted = false;
  try {
    const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
    const headers = { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' };
    const contactResponse = await fetch('https://api.razorpay.com/v1/contacts', {
      method: 'POST', headers,
      body: JSON.stringify({ name: `PickDrop driver ${String(payout.driverId).slice(0, 8)}`, type: 'vendor', reference_id: payoutId.slice(0, 40), notes: { driverId: payout.driverId } }),
    });
    const contact = await contactResponse.json() as Record<string, any>;
    if (!contactResponse.ok) throw new Error(String(contact.error?.description ?? 'Could not create payout contact'));
    const fundResponse = await fetch('https://api.razorpay.com/v1/fund_accounts', {
      method: 'POST', headers,
      body: JSON.stringify({ contact_id: contact.id, account_type: 'vpa', vpa: { address: payout.upiId } }),
    });
    const fund = await fundResponse.json() as Record<string, any>;
    if (!fundResponse.ok) throw new Error(String(fund.error?.description ?? 'Could not create UPI fund account'));
    const transfer = await fetch('https://api.razorpay.com/v1/payouts', {
      method: 'POST', headers,
      body: JSON.stringify({ account_number: accountNumber, fund_account_id: fund.id, amount: Math.round(Number(payout.amount) * 100), currency: 'INR', mode: 'UPI', purpose: 'payout', queue_if_low_balance: true, reference_id: payoutId, narration: 'PickDrop driver payout' }),
    });
    providerResponseReceived = true;
    const result = await transfer.json() as Record<string, any>;
    if (!transfer.ok) throw new Error(String(result.error?.description ?? 'RazorpayX payout failed'));
    providerAccepted = true;
    await payoutRef.update({ status: 'PROCESSING', providerPayoutId: result.id, providerStatus: result.status, updatedAt: Timestamp.now() });
    return { status: result.status, providerPayoutId: result.id };
  } catch (error) {
    if (providerResponseReceived && !providerAccepted) {
      await payoutRef.update({ status: 'FAILED', failureReason: String(error).slice(0, 500), updatedAt: Timestamp.now() });
      await db.collection('drivers').doc(String(payout.driverId)).update({ availableBalance: FieldValue.increment(Number(payout.amount)), updatedAt: Timestamp.now() });
      throw new HttpsError('internal', 'Payout provider rejected the transfer; the reserved balance was released.');
    }
    await payoutRef.update({ status: 'PROCESSING_REVIEW', failureReason: 'Provider response was uncertain; reconcile in RazorpayX before releasing balance.', updatedAt: Timestamp.now() });
    throw new HttpsError('unavailable', 'Payout status is uncertain. The reserved balance is held until the provider webhook or reconciliation confirms the outcome.');
  }
});

/** Reconciles provider terminal events and safely releases failed payout reserves once. */
export const razorpayXPayoutWebhook = onRequest({ secrets: [razorpayXWebhookSecret] }, async (request, response) => {
  if (request.method !== 'POST') { response.status(405).send('Method not allowed'); return; }
  const secret = razorpayXWebhookSecret.value();
  const signature = request.header('x-razorpay-signature') ?? '';
  const expected = crypto.createHmac('sha256', secret).update(request.rawBody).digest('hex');
  const a = Buffer.from(signature, 'hex');
  const b = Buffer.from(expected, 'hex');
  if (!secret || a.length !== b.length || !crypto.timingSafeEqual(a, b)) { response.status(401).send('Invalid signature'); return; }
  const event = request.body?.event as string | undefined;
  if (!['payout.processed', 'payout.failed', 'payout.reversed'].includes(event ?? '')) { response.status(200).send('Ignored'); return; }
  const entity = request.body?.payload?.payout?.entity as Record<string, any> | undefined;
  const payoutId = entity?.reference_id as string | undefined;
  if (!entity || !payoutId) { response.status(400).send('Missing reference'); return; }
  const db = getFirestore();
  const payoutRef = db.collection('driverPayouts').doc(payoutId);
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(payoutRef);
      if (!snap.exists) return;
      const payout = snap.data()!;
      if (['PAID', 'FAILED', 'REJECTED'].includes(String(payout.status))) return;
      const failed = event !== 'payout.processed';
      tx.update(payoutRef, {
        status: failed ? 'FAILED' : 'PAID',
        providerPayoutId: entity.id ?? payout.providerPayoutId ?? null,
        providerStatus: entity.status ?? event,
        updatedAt: Timestamp.now(),
      });
      if (failed) {
        tx.update(db.collection('drivers').doc(String(payout.driverId)), {
          availableBalance: FieldValue.increment(Number(payout.amount)),
          updatedAt: Timestamp.now(),
        });
      }
    });
    response.status(200).send('OK');
  } catch (_) {
    response.status(500).send('Retry');
  }
});

/** A6.1 — dispatch scheduled bookings 30 minutes ahead. */
export const dispatchScheduledBookings = onSchedule(
  'every 1 minutes',
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(Date.now() + SCHEDULE_LEAD_MINUTES * 60 * 1000);

    const due = await db
      .collection('scheduledBookings')
      .where('status', '==', 'SCHEDULED')
      .where('scheduledAt', '<=', cutoff)
      .limit(20)
      .get();

    if (due.empty) return;

    const vehicleSnap = await db.collection('vehicleTypes').limit(50).get();
    const vehicles = vehicleSnap.docs.map((d) => ({ id: d.id, name: d.data().name }));

    for (const doc of due.docs) {
      const data = doc.data();
      const pickup = { lat: Number(data.pickupLat), lng: Number(data.pickupLng) };
      const dropPoint = { lat: Number(data.dropLat), lng: Number(data.dropLng) };
      const match =
        vehicles.find((v) => v.name === data.vehicleType) ?? vehicles[0];
      if (!match) continue;

      const bookingRef = db.collection('bookings').doc();
      const bookingSecretsRef = db.collection('bookingSecrets').doc(bookingRef.id);
      const pickupOtp = generateOtp();
      const dropOtp = generateOtp();
      const claimed = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists || fresh.data()?.status !== 'SCHEDULED') return false;
        const current = fresh.data()!;
        const scheduledPickup = { lat: Number(current.pickupLat), lng: Number(current.pickupLng) };
        const scheduledDrop = { lat: Number(current.dropLat), lng: Number(current.dropLng) };
        const stops = Array.isArray(current.intermediateStops) ? current.intermediateStops as Array<Record<string, any>> : [];
        const stopOtps = stops.map(() => generateOtp());
        const distance = Number(current.distanceKm ?? haversineKm(scheduledPickup, scheduledDrop));
        tx.create(bookingRef, {
          customerId: current.customerId,
          driverId: null,
          status: 'SEARCHING',
          vehicleTypeId: current.vehicleTypeId ?? match.id,
          scheduledBookingId: doc.id,
          scheduledAt: current.scheduledAt,
          pickup: {
            address: current.pickupAddress ?? '',
            ...scheduledPickup,
            geohash: encodeGeohash(scheduledPickup.lat, scheduledPickup.lng),
          },
          drop: {
            address: current.dropAddress ?? '',
            ...scheduledDrop,
            geohash: encodeGeohash(scheduledDrop.lat, scheduledDrop.lng),
          },
          intermediateStops: stops.map((stop, index) => ({
            sequence: index + 1,
            address: String(stop.address ?? '').slice(0, 300),
            lat: Number(stop.lat),
            lng: Number(stop.lng),
            geohash: stop.geohash ?? encodeGeohash(Number(stop.lat), Number(stop.lng)),
            otpVerified: false,
          })),
          distanceKm: distance,
          estimatedDurationMin: Number(current.estimatedDurationMin ?? Math.max(5, Math.round((distance / 25) * 60) + 2)),
          fareBreakdown: current.fareBreakdown ?? { total: Number(current.estimatedFare ?? 0) },
          paymentMethod: 'cod',
          paymentStatus: 'pending',
          goodsType: current.goodsType ?? '',
          notes: stops.length ? `Scheduled delivery with ${stops.length} intermediate stop(s)` : 'Scheduled delivery',
          loadingHelper: false,
          cancellationFee: 0,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        });
        tx.create(bookingSecretsRef, {
          customerId: current.customerId,
          pickupOtp,
          dropOtp,
          intermediateStopOtps: Object.fromEntries(stopOtps.map((code, index) => [String(index + 1), code])),
          createdAt: Timestamp.now(),
        });
        tx.update(doc.ref, {
          status: 'DISPATCHING',
          bookingId: bookingRef.id,
          dispatchedAt: Timestamp.now(),
        });
        return true;
      });
      if (!claimed) continue;
    }
  },
);

/** Keeps `scheduledBookings` in sync when the driver confirms pickup. */
export const onBookingUpdated = onDocumentUpdated(
  'bookings/{bookingId}',
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after || !before) return;
    if (after.status === before.status) return;

    const scheduledId = after.scheduledBookingId;
    if (!scheduledId) return;

    const db = getFirestore();
    const status = after.status === 'CANCELLED'
      ? 'CANCELLED'
      : after.status === 'DELIVERED'
        ? 'COMPLETED'
        : after.status === 'DRIVER_ASSIGNED'
          ? 'DRIVER_ASSIGNED'
          : after.status;

    await db.collection('scheduledBookings').doc(scheduledId).update({
      status,
      assignedDriverId: after.driverId ?? '',
      updatedAt: Timestamp.now(),
    });
  },
);

/** Idempotent earnings ledger entry after a verified delivery completes. */
export const settleDeliveredTrip = onDocumentUpdated(
  'bookings/{bookingId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status || after.status !== 'DELIVERED') return;
    const driverId = after.driverId as string | undefined;
    if (!driverId) return;
    const db = getFirestore();
    const bookingRef = db.collection('bookings').doc(event.params.bookingId);
    const driverRef = db.collection('drivers').doc(driverId);
    const ledgerRef = db.collection('driverLedger').doc(event.params.bookingId);
    const customerId = String(after.customerId ?? '');
    const referralClaimRef = customerId ? db.collection('referralClaims').doc(customerId) : null;
    const referralRewardRef = customerId ? db.collection('referralRewards').doc(customerId) : null;
    const customerWalletRef = customerId ? db.collection('wallets').doc(customerId) : null;
    const config = await getConfig(db);
    await db.runTransaction(async (tx) => {
      const [bookingSnap, driverSnap, ledgerSnap, referralClaimSnap, referralRewardSnap] = await Promise.all([
        tx.get(bookingRef), tx.get(driverRef), tx.get(ledgerRef),
        referralClaimRef ? tx.get(referralClaimRef) : Promise.resolve(null),
        referralRewardRef ? tx.get(referralRewardRef) : Promise.resolve(null),
      ]);
      if (!bookingSnap.exists || !driverSnap.exists || ledgerSnap.exists) return;
      const booking = bookingSnap.data()!;
      const driver = driverSnap.data()!;
      if (booking.status !== 'DELIVERED' || booking.earningsSettledAt) return;
      const gross = Number(booking.fareBreakdown?.total ?? 0);
      if (!Number.isFinite(gross) || gross <= 0) return;
      const commission = commissionFor(gross, Number(driver.totalTrips ?? 0), config.commissionPercent);
      const net = Math.max(0, gross - commission);
      const now = Timestamp.now();
      const pendingReferral = referralClaimSnap?.data()?.status === 'PENDING' && !referralRewardSnap?.exists
        ? referralClaimSnap.data()
        : null;
      const referrerId = String(pendingReferral?.referrerId ?? '');
      const referrerWalletRef = pendingReferral && referrerId
        ? db.collection('wallets').doc(referrerId)
        : null;
      const [referrerWalletSnap, referredWalletSnap] = await Promise.all([
        referrerWalletRef ? tx.get(referrerWalletRef) : Promise.resolve(null),
        pendingReferral && customerWalletRef ? tx.get(customerWalletRef) : Promise.resolve(null),
      ]);
      tx.create(ledgerRef, {
        bookingId: event.params.bookingId,
        driverId,
        customerId: booking.customerId,
        gross,
        commission,
        net,
        commissionPercent: config.commissionPercent,
        createdAt: now,
      });
      tx.update(bookingRef, { earningsSettledAt: now });
      tx.update(driverRef, {
        totalTrips: Number(driver.totalTrips ?? 0) + 1,
        totalEarnings: Number(driver.totalEarnings ?? 0) + net,
        todayEarnings: Number(driver.todayEarnings ?? 0) + net,
        weekEarnings: Number(driver.weekEarnings ?? 0) + net,
        monthEarnings: Number(driver.monthEarnings ?? 0) + net,
        availableBalance: Number(driver.availableBalance ?? 0) +
          (booking.paymentMethod === 'razorpay' || booking.paymentMethod === 'wallet' ? net : 0),
        updatedAt: now,
      });
      if (pendingReferral && referrerId && referralClaimRef && referralRewardRef &&
          referrerWalletRef && customerWalletRef && referralClaimSnap) {
        const rewardAmount = 50;
        const referrerBalance = Number(referrerWalletSnap?.data()?.balance ?? 0);
        const customerBalance = Number(referredWalletSnap?.data()?.balance ?? 0);
        const referrerTxnRef = db.collection('walletTransactions').doc(`referral_referrer_${customerId}`);
        const customerTxnRef = db.collection('walletTransactions').doc(`referral_customer_${customerId}`);
        tx.set(referrerWalletRef, { userId: referrerId, balance: Math.round((referrerBalance + rewardAmount) * 100) / 100, updatedAt: now }, { merge: true });
        tx.set(customerWalletRef, { userId: customerId, balance: Math.round((customerBalance + rewardAmount) * 100) / 100, updatedAt: now }, { merge: true });
        tx.create(referrerTxnRef, { userId: referrerId, type: 'REFERRAL_REWARD', amount: rewardAmount, status: 'SUCCESS', referredUserId: customerId, createdAt: now });
        tx.create(customerTxnRef, { userId: customerId, type: 'REFERRAL_REWARD', amount: rewardAmount, status: 'SUCCESS', referrerId, createdAt: now });
        tx.create(referralRewardRef, { userId: customerId, referrerId, amount: rewardAmount, bookingId: event.params.bookingId, createdAt: now });
        tx.update(referralClaimRef, { status: 'REWARDED', rewardedAt: now, bookingId: event.params.bookingId });
      }
    });
  },
);

/** A6.1 — reminder 24 h before a scheduled delivery. */
export const remindScheduledBookings = onSchedule(
  'every 15 minutes',
  async () => {
    const db = getFirestore();
    const from = Timestamp.now();
    const to = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);

    const due = await db
      .collection('scheduledBookings')
      .where('status', '==', 'SCHEDULED')
      .where('scheduledAt', '>=', from)
      .where('scheduledAt', '<=', to)
      .limit(50)
      .get();

    for (const doc of due.docs) {
      if (doc.data().reminderSentAt) continue;
      const when = (doc.data().scheduledAt as Timestamp).toDate();
      await db.collection('notifications').add({
        userId: doc.data().customerId,
        type: 'SCHEDULED_REMINDER',
        title: 'Delivery coming up',
        body: `Your pickup is scheduled for ${when.toLocaleString('en-IN')}. A driver is guaranteed 30 minutes before.`,
        read: false,
        createdAt: Timestamp.now(),
      });
      await doc.ref.update({ reminderSentAt: Timestamp.now() });
    }
  },
);
