export interface StatusMessage {
  recipientId: string;
  title: string;
  body: string;
}

interface BookingSnapshot {
  status?: unknown;
  customerId?: unknown;
  driverId?: unknown;
  cancelledBy?: unknown;
}

/**
 * Maps a booking status transition to the people who should hear about it.
 * Pure so it can be unit-tested without Firebase.
 */
export function bookingStatusMessages(before: BookingSnapshot, after: BookingSnapshot): StatusMessage[] {
  if (before.status === after.status) return [];
  const customerId = typeof after.customerId === 'string' ? after.customerId : '';
  const driverId = typeof after.driverId === 'string' ? after.driverId : '';
  const toCustomer = (title: string, body: string): StatusMessage[] =>
    customerId ? [{ recipientId: customerId, title, body }] : [];

  switch (after.status) {
    case 'DRIVER_ASSIGNED':
      return toCustomer('Driver assigned', 'A driver accepted your delivery and is heading to pickup.');
    case 'PICKED_UP':
      return toCustomer('Goods picked up', 'Your goods are on the way. Share the drop code only at delivery.');
    case 'DELIVERED':
      return toCustomer('Delivered', 'Your delivery is complete. Rate your driver to help others.');
    case 'NO_DRIVER_FOUND':
      return toCustomer('No driver available', 'We could not find a driver nearby. Please try booking again in a few minutes.');
    case 'CANCELLED': {
      const messages: StatusMessage[] = [];
      if (after.cancelledBy !== customerId) {
        messages.push(...toCustomer('Booking cancelled', 'Your booking was cancelled. Open the app for details.'));
      }
      // Only drivers already on the trip need to know a customer cancelled.
      const driverWasAssigned = before.status === 'DRIVER_ASSIGNED' || before.status === 'PICKED_UP';
      if (driverId && driverWasAssigned && after.cancelledBy !== driverId) {
        messages.push({ recipientId: driverId, title: 'Trip cancelled', body: 'The customer cancelled this trip. You can go back online for new requests.' });
      }
      return messages;
    }
    default:
      return [];
  }
}

const SUPPORT_CATEGORIES = ['TRIP', 'PAYMENT', 'DAMAGE', 'ACCOUNT', 'OTHER'] as const;
export type SupportCategory = typeof SUPPORT_CATEGORIES[number];

/** Validates and normalises a customer support message. Throws a plain Error with a user-safe message. */
export function normaliseSupportTicket(input: { message?: unknown; category?: unknown; bookingId?: unknown }): {
  message: string;
  category: SupportCategory;
  bookingId: string | null;
} {
  const message = typeof input.message === 'string' ? input.message.trim() : '';
  if (message.length < 5) throw new Error('Describe the issue in at least 5 characters.');
  if (message.length > 1000) throw new Error('Keep the message under 1000 characters.');
  const category = SUPPORT_CATEGORIES.includes(input.category as SupportCategory)
    ? input.category as SupportCategory
    : 'OTHER';
  const bookingId = typeof input.bookingId === 'string' && input.bookingId.trim() ? input.bookingId.trim() : null;
  return { message, category, bookingId };
}
