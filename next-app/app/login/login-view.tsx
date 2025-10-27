'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { firebaseConfigured } from '../../lib/firebase';
import { clearSession, persistSession, signInWithEmailPassword } from '../../lib/auth';
import { useTranslation } from '../../lib/i18n';

type Status = 'idle' | 'loading' | 'success' | 'error';

export default function LoginView(): JSX.Element {
  const router = useRouter();
  const params = useSearchParams();
  const { t } = useTranslation();

  const [status, setStatus] = useState<Status>('idle');
  const [message, setMessage] = useState<string>('');

  useEffect(() => {
    if (!params) return;
    const reason = params.get('error');
    const customMessage = params.get('message');
    if (!reason && !customMessage) {
      return;
    }

    setStatus('error');
    if (reason === 'session-expired') {
      setMessage(t('login.error.sessionExpired', 'Your session expired. Please sign in again to continue.'));
      return;
    }
    if (reason === 'access-denied') {
      setMessage(t('login.error.accessDenied', 'Please sign in with an administrator account to open the console.'));
      return;
    }
    if (customMessage) {
      setMessage(customMessage);
      return;
    }
    setMessage(t('login.error.default', 'Please sign in to continue.'));
  }, [params, t]);

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
      setMessage(t('login.error.credentials', 'Enter both your email and password to continue.'));
      return;
    }

    if (!firebaseConfigured) {
      setStatus('error');
      setMessage(
        t(
          'login.error.missingFirebase',
          'Firebase environment variables are missing. Copy next-app/.env.example to .env.local and update it with your Firebase project.',
        ),
      );
      return;
    }

    setStatus('loading');
    setMessage(t('login.status.signingIn', 'Signing you in…'));

    try {
      const session = await signInWithEmailPassword(email, password);
      persistSession(session, { remember });
      setStatus('success');
      setMessage(t('login.status.success', 'Signed in successfully. Redirecting…'));
      router.replace('/app');
    } catch (error) {
      const fallback = t('login.error.generic', 'Unable to sign in. Please try again later.');
      const friendlyMessage = error instanceof Error && error.message ? error.message : fallback;
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
          <span className="badge">{t('login.badge', 'Welcome back')}</span>
          <h1>{t('login.title', 'Sign in to Easy Invoice GM7')}</h1>
          <p>{t('login.subtitle', 'Enter your workspace email address to continue where you left off.')}</p>
        </div>
      </div>

      <div className="auth-body">
        <div className="container auth-layout">
          <section className="auth-card">
            <form className="auth-form" aria-label="Member sign in" onSubmit={handleSubmit} noValidate suppressHydrationWarning>
              <div className="auth-form__field">
                <label htmlFor="email">{t('login.email', 'Email')}</label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  placeholder={t('login.placeholder.email', 'you@company.com')}
                  autoComplete="email"
                  inputMode="email"
                  required
                  suppressHydrationWarning
                />
              </div>
              <div className="auth-form__field auth-form__field--split">
                <div>
                  <label htmlFor="password">{t('login.password', 'Password')}</label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    placeholder={t('login.placeholder.password', '••••••••')}
                    autoComplete="current-password"
                    required
                    suppressHydrationWarning
                  />
                </div>
                <div className="auth-form__inline">
                  <input id="remember" name="remember" type="checkbox" defaultChecked suppressHydrationWarning />
                  <label htmlFor="remember">{t('login.remember', 'Stay signed in')}</label>
                </div>
              </div>

              {message && (
                <div className={statusClass} role="alert" aria-live="polite">
                  {message}
                </div>
              )}

              {!firebaseConfigured && (
                <div className="auth-callout" role="note">
                  <strong>{t('login.callout.heading', 'Configuration required:')}</strong>{' '}
                  {t(
                    'login.callout.config',
                    'Copy .env.example to .env.local and keep the Firebase keys provided in this repository (or replace them with your own credentials).',
                  )}
                </div>
              )}

              <button
                type="submit"
                className="button button--primary auth-form__submit"
                disabled={isLoading}
                aria-busy={isLoading}
                suppressHydrationWarning
              >
                {isLoading ? t('login.status.signingIn', 'Signing you in…') : t('login.submit', 'Continue')}
              </button>
              <div className="auth-form__links">
                <Link href="/reset" prefetch={false}>
                  {t('login.link.forgot', 'Forgot password?')}
                </Link>
                <Link href="/signup" prefetch={false}>
                  {t('login.link.signup', 'Create an account')}
                </Link>
              </div>
              <p className="auth-form__hint">
                {t('login.note.adminPrefix', 'Administrators manage workspace access inside the')}{' '}
                <Link href="/admin/console" prefetch={false}>
                  {t('login.note.adminLink', 'admin console')}
                </Link>
                .
              </p>
            </form>
          </section>

          <aside className="auth-aside">
            <article className="auth-insight">
              <h2>{t('login.aside.title', 'Everything from the dashboard, now in the browser')}</h2>
              <ul>
                <li>{t('login.aside.point1', 'Create invoices with a template gallery that mirrors the Flutter experience.')}</li>
                <li>{t('login.aside.point2', 'Track payment status, reminders, and outstanding balances in one place.')}</li>
                <li>{t('login.aside.point3', 'Switch between dashboard, invoice editor, templates, and client directories from the top navigation bar.')}</li>
              </ul>
              <Link className="button button--ghost" href="/app" prefetch={false}>
                {t('login.aside.cta', 'Explore the workspace')}
              </Link>
            </article>
          </aside>
        </div>
      </div>
    </div>
  );
}
