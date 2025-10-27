import { firebaseApiKey, firebaseConfigured } from './firebase';

const identityBaseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

export interface AuthSession {
  idToken: string;
  refreshToken: string;
  email: string;
  localId: string;
  expiresIn: number;
  displayName?: string;
}

export interface PersistOptions {
  remember: boolean;
}

export const SESSION_STORAGE_KEY = 'easyinvoicegm7.session';

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
  return {
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    email: data.email,
    localId: data.localId,
    displayName: data.displayName,
    expiresIn: normaliseExpiresIn(data.expiresIn),
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
  };

  storage.setItem(SESSION_STORAGE_KEY, JSON.stringify(payload));
  alternateStorage.removeItem(SESSION_STORAGE_KEY);
}

export function clearSession(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(SESSION_STORAGE_KEY);
  window.sessionStorage.removeItem(SESSION_STORAGE_KEY);
}

export type StoredSession = {
  idToken: string;
  refreshToken: string;
  email: string;
  localId: string;
  displayName: string;
  expiresAt: number;
};

export function loadSession(): StoredSession | null {
  if (typeof window === 'undefined') {
    return null;
  }

  const raw = window.localStorage.getItem(SESSION_STORAGE_KEY) ?? window.sessionStorage.getItem(SESSION_STORAGE_KEY);
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as StoredSession;
    if (!parsed.expiresAt || parsed.expiresAt < Date.now()) {
      clearSession();
      return null;
    }
    return parsed;
  } catch (error) {
    clearSession();
    return null;
  }
}
