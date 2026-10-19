import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { Firestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getConfig, AppConfig } from './config';
import { calculateFare, GeoPoint } from './fare';
import { getVehiclePricing } from './booking';
import { calculateRoadRoute, googleMapsServerKey } from './routing';

export interface PriceLockRequest {
  pickup: GeoPoint;
  drop: GeoPoint;
  vehicleTypeId: string;
  pickupAddress?: string;
  dropAddress?: string;
  goodsType?: string;
  notes?: string;
  loadingHelper?: boolean;
  stops?: Array<{ address: string; lat: number; lng: number }>;
}

export interface PriceLockResponse {
  priceLockId: string;
  fareBreakdown: {
    baseFare: number;
    distanceFare: number;
    timeFare: number;
    surgeMultiplier: number;
    subtotal: number;
    gst: number;
    total: number;
    minimumFare: number;
  };
  distanceKm: number;
  estimatedDurationMin: number;
  vehicleTypeId: string;
  vehicleTypeName: string;
  surgeMultiplier: number;
  expiresAt: Timestamp;
  version: number;
}

export interface PriceLockData {
  customerId: string;
  pickup: {
    address: string;
    lat: number;
    lng: number;
    geohash: string;
  };
  drop: {
    address: string;
    lat: number;
    lng: number;
    geohash: string;
  };
  vehicleTypeId: string;
  vehicleTypeName: string;
  distanceKm: number;
  estimatedDurationMin: number;
  fareBreakdown: {
    baseFare: number;
    distanceFare: number;
    timeFare: number;
    surgeMultiplier: number;
    subtotal: number;
    gst: number;
    total: number;
    minimumFare: number;
  };
  surgeMultiplier: number;
  goodsType?: string;
  notes?: string;
  loadingHelper?: boolean;
  version: number;
  status: 'active' | 'expired' | 'used' | 'cancelled';
  stops?: Array<{ address: string; lat: number; lng: number }>;
  createdAt: Timestamp;
  expiresAt: Timestamp;
  usedAt?: Timestamp;
  bookingId?: string;
}

/**
 * Creates a price lock — computes fare server-side and stores an immutable
 * price lock document that cannot be modified. Valid for 5 minutes.
 * The price shown at booking is locked; changes only allowed with
 * explicit customer approval (add stop, change destination, extend wait).
 */
export const createPriceLock = onCall<PriceLockRequest>({ secrets: [googleMapsServerKey] }, async (request) => {
  const uid = requireAuth(request);
  const data = request.data;
  
  if (!data?.pickup || !data?.drop || !data.vehicleTypeId) {
    throw new HttpsError('invalid-argument', 'pickup, drop and vehicleTypeId are required.');
  }

  const db = getFirestore();
  const config = await getConfig(db);
  const vehicle = await getVehiclePricing(db, data.vehicleTypeId);

  const stops = Array.isArray(data.stops) ? data.stops : [];
  if (stops.length > 5 || stops.some((p) => !Number.isFinite(p.lat) || !Number.isFinite(p.lng) || p.lat < -90 || p.lat > 90 || p.lng < -180 || p.lng > 180 || !p.address?.trim())) {
    throw new HttpsError('invalid-argument', 'Use up to five stops with a label and valid map position.');
  }
  const route = await calculateRoadRoute([data.pickup, ...stops, data.drop]);
  const distanceKm = route.distanceKm;
  if (distanceKm < 0.05) {
    throw new HttpsError('failed-precondition', 'Pickup and drop are too close.');
  }

  const durationMinutes = route.durationMinutes;
  const fare = calculateFare({
    vehicle,
    distanceKm,
    durationMinutes,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    gstPercent: config.gstPercent,
  });
  const stopFee = stops.length * config.multiStopFee;
  const stopGst = Math.round(stopFee * config.gstPercent) / 100;
  const totalFare = { ...fare, stopFee, subtotal: fare.subtotal + stopFee, gst: Math.round((fare.gst + stopGst) * 100) / 100, total: Math.round((fare.total + stopFee + stopGst) * 100) / 100 };

  // Create price lock document - immutable once created
  const priceLockRef = db.collection('priceLocks').doc();
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(now.toMillis() + 5 * 60 * 1000); // 5 minutes

  const priceLockData: PriceLockData = {
    customerId: uid,
    pickup: {
      address: data.pickupAddress ?? '',
      lat: data.pickup.lat,
      lng: data.pickup.lng,
      geohash: encodeGeohash(data.pickup.lat, data.pickup.lng),
    },
    drop: {
      address: data.dropAddress ?? '',
      lat: data.drop.lat,
      lng: data.drop.lng,
      geohash: encodeGeohash(data.drop.lat, data.drop.lng),
    },
    vehicleTypeId: data.vehicleTypeId,
    vehicleTypeName: vehicle.name,
    distanceKm,
    estimatedDurationMin: durationMinutes,
    fareBreakdown: totalFare,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    goodsType: data.goodsType ?? '',
    notes: data.notes ?? '',
    loadingHelper: data.loadingHelper ?? false,
    stops,
    version: 1,
    status: 'active',
    createdAt: Timestamp.now(),
    expiresAt,
  };

  await priceLockRef.set(priceLockData);

  return {
    priceLockId: priceLockRef.id,
    fareBreakdown: totalFare,
    distanceKm,
    estimatedDurationMin: durationMinutes,
    vehicleTypeId: data.vehicleTypeId,
    vehicleTypeName: vehicle.name,
    surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
    expiresAt,
    version: 1,
  };
});

