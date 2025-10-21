import dayjs from 'dayjs';
import { getFirestore, FirestoreUserDoc } from './firebaseAdmin.js';

const firestore = getFirestore();

export async function ensureUserDocument(userId: string) {
  const userRef = firestore.collection('users').doc(userId);
  const snapshot = await userRef.get();
  if (!snapshot.exists) {
    const now = dayjs().toISOString();
    await userRef.set({
      plan: 'free',
      monthlyDownloadCount: 0,
      currentPeriodEnd: dayjs().endOf('month').toISOString(),
      createdAt: now,
      updatedAt: now
    });
  }
  return userRef;
}

export async function storeStripeCustomerId(userId: string, customerId: string) {
  const userRef = await ensureUserDocument(userId);
  await userRef.set(
    {
      stripeCustomerId: customerId,
      updatedAt: dayjs().toISOString()
    },
    { merge: true }
  );
}

export async function updateSubscriptionStatus(userId: string, active: boolean, periodEnd?: number | null) {
  const userRef = await ensureUserDocument(userId);
  const update: FirestoreUserDoc = {
    plan: active ? 'premium' : 'free',
    updatedAt: dayjs().toISOString()
  };
  if (active && periodEnd) {
    update.currentPeriodEnd = dayjs.unix(periodEnd).toISOString();
  }
  if (!active) {
    update.monthlyDownloadCount = 0;
    update.currentPeriodEnd = dayjs().endOf('month').toISOString();
  }
  await userRef.set(update, { merge: true });
}

export async function getUserByStripeCustomer(customerId: string) {
  const snapshot = await firestore.collection('users').where('stripeCustomerId', '==', customerId).limit(1).get();
  if (snapshot.empty) return null;
  return snapshot.docs[0];
}
