import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bookingStatusMessages, normaliseSupportTicket } from '../src/notificationMessages';

test('no messages when status is unchanged', () => {
  assert.deepEqual(bookingStatusMessages({ status: 'PICKED_UP' }, { status: 'PICKED_UP', customerId: 'c' }), []);
});

test('customer hears about assignment, pickup and delivery', () => {
  for (const status of ['DRIVER_ASSIGNED', 'PICKED_UP', 'DELIVERED', 'NO_DRIVER_FOUND']) {
    const messages = bookingStatusMessages({ status: 'SEARCHING' }, { status, customerId: 'c', driverId: 'd' });
    assert.equal(messages.length, 1);
    assert.equal(messages[0].recipientId, 'c');
  }
});

test('customer cancellation notifies only the assigned driver', () => {
  const messages = bookingStatusMessages(
    { status: 'DRIVER_ASSIGNED' },
    { status: 'CANCELLED', customerId: 'c', driverId: 'd', cancelledBy: 'c' },
  );
  assert.deepEqual(messages.map((m) => m.recipientId), ['d']);
});

test('cancellation while searching does not notify an unassigned driver', () => {
  const messages = bookingStatusMessages(
    { status: 'SEARCHING' },
    { status: 'CANCELLED', customerId: 'c', driverId: null, cancelledBy: 'c' },
  );
  assert.deepEqual(messages, []);
});

test('support tickets are validated and normalised', () => {
  assert.throws(() => normaliseSupportTicket({ message: 'hi' }));
  assert.throws(() => normaliseSupportTicket({ message: 'x'.repeat(1001) }));
  assert.deepEqual(
    normaliseSupportTicket({ message: '  Goods were damaged  ', category: 'DAMAGE', bookingId: ' b1 ' }),
    { message: 'Goods were damaged', category: 'DAMAGE', bookingId: 'b1' },
  );
  assert.equal(normaliseSupportTicket({ message: 'Something else', category: 'BOGUS' }).category, 'OTHER');
});
