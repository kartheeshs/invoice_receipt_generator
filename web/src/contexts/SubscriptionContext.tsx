import { ReactNode, createContext, useContext, useEffect, useMemo, useState } from 'react';
import { useAuth } from './AuthContext';
import {
  canDownload,
  ensureUserProfile,
  getSubscription,
  recordDownload,
  SUBSCRIPTION_LIMIT
} from '../services/subscriptionService';
import { SubscriptionInfo } from '../types/invoice';

export type DownloadPermission = {
  allowed: boolean;
  remaining?: number;
};

type SubscriptionContextValue = {
  subscription: SubscriptionInfo | null;
  loading: boolean;
  refresh: () => Promise<void>;
  requestDownloadPermission: () => Promise<DownloadPermission>;
  limit: number;
};

const SubscriptionContext = createContext<SubscriptionContextValue | undefined>(undefined);

export function SubscriptionProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [subscription, setSubscription] = useState<SubscriptionInfo | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!user) {
      setSubscription(null);
      return;
    }
    refreshSubscription();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.uid]);

  const refreshSubscription = async () => {
    if (!user) return;
    setLoading(true);
    try {
      await ensureUserProfile(user.uid);
      const data = await getSubscription(user.uid);
      setSubscription(data);
    } catch (error) {
      console.error('Failed to refresh subscription', error);
    } finally {
      setLoading(false);
    }
  };

  const requestDownloadPermission = async () => {
    if (!user || !subscription) {
      return { allowed: false, remaining: 0 };
    }
    const permission = canDownload(subscription);
    if (permission.allowed) {
      try {
        const updated = await recordDownload(user.uid);
        setSubscription(updated);
        const after = canDownload(updated);
        return { allowed: true, remaining: after.remaining };
      } catch (error) {
        console.error('Failed to record download usage', error);
        return { allowed: false, remaining: permission.remaining };
      }
    }
    return permission;
  };

  const value = useMemo(
    () => ({ subscription, loading, refresh: refreshSubscription, requestDownloadPermission, limit: SUBSCRIPTION_LIMIT }),
    [subscription, loading]
  );

  return <SubscriptionContext.Provider value={value}>{children}</SubscriptionContext.Provider>;
}

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (!context) {
    throw new Error('useSubscription must be used within a SubscriptionProvider');
  }
  return context;
}
