'use strict';

const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const expectedProject = 'pickdrop-dk2107';
const projectId = process.env.PICKDROP_FIREBASE_PROJECT_ID;
const uid = process.argv[2];

if (projectId !== expectedProject) {
  throw new Error(`Set PICKDROP_FIREBASE_PROJECT_ID=${expectedProject} before running this script.`);
}
if (!uid || uid.length > 128) {
  throw new Error('Usage: npm run grant-admin -- <firebase-auth-uid>');
}

initializeApp({ credential: applicationDefault(), projectId });

async function grantAdmin() {
  const auth = getAuth();
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), role: 'admin' });
  process.stdout.write(`Granted role=admin to Firebase Auth UID ${uid} in ${projectId}. The user must refresh their ID token.\n`);
}

grantAdmin().catch((error) => {
  process.stderr.write(`Admin claim update failed: ${error.message}\n`);
  process.exitCode = 1;
});
