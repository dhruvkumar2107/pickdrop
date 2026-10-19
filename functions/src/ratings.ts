import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

export const submitTripRating = onCall<{
  bookingId: string;
  rating: number;
  review?: string;
}>(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to submit a rating.');
  const { bookingId, rating, review = '' } = request.data ?? {};
  if (!bookingId || !Number.isInteger(rating) || rating < 1 || rating > 5 || review.length > 1000) {
    throw new HttpsError('invalid-argument', 'A booking and a rating from 1 to 5 are required.');
  }
  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const ratingRef = db.collection('ratings').doc(`${bookingId}_${uid}`);
  return db.runTransaction(async (tx) => {
    const [bookingSnap, ratingSnap] = await Promise.all([tx.get(bookingRef), tx.get(ratingRef)]);
    if (!bookingSnap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = bookingSnap.data()!;
    if (booking.customerId !== uid || booking.status !== 'DELIVERED' || !booking.driverId) {
      throw new HttpsError('failed-precondition', 'Only completed trips can be rated.');
    }
    if (ratingSnap.exists) throw new HttpsError('already-exists', 'This trip has already been rated.');
    const driverRef = db.collection('drivers').doc(String(booking.driverId));
    const driverSnap = await tx.get(driverRef);
    if (!driverSnap.exists) throw new HttpsError('not-found', 'Driver profile not found.');
    const driver = driverSnap.data()!;
    const count = Number(driver.ratingCount ?? 0);
    const average = Number(driver.rating ?? 0);
    const nextCount = count + 1;
    tx.create(ratingRef, {
      bookingId,
      fromUserId: uid,
      toUserId: booking.driverId,
      driverId: booking.driverId,
      rating,
      review: review.trim() || null,
      createdAt: Timestamp.now(),
    });
    tx.update(driverRef, {
      rating: Math.round(((average * count + rating) / nextCount) * 100) / 100,
      ratingCount: nextCount,
      updatedAt: Timestamp.now(),
    });
    return { success: true };
  });
});
