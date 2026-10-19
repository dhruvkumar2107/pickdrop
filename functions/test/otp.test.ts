import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateOtp, verifyOtp } from '../src/otp';

test('generateOtp always returns four digits', () => {
  for (let i = 0; i < 200; i++) {
    assert.match(generateOtp(), /^\d{4}$/);
  }
});

test('verifyOtp accepts an exact match and rejects everything else', () => {
  assert.equal(verifyOtp('1234', '1234'), true);
  assert.equal(verifyOtp('1234', '1235'), false);
  assert.equal(verifyOtp('1234', '123'), false);
  assert.equal(verifyOtp('1234', ''), false);
  assert.equal(verifyOtp('', '1234'), false);
});
