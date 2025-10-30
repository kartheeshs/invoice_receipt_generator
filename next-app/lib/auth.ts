import { firebaseApiKey, firebaseConfig, firebaseConfigured } from './firebase';

const identityBaseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
const fallbackAdminEmails = new Set(['admin@easyinvoicegm7.example.com']);

export interface AuthSession {
  idToken: string;
  refreshToken: string;
  email: string;
  localId: string;
  expiresIn: number;
  displayName?: string;
  role?: UserRole;
}

export type UserRole = 'admin' | 'member';

export interface PersistOptions {
  remember: boolean;
}

const BASE_SESSION_STORAGE_KEY = 'easyinvoicegm7.session';
const projectKeySuffix =
  firebaseConfigured && firebaseConfig.projectId
    ? `.${firebaseConfig.projectId}`
    : '';

export const SESSION_STORAGE_KEY = `${BASE_SESSION_STORAGE_KEY}${projectKeySuffix}`;

const LEGACY_SESSION_KEYS = projectKeySuffix ? [BASE_SESSION_STORAGE_KEY] : [];

function removeLegacySessionEntries(storage: Storage) {
  for (const key of LEGACY_SESSION_KEYS) {
    storage.removeItem(key);
  }
}

function normaliseExpiresIn(expiresIn: string | number | undefined): number {
  if (!expiresIn) {
    return 3600;
  }

  const value = typeof expiresIn === 'string' ? Number.parseInt(expiresIn, 10) : expiresIn;
  return Number.isFinite(value) && value > 0 ? value : 3600;
}

function mapFirebaseError(code?: string): string {
  switch (code) {
    case 'EMAIL_NOT_FOUND':
    case 'INVALID_PASSWORD':
    case 'INVALID_EMAIL':
      return 'The email or password you entered is incorrect. Please try again.';
    case 'USER_DISABLED':
      return 'This account has been disabled. Reach out to your workspace administrator for assistance.';
    case 'OPERATION_NOT_ALLOWED':
      return 'Email/password sign-in is disabled for this project.';
    default:
      return 'Unable to sign in with Firebase Authentication right now. Please try again in a moment.';
  }
}

type LookupUser = {
  displayName?: string;
  email?: string;
  customAttributes?: string;
  customClaims?: Record<string, unknown>;
};

type LookupResponse = {
  users?: LookupUser[];
};

function resolveRole(email: string | undefined, claims?: Record<string, unknown>): UserRole {
  const lower = email?.toLowerCase();
  if (claims && typeof claims.role === 'string') {
    return claims.role === 'admin' ? 'admin' : 'member';
  }
  if (lower && fallbackAdminEmails.has(lower)) {
    return 'admin';
  }
  return 'member';
}

function parseClaims(user: LookupUser): Record<string, unknown> | undefined {
  if (user.customClaims && typeof user.customClaims === 'object') {
    return user.customClaims;
  }
  if (typeof user.customAttributes === 'string') {
    try {
      return JSON.parse(user.customAttributes) as Record<string, unknown>;
    } catch (error) {
      return undefined;
    }
  }
  return undefined;
}

async function fetchAccountProfile(idToken: string, email?: string): Promise<{ displayName?: string; role: UserRole }>
{
  const response = await fetch(`${identityBaseUrl}:lookup?key=${firebaseApiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
    cache: 'no-store',
  });

  if (!response.ok) {
    const fallbackRole = resolveRole(email, undefined);
    return { displayName: undefined, role: fallbackRole };
  }

  const payload = (await response.json()) as LookupResponse;
  const user = payload.users?.[0];
  if (!user) {
    const fallbackRole = resolveRole(email, undefined);
    return { displayName: undefined, role: fallbackRole };
  }

  const claims = parseClaims(user);
  const role = resolveRole(user.email ?? email, claims);
  return { displayName: user.displayName, role };
}

export async function signInWithEmailPassword(email: string, password: string): Promise<AuthSession> {
  if (!firebaseConfigured || !firebaseApiKey) {
    throw new Error(
      'Firebase configuration is missing. Set NEXT_PUBLIC_FIREBASE_PROJECT_ID and NEXT_PUBLIC_FIREBASE_API_KEY (see next-app/.env.example).',
    );
  }

  const payload = {
    email,
    password,
    returnSecureToken: true,
  };

  const response = await fetch(`${identityBaseUrl}:signInWithPassword?key=${firebaseApiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    cache: 'no-store',
  });

  if (!response.ok) {
    let errorCode: string | undefined;
    try {
      const data = await response.json();
      errorCode = data?.error?.message;
    } catch (error) {
      // ignore JSON parse errors and use the default message
    }

    throw new Error(mapFirebaseError(errorCode));
  }

  const data = await response.json();

  let profileDisplayName: string | undefined = data.displayName;
  let role: UserRole = resolveRole(data.email, undefined);
  try {
    const profile = await fetchAccountProfile(data.idToken, data.email);
    profileDisplayName = profile.displayName ?? profileDisplayName ?? data.email;
    role = profile.role;
  } catch (error) {
    role = resolveRole(data.email, undefined);
  }

  return {
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    email: data.email,
    localId: data.localId,
    displayName: profileDisplayName ?? data.email,
    expiresIn: normaliseExpiresIn(data.expiresIn),
    role,
  } satisfies AuthSession;
}

export function persistSession(session: AuthSession, options: PersistOptions = { remember: true }): void {
  if (typeof window === 'undefined') {
    return;
  }

  const storage = options.remember ? window.localStorage : window.sessionStorage;
  const alternateStorage = options.remember ? window.sessionStorage : window.localStorage;

  const payload = {
    idToken: session.idToken,
    refreshToken: session.refreshToken,
    email: session.email,
    localId: session.localId,
    displayName: session.displayName ?? session.email,
    expiresAt: Date.now() + session.expiresIn * 1000,
    role: session.role ?? 'member',
  };

  storage.setItem(SESSION_STORAGE_KEY, JSON.stringify(payload));
  alternateStorage.removeItem(SESSION_STORAGE_KEY);
  removeLegacySessionEntries(storage);
  removeLegacySessionEntries(alternateStorage);
}

export function clearSession(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(SESSION_STORAGE_KEY);
  window.sessionStorage.removeItem(SESSION_STORAGE_KEY);
  removeLegacySessionEntries(window.localStorage);
  removeLegacySessionEntries(window.sessionStorage);
}

export type StoredSession = {
  idToken: string;
  refreshToken: string;
  email: string;
  localId: string;
  displayName: string;
  expiresAt: number;
  role: UserRole;
};

export function loadSession(): StoredSession | null {
  if (typeof window === 'undefined') {
    return null;
  }

  const storages: Storage[] = [window.localStorage, window.sessionStorage];
  storages.forEach((storage) => removeLegacySessionEntries(storage));

  let raw: string | null = null;
  for (const storage of storages) {
    raw = storage.getItem(SESSION_STORAGE_KEY);
    if (raw) {
      break;
    }
  }

  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as StoredSession;
    if (!parsed.expiresAt || parsed.expiresAt < Date.now()) {
      clearSession();
      return null;
    }
    if (parsed.role !== 'admin') {
      parsed.role = 'member';
    }
    return parsed;
  } catch (error) {
    clearSession();
    return null;
  }
}
