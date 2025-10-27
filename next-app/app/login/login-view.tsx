'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import type { ReadonlyURLSearchParams } from 'next/navigation';
import { firebaseConfigured } from '../../lib/firebase';
import { clearSession, persistSession, signInWithEmailPassword } from '../../lib/auth';

type Status = 'idle' | 'loading' | 'success' | 'error';

function extractErrorFromParams(params: ReadonlyURLSearchParams | null): string | null {
  if (!params) {
    return null;
  }

  const reason = params.get('error');
  if (!reason) {
    return null;
  }

  switch (reason) {
    case 'session-expired':
      return 'Your session expired. Please sign in again to continue.';
    case 'access-denied':
      return 'Please sign in with an administrator account to open the console.';
    default:
      return params.get('message') ?? 'Please sign in to continue.';
  }
}

export default function LoginView(): JSX.Element {
  const router = useRouter();
  const params = useSearchParams();

  const [status, setStatus] = useState<Status>('idle');
  const [message, setMessage] = useState<string>('');

  useEffect(() => {
    const initialError = extractErrorFromParams(params);
    if (initialError) {
      setStatus('error');
      setMessage(initialError);
    }
  }, [params]);

  useEffect(() => {
    clearSession();
  }, []);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    const email = String(formData.get('email') ?? '').trim();
    const password = String(formData.get('password') ?? '');
    const remember = formData.get('remember') === 'on';

    if (!email || !password) {
      setStatus('error');
      setMessage('Enter both your email and password to continue.');
      return;
    }

    if (!firebaseConfigured) {
      setStatus('error');
      setMessage('Firebase environment variables are missing. Copy next-app/.env.example to .env.local and update it with your Firebase project.');
      return;
    }

    setStatus('loading');
    setMessage('Signing you in…');

    try {
      const session = await signInWithEmailPassword(email, password);
      persistSession(session, { remember });
      setStatus('success');
      setMessage('Signed in successfully. Redirecting…');
      router.replace('/app');
    } catch (error) {
      const friendlyMessage = error instanceof Error ? error.message : 'Unable to sign in. Please try again later.';
      setStatus('error');
      setMessage(friendlyMessage);
    }
  }

  const isLoading = status === 'loading';
  const statusVariant = status === 'error' ? 'error' : status === 'success' ? 'success' : 'info';
  const statusClass = `auth-form__status auth-form__status--${statusVariant}`;

  return (
    <div className="auth-page">
      <div className="auth-hero">
        <div className="container">
          <span className="badge">Welcome back</span>
          <h1>Sign in to Invoice Atlas</h1>
          <p>Enter your workspace email address to continue where you left off.</p>
        </div>
      </div>

      <div className="auth-body">
        <div className="container auth-layout">
          <section className="auth-card">
            <form className="auth-form" aria-label="Member sign in" onSubmit={handleSubmit} noValidate suppressHydrationWarning>
              <div className="auth-form__field">
                <label htmlFor="email">Email</label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="you@company.com"
                  autoComplete="email"
                  inputMode="email"
                  required
                  suppressHydrationWarning
                />
              </div>
              <div className="auth-form__field auth-form__field--split">
                <div>
                  <label htmlFor="password">Password</label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    placeholder="••••••••"
                    autoComplete="current-password"
                    required
                    suppressHydrationWarning
                  />
                </div>
                <div className="auth-form__inline">
                  <input id="remember" name="remember" type="checkbox" defaultChecked suppressHydrationWarning />
                  <label htmlFor="remember">Stay signed in</label>
                </div>
              </div>

              {message && (
                <div className={statusClass} role="alert" aria-live="polite">
                  {message}
                </div>
              )}

              {!firebaseConfigured && (
                <div className="auth-callout" role="note">
                  <strong>Configuration required:</strong> Copy <code>.env.example</code> to <code>.env.local</code> and keep the Firebase keys provided in this repository (or replace them with your own credentials).
                </div>
              )}

              <button
                type="submit"
                className="button button--primary auth-form__submit"
                disabled={isLoading}
                aria-busy={isLoading}
                suppressHydrationWarning
              >
                {isLoading ? 'Signing in…' : 'Continue'}
              </button>
              <div className="auth-form__links">
                <Link href="/reset" prefetch={false}>
                  Forgot password?
                </Link>
                <Link href="/signup" prefetch={false}>
                  Create an account
                </Link>
              </div>
              <p className="auth-form__hint">
                Administrators manage workspace access inside the{' '}
                <Link href="/admin/console" prefetch={false}>
                  admin console
                </Link>
                .
              </p>
            </form>
          </section>

          <aside className="auth-aside">
            <article className="auth-insight">
              <h2>Everything from the dashboard, now in the browser</h2>
              <ul>
                <li>Create invoices with a template gallery that mirrors the Flutter experience.</li>
                <li>Track payment status, reminders, and outstanding balances in one place.</li>
                <li>Switch between dashboard, invoice editor, templates, and client directories from the top navigation bar.</li>
              </ul>
              <Link className="button button--ghost" href="/app" prefetch={false}>
                Explore the workspace
              </Link>
            </article>
          </aside>
        </div>
      </div>
    </div>
  );
}
