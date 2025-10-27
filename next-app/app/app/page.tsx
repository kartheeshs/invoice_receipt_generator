'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  InvoiceDraft,
  InvoiceLine,
  InvoiceRecord,
  InvoiceStatus,
  calculateTotals,
  cleanLines,
  createEmptyDraft,
  createEmptyLine,
  describeStatus,
  formatCurrency,
} from '../../lib/invoices';
import { firebaseConfigured, fetchRecentInvoices, saveInvoice } from '../../lib/firebase';
import { sampleInvoices } from '../../lib/sample-data';

type SectionId = 'dashboard' | 'invoices' | 'templates' | 'clients' | 'activity' | 'settings';

type Section = {
  id: SectionId;
  label: string;
  description: string;
  icon: string;
};

type TemplateDefinition = {
  id: string;
  name: string;
  description: string;
  accent: string;
  accentSoft: string;
  bestFor: string;
  highlights: string[];
};

type ClientSummary = {
  key: string;
  name: string;
  email: string | undefined;
  invoices: number;
  outstanding: number;
  lastInvoice?: string;
  status: InvoiceStatus;
  currency: string;
};

const sections: Section[] = [
  { id: 'dashboard', label: 'Overview', description: 'Pulse of your billing workspace', icon: '📊' },
  { id: 'invoices', label: 'Invoices', description: 'Compose and preview drafts', icon: '🧾' },
  { id: 'templates', label: 'Templates', description: 'Switch the invoice look & feel', icon: '🎨' },
  { id: 'clients', label: 'Clients', description: 'Track customer history', icon: '👥' },
  { id: 'activity', label: 'Activity', description: 'Monitor timeline & reminders', icon: '🕒' },
  { id: 'settings', label: 'Settings', description: 'Default business preferences', icon: '⚙️' },
];

const statusOptions: { value: InvoiceStatus; label: string }[] = [
  { value: 'draft', label: 'Draft' },
  { value: 'sent', label: 'Sent' },
  { value: 'paid', label: 'Paid' },
  { value: 'overdue', label: 'Overdue' },
];

const templateCatalog: TemplateDefinition[] = [
  {
    id: 'wave-blue',
    name: 'Wave Blue',
    description: 'Gradient header, balance badge, and crisp table styling designed for agencies and studios.',
    accent: 'linear-gradient(135deg, rgba(37,99,235,0.95), rgba(129,140,248,0.95))',
    accentSoft: 'rgba(37, 99, 235, 0.12)',
    bestFor: 'Creative teams who want a vibrant, polished statement.',
    highlights: ['Hero balance badge', 'Bilingual labels ready', 'Clean table totals'],
  },
  {
    id: 'minimal-slate',
    name: 'Minimal Slate',
    description: 'Monochrome layout with subtle dividers and a focus on clarity for consulting firms.',
    accent: 'linear-gradient(135deg, rgba(15,23,42,0.95), rgba(100,116,139,0.85))',
    accentSoft: 'rgba(15, 23, 42, 0.1)',
    bestFor: 'Professional services requiring a conservative, finance-first aesthetic.',
    highlights: ['Muted neutral palette', 'Signature-ready footer', 'Auto-aligned totals'],
  },
  {
    id: 'emerald-ledger',
    name: 'Emerald Ledger',
    description: 'Fresh green accents with card-style totals and payment reminders built into the footer.',
    accent: 'linear-gradient(135deg, rgba(16,185,129,0.95), rgba(22,163,74,0.9))',
    accentSoft: 'rgba(16, 185, 129, 0.12)',
    bestFor: 'Subscription or SaaS teams sending recurring invoices.',
    highlights: ['Balance summary sidebar', 'Reminder callouts', 'Payment instructions block'],
  },
  {
    id: 'seikyu',
    name: 'Seikyūsho',
    description: 'Bilingual Japanese / English headings, hanko placeholder, and tax summary grid.',
    accent: 'linear-gradient(135deg, rgba(239,68,68,0.95), rgba(249,115,22,0.9))',
    accentSoft: 'rgba(239, 68, 68, 0.12)',
    bestFor: 'Teams invoicing Japanese clients with localised terminology.',
    highlights: ['Hanko-ready footer', 'Tax summary rows', 'Dual-language columns'],
  },
];

