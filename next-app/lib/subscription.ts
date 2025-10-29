export type SubscriptionPlan = 'free' | 'premium';

export type SubscriptionState = {
  plan: SubscriptionPlan;
  downloadCount: number;
  windowStart: number;
};

export const SUBSCRIPTION_STORAGE_KEY = 'easyinvoicegm7.subscription.v1';
export const FREE_PLAN_DOWNLOAD_LIMIT = 5;
export const DOWNLOAD_WINDOW_DURATION_MS = 15 * 24 * 60 * 60 * 1000; // 15 days

const defaultState = (): SubscriptionState => ({
  plan: 'free',
  downloadCount: 0,
  windowStart: Date.now(),
});

function sanitiseNumber(value: unknown, fallback = 0): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return fallback;
}

function parseStoredState(raw: unknown): SubscriptionState {
  if (!raw || typeof raw !== 'object') {
    return defaultState();
  }

  const value = raw as Partial<SubscriptionState>;
  const plan: SubscriptionPlan = value.plan === 'premium' ? 'premium' : 'free';
  const windowStart = sanitiseNumber(value.windowStart, Date.now());
  const downloadCount = sanitiseNumber(value.downloadCount, 0);

  return {
    plan,
    windowStart,
    downloadCount: Math.max(0, downloadCount),
  };
}

export function ensureSubscriptionWindow(state: SubscriptionState, now = Date.now()): SubscriptionState {
  if (state.plan === 'premium') {
    return { ...state, windowStart: state.windowStart || now, downloadCount: 0 };
  }

  const windowStart = Number.isFinite(state.windowStart) ? state.windowStart : now;
  if (now - windowStart >= DOWNLOAD_WINDOW_DURATION_MS) {
    return {
      ...state,
      windowStart: now,
      downloadCount: 0,
    };
  }

  return { ...state, windowStart };
}

export function loadSubscriptionState(): SubscriptionState {
  if (typeof window === 'undefined') {
    return defaultState();
  }

  try {
    const stored = window.localStorage.getItem(SUBSCRIPTION_STORAGE_KEY);
    if (!stored) {
      const initial = defaultState();
      window.localStorage.setItem(SUBSCRIPTION_STORAGE_KEY, JSON.stringify(initial));
      return initial;
    }
    const parsed = JSON.parse(stored) as unknown;
    const state = ensureSubscriptionWindow(parseStoredState(parsed));
    window.localStorage.setItem(SUBSCRIPTION_STORAGE_KEY, JSON.stringify(state));
    return state;
  } catch (error) {
    console.warn('Unable to load subscription state from storage', error);
    const fallback = defaultState();
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(SUBSCRIPTION_STORAGE_KEY, JSON.stringify(fallback));
    }
    return fallback;
  }
}

export function persistSubscriptionState(state: SubscriptionState): void {
  if (typeof window === 'undefined') {
    return;
  }
  try {
    window.localStorage.setItem(SUBSCRIPTION_STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    console.warn('Unable to persist subscription state', error);
  }
}

export function markSubscriptionPlan(
  state: SubscriptionState,
  plan: SubscriptionPlan,
  now = Date.now(),
): SubscriptionState {
  if (plan === 'premium') {
    return {
      plan,
      downloadCount: 0,
      windowStart: now,
    };
  }

  return {
    plan: 'free',
    downloadCount: 0,
    windowStart: now,
  };
}

export function incrementDownloadCount(state: SubscriptionState, now = Date.now()): SubscriptionState {
  if (state.plan === 'premium') {
    return {
      plan: 'premium',
      downloadCount: 0,
      windowStart: now,
    };
  }

  const ensured = ensureSubscriptionWindow(state, now);
  return {
    ...ensured,
    downloadCount: ensured.downloadCount + 1,
  };
}

export function downloadsRemaining(state: SubscriptionState): number {
  if (state.plan === 'premium') {
    return Number.POSITIVE_INFINITY;
  }
  return Math.max(0, FREE_PLAN_DOWNLOAD_LIMIT - state.downloadCount);
}

export function downloadWindowReset(state: SubscriptionState): number {
  return (Number.isFinite(state.windowStart) ? state.windowStart : Date.now()) + DOWNLOAD_WINDOW_DURATION_MS;
}
