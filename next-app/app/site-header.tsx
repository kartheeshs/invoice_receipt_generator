'use client';

import Link from 'next/link';
import LanguageSwitcher from './components/language-switcher';
import { useTranslation } from '../lib/i18n';

export default function SiteHeader() {
  const { t } = useTranslation();

  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <Link href="/" className="site-brand" prefetch={false}>
          <span className="site-brand__mark">
            <img src="/easy-invoice-gm7-logo.svg" alt="Easy Invoice GM7" />
          </span>
          <span className="site-brand__meta">
            <strong>Easy Invoice GM7</strong>
            <span>{t('layout.tagline', 'Modern billing workspace')}</span>
          </span>
        </Link>
        <nav className="site-nav" aria-label="Primary">
          <a href="#features">{t('nav.features', 'Features')}</a>
          <a href="#templates">{t('nav.templates', 'Templates')}</a>
          <a href="#workflow">{t('nav.workflow', 'Workflow')}</a>
          <a href="#pricing">{t('nav.pricing', 'Pricing')}</a>
          <Link href="/privacy-policy" prefetch={false}>
            {t('nav.privacy', 'Privacy')}
          </Link>
        </nav>
        <div className="site-header__actions">
          <LanguageSwitcher />
          <Link href="/app" className="button button--primary" prefetch={false}>
            {t('nav.launchApp', 'Launch app')}
          </Link>
        </div>
      </div>
    </header>
  );
}
