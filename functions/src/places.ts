import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

const placesServerKey = defineSecret('GOOGLE_PLACES_SERVER_KEY');
const PLACES_BASE = 'https://places.googleapis.com/v1';
const AUTOCOMPLETE_FIELDS = [
  'suggestions.placePrediction.placeId',
  'suggestions.placePrediction.text.text',
  'suggestions.placePrediction.structuredFormat.mainText.text',
  'suggestions.placePrediction.structuredFormat.secondaryText.text',
].join(',');

function requireUid(request: { auth?: { uid: string } | null }): string {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to search for a delivery location.');
  return request.auth.uid;
}

function requirePlacesKey(): string {
  const key = placesServerKey.value();
  if (!key) throw new HttpsError('failed-precondition', 'Place search is not configured yet.');
  return key;
}

function validSessionToken(value: unknown): value is string {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{16,36}$/.test(value);
}

async function consumeQuota(uid: string, kind: 'searches' | 'details', limit: number): Promise<void> {
  const ref = getFirestore().collection('placeSearchLimits').doc(uid);
  const now = Timestamp.now();
  await getFirestore().runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const data = snapshot.data();
    const startedAt = data?.windowStartedAt as Timestamp | undefined;
    const withinWindow = !!startedAt && now.toMillis() - startedAt.toMillis() < 60_000;
    const count = withinWindow ? Number(data?.[kind] ?? 0) : 0;
    if (count >= limit) throw new HttpsError('resource-exhausted', 'Too many place lookups. Wait a minute and try again.');
    tx.set(ref, {
      windowStartedAt: withinWindow ? startedAt : now,
      searches: withinWindow ? Number(data?.searches ?? 0) + (kind === 'searches' ? 1 : 0) : (kind === 'searches' ? 1 : 0),
      details: withinWindow ? Number(data?.details ?? 0) + (kind === 'details' ? 1 : 0) : (kind === 'details' ? 1 : 0),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

/** Autocomplete through the Places API from the server so the restricted key never ships in the app. */
export const searchPlaces = onCall<{ query: string; sessionToken: string; center?: { lat: number; lng: number } }>(
  { secrets: [placesServerKey] },
  async (request) => {
    const uid = requireUid(request);
    const query = String(request.data?.query ?? '').trim();
    const sessionToken = request.data?.sessionToken;
    if (query.length < 3 || query.length > 160 || !validSessionToken(sessionToken)) {
      throw new HttpsError('invalid-argument', 'Enter at least three characters to search.');
    }
    await consumeQuota(uid, 'searches', 30);
    const body: Record<string, unknown> = {
      input: query,
      includedRegionCodes: ['in'],
      regionCode: 'IN',
      languageCode: 'en',
      sessionToken,
    };
    const center = request.data?.center;
    if (center && Number.isFinite(center.lat) && Number.isFinite(center.lng) &&
        center.lat >= -90 && center.lat <= 90 && center.lng >= -180 && center.lng <= 180) {
      body.locationBias = {
        circle: { center: { latitude: center.lat, longitude: center.lng }, radius: 50000 },
      };
    }
    let response: Response;
    try {
      response = await fetch(`${PLACES_BASE}/places:autocomplete`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': requirePlacesKey(),
          'X-Goog-FieldMask': AUTOCOMPLETE_FIELDS,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(7000),
      });
    } catch {
      throw new HttpsError('unavailable', 'Place search is temporarily unavailable.');
    }
    if (!response.ok) throw new HttpsError('unavailable', 'Place search is temporarily unavailable.');
    const data = await response.json() as {
      suggestions?: Array<{ placePrediction?: {
        placeId?: string;
        text?: { text?: string };
        structuredFormat?: { mainText?: { text?: string }; secondaryText?: { text?: string } };
      } }>;
    };
    const suggestions = (data.suggestions ?? []).flatMap((suggestion) => {
      const prediction = suggestion.placePrediction;
      if (!prediction?.placeId || !prediction.text?.text) return [];
      return [{
        placeId: prediction.placeId,
        description: prediction.text.text,
        mainText: prediction.structuredFormat?.mainText?.text ?? prediction.text.text,
        secondaryText: prediction.structuredFormat?.secondaryText?.text ?? '',
      }];
    }).slice(0, 5);
    return { suggestions };
  },
);

/** Resolve one selected prediction into the exact map point used for route quoting. */
export const getPlaceDetails = onCall<{ placeId: string; sessionToken: string }>(
  { secrets: [placesServerKey] },
  async (request) => {
    const uid = requireUid(request);
    const placeId = String(request.data?.placeId ?? '');
    const sessionToken = request.data?.sessionToken;
    if (!/^[A-Za-z0-9_-]{10,200}$/.test(placeId) || !validSessionToken(sessionToken)) {
      throw new HttpsError('invalid-argument', 'The selected place is invalid. Search again.');
    }
    await consumeQuota(uid, 'details', 10);
    const url = new URL(`${PLACES_BASE}/places/${encodeURIComponent(placeId)}`);
    url.searchParams.set('sessionToken', sessionToken);
    let response: Response;
    try {
      response = await fetch(url, {
        headers: {
          'X-Goog-Api-Key': requirePlacesKey(),
          'X-Goog-FieldMask': 'id,formattedAddress,location',
        },
        signal: AbortSignal.timeout(7000),
      });
    } catch {
      throw new HttpsError('unavailable', 'Place details are temporarily unavailable.');
    }
    if (!response.ok) throw new HttpsError('unavailable', 'Place details are temporarily unavailable.');
    const place = await response.json() as {
      id?: string;
      formattedAddress?: string;
      location?: { latitude?: number; longitude?: number };
    };
    const lat = place.location?.latitude;
    const lng = place.location?.longitude;
    if (!place.formattedAddress || !Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new HttpsError('not-found', 'This place has no routable address. Choose another result.');
    }
    return { placeId: place.id ?? placeId, address: place.formattedAddress, lat, lng };
  },
);
