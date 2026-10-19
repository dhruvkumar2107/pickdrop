import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const ACTIVE_BOOKING_STATUSES = ['SEARCHING', 'DRIVER_ASSIGNED', 'PICKED_UP'];
const PENDING_PAYOUT_STATUSES = ['PENDING_REVIEW', 'APPROVED', 'PROCESSING'];

function requireAuth(request: { auth?: { uid: string } }): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to delete your account.');
  return uid;
}

/**
 * Permanently deletes a user's account. Personal data is removed; financial
 * records (bookings, payments, ledger entries) are retained for accounting and
 * legal obligations but detached from the deleted identity.
 */
export const deleteAccount = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();

  // Refuse while money or an active trip is in flight so data stays consistent.
  const [activeBookings, driverPayouts, walletTopups] = await Promise.all([
    db.collection('bookings').where('status', 'in', ACTIVE_BOOKING_STATUSES).get(),
    db.collection('driverPayouts').where('driverId', '==', uid).get(),
    db.collection('walletTopupOrders').where('userId', '==', uid).limit(20).get(),
  ]);
  const hasActiveTrip = activeBookings.docs.some(
    (doc) => doc.data().customerId === uid || doc.data().driverId === uid,
  );
  if (hasActiveTrip) {
    throw new HttpsError('failed-precondition', 'Finish or cancel your active trip before deleting your account.');
  }
  const hasPendingPayout = driverPayouts.docs.some((doc) =>
    PENDING_PAYOUT_STATUSES.includes(String(doc.data().status)),
  );
  if (hasPendingPayout) {
    throw new HttpsError('failed-precondition', 'Wait for your pending payouts to settle before deleting your account.');
  }
  const hasPendingTopup = walletTopups.docs.some(
    (doc) => doc.data().status === 'CREATED',
  );
  if (hasPendingTopup) {
    throw new HttpsError('failed-precondition', 'A wallet top-up is still processing. Try again shortly.');
  }

  const savedAddresses = await db.collection('savedAddresses').where('userId', '==', uid).get();
  const safetyContacts = await db.collection('safetyContacts').where('userId', '==', uid).get();

  await db.runTransaction(async (tx) => {
    savedAddresses.docs.forEach((doc) => tx.delete(doc.ref));
    safetyContacts.docs.forEach((doc) => tx.delete(doc.ref));
    tx.delete(db.collection('driverPrivate').doc(uid));
    tx.set(
      db.collection('drivers').doc(uid),
      { isOnline: false, accountDeleted: true, updatedAt: Timestamp.now() },
      { merge: true },
    );
    tx.set(
      db.collection('users').doc(uid),
      {
        deletionState: 'DELETED',
        deletedAt: Timestamp.now(),
        displayName: FieldValue.delete(),
        email: FieldValue.delete(),
        phoneNumber: FieldValue.delete(),
        photoUrl: FieldValue.delete(),
        referralCode: FieldValue.delete(),
        fcmToken: FieldValue.delete(),
        updatedAt: Timestamp.now(),
      },
      { merge: true },
    );
  });

  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code !== 'auth/user-not-found') throw error;
  }

  return { deleted: true };
});
