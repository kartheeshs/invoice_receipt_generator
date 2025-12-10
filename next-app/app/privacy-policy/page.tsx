import type { ReactNode } from 'react';

const sections: { title: string; body: ReactNode }[] = [
  {
    title: 'Data protection',
    body: (
      <p>
        All invoice data, uploaded media, and account metadata are encrypted at rest and monitored for unusual
        activity. Administrative tooling is limited to audited operators, and every access is logged.
      </p>
    ),
  },
  {
    title: 'User control',
    body: (
      <p>
        You retain full control over your workspace data. When you delete invoices, contacts, or uploaded assets they
        are permanently removed from our primary databases—there are no hidden archives or surprise restores.
      </p>
    ),
  },
  {
    title: 'Responsibility',
    body: (
      <p>
        Easy Invoice GM7 is a neutral platform. Any fraudulent or unlawful activity conducted through the service is the
        responsibility of the user who performed the action. We cooperate with legitimate investigations when required
        by law.
      </p>
    ),
  },
  {
    title: 'Support commitment',
    body: (
      <p>
        While we cannot assume liability for user actions, our support team will help you recover from mistakes and
        incidents. Contact us at{' '}
        <a href="mailto:support@easyinvoicegm7.example.com">support@easyinvoicegm7.example.com</a>{' '}
        and we will respond as quickly as we can.
      </p>
    ),
  },
  {
    title: 'Policy updates',
    body: (
      <p>
        We may update this policy as the product evolves. Significant changes are announced in-app and via email at
        least 14 days before they take effect so you have time to review and respond.
      </p>
    ),
  },
];

const highlights = [
  'Data encrypted at rest and in transit',
  'Granular deletion controls with no hidden backups',
  'Audited access with a two business day response SLA',
];

export const metadata = {
  title: 'Privacy Policy — Easy Invoice GM7',
  description:
    'Understand how Easy Invoice GM7 protects your invoicing data, respects deletion requests, and outlines user responsibilities.',
};

export default function PrivacyPolicyPage() {
  return (
    <>
      <section className="policy-hero">
        <div className="container policy-hero__inner">
          <div className="policy-hero__content">
            <span className="badge badge--muted">Privacy &amp; Policy</span>
            <h1>Our commitment to your data</h1>
            <p>
              We built Easy Invoice GM7 for responsible teams that care about privacy. This document explains how we
              protect your workspace and what responsibilities you accept when using the platform.
            </p>
          </div>
          <div className="policy-hero__callout">
            <h2>Key promises</h2>
            <ul>
              {highlights.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="policy-body">
        <div className="container policy-grid">
          {sections.map((section, index) => (
            <article key={section.title} className="policy-card">
              <span className="policy-card__number">{String(index + 1).padStart(2, '0')}</span>
              <h2 className="policy-card__title">{section.title}</h2>
              <div className="policy-card__body">{section.body}</div>
            </article>
          ))}
        </div>

        <div className="container policy-contact">
          <div className="policy-contact__card">
            <h2>Contact</h2>
            <p>
              Questions or concerns? Email{' '}
              <a href="mailto:privacy@easyinvoicegm7.example.com">privacy@easyinvoicegm7.example.com</a>. We respond to
              most requests within two business days.
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
