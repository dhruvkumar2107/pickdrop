#!/usr/bin/env node
// Seed script for Firestore - Vehicle Types, Config, and Demo Data
// Run with: node scripts/seed.js

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
let app;

if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  console.log('Using default credentials (emulator or CI)');
  app = admin.initializeApp();
}

const db = admin.firestore();

const VEHICLE_TYPES = [
  {
    id: 'bike',
    name: 'Bike / Scooter',
    icon: 'assets/icons/ic_bike.svg',
    capacityKg: 20,
    baseFare: 30,
    perKmRate: 12,
    perMinuteRate: 1.5,
    minimumFare: 40,
    surgeMultiplier: 1.0,
    isActive: true,
    sortOrder: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'three_wheeler',
    name: '3-Wheeler / Tata Ace',
    icon: 'assets/icons/ic_three_wheeler.svg',
    capacityKg: 750,
    baseFare: 80,
    perKmRate: 22,
    perMinuteRate: 3,
    minimumFare: 120,
    surgeMultiplier: 1.0,
    isActive: true,
    sortOrder: 2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'mini_truck',
    name: 'Mini Truck 8ft',
    icon: 'assets/icons/ic_mini_truck.svg',
    capacityKg: 1250,
    baseFare: 150,
    perKmRate: 35,
    perMinuteRate: 5,
    minimumFare: 250,
    surgeMultiplier: 1.0,
    isActive: true,
    sortOrder: 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'pickup',
    name: 'Pickup 9ft',
    icon: 'assets/icons/ic_pickup.svg',
    capacityKg: 1500,
    baseFare: 200,
    perKmRate: 45,
    perMinuteRate: 6,
    minimumFare: 350,
    surgeMultiplier: 1.0,
    isActive: true,
    sortOrder: 4,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

const APP_CONFIG = {
  surgeMultiplier: 1.0,
  commissionPercent: 15,
  cancellationFreeWindowMinutes: 2,
  cancellationFeeAfterAssignment: 50,
  driverMatchingRadiusKm: 5,
  driverOfferTimeoutSeconds: 30,
  maxMatchingDurationMinutes: 3,
  gstPercent: 5,
};

const COUPONS = [
  {
    id: 'FIRST50',
    code: 'FIRST50',
    type: 'percentage',
    value: 50,
    minOrderValue: 100,
    maxDiscount: 100,
    usageLimit: 1000,
    usedCount: 0,
    validFrom: admin.firestore.Timestamp.fromDate(new Date()),
    validUntil: admin.firestore.Timestamp.fromDate(new Date('2026-12-31')),
    isActive: true,
    applicableVehicleTypes: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'PICKUP20',
    code: 'PICKUP20',
    type: 'flat',
    value: 20,
    minOrderValue: 150,
    maxDiscount: null,
    usageLimit: 5000,
    usedCount: 0,
    validFrom: admin.firestore.Timestamp.fromDate(new Date()),
    validUntil: admin.firestore.Timestamp.fromDate(new Date('2026-12-31')),
    isActive: true,
    applicableVehicleTypes: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'WEEKEND30',
    code: 'WEEKEND30',
    type: 'percentage',
    value: 30,
    minOrderValue: 200,
    maxDiscount: 75,
    usageLimit: 2000,
    usedCount: 0,
    validFrom: admin.firestore.Timestamp.fromDate(new Date()),
    validUntil: admin.firestore.Timestamp.fromDate(new Date('2026-12-31')),
    isActive: true,
    applicableVehicleTypes: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function seedVehicleTypes() {
  console.log('Seeding vehicle types...');
  const batch = db.batch();

  for (const vehicle of VEHICLE_TYPES) {
    const ref = db.collection('vehicleTypes').doc(vehicle.id);
    batch.set(ref, vehicle);
  }

  await batch.commit();
  console.log(`✅ Seeded ${VEHICLE_TYPES.length} vehicle types`);
}

async function seedConfig() {
  console.log('Seeding app config...');
  await db.collection('config').doc('app').set(APP_CONFIG);
  console.log('✅ Seeded app config');
}

async function seedCoupons() {
  console.log('Seeding coupons...');
  const batch = db.batch();

  for (const coupon of COUPONS) {
    const ref = db.collection('coupons').doc(coupon.id);
    batch.set(ref, coupon);
  }

  await batch.commit();
  console.log(`✅ Seeded ${COUPONS.length} coupons`);
}

async function main() {
  console.log('🌱 Starting Firestore seed...\n');

  try {
    await seedVehicleTypes();
    await seedConfig();
    await seedCoupons();

    console.log('\n✨ Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

main();