import { DocumentReference, Firestore, Timestamp } from 'firebase-admin/firestore';
import { encodeGeohash, geohashNeighbors } from './geohash';
import { GeoPoint, haversineKm } from './fare';
import { AppConfig } from './config';

export interface MatchingBooking {
  id: string;
  pickup: GeoPoint;
}

interface CandidateDriver {
  id: string;
  distanceKm: number;
  fcmToken?: string;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/**
 * Finds online, verified drivers near the pickup point using a geohash
 * prefix query (pickup cell + 8 neighbours), then filters by haversine
 * radius and sorts by distance.
 */
export async function findNearbyDrivers(
  db: Firestore,
  pickup: GeoPoint,
  config: AppConfig,
): Promise<CandidateDriver[]> {
  const cell = encodeGeohash(pickup.lat, pickup.lng, 5);
  const prefixes = [cell, ...geohashNeighbors(cell)];

  const seen = new Map<string, CandidateDriver>();

  await Promise.all(
    prefixes.map(async (prefix) => {
      const snap = await db
        .collection('drivers')
        .where('isOnline', '==', true)
        .where('isVerified', '==', true)
        .where('geohash', '>=', prefix)
        .where('geohash', '<', prefix + '~')
        .limit(25)
        .get();

      for (const doc of snap.docs) {
        if (seen.has(doc.id)) continue;
        const data = doc.data();
        if (data.isMockLocation === true) continue;
        const loc = data.currentLocation;
        if (!loc) continue;
        const distanceKm = haversineKm(pickup, {
          lat: loc.latitude,
          lng: loc.longitude,
        });
        if (distanceKm <= config.driverMatchingRadiusKm) {
          seen.set(doc.id, {
            id: doc.id,
            distanceKm,
            fcmToken: data.fcmToken,
          });
        }
      }
    }),
  );

  return rankByReliability(db, [...seen.values()]);
}

/**
 * A2.1 — drops locked / fake-GPS drivers and promotes high reliability
 * scores by treating a good score as if the driver were slightly closer.
 */
async function rankByReliability(
  db: Firestore,
  drivers: CandidateDriver[],
): Promise<CandidateDriver[]> {
  if (drivers.length === 0) return [];

  const scores = await Promise.all(
    drivers.map(async (driver) => {
      const snap = await db.collection('driverScores').doc(driver.id).get();
      return snap.data() ?? {};
    }),
  );

  const ranked: Array<CandidateDriver & { priority: number }> = [];
  drivers.forEach((driver, index) => {
    const score = scores[index];
    if (score.isTemporarilyLocked === true) return;
    if (score.isFakeGpsDetected === true) return;
    const reliability = Number(score.compositeScore ?? 70);
    ranked.push({
      ...driver,
      priority: driver.distanceKm - (reliability / 100) * 1.5,
    });
  });

  return ranked.sort((a, b) => a.priority - b.priority);
}

/**
 * Cascade driver matching:
 *
 * 1. Query nearby drivers (geohash, radius-filtered, distance-sorted).
 * 2. Offer the trip to each driver in turn with a per-offer timeout.
 * 3. The first driver to `acceptOffer` wins → booking becomes DRIVER_ASSIGNED.
 * 4. If nobody accepts within `maxMatchingDurationMinutes` → NO_DRIVER_FOUND.
 *
 * Each offer is a `driverOffers/{bookingId}_{driverId}` document that the
 * driver client listens to (push sound + countdown UI).
 */
export async function runDriverMatching(
  db: Firestore,
  booking: MatchingBooking,
  config: AppConfig,
): Promise<void> {
  const bookingRef = db.collection('bookings').doc(booking.id);
  const deadline =
    Date.now() + config.maxMatchingDurationMinutes * 60 * 1000;
  const offerMs = config.driverOfferTimeoutSeconds * 1000;

  try {
    const drivers = await findNearbyDrivers(db, booking.pickup, config);
    console.log(
      `matching booking=${booking.id}: ${drivers.length} candidate(s)`,
    );

    for (const driver of drivers) {
      if (Date.now() >= deadline) break;

      // Abort if the booking moved on (cancelled, already assigned, …).
      const current = await bookingRef.get();
      const status = current.data()?.status;
      if (status !== 'SEARCHING') return;

      const offerId = `${booking.id}_${driver.id}`;
      const offerRef = db.collection('driverOffers').doc(offerId);
      await offerRef.set({
        bookingId: booking.id,
        driverId: driver.id,
        distanceKm: driver.distanceKm,
        pickup: { lat: booking.pickup.lat, lng: booking.pickup.lng },
        status: 'PENDING',
        expiresAt: Timestamp.fromMillis(Date.now() + offerMs),
        createdAt: Timestamp.now(),
      });

      // Nudge the driver (data-only payload; client shows the full-screen
      // request UI with sound/vibration).
      void notifyDriver(driver);

      const accepted = await waitForOfferDecision(
        offerRef,
        Math.min(offerMs, Math.max(0, deadline - Date.now())),
      );

      if (accepted) {
        const assigned = await assignDriver(db, booking.id, driver.id);
        if (assigned) return;
        await offerRef
          .update({ status: 'CANCELLED', reason: 'gps_validation_failed' })
          .catch(() => {});
        continue;
      }

      await offerRef.update({ status: 'EXPIRED' }).catch(() => {});
    }

    // Nobody accepted within the matching window.
    const finalSnap = await bookingRef.get();
    if (finalSnap.data()?.status === 'SEARCHING') {
      await bookingRef.update({
        status: 'NO_DRIVER_FOUND',
        updatedAt: Timestamp.now(),
      });
      await db.collection('driverOffers').where('bookingId', '==', booking.id)
        .get()
        .then((snap) =>
          Promise.all(snap.docs.map((d) => d.ref.update({ status: 'CANCELLED' }))),
        )
        .catch(() => {});
    }
  } catch (err) {
    console.error(`matching failed booking=${booking.id}`, err);
    await bookingRef
      .update({ status: 'NO_DRIVER_FOUND', updatedAt: Timestamp.now() })
      .catch(() => {});
  }
}

async function waitForOfferDecision(
  offerRef: DocumentReference,
  timeoutMs: number,
): Promise<boolean> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const snap = await offerRef.get();
    const status = snap.data()?.status;
    if (status === 'ACCEPTED') return true;
    if (status === 'REJECTED' || status === 'CANCELLED') return false;
    await sleep(1000);
  }
  return false;
}

