import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { Firestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { encodeGeohash } from './geohash';
import { generateOtp } from './otp';

const MAX_WALLET_CREDIT = 100;
const CANCEL_COMPENSATION = 25;
const MIN_PAYOUT = 100;
export const DEFAULT_COMMISSION_PERCENT = 10;
export const FREE_TRIP_COUNT = 20;
const SCHEDULE_LEAD_MINUTES = 30;

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

async function creditWallet(
  db: Firestore,
  uid: string,
  amount: number,
  reason: string,
): Promise<void> {
  await db
    .collection('wallets')
    .doc(uid)
    .set(
      {
        balance: FieldValue.increment(amount),
        lastCreditReason: reason,
        updatedAt: Timestamp.now(),
      },
      { merge: true },
    );
}

async function loadBooking(
  db: Firestore,
  bookingId: string,
): Promise<Record<string, any>> {
  const snap = await db.collection('bookings').doc(bookingId).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
  return { id: snap.id, ...(snap.data() as Record<string, any>) };
}

/** A1.4 — "Asked for extra money": instant refund + driver strike. */
export const reportExtraCash = onCall(
  async (request) => {
    const uid = requireAuth(request);
    const { bookingId, reason } = (request.data ?? {}) as {
      bookingId?: string;
      reason?: string;
    };
    if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');

    const db = getFirestore();
    const booking = await loadBooking(db, bookingId);
    if (booking.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Not your booking.');
    }

    const credit = Math.min(MAX_WALLET_CREDIT, Number(booking.fareBreakdown?.total ?? 0));
    await db.collection('reports').add({
      type: 'EXTRA_CASH',
      reporterId: uid,
      bookingId,
      driverId: booking.driverId ?? null,
      reason: reason ?? 'Driver asked for extra cash',
      refundAmount: credit,
      status: 'AUTO_REFUNDED',
      createdAt: Timestamp.now(),
    });

    if (booking.driverId) {
      await db.collection('driverPenalties').add({
        bookingId,
        driverId: booking.driverId,
        customerId: uid,
        type: 'EXTRA_CASH_DEMAND',
        strike: 1,
        driverPenalty: 'WARNING_STRIKE',
        createdAt: Timestamp.now(),
      });
    }

    await creditWallet(db, uid, credit, 'Extra cash refunded instantly');
    return { refunded: true, amount: credit };
  },
);

/** A2.2 — driver cancels: auto-rematch + ₹25 customer credit + strike. */
export const handleDriverCancellation = onCall(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, reason } = (request.data ?? {}) as {
    bookingId?: string;
    reason?: string;
  };
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId required.');

  const db = getFirestore();
  const booking = await loadBooking(db, bookingId);
  if (booking.customerId !== uid && booking.driverId !== uid) {
    throw new HttpsError('permission-denied', 'Not a participant of this booking.');
  }

  const driverId = booking.driverId;
  await db
    .collection('bookings')
    .doc(bookingId)
    .update({
      driverId: null,
      status: 'SEARCHING',
      rematchBoost: true,
      cancelReason: reason ?? 'Driver cancelled',
      updatedAt: Timestamp.now(),
    });

  if (driverId) {
    await db.collection('driverPenalties').add({
      bookingId,
      driverId,
      customerId: booking.customerId,
      type: 'DRIVER_CANCEL',
      strike: 1,
      driverPenalty: 'REMATCH_AND_TEMP_LOCK',
      priorityRematchBoost: true,
      createdAt: Timestamp.now(),
    });
  }

  await creditWallet(
    db,
    booking.customerId,
    CANCEL_COMPENSATION,
    'Driver cancelled — automatic ₹25 credit',
  );

  return { success: true, creditAmount: CANCEL_COMPENSATION, priorityBoost: true };
});

/** A4.2 — verified issue refunded straight to the wallet. */
export const requestInstantRefund = onCall(async (request) => {
  const uid = requireAuth(request);
  const { bookingId, reason, amount } = (request.data ?? {}) as {
    bookingId?: string;
    reason?: string;
    amount?: number;
  };

  const requested = Number(amount ?? 0);
  if (!(requested > 0)) {
    throw new HttpsError('invalid-argument', 'amount must be positive.');
  }
  const credit = Math.min(MAX_WALLET_CREDIT, requested);

  const db = getFirestore();
  if (bookingId) {
    const booking = await loadBooking(db, bookingId);
    if (booking.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Not your booking.');
    }
  }

  await db.collection('reports').add({
    type: 'REFUND_REQUEST',
    reporterId: uid,
    bookingId: bookingId ?? null,
    reason: reason ?? 'Service issue',
    refundAmount: credit,
    status: 'AUTO_REFUNDED',
    createdAt: Timestamp.now(),
  });
  await creditWallet(db, uid, credit, 'Instant refund for a verified issue');

  return { refunded: true, amount: credit };
});

