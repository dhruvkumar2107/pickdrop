import { test } from 'node:test';
import assert from 'node:assert/strict';
import { commissionFor, FREE_TRIP_COUNT, DEFAULT_COMMISSION_PERCENT } from '../src/trust';

test('commission is waived for the first trips', () => {
  assert.equal(commissionFor(500, 0), 0);
  assert.equal(commissionFor(500, FREE_TRIP_COUNT - 1), 0);
});

test('commission applies the default rate once the free trips are used', () => {
  assert.equal(DEFAULT_COMMISSION_PERCENT, 10);
  assert.equal(commissionFor(500, FREE_TRIP_COUNT), 50);
});

test('commission rounds to the nearest paisa', () => {
  assert.equal(commissionFor(333.33, FREE_TRIP_COUNT), 33.33);
  assert.equal(commissionFor(19.99, FREE_TRIP_COUNT), 2);
});

test('commission honours a custom rate', () => {
  assert.equal(commissionFor(1000, 100, 7.5), 75);
});
