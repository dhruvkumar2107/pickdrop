import { randomInt, timingSafeEqual } from 'crypto';

/** Generates a cryptographically random 4-digit OTP (0000–9999). */
export function generateOtp(): string {
  return randomInt(0, 10000).toString().padStart(4, '0');
}

/** Constant-time comparison of the supplied OTP against the stored one. */
export function verifyOtp(expected: string, provided: string): boolean {
  if (!expected || !provided) return false;
  const a = Buffer.from(expected);
  const b = Buffer.from(provided);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
