import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { Firestore, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { bookingStatusMessages, normaliseSupportTicket } from './notificationMessages';

const MAX_OPEN_TICKETS = 3;

function requireAuth(request: { auth?: { uid: string } }): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  return request.auth.uid;
}

/**
 * Stores an in-app inbox entry and pushes it to the user's device. Push
 * failures are logged, never thrown: the inbox entry is the durable record.
 */
async function notifyUser(
  db: Firestore,
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  await db.collection('notifications').add({
    userId,
    title,
    body,
    type: data.type ?? 'general',
    bookingId: data.bookingId ?? null,
    isRead: false,
    createdAt: Timestamp.now(),
  });
  const [user, driver] = await Promise.all([
    db.collection('users').doc(userId).get(),
    db.collection('drivers').doc(userId).get(),
  ]);
  const token = user.data()?.fcmToken ?? driver.data()?.fcmToken;
  if (typeof token !== 'string' || !token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data,
      android: { priority: 'high', notification: { channelId: 'booking_updates' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (error) {
    console.warn(`Push failed for user ${userId}`, error);
  }
}

/** Tells customers (and affected drivers) about every booking status change. */
export const notifyBookingStatus = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const messages = bookingStatusMessages(before, after);
  if (messages.length === 0) return;
  const db = getFirestore();
  const bookingId = event.params.bookingId;
  await Promise.all(messages.map((message) => notifyUser(db, message.recipientId, message.title, message.body, {
    type: 'booking_update',
    bookingId,
    status: String(after.status),
  })));
});

/** Opens a support ticket that admins answer from the review console. */
export const createSupportTicket = onCall(async (request) => {
  const uid = requireAuth(request);
  let ticket;
  try {
    ticket = normaliseSupportTicket(request.data ?? {});
  } catch (error) {
    throw new HttpsError('invalid-argument', (error as Error).message);
  }
  const db = getFirestore();
  if (ticket.bookingId) {
    const booking = await db.collection('bookings').doc(ticket.bookingId).get();
    const data = booking.data();
    if (!data || (data.customerId !== uid && data.driverId !== uid)) {
      throw new HttpsError('permission-denied', 'That trip is not linked to your account.');
    }
  }
  const open = await db.collection('supportTickets')
    .where('customerId', '==', uid)
    .where('status', '==', 'OPEN')
    .limit(MAX_OPEN_TICKETS)
    .get();
  if (open.size >= MAX_OPEN_TICKETS) {
    throw new HttpsError('resource-exhausted', 'You already have open requests. Our team will reply to those first.');
  }
  const ref = await db.collection('supportTickets').add({
    customerId: uid,
    ...ticket,
    status: 'OPEN',
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  return { ticketId: ref.id };
});

/** Admin reply that closes a ticket and lands in the customer's inbox. */
export const respondToSupportTicket = onCall<{ ticketId: string; reply: string }>(async (request) => {
  const adminUid = requireAuth(request);
  if (request.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admin access required.');
  const ticketId = request.data?.ticketId;
  const reply = typeof request.data?.reply === 'string' ? request.data.reply.trim() : '';
  if (!ticketId || reply.length < 2 || reply.length > 1000) {
    throw new HttpsError('invalid-argument', 'A ticket and a reply of up to 1000 characters are required.');
  }
  const db = getFirestore();
  const ref = db.collection('supportTickets').doc(ticketId);
  const customerId = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Ticket not found.');
    if (snap.data()?.status !== 'OPEN') throw new HttpsError('failed-precondition', 'Ticket is already closed.');
    tx.update(ref, {
      status: 'RESOLVED',
      reply,
      resolvedBy: adminUid,
      resolvedAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    return String(snap.data()?.customerId);
  });
  await notifyUser(db, customerId, 'PickDrop support replied', reply.slice(0, 180), {
    type: 'support_reply',
    ticketId,
  });
  return { ok: true };
});
