export const metadata = {
  title: 'Privacy Policy — Invoice Atlas',
  description:
    'Understand how Invoice Atlas protects your invoicing data, respects deletion requests, and outlines user responsibilities.',
};

export default function PrivacyPolicyPage() {
  return (
    <section className="section" style={{ padding: '6rem 0 4rem' }}>
      <div style={{ display: 'grid', gap: '2rem' }}>
        <div style={{ display: 'grid', gap: '0.75rem' }}>
          <span className="badge">Privacy &amp; Policy</span>
          <h1 style={{ margin: 0 }}>Our commitment to your data</h1>
          <p>
            We built Invoice Atlas for responsible teams that care about privacy. This document explains how we
            protect your workspace and what responsibilities you accept when using the platform.
          </p>
        </div>

        <article className="policy-section">
          <h2>1. Data protection</h2>
          <p>
            All invoice data, uploaded media, and account metadata are encrypted at rest. Administrative tooling is
            limited to operational staff with audited access, and we continuously monitor for anomalous activity.
          </p>
        </article>

        <article className="policy-section">
          <h2>2. User control</h2>
          <p>
            You retain full control over your workspace data. When you delete invoices, contacts, or uploaded
            assets, they are permanently removed from our primary databases and we do not maintain hidden backups.
          </p>
        </article>

        <article className="policy-section">
          <h2>3. Responsibility</h2>
          <p>
            Invoice Atlas is a neutral platform. Any fraudulent or unlawful activity conducted through the service is
            solely the responsibility of the user who performed the action. We do not accept liability for misuse,
            though our team will cooperate with legitimate investigations when required by law.
          </p>
        </article>

        <article className="policy-section">
          <h2>4. Support commitment</h2>
          <p>
            While we cannot be held responsible for user actions, we will make every reasonable effort to support you
            if something goes wrong. Reach out to <a href="mailto:support@invoice-atlas.example.com">support@invoice-atlas.example.com</a>
            for assistance.
          </p>
        </article>

        <article className="policy-section">
          <h2>5. Updates</h2>
          <p>
            We may update this policy as our product evolves. Significant changes will be communicated in-app and via
            email to workspace owners at least 14 days before they take effect.
          </p>
        </article>

        <div className="policy-section">
          <h2>Contact</h2>
          <p>
            Questions or concerns? Email <a href="mailto:privacy@invoice-atlas.example.com">privacy@invoice-atlas.example.com</a>.
            We respond to most requests within two business days.
          </p>
        </div>
      </div>
    </section>
  );
}