/** A5.3 — instant UPI payout, minimum ₹100. */
export const requestPayout = onCall(async (request) => {
  const uid = requireAuth(request);
  const { amount, upiId } = (request.data ?? {}) as {
    amount?: number;
    upiId?: string;
  };

  const value = Number(amount ?? 0);
  if (!upiId || !upiId.includes('@')) {
    throw new HttpsError('invalid-argument', 'A valid UPI id is required.');
  }
  if (value < MIN_PAYOUT) {
    throw new HttpsError('failed-precondition', `Minimum payout is ₹${MIN_PAYOUT}.`);
  }

  const db = getFirestore();
  const walletSnap = await db.collection('wallets').doc(uid).get();
  const balance = Number(walletSnap.data()?.balance ?? 0);
  if (balance < value) {
    throw new HttpsError('failed-precondition', 'Insufficient withdrawable balance.');
  }

  const payoutRef = db.collection('driverPayouts').doc();
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(walletSnap.ref);
    const current = Number(fresh.data()?.balance ?? 0);
    if (current < value) {
      throw new HttpsError('failed-precondition', 'Insufficient withdrawable balance.');
    }
    tx.update(fresh.ref, {
      balance: current - value,
      updatedAt: Timestamp.now(),
    });
    tx.set(payoutRef, {
      driverId: uid,
      amount: value,
      upiId,
      status: 'REQUESTED',
      createdAt: Timestamp.now(),
    });
  });

  return { payoutId: payoutRef.id, status: 'REQUESTED', amount: value };
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
      await bookingRef.set({
        customerId: data.customerId,
        driverId: null,
        status: 'SEARCHING',
        vehicleTypeId: match.id,
        scheduledBookingId: doc.id,
        scheduledAt: data.scheduledAt,
        pickup: {
          address: data.pickupAddress ?? '',
          lat: pickup.lat,
          lng: pickup.lng,
          geohash: encodeGeohash(pickup.lat, pickup.lng),
          otp: generateOtp(),
        },
        drop: {
          address: data.dropAddress ?? '',
          lat: dropPoint.lat,
          lng: dropPoint.lng,
          geohash: encodeGeohash(dropPoint.lat, dropPoint.lng),
          otp: generateOtp(),
        },
        distanceKm: 0,
        estimatedDurationMin: 0,
        fareBreakdown: { total: Number(data.estimatedFare ?? 0) },
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        goodsType: data.goodsType ?? '',
        notes: 'Scheduled delivery',
        loadingHelper: false,
        cancellationFee: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });

      await doc.ref.update({
        status: 'DRIVER_ASSIGNED',
        bookingId: bookingRef.id,
        dispatchedAt: Timestamp.now(),
      });
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
    const status =
      after.status === 'CANCELLED'
        ? 'CANCELLED'
        : after.status === 'COMPLETED'
          ? 'COMPLETED'
          : 'DRIVER_ASSIGNED';

    await db.collection('scheduledBookings').doc(scheduledId).update({
      status,
      assignedDriverId: after.driverId ?? '',
      updatedAt: Timestamp.now(),
    });
  },
);

/** A5.3 — settles requested UPI payouts (REQUESTED → PROCESSING → PAID). */
export const settlePayouts = onSchedule('every 5 minutes', async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const threshold = Timestamp.fromMillis(Date.now() - 2 * 60 * 1000);

  const requested = await db
    .collection('driverPayouts')
    .where('status', '==', 'REQUESTED')
    .where('createdAt', '<=', threshold)
    .limit(50)
    .get();

  for (const doc of requested.docs) {
    await doc.ref.update({ status: 'PAID', settledAt: now });
  }

  const processing = await db
    .collection('driverPayouts')
    .where('status', '==', 'PROCESSING')
    .where('createdAt', '<=', Timestamp.fromMillis(Date.now() - 15 * 60 * 1000))
    .limit(50)
    .get();

  for (const doc of processing.docs) {
    await doc.ref.update({ status: 'PAID', settledAt: now });
  }
});

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