/**
 * Validates a price lock and returns the locked fare if still valid.
 * Used by createBooking to verify the price lock hasn't been tampered with.
 */
export const validatePriceLock = onCall<{ priceLockId: string }>(async (request) => {
  const uid = requireAuth(request);
  const { priceLockId } = request.data ?? {};

  if (!priceLockId) {
    throw new HttpsError('invalid-argument', 'priceLockId is required.');
  }

  const db = getFirestore();
  const priceLockRef = db.collection('priceLocks').doc(priceLockId);
  const snap = await priceLockRef.get();

  if (!snap.exists) {
    throw new HttpsError('not-found', 'Price lock not found.');
  }

  const data = snap.data() as PriceLockData;

  // Verify ownership
  if (data.customerId !== uid) {
    throw new HttpsError('permission-denied', 'Not your price lock.');
  }

  // Check if expired
  const now = Date.now();
  if (data.expiresAt.toMillis() < now) {
    await priceLockRef.update({ status: 'expired' });
    throw new HttpsError('deadline-exceeded', 'Price lock has expired. Please get a new quote.');
  }

  // Check status
  if (data.status !== 'active') {
    throw new HttpsError('failed-precondition', `Price lock is ${data.status}.`);
  }

  return {
    valid: true,
    fareBreakdown: data.fareBreakdown,
    distanceKm: data.distanceKm,
    estimatedDurationMin: data.estimatedDurationMin,
    vehicleTypeId: data.vehicleTypeId,
    vehicleTypeName: data.vehicleTypeName,
    surgeMultiplier: data.surgeMultiplier,
    version: data.version,
    goodsType: data.goodsType,
    notes: data.notes,
    loadingHelper: data.loadingHelper,
  };
});

/**
 * Updates a price lock with a new version (for allowed changes like
 * adding a stop, changing destination, or extending wait time).
 * Requires explicit customer approval. Returns new price lock version.
 */
