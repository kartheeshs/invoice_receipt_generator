import Link from 'next/link';

type TemplatePreviewSpec = {
  slug: string;
  name: string;
  description: string;
  gradient: [string, string];
  surface: string;
  border: string;
  accent: string;
  headerText: string;
  balance: string;
  badge: string;
  tableHeader: string;
  tableText: string;
  canvas?: string;
};

const stats = [
  { label: 'teams assemble polished PDFs each week', value: '1.8k+' },
  { label: 'average time from draft to export', value: '3 minutes' },
  { label: 'currencies formatted without extra config', value: '28' },
];

const templates: TemplatePreviewSpec[] = [
  {
    slug: 'wave-blue',
    name: 'Wave Blue',
    description: 'Gradient hero with balance badge and striped line items.',
    gradient: ['#0B2E6B', '#1D4ED8'],
    surface: '#FFFFFF',
    border: 'rgba(168, 179, 212, 0.32)',
    accent: '#2563EB',
    headerText: '#FFFFFF',
    balance: '#EFF6FF',
    badge: 'rgba(37, 99, 235, 0.22)',
    tableHeader: '#1D4ED8',
    tableText: '#FFFFFF',
  },
  {
    slug: 'corporate-slate',
    name: 'Corporate Slate',
    description: 'Minimal form layout with neutral canvas and table totals.',
    gradient: ['#F8FAFC', '#FFFFFF'],
    surface: '#FFFFFF',
    border: 'rgba(148, 163, 184, 0.42)',
    accent: '#1F2937',
    headerText: '#0F172A',
    balance: '#F1F5F9',
    badge: 'rgba(31, 41, 55, 0.14)',
    tableHeader: '#1F2937',
    tableText: '#FFFFFF',
    canvas: '#F8FAFC',
  },
  {
    slug: 'emerald-stripe',
    name: 'Emerald Stripe',
    description: 'Statement banner, soft greens, and card-style totals.',
    gradient: ['#047857', '#0D9488'],
    surface: '#FFFFFF',
    border: 'rgba(134, 239, 172, 0.45)',
    accent: '#047857',
    headerText: '#FFFFFF',
    balance: '#ECFDF5',
    badge: 'rgba(4, 120, 87, 0.18)',
    tableHeader: '#10B981',
    tableText: '#0F172A',
  },
];

const features = [
  {
    title: 'Live collaboration with guardrails',
    body: 'Comment, edit, and approve in real time while granular roles keep finance owners in control.',
  },
  {
    title: 'Brand-perfect PDF output',
    body: 'Embed logos, gradients, and bilingual labels with vector precision across every export.',
  },
  {
    title: 'Automations that feel personal',
    body: 'Schedule polite reminders, localized greetings, and client-specific payment instructions without scripts.',
  },
  {
    title: 'Admin analytics at a glance',
    body: 'Monitor receivables, payment velocity, and renewal risk without downloading raw spreadsheets.',
  },
];

const roadmap = [
  {
    step: '01',
    title: 'Tailor the canvas',
    body: 'Pick a template, dial in colors, and drop in reusable modules. No CSS or design tool required.',
  },
  {
    step: '02',
    title: 'Collect payment details',
    body: 'Store billing profiles, terms, and rails once. They stay ready for every future invoice.',
  },
  {
    step: '03',
    title: 'Share or export instantly',
    body: 'Download an audit-ready PDF, send a live link, or push via email without leaving the browser.',
  },
];

const plans = [
  {
    tier: 'Starter',
    price: '$0',
    description: 'Ideal for freelancers and boutiques shipping polished PDFs with zero setup fees.',
    points: ['Unlimited invoices and receipts', 'Two premium layout families', 'Smart reminders & scheduled sends'],
  },
  {
    tier: 'Growth',
    price: '$24/mo',
    description: 'Unlock revision history, admin controls, and client dashboards built for scaling teams.',
    featured: true,
    points: ['Everything in Starter', 'Advanced templates & sections', 'Team roles with approvals', 'Analytics workspace & exports'],
  },
  {
    tier: 'Enterprise',
    price: 'Let’s chat',
    description: 'SOC2-ready deployment, custom templates, and dedicated onboarding for finance operations.',
    points: ['Dedicated CSM & migration support', 'Custom domains & SSO (SAML/OIDC)', 'Your brand typography baked in'],
  },
];

