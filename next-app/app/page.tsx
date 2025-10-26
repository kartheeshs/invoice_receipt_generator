import Link from 'next/link';

const features = [
  {
    title: 'Design on the canvas',
    body: 'Drag-friendly sections, instant totals, and inline edits keep the invoice exactly as clients will see it.'
  },
  {
    title: 'Global-ready PDF exports',
    body: 'Localized currencies, bilingual labels, and crisp typography ensure every export feels premium.'
  },
  {
    title: 'Admin insight when you need it',
    body: 'Role-based access, subscription tracking, and audit notes keep leadership informed without extra effort.'
  }
];

const plans = [
  {
    tier: 'Free',
    price: '$0',
    description: 'Create and send polished invoices with unlimited PDF downloads.',
    points: ['Modern invoice template', 'Inline editing experience', 'Google Analytics-ready landing site']
  },
  {
    tier: 'Pro',
    price: '$24/mo',
    description: 'For teams that need history, admin controls, and premium layouts.',
    featured: true,
    points: ['All Free features', 'Revision history & template switching', 'Admin workspace with user & subscription management']
  }
];

export default function LandingPage() {
  return (
    <>
      <section className="hero">
        <div className="section hero-grid">
          <div className="hero-copy">
            <span className="eyebrow">Modern invoicing for growing teams</span>
            <h1>Build invoices that feel bespoke in minutes.</h1>
            <p>
              Invoice Atlas pairs a live WYSIWYG editor with template structures inspired by global finance teams. Drop in a
              logo, adjust line items, and export a pristine PDF without leaving the browser.
            </p>
            <div className="hero-actions">
              <Link href="/app" className="primary-button">
                Launch the app
              </Link>
              <Link href="#pricing" className="secondary-button">
                Compare plans
              </Link>
            </div>
            <div className="hero-metric-row">
              <div>
                <strong>97%</strong>
                <span>of beta customers shipped invoices in under 5 minutes.</span>
              </div>
              <div>
                <strong>2</strong>
                <span>simple plans — stay free or upgrade when you need admin tools.</span>
              </div>
            </div>
          </div>
          <div className="hero-preview">
            <div className="preview-card">
              <div className="preview-header">
                <span className="preview-badge">Canvas preview</span>
                <span className="preview-status">Draft • Wave template</span>
              </div>
              <div className="preview-body">
                <div className="preview-line" />
                <div className="preview-line" />
                <div className="preview-line short" />
              </div>
              <div className="preview-footer">
                <span>Total due</span>
                <strong>$3,240.00</strong>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="features" className="section features">
        <div className="section-heading">
          <span className="eyebrow">Why teams switch</span>
          <h2>Professional structure without the busy work</h2>
          <p>
            Choose layouts inspired by finance best practices, edit inline, and send PDFs that mirror the exact design your
            client approved.
          </p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article key={feature.title} className="feature-card">
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section id="pricing" className="section pricing">
        <div className="section-heading">
          <span className="eyebrow">Pricing</span>
          <h2>Only two plans. Start free, grow when you are ready.</h2>
          <p>Unlock the pro workspace for history, advanced templates, and admin controls.</p>
        </div>
        <div className="pricing-grid">
          {plans.map((plan) => (
            <article key={plan.tier} className={`plan-card${plan.featured ? ' featured' : ''}`}>
              <div className="plan-header">
                <span className="plan-tier">{plan.tier}</span>
                <span className="plan-price">{plan.price}</span>
              </div>
              <p className="plan-description">{plan.description}</p>
              <ul>
                {plan.points.map((point) => (
                  <li key={point}>{point}</li>
                ))}
              </ul>
              <Link href="/app" className={`plan-button${plan.featured ? ' primary' : ''}`}>
                {plan.featured ? 'Upgrade to Pro' : 'Start for free'}
              </Link>
            </article>
          ))}
        </div>
      </section>

      <section className="section cta">
        <div className="cta-banner">
          <div>
            <h2>Ready to impress your next client?</h2>
            <p>Launch the editor, customize the template, and send a polished invoice today.</p>
          </div>
          <Link href="/app" className="primary-button">
            Open Invoice Atlas
          </Link>
        </div>
      </section>
    </>
  );
}
