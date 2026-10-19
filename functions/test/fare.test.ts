import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  haversineKm,
  calculateFare,
  estimateDurationMinutes,
  type VehicleTypePricing,
} from '../src/fare';

const vehicle: VehicleTypePricing = {
  id: 'mini_truck',
  name: 'Mini Truck',
  baseFare: 30,
  perKmRate: 15,
  perMinuteRate: 1.5,
  surgeMultiplier: 1,
  minimumFare: 60,
};

test('haversineKm returns 0 for identical points', () => {
  assert.equal(haversineKm({ lat: 12.9716, lng: 77.5946 }, { lat: 12.9716, lng: 77.5946 }), 0);
});

test('haversineKm approximates one degree of latitude', () => {
  const d = haversineKm({ lat: 0, lng: 0 }, { lat: 1, lng: 0 });
  assert.ok(d > 110 && d < 112, `expected ~111km, got ${d}`);
});

test('calculateFare never drops below the minimum fare', () => {
  const fare = calculateFare({
    vehicle,
    distanceKm: 0,
    durationMinutes: 0,
    gstPercent: 5,
  });
  assert.ok(fare.total >= vehicle.minimumFare, 'total must respect minimum fare');
  assert.equal(fare.subtotal, vehicle.minimumFare);
  assert.equal(fare.gst, Math.round(vehicle.minimumFare * 0.05 * 100) / 100);
});

test('calculateFare applies surge before the minimum-fare floor', () => {
  const fare = calculateFare({
    vehicle,
    distanceKm: 10,
    durationMinutes: 20,
    surgeMultiplier: 2,
    gstPercent: 5,
  });
  assert.equal(fare.surgeMultiplier, 2);
  assert.equal(fare.subtotal, Math.round((30 + 150 + 30) * 2 * 100) / 100);
});

test('estimateDurationMinutes scales with distance and has a floor', () => {
  assert.equal(estimateDurationMinutes(0), 5);
  assert.ok(estimateDurationMinutes(12.5) > estimateDurationMinutes(2.5));
});
