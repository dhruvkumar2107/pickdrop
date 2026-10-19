import { HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { GeoPoint } from './fare';

export const googleMapsServerKey = defineSecret('GOOGLE_MAPS_SERVER_KEY');

/** Road distance and drive time for a route with ordered intermediate stops. */
export async function calculateRoadRoute(points: GeoPoint[]): Promise<{ distanceKm: number; durationMinutes: number }> {
  if (points.length < 2 || points.length > 7) throw new HttpsError('invalid-argument', 'A route must contain an origin, destination, and up to five stops.');
  const key = googleMapsServerKey.value();
  if (!key) throw new HttpsError('failed-precondition', 'Server-side Google Routes is not configured.');
  const latLng = (point: GeoPoint) => ({ location: { latLng: { latitude: point.lat, longitude: point.lng } } });
  let response: Response;
  try {
    response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': key, 'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration' },
      body: JSON.stringify({ origin: latLng(points[0]), destination: latLng(points[points.length - 1]), intermediates: points.slice(1, -1).map(latLng), travelMode: 'DRIVE', routingPreference: 'TRAFFIC_AWARE', computeAlternativeRoutes: false, units: 'METRIC' }),
    });
  } catch (_) {
    throw new HttpsError('unavailable', 'Could not calculate the road route. Retry when connectivity is restored.');
  }
  if (!response.ok) throw new HttpsError('unavailable', 'The route provider could not calculate this delivery route.');
  const payload = await response.json() as { routes?: Array<{ distanceMeters?: number; duration?: string }> };
  const route = payload.routes?.[0];
  const distanceMeters = Number(route?.distanceMeters);
  const seconds = Number(route?.duration?.replace(/s$/, ''));
  if (!route || !Number.isFinite(distanceMeters) || !Number.isFinite(seconds) || distanceMeters <= 0 || seconds <= 0) {
    throw new HttpsError('failed-precondition', 'No drivable route was found for these locations.');
  }
  return { distanceKm: Math.round((distanceMeters / 1000) * 100) / 100, durationMinutes: Math.max(1, Math.ceil(seconds / 60)) };
}
