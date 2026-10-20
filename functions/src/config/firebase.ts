import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
  // If running in development with projectId or emulator
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || 'ballhub-ac5a7',
  });
}

export const db = admin.firestore();
export const auth = admin.auth();
export { admin };
