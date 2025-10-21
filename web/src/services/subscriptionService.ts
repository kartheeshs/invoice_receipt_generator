import dayjs from 'dayjs';
import {
  doc,
  firestore,
  getDoc,
  setDoc,
  updateDoc
} from './firebase';
import { SubscriptionInfo } from '../types/invoice';

const FREE_PLAN_LIMIT = 3;

const defaultSubscription: SubscriptionInfo = {
  plan: 'free',
  monthlyDownloadCount: 0
};

export async function ensureUserProfile(userId: string) {
  const userRef = doc(firestore, 'users', userId);
  const snapshot = await getDoc(userRef);

  if (!snapshot.exists()) {
    await setDoc(userRef, {
      ...defaultSubscription,
      createdAt: dayjs().toISOString(),
      updatedAt: dayjs().toISOString(),
      currentPeriodEnd: dayjs().endOf('month').toISOString()
    });
    return defaultSubscription;
  }

  const data = snapshot.data() as SubscriptionInfo & { currentPeriodEnd?: string };
  return data;
}

export async function getSubscription(userId: string): Promise<SubscriptionInfo> {
  const userRef = doc(firestore, 'users', userId);
  const snapshot = await getDoc(userRef);

  if (!snapshot.exists()) {
    return defaultSubscription;
  }

  const data = snapshot.data() as SubscriptionInfo;
  if (data.plan === 'free') {
    const resetNeeded = isResetNeeded(data);
    if (resetNeeded) {
      const updated = { ...data, monthlyDownloadCount: 0, currentPeriodEnd: calculateNextPeriodEnd() };
      await updateDoc(userRef, {
        monthlyDownloadCount: updated.monthlyDownloadCount,
        currentPeriodEnd: updated.currentPeriodEnd,
        updatedAt: dayjs().toISOString()
      });
      return updated;
    }
  }
  return data;
}

function isResetNeeded(info: SubscriptionInfo) {
  if (!info.currentPeriodEnd) {
    return true;
  }
  return dayjs().isAfter(dayjs(info.currentPeriodEnd));
}

function calculateNextPeriodEnd() {
  return dayjs().endOf('month').toISOString();
}

export async function recordDownload(userId: string) {
  const userRef = doc(firestore, 'users', userId);
  let snapshot = await getDoc(userRef);
  if (!snapshot.exists()) {
    await ensureUserProfile(userId);
    snapshot = await getDoc(userRef);
  }
  const data = snapshot.exists() ? (snapshot.data() as SubscriptionInfo) : defaultSubscription;

  let newCount = data.monthlyDownloadCount ?? 0;
  let currentPeriodEnd = data.currentPeriodEnd ?? calculateNextPeriodEnd();

  if (dayjs().isAfter(dayjs(currentPeriodEnd))) {
    newCount = 0;
    currentPeriodEnd = calculateNextPeriodEnd();
  }

  newCount += 1;

  await updateDoc(userRef, {
    monthlyDownloadCount: newCount,
    currentPeriodEnd,
    updatedAt: dayjs().toISOString()
  });

  return { ...data, monthlyDownloadCount: newCount, currentPeriodEnd } as SubscriptionInfo;
}

export function canDownload(info: SubscriptionInfo) {
  if (info.plan === 'premium') {
    return { allowed: true };
  }
  const remaining = FREE_PLAN_LIMIT - (info.monthlyDownloadCount ?? 0);
  return { allowed: remaining > 0, remaining };
}

export const SUBSCRIPTION_LIMIT = FREE_PLAN_LIMIT;
