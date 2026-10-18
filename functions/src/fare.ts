/** Fare calculation — the single source of truth for pricing. */

export interface VehicleTypePricing {
  id: string;
  name: string;
  baseFare: number;
  perKmRate: number;
  perMinuteRate: number;
  minimumFare: number;
  surgeMultiplier?: number;
  capacityKg?: number;
}

export interface FareBreakdown {
  baseFare: number;
  distanceFare: number;
  timeFare: number;
  surgeMultiplier: number;
  subtotal: number;
  gst: number;
  total: number;
  minimumFare: number;
}

export interface GeoPoint {
  lat: number;
  lng: number;
}

const round2 = (n: number): number => Math.round(n * 100) / 100;

/**
 * Great-circle distance in kilometres.
 */
export function haversineKm(a: GeoPoint, b: GeoPoint): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return round2(2 * R * Math.asin(Math.sqrt(s)));
}

/**
 * Computes the full fare breakdown.
 *
 * fare = (base + distance*perKm + time*perMin) * surge, floored at minimumFare,
 * then GST is added on top.
 */
export function calculateFare(params: {
  vehicle: VehicleTypePricing;
  distanceKm: number;
  durationMinutes: number;
  surgeMultiplier?: number;
  gstPercent: number;
}): FareBreakdown {
  const { vehicle, distanceKm, durationMinutes, gstPercent } = params;
  const surge =
    params.surgeMultiplier ?? vehicle.surgeMultiplier ?? 1.0;

  const distanceFare = distanceKm * vehicle.perKmRate;
  const timeFare = durationMinutes * vehicle.perMinuteRate;

  const rawSubtotal = vehicle.baseFare + distanceFare + timeFare;
  const surged = rawSubtotal * surge;
  const subtotal = Math.max(surged, vehicle.minimumFare);

  const gst = round2((subtotal * gstPercent) / 100);

  return {
    baseFare: round2(vehicle.baseFare),
    distanceFare: round2(distanceFare),
    timeFare: round2(timeFare),
    surgeMultiplier: surge,
    subtotal: round2(subtotal),
    gst,
    total: round2(subtotal + gst),
    minimumFare: vehicle.minimumFare,
  };
}

/**
 * Estimates duration in minutes assuming an average urban speed of 25 km/h
 * plus a 2 minute fixed overhead. Replace with a Directions API call for
 * production-grade ETAs.
 */
export function estimateDurationMinutes(distanceKm: number): number {
  return Math.max(5, Math.round((distanceKm / 25) * 60) + 2);
}
