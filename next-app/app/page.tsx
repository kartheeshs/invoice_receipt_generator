import Link from 'next/link';

const stats = [
  { label: 'teams ship proposals with our editor each week', value: '1.8k+' },
  { label: 'avg. time to export a PDF once line items are ready', value: '3 min' },
  { label: 'languages supported with automatic currency formatting', value: '28' },
];

const features = [
  {
    title: 'Live collaboration with guardrails',
    body: 'Editors watch changes in real time while approvals are locked behind granular roles so finance stays in control.',
  },
  {
    title: 'Brand-perfect PDF output',
    body: 'Global fonts, edge-to-edge layout options, and vector logos render as crisply as they do in your design tool.',
  },
  {
    title: 'Automations that feel personal',
    body: 'Set invoice cadences, graceful reminders, and localized salutations once—then let Invoice Atlas deliver them for you.',
  },
  {
    title: 'Admin analytics at a glance',
    body: 'Subscription revenue, payment velocity, and outstanding balances stay visible without pulling raw exports.',
  },
];

const roadmap = [
  {
    step: '01',
    title: 'Tailor the canvas',
    body: 'Choose a template, lock in your palette, and drag branded modules into place. No hex codes or CSS required.',
  },
  {
    step: '02',
    title: 'Collect payment details',
    body: 'Sync contacts, drop in terms, and insert payment rails once. We remember them for future invoices automatically.',
  },
  {
    step: '03',
    title: 'Share or export instantly',
    body: 'Export an audit-ready PDF, share a live link, or send with your connected email provider without leaving the browser.',
  },
];

const plans = [
  {
    tier: 'Starter',
    price: '$0',
    description: 'Perfect for freelancers and boutiques who want beautiful PDFs with zero setup fees.',
    points: [
      'Unlimited invoices & receipt exports',
      'Two premium layout families',
      'Smart reminders + scheduled sends',
    ],
  },
  {
    tier: 'Growth',
    price: '$24/mo',
    description: 'Unlock revision history, admin tools, and client dashboards built for scaling agencies.',
    featured: true,
    points: [
      'Everything in Starter',
      'Advanced templates & rich sections',
      'Team seats with roles & approvals',
      'Analytics workspace & exports',
    ],
  },
  {
    tier: 'Enterprise',
    price: 'Let’s chat',
    description: 'SOC2-ready deployment, custom templates, and dedicated onboarding for finance teams.',
    points: [
      'Dedicated CSM and migration support',
      'Custom domains & SSO (SAML/OIDC)',
      'Your brand’s typography baked in',
    ],
  },
];

export default function LandingPage() {
  return (
    <>
      <section className="hero">
        <div className="container hero__inner">
          <div className="hero__content">
            <span className="eyebrow">Invoice design without the spreadsheet stress</span>
            <h1>Build polished, on-brand invoices in minutes.</h1>
            <p className="hero__lede">
              Invoice Atlas combines a Next.js marketing site with a Flutter workspace so prospects can learn and launch in one flow.
              Craft invoices, receipts, and statements that respect local standards while still feeling uniquely yours.
            </p>
            <div className="hero__actions">
              <Link href="/app" className="button button-primary" prefetch={false}>
                Launch the app
              </Link>
              <Link href="#features" className="button button-secondary">
                Explore features
              </Link>
            </div>
            <div className="hero__metrics">
              {stats.map((stat) => (
                <div key={stat.label} className="metric-card">
                  <strong>{stat.value}</strong>
                  <p>{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
          <div className="hero__visual">
            <div className="preview-card">
              <div className="preview-header">
                <span className="preview-badge">Canvas preview</span>
                <span>Wave template · Draft</span>
              </div>
              <div className="preview-body">
                <div className="preview-line" />
                <div className="preview-line" />
                <div className="preview-line short" />
              </div>
              <div className="preview-footer">
                <div>
                  <span>Balance due</span>
                  <strong>$3,240.00</strong>
                </div>
                <div>
                  <span>Due</span>
                  <strong>Jul 30</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="features" className="section">
        <div className="container">
          <div className="section__heading">
            <span className="eyebrow">Workflow</span>
            <h2>Purpose-built for operators who obsess over detail</h2>
            <p>
              Drag to compose, localize every label, and export a PDF that mirrors your brand guidelines. No plugins or design handoff
              required.
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
          <div className="roadmap-grid">
            {roadmap.map((item) => (
              <article key={item.step} className="roadmap-step">
                <span className="eyebrow" style={{ justifyContent: 'flex-start' }}>
                  Step {item.step}
                </span>
                <strong>{item.title}</strong>
                <p>{item.body}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="pricing" className="section pricing">
        <div className="container">
          <div className="section__heading">
            <span className="eyebrow">Pricing</span>
            <h2>Choose the plan that matches your momentum</h2>
            <p>Stay free as long as you need, then graduate to growth when finance is ready for deeper controls.</p>
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
                <Link
                  href="/app"
                  className={`button ${plan.featured ? 'button-primary' : 'button-secondary'} plan-button`}
                  prefetch={false}
                >
                  {plan.featured ? 'Upgrade to Growth' : 'Start building'}
                </Link>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="section cta">
        <div className="container">
          <div className="cta-banner">
            <div>
              <h2>Your next invoice can feel like a brand moment.</h2>
              <p>Spin up the Flutter workspace, drop in your assets, and export a client-ready PDF before the coffee cools.</p>
            </div>
            <Link href="/app" className="button button-light" prefetch={false}>
              Open the workspace
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
