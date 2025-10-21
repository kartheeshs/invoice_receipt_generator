import admin from 'firebase-admin';

let initialized = false;

export function initFirebase() {
  if (initialized) return admin;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!admin.apps.length) {
    if (serviceAccountJson) {
      const credentials = JSON.parse(Buffer.from(serviceAccountJson, 'base64').toString());
      admin.initializeApp({
        credential: admin.credential.cert(credentials)
      });
    } else {
      admin.initializeApp();
    }
  }
  initialized = true;
  return admin;
}

export function getFirestore() {
  return initFirebase().firestore();
}

export type FirestoreUserDoc = {
  plan?: 'free' | 'premium';
  stripeCustomerId?: string;
  monthlyDownloadCount?: number;
  currentPeriodEnd?: string;
  updatedAt?: string;
};
