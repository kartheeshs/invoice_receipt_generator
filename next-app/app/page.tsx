"use client";

import Link from 'next/link';
import { useMemo } from 'react';
import { useTranslation } from '../lib/i18n';
import AdSlot from './components/ad-slot';

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
    slug: 'villa-coastal',
    name: 'Villa Coastal',
    tagline: 'Azure header with booking summary badge for hospitality teams.',
    accent: '#1D5FBF',
    accentSoft: 'rgba(29, 95, 191, 0.14)',
    header: ['#0B366B', '#3CA1FF'],
    border: 'rgba(29, 95, 191, 0.18)',
    tableHeader: '#1D5FBF',
    stripe: 'rgba(28, 123, 230, 0.08)',
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
    slug: 'harbour-slate',
    name: 'Harbour Slate',
    tagline: 'Travel folio layout with grey-blue masthead and stay summary.',
    accent: '#1D4E89',
    accentSoft: 'rgba(29, 78, 137, 0.14)',
    header: ['#012A4A', '#5FA8D3'],
    border: 'rgba(29, 78, 137, 0.18)',
    tableHeader: '#1D4E89',
    stripe: 'rgba(148, 163, 184, 0.12)',
  },
  {
    slug: 'aqua-ledger',
    name: 'Aqua Ledger',
    tagline: 'Teal balance capsule with alternating aqua striping.',
    accent: '#14B8A6',
    accentSoft: 'rgba(20, 184, 166, 0.16)',
    header: ['#0F766E', '#22D3EE'],
    border: 'rgba(20, 184, 166, 0.22)',
    tableHeader: '#0F766E',
    stripe: 'rgba(45, 212, 191, 0.12)',
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

const statsJa = [
  { value: '1.8k+', label: '毎月 Easy Invoice GM7 を利用するチーム数' },
  { value: '3 分', label: '下書きからダウンロードまでの平均時間' },
  { value: '28', label: '自動フォーマット対応通貨数' },
];

const featuresJa = [
  {
    title: '文脈を保つエディター',
    body: '明細、支払い条件、ブランドカラーを更新すると、PDF プレビューがリアルタイムで反映します。',
  },
  {
    title: '信頼されるテンプレート',
    body: 'バランスサマリーやバイリンガルラベルを備えた金融監修済みのレイアウトを選択できます。',
  },
  {
    title: 'コラボレーション機能',
    body: 'チームを招待し、承認フローやコメントを追加しても、全ての履歴を公開する必要はありません。',
  },
  {
    title: '自然な自動化',
    body: 'フォローアップメールやリマインダーをスケジュールし、支払い状況をダッシュボードで確認できます。',
  },
];

const workflowJa = [
  { step: '01', title: 'キャンバスをパーソナライズ', body: 'ロゴをアップロードし、テンプレートを選び、サービスや税の文言を再利用可能なブロックとして保存します。' },
  { step: '02', title: '一度入力すれば再利用', body: '顧客情報や支払い条件、振込先を保存しておけば、次の書類は完成に近い状態で開始できます。' },
  { step: '03', title: 'すぐに共有', body: 'ベクター品質の PDF をエクスポートしたり、安全なリンクやブランドメールで送信できます。' },
];

const plansJa = [
  {
    tier: 'スターター',
    price: '¥0',
    description: 'プロ品質の請求書を素早く作成したい個人事業主向け。',
    points: ['請求書と領収書を無制限に作成', '2 種類のプレミアムテンプレート', 'スマートリマインダーとステータス追跡'],
  },
  {
    tier: 'グロース',
    price: '¥999/月',
    featured: true,
    description: '共同編集、バージョン履歴、自動化をすべて解放するチーム向けプラン。',
    points: ['スタータープランの全機能', '承認ワークフローと権限管理', 'テンプレートのバージョン履歴', '分析ワークスペース'],
  },
  {
    tier: 'エンタープライズ',
    price: 'ご相談ください',
    description: 'カスタムテンプレート、SSO、専任サポートを備えたエンタープライズ導入。',
    points: ['専任 CSM と移行支援', 'カスタムドメインと SSO', 'カスタムテンプレート開発'],
  },
];

const templateTaglinesJa: Record<string, string> = {
  'villa-coastal': 'リゾートの領収書を思わせるブルーのヘッダーと予約サマリーが特徴です。',
  'classic-ledger': '正式な帳票に最適なモノクロレイアウト。',
  'harbour-slate': '旅行明細に合わせたブルーグレーのヘッダーと予約サマリーが特徴です。',
  'aqua-ledger': 'バランスカプセルと交互のティールストライプでモダンな印象に。',
  seikyu: 'バイリンガル見出しと判子スペース付きの請求書。',
};

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
  const { language, t } = useTranslation();

  const localizedStats = useMemo(() => (language === 'ja' ? statsJa : stats), [language]);
  const localizedFeatures = useMemo(() => (language === 'ja' ? featuresJa : features), [language]);
  const localizedWorkflow = useMemo(() => (language === 'ja' ? workflowJa : workflow), [language]);
  const localizedPlans = useMemo(() => {
    const base = language === 'ja' ? plansJa : plans;
    return base.map((plan) => {
      if ((language === 'ja' && plan.tier === 'グロース') || (language === 'en' && plan.tier === 'Growth')) {
        return { ...plan, price: language === 'ja' ? '¥999/月' : '$10/mo' };
      }
      return plan;
    });
  }, [language]);

  const priceNote = t(
    'landing.pricing.currencyHint',
    'Use Easy Invoice GM7 for ¥999/mo in Japan and $10/mo in other regions.',
  );

  return (
    <>
      <section className="hero container" id="hero">
        <div className="hero__content">
          <span className="badge">{t('landing.hero.badge', 'Invoice & receipt workspace')}</span>
          <h1 className="hero__title">{t('landing.hero.title', 'Send polished invoices in minutes, not hours.')}</h1>
          <p>{t('landing.hero.subtitle', 'Build branded invoices and receipts with finance-reviewed templates and export vector-perfect PDFs in minutes.')}</p>
          <div className="hero__actions">
            <Link href="/app" className="button button--primary" prefetch={false}>
              {t('landing.hero.ctaPrimary', 'Launch the app')}
            </Link>
            <Link href="#templates" className="button button--ghost" prefetch={false}>
              {t('landing.hero.ctaSecondary', 'Browse templates')}
            </Link>
          </div>
          <div className="hero__card-grid">
            {localizedStats.map((stat) => (
              <div key={`${stat.value}-${stat.label}`} className="hero__card-metric">
                <strong style={{ fontSize: '1.4rem', color: 'var(--text-strong)' }}>{stat.value}</strong>
                <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>{stat.label}</span>
              </div>
            ))}
          </div>
        </div>
        <aside className="hero__card">
          <div style={{ display: 'grid', gap: '0.6rem' }}>
            <span className="badge" style={{ width: 'fit-content' }}>
              {t('landing.hero.cardBadge', 'Live preview')}
            </span>
            <h3 style={{ margin: 0, color: 'var(--text-strong)' }}>{t('landing.hero.cardTitle', 'Easy Invoice GM7 Canvas')}</h3>
            <p style={{ margin: 0 }}>
              {t(
                'landing.hero.cardBody',
                'Every tweak you make—colours, copy, payments—updates the PDF instantly so you always know what clients will see.',
              )}
            </p>
          </div>
          <TemplateThumbnail template={templates[0]} />
          <div style={{ display: 'grid', gap: '0.5rem' }}>
            <strong style={{ color: 'var(--text-strong)' }}>{t('landing.hero.switchReasons', 'Why teams switch')}</strong>
            <ul style={{ margin: 0, paddingLeft: '1.1rem', display: 'grid', gap: '0.35rem', color: 'var(--text-body)' }}>
              <li>{t('landing.hero.reason1', 'No design tools required')}</li>
              <li>{t('landing.hero.reason2', 'Shared template library')}</li>
              <li>{t('landing.hero.reason3', 'PDFs that pass finance reviews')}</li>
            </ul>
          </div>
        </aside>
      </section>

      <section className="container ad-section">
        <AdSlot
          label={t('ads.landing.heroLeaderboard', 'Homepage leaderboard (970×250)')}
          description={t(
            'ads.landing.heroLeaderboardDescription',
            'Reserve this hero banner for high-impact campaigns or important partner announcements.',
          )}
        />
      </section>

      <section className="container" id="features">
        <div className="section-heading">
          <h2>{t('landing.features.heading', 'Everything you need to move from draft to paid')}</h2>
          <p>
            {t(
              'landing.features.subtitle',
              'The workspace blends the speed of a form with the power of a layout designer. Start with a proven template, update the details, and export with confidence.',
            )}
          </p>
        </div>
        <div className="feature-grid" style={{ marginTop: '2rem' }}>
          {localizedFeatures.map((feature) => (
            <article key={feature.title} className="feature-card">
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="container template-gallery" id="templates">
        <div className="section-heading">
          <h2>{t('landing.templates.heading', 'Template gallery')}</h2>
          <p>
            {t(
              'landing.templates.body',
              'Swap layouts with a click. Each template adjusts typography, colour, and summary blocks without breaking your data.',
            )}
          </p>
        </div>
        <div className="template-grid">
          {templates.map((template) => {
            const tagline = language === 'ja' ? templateTaglinesJa[template.slug] ?? template.tagline : template.tagline;
            return (
              <article key={template.slug} className="template-card">
                <TemplateThumbnail template={template} />
                <div style={{ display: 'grid', gap: '0.35rem' }}>
                  <h3>{template.name}</h3>
                  <p style={{ margin: 0 }}>{tagline}</p>
                </div>
              </article>
            );
          })}
        </div>
        <div className="template-gallery__ad">
          <AdSlot
            label={t('ads.landing.midPage', 'Template gallery spotlight (728×90)')}
            description={t(
              'ads.landing.midPageDescription',
              'Ideal for showcasing design partners, integrations, or seasonal promotions alongside templates.',
            )}
          />
        </div>
      </section>

      <section className="container" id="workflow">
        <div className="section-heading">
          <h2>{t('landing.workflow.heading', 'Designed for the full billing workflow')}</h2>
          <p>
            {t(
              'landing.workflow.subtitle',
              'From the first draft to the paid receipt, Easy Invoice GM7 keeps teams aligned and clients confident.',
            )}
          </p>
        </div>
        <div className="workflow-timeline" style={{ marginTop: '2rem' }}>
          {localizedWorkflow.map((item) => (
            <article key={item.step} className="workflow-step">
              <strong>{item.step}</strong>
              <h3 style={{ margin: 0, color: 'var(--text-strong)' }}>{item.title}</h3>
              <p>{item.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="container ad-section">
        <AdSlot
          label={t('ads.landing.pricingNative', 'Native placement beside pricing (300×250)')}
          description={t(
            'ads.landing.pricingNativeDescription',
            'Use this space for upgrade nudges, referral programmes, or sponsor content near the pricing table.',
          )}
        />
      </section>

      <section className="container" id="pricing">
        <div className="section-heading">
          <h2>{t('landing.pricing.heading', 'Pricing that scales with your billing volume')}</h2>
          <p>
            {t(
              'landing.pricing.subtitle',
              'Start free, upgrade when collaboration or automation becomes essential. No surprise fees—ever.',
            )}
          </p>
        </div>
        <p className="pricing-note">{priceNote}</p>
        <div className="pricing-grid" style={{ marginTop: '1.5rem' }}>
          {localizedPlans.map((plan) => (
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
                {t('landing.pricing.cta', 'Get started')}
              </Link>
            </article>
          ))}
        </div>
      </section>

      <section className="container">
        <div className="cta">
          <h2>{t('landing.cta.title', 'Ready to send your next invoice?')}</h2>
          <p>{t('landing.cta.body', 'Spin up a polished invoice in minutes and keep every client touchpoint on brand.')}</p>
          <div className="hero__actions" style={{ justifyContent: 'center' }}>
            <Link href="/app" className="button button--primary" prefetch={false}>
              {t('landing.cta.primary', 'Launch workspace')}
            </Link>
            <Link href="/app" className="button button--ghost" prefetch={false}>
              {t('landing.cta.secondary', 'View dashboard')}
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