/**
 * A2.3 — atomically flips the booking to DRIVER_ASSIGNED for the winning
 * driver, but only after the live GPS position is validated (within 3 km
 * of pickup and not a mock location).
 */
async function assignDriver(
  db: Firestore,
  bookingId: string,
  driverId: string,
): Promise<boolean> {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef = db.collection('drivers').doc(driverId);

  return db.runTransaction(async (tx) => {
    const [bookingSnap, driverSnap] = await Promise.all([
      tx.get(bookingRef),
      tx.get(driverRef),
    ]);
    if (bookingSnap.data()?.status !== 'SEARCHING') return false;

    const booking = bookingSnap.data() as {
      pickup?: { lat?: number; lng?: number };
    };
    const driver = driverSnap.data() as
      | {
          isMockLocation?: boolean;
          currentLocation?: { latitude?: number; longitude?: number };
        }
      | undefined;

    const pickup = booking.pickup;
    const loc = driver?.currentLocation;
    if (driver?.isMockLocation === true || !pickup?.lat || !loc?.latitude) {
      return false;
    }

    const distanceKm = haversineKm(
      { lat: pickup.lat, lng: pickup.lng ?? 0 },
      { lat: loc.latitude, lng: loc.longitude ?? 0 },
    );
    if (distanceKm > 3) return false;

    tx.update(bookingRef, {
      driverId,
      status: 'DRIVER_ASSIGNED',
      driverAssignedAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    return true;
  });
}

async function notifyDriver(driver: CandidateDriver): Promise<void> {
  if (!driver.fcmToken) return;
  // Wire up firebase-admin messaging here:
  //   await getMessaging().send({ token: driver.fcmToken, data: { ... } });
  // Kept as a no-op scaffold so the project builds without FCM configured.
}