export const updatePriceLock = onCall<{
  priceLockId: string;
  newDrop?: { lat: number; lng: number; address: string };
  newPickup?: { lat: number; lng: number; address: string };
  addStop?: boolean;
  extendWaitMinutes?: number;
  customerApproved: boolean;
}>({ secrets: [googleMapsServerKey] }, async (request) => {
  const uid = requireAuth(request);
  const { priceLockId, newDrop, newPickup, addStop, extendWaitMinutes, customerApproved } = request.data ?? {};

  if (!priceLockId || !customerApproved) {
    throw new HttpsError('invalid-argument', 'priceLockId and customerApproved are required.');
  }

  const db = getFirestore();
  const priceLockRef = db.collection('priceLocks').doc(priceLockId);
  
  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(priceLockRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Price lock not found.');
    }

    const data = snap.data() as PriceLockData;

    // Verify ownership
    if (data.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Not your price lock.');
    }

    // Check if expired
    const now = Timestamp.now();
    if (data.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError('deadline-exceeded', 'Price lock has expired.');
    }

    // Check status
    if (data.status !== 'active') {
      throw new HttpsError('failed-precondition', `Price lock is ${data.status}.`);
    }

    // Get updated coordinates
    const pickup = newPickup ? { lat: newPickup.lat, lng: newPickup.lng } : { lat: data.pickup.lat, lng: data.pickup.lng };
    const drop = newDrop ? { lat: newDrop.lat, lng: newDrop.lng } : { lat: data.drop.lat, lng: data.drop.lng };

    // Recalculate distance and duration
    const route = await calculateRoadRoute([{ lat: pickup.lat, lng: pickup.lng }, ...(data.stops ?? []), { lat: drop.lat, lng: drop.lng }]);
    const distanceKm = route.distanceKm;
    if (distanceKm < 0.05) {
      throw new HttpsError('failed-precondition', 'Pickup and drop are too close.');
    }

    const db2 = getFirestore();
    const config = await getConfig(db2);
    const vehicle = await getVehiclePricing(db2, data.vehicleTypeId);

    const durationMinutes = route.durationMinutes;
    
    // Calculate additional waiting charge if extended
    let waitMinutes = 0;
    if (extendWaitMinutes && extendWaitMinutes > 0) {
      waitMinutes = extendWaitMinutes;
      // Free 10 min at pickup + 10 min at drop
      const freeWaitMinutes = 20;
      if (waitMinutes > freeWaitMinutes) {
        waitMinutes = waitMinutes - freeWaitMinutes;
      } else {
        waitMinutes = 0;
      }
    }

    // Add waiting fare
    const waitFare = waitMinutes * (vehicle.perMinuteRate ?? 0);

    const fare = calculateFare({
      vehicle,
      distanceKm,
      durationMinutes,
      surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
      gstPercent: config.gstPercent,
    });

    // Add waiting fare to subtotal and recalculate total
    const subtotalWithWait = fare.subtotal + waitFare;
    const gstWithWait = Math.round((subtotalWithWait * config.gstPercent) / 100 * 100) / 100;

    const updatedFare = {
      ...fare,
      subtotal: round2(subtotalWithWait),
      gst: gstWithWait,
      total: round2(subtotalWithWait + gstWithWait),
    };

    const newVersion = data.version + 1;
    const expiresAt = Timestamp.fromMillis(Date.now() + 5 * 60 * 1000); // Extend 5 minutes from now

    const updates = {
      version: newVersion,
      fareBreakdown: updatedFare,
      distanceKm,
      estimatedDurationMin: durationMinutes,
      expiresAt,
      updatedAt: Timestamp.now(),
      // Update pickup/drop if changed
      ...(newPickup ? {
        pickup: {
          address: newPickup.address,
          lat: newPickup.lat,
          lng: newPickup.lng,
          geohash: encodeGeohash(newPickup.lat, newPickup.lng),
        },
      } : {}),
      ...(newDrop ? {
        drop: {
          address: newDrop.address,
          lat: newDrop.lat,
          lng: newDrop.lng,
          geohash: encodeGeohash(newDrop.lat, newDrop.lng),
        },
      } : {}),
    };

    tx.update(priceLockRef, updates);

    return {
      priceLockId,
      fareBreakdown: updatedFare,
      distanceKm,
      estimatedDurationMin: durationMinutes,
      vehicleTypeId: data.vehicleTypeId,
      vehicleTypeName: data.vehicleTypeName,
      surgeMultiplier: config.surgeMultiplier * (vehicle.surgeMultiplier ?? 1),
      expiresAt,
      version: newVersion,
    };
  });
});

/**
 * Marks a price lock as used when a booking is created from it.
 */
export const markPriceLockUsed = async (priceLockId: string, bookingId: string): Promise<void> => {
  const db = getFirestore();
  await db.collection('priceLocks').doc(priceLockId).update({
    status: 'used',
    usedAt: Timestamp.now(),
    bookingId,
  });
};

function requireAuth(request: { auth?: { uid: string } }): string {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return request.auth.uid;
}

function encodeGeohash(lat: number, lng: number): string {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  let latMin = -90, latMax = 90;
  let lngMin = -180, lngMax = 180;
  let geohash = '';
  let bit = 0;
  let ch = 0;
  let evenBit = true;

  while (geohash.length < 8) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch = (ch << 1) | 1;
        lngMin = mid;
      } else {
        ch = (ch << 1) | 0;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch = (ch << 1) | 1;
        latMin = mid;
      } else {
        ch = (ch << 1) | 0;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (bit < 4) {
      bit++;
    } else {
      geohash += base32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return geohash;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
