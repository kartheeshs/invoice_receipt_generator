'use client';

import Link from 'next/link';
import { useTranslation } from '../lib/i18n';

export default function SiteFooter() {
  const { t } = useTranslation();
  const year = new Date().getFullYear();

  return (
    <footer className="site-footer">
      <div className="container site-footer__grid">
        <div>
          <h3>Easy Invoice GM7</h3>
          <p>{t('footer.tagline', 'Create invoices and receipts without fighting a designer. Both the marketing site and workspace share one design system.')}</p>
        </div>
        <div>
          <h3>{t('footer.explore', 'Explore')}</h3>
          <ul>
            <li>
              <a href="#features">{t('footer.featureTour', 'Feature tour')}</a>
            </li>
            <li>
              <a href="#templates">{t('footer.templateGallery', 'Template gallery')}</a>
            </li>
            <li>
              <a href="#pricing">{t('footer.pricing', 'Pricing')}</a>
            </li>
          </ul>
        </div>
        <div>
          <h3>{t('footer.company', 'Company')}</h3>
          <ul>
            <li>
              <Link href="/privacy-policy" prefetch={false}>
                {t('footer.privacy', 'Privacy policy')}
              </Link>
            </li>
            <li>
              <a href="mailto:support@easyinvoicegm7.example.com">support@easyinvoicegm7.example.com</a>
            </li>
            <li>
              <Link href="/admin" prefetch={false}>
                {t('footer.admin', 'Admin console')}
              </Link>
            </li>
          </ul>
        </div>
      </div>
      <div className="site-footer__meta">© {year} Easy Invoice GM7. All rights reserved.</div>
    </footer>
  );
}
