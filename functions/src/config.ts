import { Firestore } from 'firebase-admin/firestore';

/** Runtime configuration stored in `config/app`. */
export interface AppConfig {
  surgeMultiplier: number;
  commissionPercent: number;
  cancellationFreeWindowMinutes: number;
  cancellationFeeAfterAssignment: number;
  driverMatchingRadiusKm: number;
  driverOfferTimeoutSeconds: number;
  maxMatchingDurationMinutes: number;
  gstPercent: number;
  multiStopFee: number;
  /** Off until a licensed insurance partner backs the cover sold in-app. */
  transitInsuranceEnabled: boolean;
}

export const DEFAULT_CONFIG: AppConfig = {
  surgeMultiplier: 1.0,
  commissionPercent: 10,
  cancellationFreeWindowMinutes: 2,
  cancellationFeeAfterAssignment: 50,
  driverMatchingRadiusKm: 5,
  driverOfferTimeoutSeconds: 30,
  maxMatchingDurationMinutes: 3,
  gstPercent: 5,
  multiStopFee: 65,
  transitInsuranceEnabled: false,
};

/** Reads `config/app`, falling back to defaults for any missing field. */
export async function getConfig(db: Firestore): Promise<AppConfig> {
  try {
    const snap = await db.collection('config').doc('app').get();
    const data = snap.data() as Partial<AppConfig> | undefined;
    return { ...DEFAULT_CONFIG, ...(data ?? {}) };
  } catch (err) {
    console.error('getConfig failed, using defaults', err);
    return { ...DEFAULT_CONFIG };
  }
}
