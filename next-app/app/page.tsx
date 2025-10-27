import Link from 'next/link';

type TemplatePreview = {
  slug: string;
  name: string;
  tagline: string;
  accent: string;
  accentSoft: string;
  header: [string, string];
  border: string;
  tableHeader: string;
  stripe: string;
};

const stats = [
  { value: '1.8k+', label: 'teams invoice with Atlas each month' },
  { value: '3 min', label: 'average draft-to-download time' },
  { value: '28', label: 'currencies formatted automatically' },
];

const features = [
  {
    title: 'Editor that keeps context',
    body: 'Update line items, payment terms, and brand colours while the PDF preview mirrors every change in real time.',
  },
  {
    title: 'Templates clients trust',
    body: 'Choose clean finance-reviewed layouts with balance summaries, bilingual labels, and optional signature space.',
  },
  {
    title: 'Collaboration built-in',
    body: 'Invite teammates, assign approvals, and leave comments without exposing the entire billing history.',
  },
  {
    title: 'Automations that feel human',
    body: 'Schedule reminders, tailor follow-up copy, and monitor payment status from a single dashboard.',
  },
];

const templates: TemplatePreview[] = [
  {
    slug: 'wave-blue',
    name: 'Wave Blue',
    tagline: 'Gradient masthead with balance badge and polished totals.',
    accent: '#2563EB',
    accentSoft: 'rgba(37, 99, 235, 0.14)',
    header: ['#1D4ED8', '#60A5FA'],
    border: 'rgba(37, 99, 235, 0.18)',
    tableHeader: '#1D4ED8',
    stripe: 'rgba(37, 99, 235, 0.08)',
  },
  {
    slug: 'classic-ledger',
    name: 'Classic Ledger',
    tagline: 'Sharp monochrome layout with crisp dividers for formal billing.',
    accent: '#111827',
    accentSoft: 'rgba(15, 23, 42, 0.1)',
    header: ['#F8FAFC', '#E2E8F0'],
    border: 'rgba(15, 23, 42, 0.16)',
    tableHeader: '#1F2937',
    stripe: 'rgba(15, 23, 42, 0.05)',
  },
  {
    slug: 'emerald-stripe',
    name: 'Emerald Stripe',
    tagline: 'Fresh greens with card-style totals and signature block.',
    accent: '#047857',
    accentSoft: 'rgba(4, 120, 87, 0.16)',
    header: ['#0F766E', '#22C55E'],
    border: 'rgba(4, 120, 87, 0.22)',
    tableHeader: '#0F766E',
    stripe: 'rgba(4, 120, 87, 0.08)',
  },
  {
    slug: 'seikyu',
    name: 'Seikyūsho',
    tagline: 'Bilingual headings, hanko placeholder, and tax summary.',
    accent: '#B91C1C',
    accentSoft: 'rgba(185, 28, 28, 0.14)',
    header: ['#FEE2E2', '#FFFFFF'],
    border: 'rgba(185, 28, 28, 0.18)',
    tableHeader: '#991B1B',
    stripe: 'rgba(185, 28, 28, 0.1)',
  },
];

const workflow = [
  {
    step: '01',
    title: 'Personalise the canvas',
    body: 'Upload your logo, choose a template, and set reusable blocks for service notes or tax language.',
  },
  {
    step: '02',
    title: 'Fill once, reuse forever',
    body: 'Store client records, payment terms, and bank info so new documents start from a polished base.',
  },
  {
    step: '03',
    title: 'Share instantly',
    body: 'Export vector-perfect PDFs, send secure links, or deliver branded emails with automatic reminders.',
  },
];

