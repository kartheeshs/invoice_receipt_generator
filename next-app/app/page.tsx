import Link from 'next/link';

const featureCards = [
  {
    title: 'Template intelligence',
    description:
      'Seven meticulously crafted templates cover Western, APAC, and Japanese compliance, each with its own layout personality and bilingual-ready structure.',
  },
  {
    title: 'Collaborative workflows',
    description:
      'Invite teammates to comment, request edits, and approve drafts while revision history keeps your auditors confident.',
  },
  {
    title: 'Precise PDF exports',
    description:
      'Generate vector-sharp PDFs in any currency with localized date/number formats, watermarks, and branded accent colors.',
  },
  {
    title: 'Inline editing',
    description:
      'Build invoices directly on the canvas—add sections, reorder blocks, and drop in local logos without touching a form.',
  },
  {
    title: 'Global-ready payments',
    description:
      'Store regional bank data, Stripe links, and tax IDs so every invoice ships with the right settlement instructions.',
  },
  {
    title: 'Secure admin controls',
    description:
      'Role-based administration, subscription management, and activity insights keep compliance teams in control.',
  },
];

const templateSpotlights = [
  {
    name: 'Wave Spotlight',
    blurb: 'A dramatic gradient hero with spotlight totals and service highlights for agencies and consultants.',
    accent: 'linear-gradient(135deg, rgba(99,102,241,0.35), rgba(236,72,153,0.3))',
  },
  {
    name: 'Corporate Ledger',
    blurb: 'Precision-driven grid layout with sidebar ledger and approval stamps suited for enterprise billing.',
    accent: 'linear-gradient(135deg, rgba(56,189,248,0.32), rgba(15,118,110,0.35))',
  },
  {
    name: 'Tokyo Statement',
    blurb: 'Japanese bilingual invoice with hanko placement, kana-ready typography, and tax subtotals.',
    accent: 'linear-gradient(135deg, rgba(248,113,113,0.32), rgba(248,250,252,0.15))',
  },
];

const pricing = [
  {
    tier: 'Starter',
    price: 'Free',
    description: 'For freelancers sending a handful of invoices each month.',
    points: ['2 active templates', 'PDF exports with your branding', 'Single-user workspace'],
  },
  {
    tier: 'Studio',
    price: '$24',
    description: 'For growing teams that require collaboration and payment tracking.',
    featured: true,
    points: ['Unlimited invoices & history', 'Team collaboration', 'Customer portals & auto reminders'],
  },
  {
    tier: 'Enterprise',
    price: 'Let’s talk',
    description: 'Tailored governance, SSO, and dedicated success management.',
    points: ['Custom approval workflows', 'Advanced analytics', 'Premium localization support'],
  },
];

