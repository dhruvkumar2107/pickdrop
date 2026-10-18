/** Minimal geohash implementation (base32, WGS84) for driver proximity queries. */

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export function encodeGeohash(lat: number, lng: number, precision = 5): string {
  let minLat = -90;
  let maxLat = 90;
  let minLng = -180;
  let maxLng = 180;
  let hash = '';
  let bit = 0;
  let ch = 0;
  let even = true;

  while (hash.length < precision) {
    if (even) {
      const mid = (minLng + maxLng) / 2;
      if (lng >= mid) {
        ch = (ch << 1) + 1;
        minLng = mid;
      } else {
        ch = ch << 1;
        maxLng = mid;
      }
    } else {
      const mid = (minLat + maxLat) / 2;
      if (lat >= mid) {
        ch = (ch << 1) + 1;
        minLat = mid;
      } else {
        ch = ch << 1;
        maxLat = mid;
      }
    }
    even = !even;
    bit++;
    if (bit === 5) {
      hash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}

interface Decoded {
  lat: number;
  lng: number;
  latErr: number;
  lngErr: number;
}

/** Returns the center of the cell plus its half-size in each axis. */
export function decodeGeohash(hash: string): Decoded {
  let minLat = -90;
  let maxLat = 90;
  let minLng = -180;
  let maxLng = 180;
  let even = true;

  for (const c of hash) {
    const cd = BASE32.indexOf(c);
    if (cd < 0) throw new Error(`Invalid geohash character: ${c}`);
    for (let mask = 16; mask > 0; mask >>= 1) {
      if (even) {
        const mid = (minLng + maxLng) / 2;
        if (cd & mask) minLng = mid;
        else maxLng = mid;
      } else {
        const mid = (minLat + maxLat) / 2;
        if (cd & mask) minLat = mid;
        else maxLat = mid;
      }
      even = !even;
    }
  }

  return {
    lat: (minLat + maxLat) / 2,
    lng: (minLng + maxLng) / 2,
    latErr: (maxLat - minLat) / 2,
    lngErr: (maxLng - minLng) / 2,
  };
}

/**
 * The 8 horizontally/diagonally adjacent cells (same precision).
 * Used to widen pickup-cell queries so drivers in bordering cells are found.
 */
export function geohashNeighbors(hash: string): string[] {
  const { lat, lng, latErr, lngErr } = decodeGeohash(hash);
  const at = (la: number, lo: number) => encodeGeohash(la, lo, hash.length);
  return [
    at(lat, lng + lngErr),
    at(lat, lng - lngErr),
    at(lat + latErr, lng),
    at(lat - latErr, lng),
    at(lat + latErr, lng + lngErr),
    at(lat + latErr, lng - lngErr),
    at(lat - latErr, lng + lngErr),
    at(lat - latErr, lng - lngErr),
  ];
}