const plans = [
  {
    tier: 'Starter',
    price: '$0',
    description: 'For solo builders who need professional invoices without the busywork.',
    points: ['Unlimited invoices & receipts', 'Two premium template families', 'Smart reminders and status tracking'],
  },
  {
    tier: 'Growth',
    price: '$24/mo',
    featured: true,
    description: 'Unlock collaboration, version history, and automation for scaling teams.',
    points: ['Everything in Starter', 'Approval workflows & roles', 'Template version history', 'Analytics workspace'],
  },
  {
    tier: 'Enterprise',
    price: 'Let’s talk',
    description: 'SOC2-ready deployment with custom templates, SSO, and dedicated support.',
    points: ['Dedicated CSM & migration', 'Custom domains & SSO', 'Bespoke template engineering'],
  },
];

function TemplateThumbnail({ template }: { template: TemplatePreview }) {
  return (
    <div
      className="template-preview"
      style={{
        background: `linear-gradient(160deg, var(--surface) 0%, ${template.accentSoft} 100%)`,
        borderColor: template.border,
      }}
    >
      <div className="template-preview__header">
        <span
          className="template-preview__logo"
          style={{
            background: `linear-gradient(135deg, ${template.header[0]}, ${template.header[1]})`,
          }}
        />
        <div className="template-preview__lines" style={{ flex: 1 }}>
          <span className="template-preview__line" style={{ width: '82%' }} />
          <span className="template-preview__line" style={{ width: '64%' }} />
        </div>
        <div
          style={{
            width: '64px',
            height: '28px',
            borderRadius: '12px',
            background: template.accentSoft,
          }}
        />
      </div>
      <div className="template-preview__lines">
        <span className="template-preview__line" style={{ width: '92%' }} />
        <span className="template-preview__line" style={{ width: '70%' }} />
        <span className="template-preview__line" style={{ width: '56%' }} />
      </div>
      <div className="template-preview__table">
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '2.2fr 1fr',
            gap: '0.45rem',
            padding: '0.55rem 0.7rem',
            borderRadius: '14px',
            background: template.tableHeader,
          }}
        >
          <span className="template-preview__line" style={{ height: '6px', background: 'rgba(255,255,255,0.8)' }} />
          <span className="template-preview__line" style={{ height: '6px', background: 'rgba(255,255,255,0.8)' }} />
        </div>
        {[0, 1, 2].map((row) => (
          <div
            key={row}
            style={{
              display: 'grid',
              gridTemplateColumns: '2.2fr 1fr',
              gap: '0.55rem',
              padding: '0.5rem 0.7rem',
              borderRadius: '14px',
              background: row % 2 === 0 ? 'rgba(15,23,42,0.03)' : template.stripe,
            }}
          >
            <span className="template-preview__line" style={{ height: '6px', background: 'rgba(15,23,42,0.2)' }} />
            <span className="template-preview__line" style={{ height: '6px', background: template.accentSoft }} />
          </div>
        ))}
      </div>
      <div className="template-preview__lines">
        <span className="template-preview__line" style={{ width: '68%', height: '7px' }} />
        <span className="template-preview__line" style={{ width: '42%', height: '7px', background: template.accentSoft }} />
      </div>
    </div>
  );
}