function TemplateMock({ template }: { template: TemplatePreviewSpec }) {
  const gradient = `linear-gradient(135deg, ${template.gradient[0]}, ${template.gradient[1]})`;
  return (
    <div
      className="template-preview"
      style={{
        background: template.canvas ?? template.surface,
        borderColor: template.border,
      }}
    >
      <div className="template-preview__header" style={{ background: gradient }}>
        <div className="template-preview__logo" />
        <div className="template-preview__heading" style={{ color: template.headerText }}>
          <span className="template-preview__title" />
          <span className="template-preview__subtitle" />
        </div>
        <div
          className="template-preview__badge"
          style={{ background: template.badge, color: template.headerText }}
        />
      </div>
      <div className="template-preview__body">
        <div className="template-preview__info">
          <span style={{ background: `${template.accent}33` }} />
          <span style={{ background: `${template.accent}22` }} />
          <span style={{ background: `${template.accent}18` }} />
          <span style={{ background: `${template.accent}10` }} />
        </div>
        <div className="template-preview__summary" style={{ background: template.balance }}>
          <span style={{ background: `${template.accent}33` }} />
          <span style={{ background: template.accent }} />
        </div>
      </div>
      <div className="template-preview__table">
        <div className="template-preview__table-header" style={{ background: template.tableHeader }}>
          <span style={{ background: template.tableText }} />
          <span style={{ background: template.tableText }} />
        </div>
        <div className="template-preview__table-rows">
          {[0, 1, 2].map((row) => (
            <div key={row} className="template-preview__table-row">
              <span style={{ background: `${template.accent}20` }} />
              <span style={{ background: `${template.accent}35` }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function LandingPage() {
  return (
    <>
      <section className="hero">
        <div className="container hero__wrap">
          <div className="hero__copy">
            <span className="eyebrow">Invoice design without the spreadsheet stress</span>
            <h1>Build polished, on-brand invoices in minutes.</h1>
            <p>
              Invoice Atlas pairs a Next.js marketing site with a Flutter workspace so prospects can learn and launch in one flow.
              Craft invoices, receipts, and statements that respect local standards while still feeling uniquely yours.
            </p>
            <div className="hero__actions">
              <Link href="/app" className="button button-primary" prefetch={false}>
                Launch the app
              </Link>
              <Link href="#templates" className="button button-secondary">
                Browse templates
              </Link>
            </div>
            <div className="hero__stats">
              {stats.map((stat) => (
                <div key={stat.label} className="stat-card">
                  <strong>{stat.value}</strong>
                  <p>{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
          <div className="hero__preview">
            <div className="preview-card">
              <div className="preview-card__header">
                <span className="preview-card__badge">Canvas preview</span>
                <span>Wave template · Draft</span>
              </div>
              <div className="preview-card__body">
                <div className="preview-card__line" />
                <div className="preview-card__line" />
                <div className="preview-card__line short" />
              </div>
              <div className="template-card__preview">
                <TemplateMock template={templates[0]} />
              </div>
              <div className="preview-card__footer">
                <div>
                  <span>Balance due</span>
                  <strong style={{ display: 'block', color: 'var(--text-primary)' }}>$3,240.00</strong>
                </div>
                <div>
                  <span>Due</span>
                  <strong style={{ display: 'block', color: 'var(--text-primary)' }}>Jul 30</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="templates" className="section template-section">
        <div className="container">
          <div className="section__heading">
            <span className="eyebrow">Template library</span>
            <h2>Choose a canvas curated by finance and brand teams</h2>
            <p>
              Every template respects regional billing etiquette while keeping your brand front and center. Swap layouts without
              losing your content or currency formatting.
            </p>
          </div>
          <div className="template-grid">
            {templates.map((template) => (
              <article key={template.slug} className="template-card">
                <div className="template-card__preview">
                  <TemplateMock template={template} />
                </div>
                <h3>{template.name}</h3>
                <p>{template.description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="features" className="section">
        <div className="container">
          <div className="section__heading">
            <span className="eyebrow">Workflow</span>
            <h2>Purpose-built for operators who obsess over detail</h2>
            <p>
              Drag components into place, localize every label, and export a PDF that mirrors your brand guidelines. No plugins or
              design handoff required.
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
            <Link href="/app" className="button" prefetch={false}>
              Open the workspace
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
