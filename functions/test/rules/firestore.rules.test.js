const { test, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'demo-pickdrop';
const RULES = fs.readFileSync(
  path.join(__dirname, '../../../firestore.rules'),
  'utf8',
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

afterEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

const as = (uid, claims) => testEnv.authenticatedContext(uid, claims).firestore();
const anon = () => testEnv.unauthenticatedContext().firestore();

async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

test('users: owner may create self as customer, cannot self-promote to admin', async () => {
  await assertSucceeds(
    as('alice').collection('users').doc('alice').set({
      uid: 'alice',
      role: 'customer',
      displayName: 'Alice',
    }),
  );
  await assertFails(
    as('bob')
      .collection('users')
      .doc('alice')
      .set({ uid: 'alice', role: 'customer' }),
  );
  await assertFails(
    as('bob').collection('users').doc('bob').set({ uid: 'bob', role: 'admin' }),
  );
});

test('users: only the owner can read their profile', async () => {
  await seed(async (db) => {
    await db.collection('users').doc('alice').set({ uid: 'alice', role: 'customer' });
  });
  await assertSucceeds(as('alice').collection('users').doc('alice').get());
  await assertFails(as('bob').collection('users').doc('alice').get());
  await assertFails(anon().collection('users').doc('alice').get());
});

test('users: update cannot escalate role to admin', async () => {
  await seed(async (db) => {
    await db.collection('users').doc('alice').set({ uid: 'alice', role: 'customer' });
  });
  await assertSucceeds(
    as('alice').collection('users').doc('alice').update({ displayName: 'Alice' }),
  );
  await assertFails(
    as('alice').collection('users').doc('alice').update({ role: 'admin' }),
  );
});

test('bookings: only participants and admins can read; no client writes', async () => {
  await seed(async (db) => {
    await db
      .collection('bookings')
      .doc('b1')
      .set({ customerId: 'alice', driverId: 'dan', status: 'SEARCHING' });
  });
  await assertSucceeds(as('alice').collection('bookings').doc('b1').get());
  await assertSucceeds(as('dan').collection('bookings').doc('b1').get());
  await assertSucceeds(as('root', { role: 'admin' }).collection('bookings').doc('b1').get());
  await assertFails(as('mallory').collection('bookings').doc('b1').get());
  await assertFails(as('alice').collection('bookings').doc('b1').update({ status: 'DELIVERED' }));
  await assertFails(as('alice').collection('bookings').doc('b1').delete());
});

test('payments: owner read only, never client-writable', async () => {
  await seed(async (db) => {
    await db.collection('payments').doc('p1').set({ userId: 'alice', amount: 300, status: 'success' });
  });
  await assertSucceeds(as('alice').collection('payments').doc('p1').get());
  await assertFails(as('bob').collection('payments').doc('p1').get());
  await assertFails(as('alice').collection('payments').doc('p1').set({ userId: 'alice', amount: 1 }));
});

test('wallets and ledger: owner read only, server-only writes', async () => {
  await seed(async (db) => {
    await db.collection('wallets').doc('alice').set({ userId: 'alice', balance: 500 });
    await db.collection('walletTransactions').doc('t1').set({ userId: 'alice', amount: 500 });
    await db.collection('driverLedger').doc('l1').set({ driverId: 'dan', amount: 240 });
  });
  await assertSucceeds(as('alice').collection('wallets').doc('alice').get());
  await assertFails(as('dan').collection('wallets').doc('alice').get());
  await assertSucceeds(as('alice').collection('walletTransactions').doc('t1').get());
  await assertFails(as('alice').collection('wallets').doc('alice').update({ balance: 99999 }));
  await assertSucceeds(as('dan').collection('driverLedger').doc('l1').get());
});

test('driverPayouts: owner read only; no auto-complete from client', async () => {
  await seed(async (db) => {
    await db.collection('driverPayouts').doc('pay1').set({ driverId: 'dan', status: 'PENDING_REVIEW', amount: 1000 });
  });
  await assertSucceeds(as('dan').collection('driverPayouts').doc('pay1').get());
  await assertFails(as('alice').collection('driverPayouts').doc('p1').get());
  await assertFails(as('dan').collection('driverPayouts').doc('pay1').update({ status: 'PAID' }));
});

test('driverPrivate (KYC): owner read only, never client-writable', async () => {
  await seed(async (db) => {
    await db.collection('driverPrivate').doc('dan').set({ uid: 'dan', licenseNumber: 'X123', status: 'PENDING_REVIEW' });
  });
  await assertSucceeds(as('dan').collection('driverPrivate').doc('dan').get());
  await assertFails(as('alice').collection('driverPrivate').doc('dan').get());
  await assertFails(as('dan').collection('driverPrivate').doc('dan').update({ status: 'APPROVED' }));
});

test('bookingSecrets (OTPs): customer read only, no client writes', async () => {
  await seed(async (db) => {
    await db.collection('bookingSecrets').doc('b1').set({ customerId: 'alice', pickupOtp: '1234' });
  });
  await assertSucceeds(as('alice').collection('bookingSecrets').doc('b1').get());
  await assertFails(as('dan').collection('bookingSecrets').doc('b1').get());
  await assertFails(as('alice').collection('bookingSecrets').doc('b1').update({ pickupOtp: '0000' }));
});

test('chat: participants write valid messages, outsiders cannot', async () => {
  await seed(async (db) => {
    await db
      .collection('bookings')
      .doc('b1')
      .set({ customerId: 'alice', driverId: 'dan', status: 'PICKED_UP' });
  });
  const msg = (extra) => ({
    senderId: 'alice',
    senderRole: 'customer',
    text: 'On my way',
    createdAt: new Date(),
    ...extra,
  });
  await assertSucceeds(
    as('alice').collection('bookings').doc('b1').collection('chatMessages').doc('m1').set(msg({})),
  );
  await assertFails(
    as('mallory').collection('bookings').doc('b1').collection('chatMessages').doc('m2').set(
      msg({ senderId: 'mallory' }),
    ),
  );
  await assertFails(
    as('alice').collection('bookings').doc('b1').collection('chatMessages').doc('m3').set(
      msg({ senderRole: 'driver' }),
    ),
  );
});

test('safetyContacts: owner can create/delete with strict fields, not read others', async () => {
  await seed(async (db) => {
    await db.collection('safetyContacts').doc('c1').set({ userId: 'alice', name: 'Mom', phone: '9999999999' });
  });
  await assertSucceeds(as('alice').collection('safetyContacts').doc('c1').get());
  await assertFails(as('bob').collection('safetyContacts').doc('c1').get());
  await assertSucceeds(
    as('alice').collection('safetyContacts').doc('c2').set({
      userId: 'alice',
      name: 'Dad',
      phone: '8888888888',
      createdAt: new Date(),
    }),
  );
  await assertFails(
    as('alice').collection('safetyContacts').doc('c3').set({
      userId: 'alice',
      name: 'X',
      phone: '1',
      createdAt: new Date(),
    }),
  );
  await assertFails(
    as('alice').collection('safetyContacts').doc('c4').set({
      userId: 'alice',
      name: 'Ok',
      phone: '8888888888',
      extra: true,
      createdAt: new Date(),
    }),
  );
  await assertSucceeds(as('alice').collection('safetyContacts').doc('c1').delete());
});

test('driverPayouts/admin: admins can read, non-admins cannot', async () => {
  await seed(async (db) => {
    await db.collection('driverPayouts').doc('p1').set({ driverId: 'dan', amount: 100 });
  });
  await assertSucceeds(as('root', { role: 'admin' }).collection('driverPayouts').doc('p1').get());
  await assertFails(as('mallory').collection('driverPayouts').doc('p1').get());
});

test('unlisted collections are denied by default', async () => {
  await seed(async (db) => {
    await db.collection('secrets_bucket').doc('x').set({ secret: 'value' });
  });
  await assertFails(as('alice').collection('sosAlerts').doc('s1').get());
  await assertFails(as('alice').collection('walletTopupOrders').doc('o1').set({ userId: 'alice' }));
  await assertFails(as('alice').collection('secretStuff').doc('x').get());
});
