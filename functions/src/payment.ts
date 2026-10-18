import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, Firestore, Timestamp } from 'firebase-admin/firestore';
import * as crypto from 'crypto';

const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET ?? '';

interface VerifyPaymentRequest {
  orderId: string;
  paymentId: string;
  signature: string;
  bookingId: string;
}

interface VerifyPaymentResponse {
  verified: boolean;
  bookingId: string;
  message?: string;
}

function verifyRazorpaySignature(orderId: string, paymentId: string, signature: string): boolean {
  if (!RAZORPAY_KEY_SECRET) {
    console.warn('RAZORPAY_KEY_SECRET not set - skipping signature verification');
    return true;
  }

  const generatedSignature = crypto
    .createHmac('sha256', RAZORPAY_KEY_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  return generatedSignature === signature;
}

export const verifyPayment = onCall<VerifyPaymentRequest>(async (request): Promise<VerifyPaymentResponse> => {
  const { orderId, paymentId, signature, bookingId } = request.data ?? {};

  if (!orderId || !paymentId || !signature || !bookingId) {
    throw new HttpsError('invalid-argument', 'orderId, paymentId, signature, and bookingId are required.');
  }

  const isValidSignature = verifyRazorpaySignature(orderId, paymentId, signature);

  if (!isValidSignature) {
    return { verified: false, bookingId, message: 'Invalid payment signature' };
  }

  const db = getFirestore();
  const bookingRef = db.collection('bookings').doc(bookingId);

  await db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    if (!bookingSnap.exists) {
      throw new HttpsError('not-found', 'Booking not found.');
    }

    const booking = bookingSnap.data()!;
    if (booking.paymentStatus === 'paid') {
      throw new HttpsError('already-exists', 'Payment already verified.');
    }

    tx.update(bookingRef, {
      paymentStatus: 'paid',
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
      updatedAt: Timestamp.now(),
    });
  });

  return { verified: true, bookingId, message: 'Payment verified successfully' };
});

interface CreateRazorpayOrderRequest {
  amount: number; // in paise
  currency?: string;
  bookingId?: string;
}

interface CreateRazorpayOrderResponse {
  orderId: string;
  amount: number;
  currency: string;
}

export const createRazorpayOrder = onCall<CreateRazorpayOrderRequest>(async (request): Promise<CreateRazorpayOrderResponse> => {
  const { amount, currency = 'INR', bookingId } = request.data ?? {};

  if (!amount || amount <= 0) {
    throw new HttpsError('invalid-argument', 'Amount must be greater than 0.');
  }

  const Razorpay = (await import('razorpay')).default;
  const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID ?? '',
    key_secret: process.env.RAZORPAY_KEY_SECRET ?? '',
  });

  const order = await razorpay.orders.create({
    amount,
    currency,
    receipt: bookingId ?? `receipt_${Date.now()}`,
    partial_payment: false,
  });

  return {
    orderId: order.id,
    amount: Number(order.amount),
    currency: order.currency,
  };
});