export default function LandingPage() {
  return (
    <>
      <section className="hero container" id="hero">
        <div className="hero__content">
          <span className="badge">Invoice &amp; receipt workspace</span>
          <h1 className="hero__title">Send polished invoices in minutes, not hours.</h1>
          <p>
            Build branded invoices and receipts with finance-approved templates, collaborate with teammates, and export
            vector-perfect PDFs from one shared workspace.
          </p>
          <div className="hero__actions">
            <Link href="/app" className="button button--primary" prefetch={false}>
              Launch the app
            </Link>
            <Link href="#templates" className="button button--ghost" prefetch={false}>
              Browse templates
            </Link>
          </div>
          <div className="hero__card-grid">
            {stats.map((stat) => (
              <div key={stat.value} className="hero__card-metric">
                <strong style={{ fontSize: '1.4rem', color: 'var(--text-strong)' }}>{stat.value}</strong>
                <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>{stat.label}</span>
              </div>
            ))}
          </div>
        </div>
        <aside className="hero__card">
          <div style={{ display: 'grid', gap: '0.6rem' }}>
            <span className="badge" style={{ width: 'fit-content' }}>
              Live preview
            </span>
            <h3 style={{ margin: 0, color: 'var(--text-strong)' }}>Easy Invoice GM7 Canvas</h3>
            <p style={{ margin: 0 }}>
              Every tweak you make—colours, copy, payments—updates the PDF instantly so you always know what clients will see.
            </p>
          </div>
          <TemplateThumbnail template={templates[0]} />
          <div style={{ display: 'grid', gap: '0.5rem' }}>
            <strong style={{ color: 'var(--text-strong)' }}>Why teams switch</strong>
            <ul style={{ margin: 0, paddingLeft: '1.1rem', display: 'grid', gap: '0.35rem', color: 'var(--text-body)' }}>
              <li>No design tools required</li>
              <li>Shared template library</li>
              <li>PDFs that pass finance reviews</li>
            </ul>
          </div>
        </aside>
      </section>

      <section className="container" id="features">
        <div className="section-heading">
          <h2>Everything you need to move from draft to paid</h2>
          <p>
            The workspace blends the speed of a form with the power of a layout designer. Start with a proven template, update
            the details, and export with confidence.
          </p>
        </div>
        <div className="feature-grid" style={{ marginTop: '2rem' }}>
          {features.map((feature) => (
            <article key={feature.title} className="feature-card">
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="container template-gallery" id="templates">
        <div className="section-heading">
          <h2>Template gallery</h2>
          <p>
            Swap layouts with a click. Each template adjusts typography, colour, and summary blocks without breaking your data.
          </p>
        </div>
        <div className="template-grid">
          {templates.map((template) => (
            <article key={template.slug} className="template-card">
              <TemplateThumbnail template={template} />
              <div style={{ display: 'grid', gap: '0.35rem' }}>
                <h3>{template.name}</h3>
                <p style={{ margin: 0 }}>{template.tagline}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="container" id="workflow">
        <div className="section-heading">
          <h2>Designed for the full billing workflow</h2>
          <p>
            From the first draft to the paid receipt, Easy Invoice GM7 keeps teams aligned and clients confident.
          </p>
        </div>
        <div className="workflow-timeline" style={{ marginTop: '2rem' }}>
          {workflow.map((item) => (
            <article key={item.step} className="workflow-step">
              <strong>{item.step}</strong>
              <h3 style={{ margin: 0, color: 'var(--text-strong)' }}>{item.title}</h3>
              <p>{item.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="container" id="pricing">
        <div className="section-heading">
          <h2>Pricing that scales with your billing volume</h2>
          <p>
            Start free, upgrade when collaboration or automation becomes essential. No surprise fees—ever.
          </p>
        </div>
        <div className="pricing-grid" style={{ marginTop: '2rem' }}>
          {plans.map((plan) => (
            <article key={plan.tier} className={`pricing-card${plan.featured ? ' is-featured' : ''}`}>
              <div>
                <h3>{plan.tier}</h3>
                <p style={{ margin: '0.2rem 0 0', color: 'var(--text-muted)' }}>{plan.description}</p>
              </div>
              <strong style={{ fontSize: '1.5rem', color: 'var(--text-strong)' }}>{plan.price}</strong>
              <ul>
                {plan.points.map((point) => (
                  <li key={point}>• {point}</li>
                ))}
              </ul>
              <Link href="/app" className="button button--ghost" prefetch={false}>
                Get started
              </Link>
            </article>
          ))}
        </div>
      </section>

      <section className="container">
        <div className="cta">
          <h2>Ready to send your next invoice?</h2>
          <p>Spin up a polished invoice in minutes and keep every client touchpoint on brand.</p>
          <div className="hero__actions" style={{ justifyContent: 'center' }}>
            <Link href="/app" className="button button--primary" prefetch={false}>
              Launch workspace
            </Link>
            <Link href="/app" className="button button--ghost" prefetch={false}>
              View dashboard
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
