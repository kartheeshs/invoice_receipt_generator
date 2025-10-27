'use client';

import Link from 'next/link';
import { useTranslation } from '../../lib/i18n';

export default function AdminLandingView() {
  const { t } = useTranslation();

  return (
    <section style={{ padding: '6rem 0 4rem' }}>
      <div className="container" style={{ display: 'flex', justifyContent: 'center' }}>
        <div className="template-card" style={{ maxWidth: '620px', padding: '2.25rem 2rem', boxShadow: 'var(--shadow-md)' }}>
          <span className="badge">{t('admin.landing.badge', 'Administrator sign-in')}</span>
          <h1 style={{ marginTop: '1rem' }}>{t('admin.landing.title', 'Secure access required')}</h1>
          <p style={{ marginTop: '0.75rem', lineHeight: 1.7 }}>
            {t(
              'admin.landing.description',
              'Administrators manage workspaces, subscriptions, and compliance logs inside the dedicated console embedded in the Easy Invoice GM7 web application. Launch the console below and sign in with your administrator credentials.',
            )}
          </p>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', marginTop: '1.75rem' }}>
            <Link className="button button--primary" href="/admin/console">
              {t('admin.landing.openConsole', 'Open admin console')}
            </Link>
            <Link className="button button--ghost" href="/">
              {t('admin.landing.returnSite', 'Return to marketing site')}
            </Link>
          </div>
          <small style={{ display: 'block', marginTop: '1.5rem', color: 'var(--text-muted)' }}>
            {t('admin.landing.help', 'Need access? Email admin@easyinvoicegm7.example.com.')}
          </small>
        </div>
      </div>
    </section>
  );
}