export default function LandingPage() {
  return (
    <>
      <section className="section" style={{ paddingTop: '6rem' }}>
        <div className="hero-grid">
          <div style={{ display: 'grid', gap: '1.5rem' }}>
            <span className="tag">Global-first invoice platform</span>
            <h1 style={{ fontSize: 'clamp(2.8rem, 5vw, 4rem)', margin: 0 }}>
              Craft, localize, and ship invoices that impress clients anywhere in the world.
            </h1>
            <p style={{ fontSize: '1.05rem', maxWidth: '32rem' }}>
              Invoice Atlas pairs a modern WYSIWYG editor with export-ready templates so every invoice reflects
              your brand. Switch effortlessly between English and Japanese layouts while keeping compliance in
              check.
            </p>
            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
              <Link className="button-primary" href="/app">
                Launch web app
              </Link>
              <Link className="button-secondary" href="#templates">
                Explore templates
              </Link>
            </div>
            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
              <div className="hero-metric">
                <strong style={{ fontSize: '1.35rem', color: '#f8fafc' }}>97%</strong>
                <span>Customer satisfaction score</span>
              </div>
              <div className="hero-metric">
                <strong style={{ fontSize: '1.35rem', color: '#f8fafc' }}>65+</strong>
                <span>Localization presets supported</span>
              </div>
            </div>
          </div>
          <div className="hero-visual">
            <div className="hero-visual-content" style={{ display: 'grid', gap: '1.5rem' }}>
              <div className="gradient-border">
                <div className="inner" style={{ padding: '1.5rem' }}>
                  <h3 style={{ marginTop: 0 }}>Inline editor preview</h3>
                  <p style={{ marginBottom: '0.75rem' }}>
                    Switch templates, adjust bilingual titles, and drop in company seals directly on the canvas.
                  </p>
                  <div style={{ display: 'grid', gap: '0.75rem', fontSize: '0.95rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Template</span>
                      <strong>Wave Spotlight</strong>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Status</span>
                      <strong>Awaiting approval</strong>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Language</span>
                      <strong>English / 日本語</strong>
                    </div>
                  </div>
                </div>
              </div>
              <div style={{ display: 'grid', gap: '0.75rem' }}>
                <div className="hero-metric" style={{ width: 'fit-content' }}>
                  <span role="img" aria-label="chart">
                    📈
                  </span>
                  <span>Automated revenue summaries for admins</span>
                </div>
                <div className="hero-metric" style={{ width: 'fit-content' }}>
                  <span role="img" aria-label="globe">
                    🌐
                  </span>
                  <span>Currency-aware totals &amp; FX snapshots</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="templates" className="section">
        <div style={{ display: 'grid', gap: '2rem' }}>
          <div style={{ display: 'grid', gap: '0.75rem' }}>
            <span className="badge">Templates</span>
            <h2 style={{ fontSize: 'clamp(2rem, 3.6vw, 3rem)', margin: 0 }}>Signature layouts for every client</h2>
            <p style={{ maxWidth: '40rem' }}>
              Choose from seven pixel-perfect invoice experiences including Japanese statements with hanko
              support, modern spotlight headers, and ledger-first corporate formats.
            </p>
          </div>
          <div className="template-gallery">
            {templateSpotlights.map((template) => (
              <article key={template.name} className="template-card">
                <div style={{ position: 'relative' }}>
                  <div
                    style={{
                      position: 'absolute',
                      top: '0.75rem',
                      right: '0.75rem',
                      background: 'rgba(15,23,42,0.78)',
                      borderRadius: '999px',
                      padding: '0.35rem 0.9rem',
                      fontSize: '0.8rem',
                      border: '1px solid rgba(148,163,184,0.18)',
                    }}
                  >
                    {template.name}
                  </div>
                  <div
                    style={{
                      width: '100%',
                      borderRadius: '1.1rem',
                      aspectRatio: '4 / 5',
                      border: '1px solid rgba(148,163,184,0.12)',
                      background: template.accent,
                      position: 'relative',
                      overflow: 'hidden',
                      display: 'grid',
                      placeItems: 'center',
                      color: 'rgba(248,250,252,0.9)',
                      fontWeight: 600,
                      letterSpacing: '0.05em',
                    }}
                  >
                    Layout Preview
                  </div>
                </div>
                <p>{template.blurb}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="workflow" className="section">
        <div className="highlight">
          <div>
            <span className="badge">Why teams switch</span>
            <h2 style={{ fontSize: 'clamp(2.1rem, 4vw, 3.1rem)', marginTop: '0.5rem' }}>
              Built for finance teams that demand clarity and compliance.
            </h2>
            <p>
              Invoice Atlas unifies inline editing, approval workflows, and data governance. From PDF exports to
              localized numbering, every touchpoint is tuned for international business.
            </p>
            <ul>
              {featureCards.slice(0, 3).map((feature) => (
                <li key={feature.title}>
                  <span>✓</span>
                  <div>
                    <strong style={{ color: '#f8fafc' }}>{feature.title}</strong>
                    <p style={{ marginTop: '0.35rem' }}>{feature.description}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
          <div className="visual">
            <div className="card" style={{ background: 'rgba(2,6,23,0.72)' }}>
              <h3 style={{ marginTop: 0 }}>From draft to paid</h3>
              <ol style={{ margin: 0, paddingLeft: '1.2rem', display: 'grid', gap: '0.6rem' }}>
                <li>Choose template &amp; brand palette</li>
                <li>Invite reviewers or switch to Japanese layout</li>
                <li>Export polished PDF or trigger payment reminder</li>
              </ol>
            </div>
            <div className="card" style={{ background: 'rgba(15,23,42,0.9)' }}>
              <h3 style={{ marginTop: 0 }}>Admin visibility</h3>
              <p>Monitor user activity, subscription plans, and revenue trends from a dedicated admin console.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="section">
        <div style={{ display: 'grid', gap: '2.5rem' }}>
          <div style={{ display: 'grid', gap: '0.75rem' }}>
            <span className="badge">Platform pillars</span>
            <h2 style={{ margin: 0 }}>What makes Invoice Atlas different?</h2>
            <p>Design once, reuse everywhere. Keep finance operations compliant without losing creative control.</p>
          </div>
          <div className="grid-cards">
            {featureCards.map((feature) => (
              <article key={feature.title} className="card">
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="pricing" className="section">
        <div style={{ display: 'grid', gap: '2rem' }}>
          <div style={{ display: 'grid', gap: '0.75rem', textAlign: 'center' }}>
            <span className="badge">Pricing</span>
            <h2 style={{ margin: 0 }}>Simple tiers for every stage</h2>
            <p>Start for free, scale with your team, and unlock enterprise governance when you are ready.</p>
          </div>
          <div className="pricing-grid">
            {pricing.map((plan) => (
              <div key={plan.tier} className={`pricing-card${plan.featured ? ' featured' : ''}`}>
                <div>
                  <h3 style={{ margin: 0 }}>{plan.tier}</h3>
                  <p style={{ margin: '0.35rem 0 0' }}>{plan.description}</p>
                </div>
                <div>
                  <span style={{ fontSize: '2.25rem', fontWeight: 600, color: '#f8fafc' }}>{plan.price}</span>
                  {plan.price !== 'Free' && <span style={{ marginLeft: '0.35rem', color: 'rgba(226,232,240,0.6)' }}>/ month</span>}
                </div>
                <ul>
                  {plan.points.map((point) => (
                    <li key={point} style={{ display: 'flex', gap: '0.6rem' }}>
                      <span>•</span>
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
                <Link className={plan.featured ? 'button-primary' : 'button-secondary'} href="/app">
                  {plan.featured ? 'Start free trial' : 'Get started'}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="trust-grid">
          <div className="trust-card">
            <strong>Data residency &amp; security</strong>
            <p>All invoice content is encrypted at rest. Delete an invoice and it is permanently removed—no hidden backups.</p>
          </div>
          <div className="trust-card">
            <strong>Customer-first policies</strong>
            <p>
              You control every asset. Upload, update, or erase your company data at any time—we simply provide the tools.
            </p>
          </div>
          <div className="trust-card">
            <strong>Responsible usage</strong>
            <p>
              Invoice Atlas empowers legitimate business operations. Users are responsible for any misuse, though our team is
              ready to assist if issues arise.
            </p>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="cta">
          <div>
            <span className="badge">Ready to launch?</span>
            <h2 style={{ margin: '0.75rem 0 0' }}>Join finance teams delivering beautiful invoices worldwide.</h2>
            <p>Spin up your workspace, invite collaborators, and export compliant invoices in minutes.</p>
          </div>
          <div className="cta-actions">
            <Link className="button-primary" href="/app">
              Open web app
            </Link>
            <Link className="button-secondary" href="mailto:sales@invoice-atlas.example.com">
              Talk to sales
            </Link>
          </div>
          <small>
            Need the admin console? Head to <a href="/admin">invoice-atlas.example.com/admin</a> for secure access.
          </small>
        </div>
      </section>
    </>
  );
}
