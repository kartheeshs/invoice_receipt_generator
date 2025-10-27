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

  function renderInvoiceEditor() {
    return (
      <div className="workspace-section workspace-section--two-column">
        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>Invoice details</h2>
              <p>Fill out the draft form and keep an eye on the preview.</p>
            </div>
            <span className="status-pill status-pill--outline">{statusLookup.get(draft.status)}</span>
          </header>
          <form className="form-grid" onSubmit={handleSave}>
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
                placeholder="billing@client.com"
                onChange={(event) => updateDraftField('clientEmail', event.target.value)}
              />
            </div>
            <div className="form-grid__group">
              <label htmlFor="issueDate">Issue date</label>
              <input
                id="issueDate"
                type="date"
                value={draft.issueDate}
                onChange={(event) => updateDraftField('issueDate', event.target.value)}
              />
            </div>
            <div className="form-grid__group">
              <label htmlFor="dueDate">Due date</label>
              <input
                id="dueDate"
                type="date"
                value={draft.dueDate}
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
              <label htmlFor="taxRate">Tax rate (%)</label>
              <input
                id="taxRate"
                type="number"
                min={0}
                step={0.1}
                value={(draft.taxRate * 100).toFixed(1)}
                onChange={(event) => updateDraftField('taxRate', Number(event.target.value) / 100)}
              />
            </div>
            <div className="form-grid__group">
              <label htmlFor="status">Status</label>
              <select
                id="status"
                value={draft.status}
                onChange={(event) => updateDraftField('status', event.target.value as InvoiceStatus)}
              >
                {statusOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-grid__group form-grid__group--full">
              <label htmlFor="notes">Notes</label>
              <textarea
                id="notes"
                rows={3}
                value={draft.notes}
                placeholder="Add payment instructions or a thank-you note."
                onChange={(event) => updateDraftField('notes', event.target.value)}
              />
            </div>

            <div className="line-items">
              <div className="line-items__header">
                <h3>Line items</h3>
                <button type="button" className="button button--ghost" onClick={addLine}>
                  Add line
                </button>
              </div>
              <div className="line-items__table">
                <div className="line-items__row line-items__row--head">
                  <span>Description</span>
                  <span>Qty</span>
                  <span>Rate</span>
                  <span>Total</span>
                  <span />
                </div>
                {draft.lines.map((line) => (
                  <div key={line.id} className="line-items__row">
                    <input
                      type="text"
                      value={line.description}
                      placeholder="Design sprint"
                      onChange={(event) => updateLine(line.id, 'description', event.target.value)}
                    />
                    <input
                      type="number"
                      min={0}
                      step={1}
                      value={line.quantity}
                      onChange={(event) => updateLine(line.id, 'quantity', event.target.value)}
                    />
                    <input
                      type="number"
                      min={0}
                      step={0.01}
                      value={line.rate}
                      onChange={(event) => updateLine(line.id, 'rate', event.target.value)}
                    />
                    <span>{formatCurrency(line.quantity * line.rate, draft.currency)}</span>
                    <button type="button" onClick={() => removeLine(line.id)} aria-label="Remove line item">
                      ×
                    </button>
                  </div>
                ))}
              </div>
            </div>

            <footer className="form-grid__footer">
              <div>
                <span>Subtotal</span>
                <strong>{formatCurrency(totals.subtotal, draft.currency)}</strong>
              </div>
              <div>
                <span>Tax</span>
                <strong>{formatCurrency(totals.taxAmount, draft.currency)}</strong>
              </div>
              <div>
                <span>Total</span>
                <strong>{formatCurrency(totals.total, draft.currency)}</strong>
              </div>
              <div className="form-grid__actions">
                <button type="submit" className="button button--primary" disabled={saveState === 'saving'}>
                  {saveState === 'saving' ? 'Saving…' : 'Save invoice'}
                </button>
                <button type="button" className="button button--ghost" onClick={handleDownload}>
                  Download preview
                </button>
              </div>
            </footer>
          </form>
        </section>

        <aside className="panel preview-panel">
          <header className="panel__header">
            <div>
              <h2>Live preview</h2>
              <p>{templateCatalog.find((template) => template.id === selectedTemplate)?.name ?? 'Invoice preview'}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('templates')}>
              Change template
            </button>
          </header>
          <div className="preview">
            <div className="preview__header" style={{ background: templateCatalog.find((template) => template.id === selectedTemplate)?.accentSoft }}>
              <div>
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
                <span>Bill to</span>
                <strong>{draft.clientName || 'Client name'}</strong>
                <span>{draft.clientEmail || 'client@email.com'}</span>
              </div>
              <div>
                <span>Issued</span>
                <strong>{formatFriendlyDate(draft.issueDate)}</strong>
              </div>
              <div>
                <span>Due</span>
                <strong>{formatFriendlyDate(draft.dueDate)}</strong>
              </div>
            </div>
            <div className="preview__table">
              <div className="preview__table-row preview__table-row--head">
                <span>Description</span>
                <span>Qty</span>
                <span>Rate</span>
                <span>Total</span>
              </div>
              {draft.lines.map((line) => (
                <div key={line.id} className="preview__table-row">
                  <span>{line.description || 'Line description'}</span>
                  <span>{line.quantity}</span>
                  <span>{formatCurrency(line.rate, draft.currency)}</span>
                  <span>{formatCurrency(line.quantity * line.rate, draft.currency)}</span>
                </div>
              ))}
            </div>
            <div className="preview__totals">
              <div>
                <span>Subtotal</span>
                <strong>{formatCurrency(totals.subtotal, draft.currency)}</strong>
              </div>
              <div>
                <span>Tax</span>
                <strong>{formatCurrency(totals.taxAmount, draft.currency)}</strong>
              </div>
              <div>
                <span>Total</span>
                <strong>{formatCurrency(totals.total, draft.currency)}</strong>
              </div>
            </div>
            <div className="preview__notes">
              <strong>Notes</strong>
              <p>{draft.notes || 'Add payment instructions or a thank you message.'}</p>
            </div>
          </div>
        </aside>
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
              <p>Select a template to update the preview instantly.</p>
            </div>
            <span className="badge">{templateCatalog.length} options</span>
          </header>
          <div className="template-grid">
            {templateCatalog.map((template) => {
              const isActive = template.id === selectedTemplate;
              return (
                <button
                  type="button"
                  key={template.id}
                  onClick={() => setSelectedTemplate(template.id)}
                  className={`template-card${isActive ? ' template-card--active' : ''}`}
                >
                  <div className="template-card__preview" style={{ background: template.accent }}>
                    <span>{template.name}</span>
                  </div>
                  <div className="template-card__body">
                    <strong>{template.name}</strong>
                    <p>{template.description}</p>
                    <ul>
                      {template.highlights.map((highlight) => (
                        <li key={highlight}>{highlight}</li>
                      ))}
                    </ul>
                    <small>{template.bestFor}</small>
                  </div>
                </button>
              );
            })}
          </div>
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
        return renderInvoiceEditor();
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
        <div className="workspace-topbar__primary">
          <div className="workspace-shell__brand">
            <span className="workspace-shell__logo">IA</span>
            <div>
              <strong>Invoice Atlas</strong>
              <span>Browser workspace</span>
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
              >
                <span className="workspace-topbar__nav-icon" aria-hidden="true">
                  {section.icon}
                </span>
                <div>
                  <strong>{section.label}</strong>
                  <small>{section.description}</small>
                </div>
              </button>
            ))}
          </nav>
        </div>
        <div className="workspace-topbar__meta">
          <div className="workspace-shell__summary">
            <strong>Workspace snapshot</strong>
            <ul>
              <li>
                <span>Outstanding</span>
                <strong>{formatCurrency(outstandingTotal, draft.currency)}</strong>
              </li>
              <li>
                <span>Invoices tracked</span>
                <strong>{recentInvoices.length}</strong>
              </li>
              <li>
                <span>Selected template</span>
                <strong>{templateCatalog.find((template) => template.id === selectedTemplate)?.name ?? 'Wave Blue'}</strong>
              </li>
            </ul>
          </div>
          {!firebaseConfigured && (
            <p className="workspace-topbar__offline">Connect Firebase credentials to persist data for your workspace.</p>
          )}
          <p className="workspace-topbar__support">
            Need help? Visit the{' '}
            <Link href="/privacy-policy" prefetch={false}>
              help center
            </Link>{' '}
            or email support.
          </p>
        </div>
      </div>

      <div className="workspace-shell__main">
        <header className="workspace-shell__header">
          <div>
            <span>{activeMeta?.icon}</span>
            <div>
              <h1>{activeMeta?.label}</h1>
              <p>{activeMeta?.description}</p>
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