const currencyOptions = ['USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY', 'SGD'];

function formatFriendlyDate(value?: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function ensureLine(line: InvoiceLine, field: keyof InvoiceLine, value: string): InvoiceLine {
  if (field === 'description') {
    return { ...line, description: value };
  }

  const numeric = Number(value);
  if (field === 'quantity') {
    return { ...line, quantity: Number.isFinite(numeric) && numeric > 0 ? numeric : line.quantity };
  }

  return { ...line, rate: Number.isFinite(numeric) && numeric >= 0 ? numeric : line.rate };
}

export default function WorkspacePage() {
  const [activeSection, setActiveSection] = useState<SectionId>('dashboard');
  const [selectedTemplate, setSelectedTemplate] = useState<string>(templateCatalog[0]?.id ?? 'wave-blue');
  const [draft, setDraft] = useState<InvoiceDraft>(() => createEmptyDraft());
  const [recentInvoices, setRecentInvoices] = useState<InvoiceRecord[]>([]);
  const [loadingInvoices, setLoadingInvoices] = useState<boolean>(true);
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  const [alertMessage, setAlertMessage] = useState<string>('');
  const [invoiceView, setInvoiceView] = useState<'edit' | 'preview'>('edit');

  useEffect(() => {
    let active = true;

    async function loadInvoices() {
      try {
        if (firebaseConfigured) {
          const invoices = await fetchRecentInvoices(12);
          if (!active) return;
          setRecentInvoices(invoices.length ? invoices : sampleInvoices);
        } else if (active) {
          setRecentInvoices(sampleInvoices);
        }
      } catch (error) {
        console.error(error);
        if (!active) return;
        setAlertMessage('Unable to reach Firestore. Displaying sample invoices.');
        setSaveState('error');
        setRecentInvoices(sampleInvoices);
      } finally {
        if (active) {
          setLoadingInvoices(false);
        }
      }
    }

    loadInvoices();

    return () => {
      active = false;
    };
  }, []);

  const totals = useMemo(() => calculateTotals(draft.lines, draft.taxRate), [draft.lines, draft.taxRate]);
  const statusLookup = useMemo(() => new Map(statusOptions.map((option) => [option.value, option.label])), []);
  const activeTemplate = useMemo(
    () => templateCatalog.find((template) => template.id === selectedTemplate) ?? templateCatalog[0],
    [selectedTemplate],
  );

  const outstandingTotal = useMemo(
    () =>
      recentInvoices.reduce((sum, invoice) => {
        return invoice.status === 'paid' ? sum : sum + invoice.total;
      }, 0),
    [recentInvoices],
  );

  const paidThisMonth = useMemo(() => {
    const now = new Date();
    const month = now.getMonth();
    const year = now.getFullYear();
    return recentInvoices
      .filter((invoice) => {
        if (invoice.status !== 'paid') return false;
        const issued = invoice.createdAt ? new Date(invoice.createdAt) : new Date(invoice.issueDate);
        return issued.getMonth() === month && issued.getFullYear() === year;
      })
      .reduce((sum, invoice) => sum + invoice.total, 0);
  }, [recentInvoices]);

  const clientSummaries = useMemo(() => {
    const summaries = new Map<string, ClientSummary>();

    for (const invoice of recentInvoices) {
      const key = invoice.clientEmail || invoice.clientName || invoice.id;
      const outstanding = invoice.status === 'paid' ? 0 : invoice.total;
      const candidateDate = invoice.issueDate ? new Date(invoice.issueDate) : undefined;
      const existing = summaries.get(key);

      if (existing) {
        const previousDate = existing.lastInvoice ? new Date(existing.lastInvoice) : undefined;
        const shouldReplace = candidateDate && (!previousDate || candidateDate > previousDate);

        summaries.set(key, {
          ...existing,
          invoices: existing.invoices + 1,
          outstanding: existing.outstanding + outstanding,
          lastInvoice: shouldReplace ? invoice.issueDate : existing.lastInvoice,
          status: shouldReplace ? invoice.status : existing.status,
          currency: invoice.currency || existing.currency,
        });
      } else {
        summaries.set(key, {
          key,
          name: invoice.clientName || 'Client',
          email: invoice.clientEmail,
          invoices: 1,
          outstanding,
          lastInvoice: invoice.issueDate,
          status: invoice.status,
          currency: invoice.currency,
        });
      }
    }

    return Array.from(summaries.values()).sort((a, b) => b.outstanding - a.outstanding);
  }, [recentInvoices]);

  const activityFeed = useMemo(() => {
    return recentInvoices
      .map((invoice) => ({
        id: invoice.id,
        title: `${invoice.clientName || 'Client'} — ${describeStatus(invoice.status)}`,
        amount: formatCurrency(invoice.total, invoice.currency),
        timestamp: invoice.createdAt || invoice.issueDate,
        status: invoice.status,
      }))
      .sort((a, b) => {
        const dateA = new Date(a.timestamp ?? '').getTime();
        const dateB = new Date(b.timestamp ?? '').getTime();
        return dateB - dateA;
      });
  }, [recentInvoices]);

  function updateDraftField<K extends keyof InvoiceDraft>(field: K, value: InvoiceDraft[K]) {
    setDraft((prev) => ({ ...prev, [field]: value }));
  }

  function addLine() {
    setDraft((prev) => ({ ...prev, lines: [...prev.lines, createEmptyLine()] }));
  }

  function updateLine(id: string, field: keyof InvoiceLine, value: string) {
    setDraft((prev) => ({
      ...prev,
      lines: prev.lines.map((line) => (line.id === id ? ensureLine(line, field, value) : line)),
    }));
  }

  function removeLine(id: string) {
    setDraft((prev) => {
      const remaining = prev.lines.filter((line) => line.id !== id);
      return {
        ...prev,
        lines: remaining.length ? remaining : [createEmptyLine()],
      };
    });
  }

  async function handleSave(event?: FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    if (saveState === 'saving') {
      return;
    }

    setSaveState('saving');
    setAlertMessage('');

    const cleanedLines = cleanLines(draft.lines);
    const ensuredLines = cleanedLines.length ? cleanedLines : [createEmptyLine()];
    const preparedDraft: InvoiceDraft = {
      ...draft,
      clientName: draft.clientName.trim(),
      clientEmail: draft.clientEmail.trim(),
      businessName: draft.businessName.trim(),
      businessAddress: draft.businessAddress.trim(),
      notes: draft.notes.trim(),
      lines: ensuredLines,
    };

    setDraft(preparedDraft);

    try {
      const computedTotals = calculateTotals(preparedDraft.lines, preparedDraft.taxRate);

      if (!firebaseConfigured) {
        const offlineRecord: InvoiceRecord = {
          id: `local-${Date.now()}`,
          ...preparedDraft,
          subtotal: computedTotals.subtotal,
          taxAmount: computedTotals.taxAmount,
          total: computedTotals.total,
          createdAt: new Date().toISOString(),
        };

        setRecentInvoices((prev) => [offlineRecord, ...prev].slice(0, 12));
        setAlertMessage('Firebase is not configured. Stored invoice locally for this session.');
        setSaveState('success');
        setLoadingInvoices(false);
        return;
      }

      const saved = await saveInvoice({ draft: preparedDraft });
      setRecentInvoices((prev) => {
        const filtered = prev.filter((invoice) => invoice.id !== saved.id);
        return [saved, ...filtered].slice(0, 12);
      });
      setAlertMessage('Invoice saved to Firestore.');
      setSaveState('success');
    } catch (error) {
      console.error(error);
      setAlertMessage(error instanceof Error ? error.message : 'Unable to save invoice.');
      setSaveState('error');
    }
  }

  function handleDownload() {
    if (typeof window === 'undefined') {
      console.warn('Download is only available in the browser.');
      return;
    }

    window.print();
  }

  function renderTemplateThumbnails({ showDetails = false }: { showDetails?: boolean } = {}) {
    return (
      <div className={`template-thumbnail-grid${showDetails ? ' template-thumbnail-grid--detailed' : ''}`}>
        {templateCatalog.map((template) => {
          const isActive = template.id === selectedTemplate;
          return (
            <button
              key={template.id}
              type="button"
              onClick={() => setSelectedTemplate(template.id)}
              className={`template-thumbnail${isActive ? ' template-thumbnail--active' : ''}`}
              aria-pressed={isActive}
            >
              <span className="template-thumbnail__preview" style={{ background: template.accent }} aria-hidden="true">
                <span className="template-thumbnail__preview-header">{template.name}</span>
                <span className="template-thumbnail__preview-body" />
                <span className="template-thumbnail__preview-footer">{template.highlights[0]}</span>
              </span>
              <span className="template-thumbnail__label">
                <strong>{template.name}</strong>
                <small>{template.bestFor}</small>
              </span>
              {showDetails && (
                <ul className="template-thumbnail__highlights">
                  {template.highlights.map((highlight) => (
                    <li key={highlight}>{highlight}</li>
                  ))}
                </ul>
              )}
            </button>
          );
        })}
      </div>
    );
  }

  function renderDashboard() {
    return (
      <div className="workspace-section">
        <div className="workspace-metrics">
          <article className="metric-card">
            <header>
              <span className="metric-label">Outstanding balance</span>
              <span className="metric-icon">💳</span>
            </header>
            <strong className="metric-value">{formatCurrency(outstandingTotal, draft.currency)}</strong>
            <p>{recentInvoices.length ? `${recentInvoices.length} invoices tracked` : 'No invoices yet'}</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">Paid this month</span>
              <span className="metric-icon">✅</span>
            </header>
            <strong className="metric-value">{formatCurrency(paidThisMonth, draft.currency)}</strong>
            <p>Auto-reconciled with client receipts</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">Average payment time</span>
              <span className="metric-icon">⏱️</span>
            </header>
            <strong className="metric-value">9.4 days</strong>
            <p>Down 2.1 days vs last month</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">Templates in use</span>
              <span className="metric-icon">🖌️</span>
            </header>
            <strong className="metric-value">{templateCatalog.length}</strong>
            <p>Switch templates from the gallery</p>
          </article>
        </div>

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Recent invoices</h2>
              <p>Monitor drafts, sent documents, and payments at a glance.</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
              Create invoice
            </button>
          </header>
          {loadingInvoices ? (
            <div className="empty-state">Loading invoices…</div>
          ) : recentInvoices.length ? (
            <div className="table">
              <div className="table__row table__row--head">
                <span>Client</span>
                <span>Status</span>
                <span>Issued</span>
                <span>Due</span>
                <span>Total</span>
              </div>
              {recentInvoices.map((invoice) => (
                <div key={invoice.id} className="table__row">
                  <span>
                    <strong>{invoice.clientName || 'Client'}</strong>
                    <small>{invoice.clientEmail || '—'}</small>
                  </span>
                  <span>
                    <span className={`status-pill status-pill--${invoice.status}`}>{statusLookup.get(invoice.status)}</span>
                  </span>
                  <span>{formatFriendlyDate(invoice.issueDate)}</span>
                  <span>{formatFriendlyDate(invoice.dueDate)}</span>
                  <span>{formatCurrency(invoice.total, invoice.currency)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">Save your first invoice to populate the dashboard.</div>
          )}
        </div>

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Template spotlight</h2>
              <p>Highlighting the most popular template with clients this week.</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('templates')}>
              Browse gallery
            </button>
          </header>
          <div className="template-spotlight">
            <div className="template-spotlight__preview" style={{ background: templateCatalog[0].accent }}>
              <span>{templateCatalog[0].name}</span>
            </div>
            <div className="template-spotlight__body">
              <strong>{templateCatalog[0].name}</strong>
              <p>{templateCatalog[0].description}</p>
              <ul>
                {templateCatalog[0].highlights.map((highlight) => (
                  <li key={highlight}>{highlight}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </div>
    );
  }


  function renderInvoices() {
    return (
      <div className="workspace-section">
        <section className="panel panel--stack">
          <header className="panel__header panel__header--stacked">
            <div>
              <h2>Invoice workspace</h2>
              <p>Toggle between editing your draft and reviewing the formatted preview.</p>
            </div>
            <div className="view-toggle" role="group" aria-label="Invoice workspace view">
              <button
                type="button"
                className={`view-toggle__button${invoiceView === 'edit' ? ' view-toggle__button--active' : ''}`}
                onClick={() => setInvoiceView('edit')}
                aria-pressed={invoiceView === 'edit'}
              >
                ✏️ Edit draft
              </button>
              <button
                type="button"
                className={`view-toggle__button${invoiceView === 'preview' ? ' view-toggle__button--active' : ''}`}
                onClick={() => setInvoiceView('preview')}
                aria-pressed={invoiceView === 'preview'}
              >
                👀 Preview
              </button>
            </div>
          </header>

          <div className="panel__section">
            <header className="panel__section-header">
              <div>
                <h3>Templates</h3>
                <p>Select a template thumbnail to style your invoice.</p>
              </div>
              <span className="badge">{templateCatalog.length} options</span>
            </header>
            {renderTemplateThumbnails()}
          </div>

          {invoiceView === 'edit' ? (
            <form className="form-grid form-grid--single" onSubmit={handleSave}>
              <div className="form-grid__group">
                <label htmlFor="businessName">Business name</label>
                <input
                  id="businessName"
                  type="text"
                  value={draft.businessName}
                  placeholder="Atlas Studio"
                  onChange={(event) => updateDraftField('businessName', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="businessAddress">Business address</label>
                <input
                  id="businessAddress"
                  type="text"
                  value={draft.businessAddress}
                  placeholder="88 Harbor Lane, Portland, OR"
                  onChange={(event) => updateDraftField('businessAddress', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="clientName">Client name</label>
                <input
                  id="clientName"
                  type="text"
                  value={draft.clientName}
                  placeholder="Northwind Co."
                  onChange={(event) => updateDraftField('clientName', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="clientEmail">Client email</label>
                <input
                  id="clientEmail"
                  type="email"
                  value={draft.clientEmail}
                  placeholder="client@email.com"
                  onChange={(event) => updateDraftField('clientEmail', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="issueDate">Issue date</label>
                <input
                  id="issueDate"
                  type="date"
                  value={draft.issueDate?.slice(0, 10) || ''}
                  onChange={(event) => updateDraftField('issueDate', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="dueDate">Due date</label>
                <input
                  id="dueDate"
                  type="date"
                  value={draft.dueDate?.slice(0, 10) || ''}
                  onChange={(event) => updateDraftField('dueDate', event.target.value)}
                />
              </div>
              <div className="form-grid__group">
                <label htmlFor="currency">Currency</label>
                <select
                  id="currency"
                  value={draft.currency}
                  onChange={(event) => updateDraftField('currency', event.target.value)}
                >
                  {currencyOptions.map((currency) => (
                    <option key={currency} value={currency}>
                      {currency}
                    </option>
                  ))}
                </select>
              </div>
              <div className="form-grid__group">
                <label htmlFor="status">Status</label>
                <select id="status" value={draft.status} onChange={(event) => updateDraftField('status', event.target.value as InvoiceStatus)}>
                  {statusOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
              <div className="form-grid__group form-grid__group--wide">
                <label htmlFor="notes">Notes</label>
                <textarea
                  id="notes"
                  value={draft.notes}
                  placeholder="Share payment instructions or a thank you."
                  rows={3}
                  onChange={(event) => updateDraftField('notes', event.target.value)}
                />
              </div>
              <div className="form-grid__group form-grid__group--wide">
                <label htmlFor="taxRate">Tax rate</label>
                <div className="input-with-addon">
                  <input
                    id="taxRate"
                    type="number"
                    value={draft.taxRate}
                    min="0"
                    step="0.1"
                    onChange={(event) => updateDraftField('taxRate', Number(event.target.value))}
                  />
                  <span className="input-addon">%</span>
                </div>
              </div>
              <div className="form-grid__group form-grid__group--wide">
                <header className="form-grid__header">
                  <h3>Line items</h3>
                  <button type="button" className="button button--ghost" onClick={addLine}>
                    Add line
                  </button>
                </header>
                <div className="line-items">
                  {draft.lines.map((line) => (
                    <div key={line.id} className="line-item">
                      <div className="line-item__description">
                        <label htmlFor={`description-${line.id}`}>Description</label>
                        <input
                          id={`description-${line.id}`}
                          type="text"
                          value={line.description}
                          placeholder="Service provided"
                          onChange={(event) => updateLine(line.id, 'description', event.target.value)}
                        />
                      </div>
                      <div>
                        <label htmlFor={`quantity-${line.id}`}>Qty</label>
                        <input
                          id={`quantity-${line.id}`}
                          type="number"
                          min="1"
                          value={line.quantity}
                          onChange={(event) => updateLine(line.id, 'quantity', event.target.value)}
                        />
                      </div>
                      <div>
                        <label htmlFor={`rate-${line.id}`}>Rate</label>
                        <input
                          id={`rate-${line.id}`}
                          type="number"
                          min="0"
                          step="0.01"
                          value={line.rate}
                          onChange={(event) => updateLine(line.id, 'rate', event.target.value)}
                        />
                      </div>
                      <button type="button" className="line-item__remove" onClick={() => removeLine(line.id)}>
                        Remove
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </form>
          ) : (
            <div className="preview" data-template={activeTemplate.id}>
              <div className="preview__header" style={{ background: activeTemplate.accent }}>
                <div className="preview__header-info">
                  <span className="preview__header-subtitle">{activeTemplate.description}</span>
                  <strong>{draft.businessName || 'Your business name'}</strong>
                  <span>{draft.businessAddress || 'Add your business address'}</span>
                </div>
                <div className="preview__badge">
                  <span>{statusLookup.get(draft.status)}</span>
                  <strong>{formatCurrency(totals.total, draft.currency)}</strong>
                </div>
              </div>

              <div className="preview__meta">
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '請求先 / Bill to' : 'Bill to'}</span>
                  <strong>{draft.clientName || 'Client name'}</strong>
                  <span>{draft.clientEmail || 'client@email.com'}</span>
                </div>
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '発行日 / Issued' : 'Issued'}</span>
                  <strong>{formatFriendlyDate(draft.issueDate)}</strong>
                </div>
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '支払期日 / Due' : 'Due'}</span>
                  <strong>{formatFriendlyDate(draft.dueDate)}</strong>
                </div>
              </div>

              {activeTemplate.id === 'emerald-ledger' && (
                <div className="preview__summary-card">
                  <header>
                    <span>Payment summary</span>
                    <strong>{formatCurrency(totals.total, draft.currency)}</strong>
                  </header>
                  <ul>
                    <li>
                      <span>Subtotal</span>
                      <strong>{formatCurrency(totals.subtotal, draft.currency)}</strong>
                    </li>
                    <li>
                      <span>Tax</span>
                      <strong>{formatCurrency(totals.taxAmount, draft.currency)}</strong>
                    </li>
                    <li>
                      <span>Status</span>
                      <strong>{statusLookup.get(draft.status)}</strong>
                    </li>
                  </ul>
                </div>
              )}

              <div className="preview__table">
                <div className="preview__table-row preview__table-row--head">
                  <span>{activeTemplate.id === 'seikyu' ? '品目 / Item' : 'Description'}</span>
                  <span>{activeTemplate.id === 'seikyu' ? '数量 / Qty' : 'Qty'}</span>
                  <span>{activeTemplate.id === 'seikyu' ? '単価 / Rate' : 'Rate'}</span>
                  <span>{activeTemplate.id === 'seikyu' ? '金額 / Total' : 'Total'}</span>
                </div>
                {draft.lines.map((line) => (
                  <div key={line.id} className="preview__table-row">
                    <span>{line.description || (activeTemplate.id === 'seikyu' ? 'サービス' : 'Line description')}</span>
                    <span>{line.quantity}</span>
                    <span>{formatCurrency(line.rate, draft.currency)}</span>
                    <span>{formatCurrency(line.quantity * line.rate, draft.currency)}</span>
                  </div>
                ))}
              </div>

              <div className="preview__totals">
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '小計 / Subtotal' : 'Subtotal'}</span>
                  <strong>{formatCurrency(totals.subtotal, draft.currency)}</strong>
                </div>
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '税額 / Tax' : 'Tax'}</span>
                  <strong>{formatCurrency(totals.taxAmount, draft.currency)}</strong>
                </div>
                <div>
                  <span>{activeTemplate.id === 'seikyu' ? '合計 / Total' : 'Total'}</span>
                  <strong>{formatCurrency(totals.total, draft.currency)}</strong>
                </div>
              </div>

              {activeTemplate.id === 'seikyu' && (
                <div className="preview__hanko">
                  <span>印</span>
                  <small>Authorised seal</small>
                </div>
              )}

              <div className="preview__notes">
                <strong>{activeTemplate.id === 'seikyu' ? '備考 / Notes' : 'Notes'}</strong>
                <p>{draft.notes || 'Add payment instructions or a thank you message.'}</p>
                {activeTemplate.id === 'seikyu' && (
                  <small>お支払い期限までにお振り込みをお願いいたします。</small>
                )}
              </div>
            </div>
          )}
        </section>
      </div>
    );
  }

  function renderTemplateGallery() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Template gallery</h2>
              <p>Explore each template's layout before applying it to your invoice.</p>
            </div>
            <span className="badge">{templateCatalog.length} options</span>
          </header>
          {renderTemplateThumbnails({ showDetails: true })}
        </div>
      </div>
    );
  }

  function renderClients() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Client insights</h2>
              <p>Outstanding balances and recent invoice activity per client.</p>
            </div>
            <button type="button" className="button button--ghost">
              Add client
            </button>
          </header>
          {clientSummaries.length ? (
            <div className="cards-grid">
              {clientSummaries.map((client) => (
                <article key={client.key} className="client-card">
                  <header>
                    <div>
                      <strong>{client.name}</strong>
                      {client.email && <span>{client.email}</span>}
                    </div>
                    <span className={`status-pill status-pill--${client.status}`}>
                      {statusLookup.get(client.status)}
                    </span>
                  </header>
                  <dl>
                    <div>
                      <dt>Outstanding</dt>
                      <dd>{formatCurrency(client.outstanding, client.currency || draft.currency)}</dd>
                    </div>
                    <div>
                      <dt>Invoices</dt>
                      <dd>{client.invoices}</dd>
                    </div>
                    <div>
                      <dt>Last invoice</dt>
                      <dd>{formatFriendlyDate(client.lastInvoice)}</dd>
                    </div>
                  </dl>
                </article>
              ))}
            </div>
          ) : (
            <div className="empty-state">Save an invoice to build the client directory.</div>
          )}
        </div>
      </div>
    );
  }

  function renderActivity() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Activity timeline</h2>
              <p>Review invoice saves, reminders, and payments from newest to oldest.</p>
            </div>
            <Link className="button button--ghost" href="/admin/console" prefetch={false}>
              View admin console
            </Link>
          </header>
          {activityFeed.length ? (
            <ul className="timeline">
              {activityFeed.map((item) => (
                <li key={item.id}>
                  <div className="timeline__marker" />
                  <div className="timeline__body">
                    <div className="timeline__title">
                      <strong>{item.title}</strong>
                      <span className={`status-pill status-pill--${item.status}`}>{statusLookup.get(item.status)}</span>
                    </div>
                    <p>{item.amount}</p>
                    <small>{formatFriendlyDate(item.timestamp)}</small>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state">Activity will appear once invoices are saved.</div>
          )}
        </div>
      </div>
    );
  }

  function renderSettings() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>Workspace settings</h2>
              <p>Default information used across every new invoice.</p>
            </div>
          </header>
          <dl className="settings-grid">
            <div>
              <dt>Business name</dt>
              <dd>{draft.businessName || 'Atlas Studio'}</dd>
            </div>
            <div>
              <dt>Business address</dt>
              <dd>{draft.businessAddress || '88 Harbor Lane, Portland, OR'}</dd>
            </div>
            <div>
              <dt>Default currency</dt>
              <dd>{draft.currency}</dd>
            </div>
            <div>
              <dt>Tax rate</dt>
              <dd>{(draft.taxRate * 100).toFixed(1)}%</dd>
            </div>
            <div>
              <dt>Reminder emails</dt>
              <dd>Enabled — 3 days before due date</dd>
            </div>
            <div>
              <dt>Template</dt>
              <dd>{templateCatalog.find((template) => template.id === selectedTemplate)?.name ?? 'Wave Blue'}</dd>
            </div>
          </dl>
          <div className="settings-actions">
            <button type="button" className="button button--primary">
              Update profile
            </button>
            <button type="button" className="button button--ghost">
              Manage automations
            </button>
          </div>
        </div>
      </div>
    );
  }

  function renderActiveSection() {
    switch (activeSection) {
      case 'dashboard':
        return renderDashboard();
      case 'invoices':
        return renderInvoices();
      case 'templates':
        return renderTemplateGallery();
      case 'clients':
        return renderClients();
      case 'activity':
        return renderActivity();
      case 'settings':
        return renderSettings();
      default:
        return null;
    }
  }

  const activeMeta = sections.find((section) => section.id === activeSection);

  return (
    <div className="workspace-shell workspace-shell--topnav">
      <div className="workspace-topbar">
        <div className="workspace-shell__brand">
          <img
            src="/easy-invoice-gm7-logo.svg"
            alt="Easy Invoice GM7"
            className="workspace-shell__logo"
            width={44}
            height={44}
          />
          <div>
            <strong>Easy Invoice GM7</strong>
            <span>Billing workspace</span>
          </div>
        </div>
        <nav className="workspace-topbar__nav" aria-label="Workspace sections">
          {sections.map((section) => (
            <button
              key={section.id}
              type="button"
              className={`workspace-topbar__nav-item${
                activeSection === section.id ? ' workspace-topbar__nav-item--active' : ''
              }`}
              onClick={() => setActiveSection(section.id)}
              title={section.description}
              aria-pressed={activeSection === section.id}
            >
              <span className="workspace-topbar__nav-icon" aria-hidden="true">
                {section.icon}
              </span>
              <span className="workspace-topbar__nav-label">{section.label}</span>
            </button>
          ))}
        </nav>
      </div>

      <div className="workspace-shell__main">
        <header className="workspace-shell__header">
          <div>
            <span>{activeMeta?.icon}</span>
            <div>
              <h1>{activeMeta?.label}</h1>
              <p>{activeMeta?.description}</p>
              {!firebaseConfigured && (
                <span className="workspace-shell__hint">
                  Connected to demo data until Firebase credentials are added.
                </span>
              )}
            </div>
          </div>
          {activeSection !== 'invoices' ? (
            <div className="workspace-shell__actions">
              <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
                Create invoice
              </button>
              <button type="button" className="button button--primary" onClick={() => setActiveSection('dashboard')}>
                View dashboard
              </button>
            </div>
          ) : (
            <div className="workspace-shell__actions">
              <button type="button" className="button button--ghost" onClick={handleDownload}>
                Download preview
              </button>
              <button type="button" className="button button--primary" onClick={() => handleSave()} disabled={saveState === 'saving'}>
                {saveState === 'saving' ? 'Saving…' : 'Save invoice'}
              </button>
            </div>
          )}
        </header>

        {alertMessage && (
          <div
            className={`workspace-shell__alert${saveState !== 'idle' ? ` workspace-shell__alert--${saveState}` : ''}`}
            role="status"
          >
            {alertMessage}
          </div>
        )}

        {renderActiveSection()}
      </div>
    </div>
  );
}
