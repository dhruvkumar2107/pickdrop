import { test } from 'node:test';
import assert from 'node:assert/strict';
import { encodeGeohash, decodeGeohash, geohashNeighbors } from '../src/geohash';

test('encodeGeohash honours the requested precision', () => {
  assert.equal(encodeGeohash(12.9716, 77.5946).length, 5);
  assert.equal(encodeGeohash(12.9716, 77.5946, 7).length, 7);
});

test('decodeGeohash returns a cell containing the original point', () => {
  const lat = 12.9716;
  const lng = 77.5946;
  const decoded = decodeGeohash(encodeGeohash(lat, lng, 7));
  assert.ok(Math.abs(decoded.lat - lat) <= decoded.latErr);
  assert.ok(Math.abs(decoded.lng - lng) <= decoded.lngErr);
});

test('geohashNeighbors returns eight distinct neighbours', () => {
  const neighbors = geohashNeighbors(encodeGeohash(12.9716, 77.5946, 6));
  assert.equal(neighbors.length, 8);
  assert.equal(new Set(neighbors).size, 8);
});

test('decodeGeohash rejects invalid characters', () => {
  assert.throws(() => decodeGeohash('abc!'));
});
