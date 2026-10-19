import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import * as crypto from 'crypto';

const razorpayKeyId = defineSecret('RAZORPAY_KEY_ID');
const razorpayKeySecret = defineSecret('RAZORPAY_KEY_SECRET');
const razorpayWebhookSecret = defineSecret('RAZORPAY_WEBHOOK_SECRET');

interface PaymentRequest { bookingId: string; }
interface VerifyPaymentRequest extends PaymentRequest {
  orderId: string;
  paymentId: string;
  signature: string;
}

function requireUser(request: { auth?: { uid: string } }): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  return request.auth.uid;
}

function requireRazorpayConfiguration(): { keyId: string; keySecret: string } {
  const keyId = razorpayKeyId.value();
  const keySecret = razorpayKeySecret.value();
  if (!keyId || !keySecret) {
    throw new HttpsError('failed-precondition', 'Online payments are not configured. Choose cash or contact support.');
  }
  return { keyId, keySecret };
}

function validSignature(orderId: string, paymentId: string, signature: string, keySecret: string): boolean {
  const expected = crypto.createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`).digest('hex');
  const expectedBytes = Buffer.from(expected, 'hex');
  const actualBytes = Buffer.from(signature, 'hex');
  return expectedBytes.length === actualBytes.length && crypto.timingSafeEqual(expectedBytes, actualBytes);
}

export const createRazorpayOrder = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  const uid = requireUser(request);
  const { keyId, keySecret } = requireRazorpayConfiguration();
  const bookingId = request.data?.bookingId as string | undefined;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId is required.');

  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw new HttpsError('not-found', 'Booking not found.');
  const booking = bookingSnap.data()!;
  if (booking.customerId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
  if (booking.paymentMethod !== 'razorpay' || booking.paymentStatus === 'paid') {
    throw new HttpsError('failed-precondition', 'This booking cannot be paid online.');
  }
  const amount = Math.round(Number(booking.fareBreakdown?.total ?? 0) * 100);
  if (!Number.isSafeInteger(amount) || amount < 100) {
    throw new HttpsError('failed-precondition', 'Booking does not have a valid authoritative fare.');
  }

  const Razorpay = (await import('razorpay')).default;
  const client = new Razorpay({ key_id: keyId, key_secret: keySecret });
  const order = await client.orders.create({ amount, currency: 'INR', receipt: bookingId, partial_payment: false });
  await bookingRef.update({ razorpayOrderId: order.id, paymentStatus: 'payment_pending', updatedAt: Timestamp.now() });
  return { orderId: order.id, amount: Number(order.amount), currency: order.currency, bookingId };
});

export const verifyPayment = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  const uid = requireUser(request);
  const { keyId, keySecret } = requireRazorpayConfiguration();
  const { orderId, paymentId, signature, bookingId } = (request.data ?? {}) as VerifyPaymentRequest;
  if (!orderId || !paymentId || !signature || !bookingId) {
    throw new HttpsError('invalid-argument', 'orderId, paymentId, signature, and bookingId are required.');
  }
  if (!validSignature(orderId, paymentId, signature, keySecret)) {
    throw new HttpsError('permission-denied', 'Invalid payment signature.');
  }

  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw new HttpsError('not-found', 'Booking not found.');
  const booking = bookingSnap.data()!;
  if (booking.customerId !== uid) throw new HttpsError('permission-denied', 'Not your booking.');
  if (booking.razorpayOrderId !== orderId) throw new HttpsError('failed-precondition', 'Payment order does not belong to this booking.');
  if (booking.paymentStatus === 'paid') return { accepted: true, paid: true, bookingId };

  // The callback signature proves the response originated from Checkout; query
  // Razorpay as well so a fabricated/stale callback can never settle the fare.
  const Razorpay = (await import('razorpay')).default;
  const client = new Razorpay({ key_id: keyId, key_secret: keySecret });
  const [order, payment] = await Promise.all([
    client.orders.fetch(orderId),
    client.payments.fetch(paymentId),
  ]);
  const expectedAmount = Math.round(Number(booking.fareBreakdown?.total ?? 0) * 100);
  if (order.id !== orderId || order.receipt !== bookingId || Number(order.amount) !== expectedAmount || order.currency !== 'INR') {
    throw new HttpsError('failed-precondition', 'Payment order does not match the booking fare.');
  }
  if (payment.order_id !== orderId || Number(payment.amount) !== expectedAmount || payment.currency !== 'INR') {
    throw new HttpsError('failed-precondition', 'Payment does not match the booking order.');
  }
  if (payment.status === 'authorized') {
    await client.payments.capture(paymentId, expectedAmount, 'INR');
  } else if (payment.status !== 'captured') {
    throw new HttpsError('failed-precondition', `Payment is not capturable (status: ${payment.status}).`);
  }

  await settleBookingPayment(db, {
    bookingId,
    orderId,
    paymentId,
    amountPaise: expectedAmount,
    userId: uid,
  });
  return { accepted: true, paid: true, bookingId };
});

export const createWalletTopupOrder = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  const uid = requireUser(request);
  const { keyId, keySecret } = requireRazorpayConfiguration();
  const amountRupees = Number(request.data?.amount);
  if (!Number.isInteger(amountRupees) || amountRupees < 100 || amountRupees > 10000) {
    throw new HttpsError('invalid-argument', 'Top-up must be a whole-rupee amount between ₹100 and ₹10,000.');
  }
  const Razorpay = (await import('razorpay')).default;
  const client = new Razorpay({ key_id: keyId, key_secret: keySecret });
  const receipt = `wallet_${uid}_${Date.now()}`;
  const order = await client.orders.create({ amount: amountRupees * 100, currency: 'INR', receipt, partial_payment: false });
  await getFirestore().collection('walletTopupOrders').doc(order.id).set({ userId: uid, amount: amountRupees, currency: 'INR', receipt, status: 'CREATED', createdAt: Timestamp.now() });
  return { orderId: order.id, amount: Number(order.amount), currency: order.currency };
});

export const verifyWalletTopup = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  const uid = requireUser(request);
  const { keyId, keySecret } = requireRazorpayConfiguration();
  const { orderId, paymentId, signature } = request.data ?? {};
  if (!orderId || !paymentId || !signature || !validSignature(String(orderId), String(paymentId), String(signature), keySecret)) {
    throw new HttpsError('permission-denied', 'Valid order, payment, and signature are required.');
  }
  const db = getFirestore();
  const orderRef = db.collection('walletTopupOrders').doc(String(orderId));
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists || orderSnap.data()?.userId !== uid) throw new HttpsError('permission-denied', 'Top-up order does not belong to this account.');
  const topup = orderSnap.data()!;
  if (topup.status === 'PAID') return { paid: true };
  const Razorpay = (await import('razorpay')).default;
  const client = new Razorpay({ key_id: keyId, key_secret: keySecret });
  const [order, payment] = await Promise.all([client.orders.fetch(String(orderId)), client.payments.fetch(String(paymentId))]);
  const amountPaise = Math.round(Number(topup.amount) * 100);
  if (order.id !== orderId || order.receipt !== topup.receipt) throw new HttpsError('failed-precondition', 'Top-up order mismatch.');
  if (Number(order.amount) !== amountPaise || order.currency !== 'INR' || payment.order_id !== orderId || Number(payment.amount) !== amountPaise || payment.currency !== 'INR') {
    throw new HttpsError('failed-precondition', 'Payment does not match the top-up amount.');
  }
  if (payment.status === 'authorized') await client.payments.capture(String(paymentId), amountPaise, 'INR');
  else if (payment.status !== 'captured') throw new HttpsError('failed-precondition', 'Payment is not captured.');
  await settleWalletTopup(db, uid, String(orderId), String(paymentId), Number(topup.amount));
  return { paid: true };
});

export const razorpayPaymentWebhook = onRequest({ secrets: [razorpayWebhookSecret] }, async (request, response) => {
  if (request.method !== 'POST') { response.status(405).send('Method not allowed'); return; }
  const secret = razorpayWebhookSecret.value();
  const signature = request.header('x-razorpay-signature') ?? '';
  const expected = crypto.createHmac('sha256', secret).update(request.rawBody).digest('hex');
  const actual = Buffer.from(signature, 'hex');
  const wanted = Buffer.from(expected, 'hex');
  if (!secret || actual.length !== wanted.length || !crypto.timingSafeEqual(actual, wanted)) { response.status(401).send('Invalid signature'); return; }
  if (request.body?.event !== 'payment.captured') { response.status(200).send('Ignored'); return; }
  const payment = request.body?.payload?.payment?.entity as Record<string, any> | undefined;
  const orderId = payment?.order_id as string | undefined;
  const paymentId = payment?.id as string | undefined;
  if (!payment || !orderId || !paymentId) { response.status(400).send('Missing payment references'); return; }
  const db = getFirestore();
  try {
    const order = await db.collection('walletTopupOrders').doc(orderId).get();
    if (order.exists) {
      if (Number(payment.amount) !== Math.round(Number(order.data()?.amount) * 100) || payment.currency !== 'INR') { response.status(200).send('Amount mismatch'); return; }
      await settleWalletTopup(db, String(order.data()?.userId), orderId, paymentId, Number(order.data()?.amount));
      response.status(200).send('OK');
      return;
    }
    // Otherwise this may be a booking fare. Reconcile it even if the client
    // never returned from Razorpay Checkout.
    const bookings = await db.collection('bookings').where('razorpayOrderId', '==', orderId).limit(1).get();
    if (bookings.empty) { response.status(200).send('Not a booking order'); return; }
    const bookingDoc = bookings.docs[0];
    const booking = bookingDoc.data();
    const expectedAmount = Math.round(Number(booking.fareBreakdown?.total ?? 0) * 100);
    if (payment.currency !== 'INR' || Number(payment.amount) !== expectedAmount) {
      response.status(200).send('Booking amount mismatch'); return;
    }
    if (booking.paymentStatus === 'paid') { response.status(200).send('Already settled'); return; }
    await settleBookingPayment(db, {
      bookingId: bookingDoc.id,
      orderId,
      paymentId,
      amountPaise: expectedAmount,
      userId: String(booking.customerId ?? ''),
    });
    response.status(200).send('OK');
  } catch (_) {
    response.status(500).send('Retry');
  }
});

/**
 * Idempotently marks a booking paid and moves it into SEARCHING. Shared by the
 * client verify call and the Razorpay webhook so a closed app can still settle.
 */
async function settleBookingPayment(
  db: FirebaseFirestore.Firestore,
  args: { bookingId: string; orderId: string; paymentId: string; amountPaise: number; userId: string },
): Promise<void> {
  const bookingRef = db.collection('bookings').doc(args.bookingId);
  const paymentRef = db.collection('payments').doc(args.paymentId);
  await db.runTransaction(async (tx) => {
    const [freshBooking, existingPayment] = await Promise.all([
      tx.get(bookingRef), tx.get(paymentRef),
    ]);
    if (!freshBooking.exists) throw new HttpsError('not-found', 'Booking not found.');
    const fresh = freshBooking.data()!;
    if (fresh.razorpayOrderId !== args.orderId) {
      throw new HttpsError('permission-denied', 'Booking payment ownership changed.');
    }
    if (fresh.paymentStatus === 'paid') return;
    if (existingPayment.exists && existingPayment.data()?.bookingId !== args.bookingId) {
      throw new HttpsError('already-exists', 'Payment is already linked to another booking.');
    }
    const now = Timestamp.now();
    tx.set(paymentRef, {
      userId: args.userId,
      bookingId: args.bookingId,
      amount: args.amountPaise / 100,
      currency: 'INR',
      method: 'razorpay',
      status: 'success',
      razorpayOrderId: args.orderId,
      razorpayPaymentId: args.paymentId,
      createdAt: existingPayment.data()?.createdAt ?? now,
      updatedAt: now,
    });
    tx.update(bookingRef, {
      paymentStatus: 'paid',
      status: 'SEARCHING',
      razorpayPaymentId: args.paymentId,
      updatedAt: now,
    });
  });
}

async function settleWalletTopup(db: FirebaseFirestore.Firestore, uid: string, orderId: string, paymentId: string, amount: number): Promise<void> {
  const orderRef = db.collection('walletTopupOrders').doc(orderId);
  const walletRef = db.collection('wallets').doc(uid);
  const transactionRef = db.collection('walletTransactions').doc(paymentId);
  await db.runTransaction(async (tx) => {
    const [fresh, wallet, existing] = await Promise.all([tx.get(orderRef), tx.get(walletRef), tx.get(transactionRef)]);
    if (fresh.data()?.status === 'PAID') return;
    if (!fresh.exists || fresh.data()?.userId !== uid || Number(fresh.data()?.amount) !== amount) throw new HttpsError('permission-denied', 'Top-up order ownership or amount mismatch.');
    if (existing.exists) throw new HttpsError('already-exists', 'Payment has already been credited.');
    tx.set(walletRef, { userId: uid, balance: Number(wallet.data()?.balance ?? 0) + amount, updatedAt: Timestamp.now() }, { merge: true });
    tx.create(transactionRef, { userId: uid, type: 'TOPUP', amount, status: 'SUCCESS', provider: 'razorpay', providerPaymentId: paymentId, orderId, createdAt: Timestamp.now() });
    tx.update(orderRef, { status: 'PAID', paymentId, paidAt: Timestamp.now() });
  });
}
