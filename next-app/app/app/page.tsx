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
  formatCurrency,
} from '../../lib/invoices';
import { firebaseConfigured, fetchRecentInvoices, saveInvoice } from '../../lib/firebase';
import { sampleInvoices } from '../../lib/sample-data';

const statusOptions: { value: InvoiceStatus; label: string; tone: 'neutral' | 'accent' | 'success' | 'warning' }[] = [
  { value: 'draft', label: 'Draft', tone: 'neutral' },
  { value: 'sent', label: 'Sent', tone: 'accent' },
  { value: 'paid', label: 'Paid', tone: 'success' },
  { value: 'overdue', label: 'Overdue', tone: 'warning' },
];

const currencyOptions = ['USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY', 'SGD'];

const navItems: { href: string; label: string; hint: string }[] = [
  { href: '#dashboard', label: 'Dashboard', hint: 'Overview & health' },
  { href: '#invoice-editor', label: 'Invoices', hint: 'Compose & send billing' },
  { href: '#recent', label: 'Activity', hint: 'Track recent updates' },
  { href: '#templates', label: 'Templates', hint: 'Switch visual styles' },
  { href: '#clients', label: 'Clients', hint: 'Customer history' },
  { href: '#settings', label: 'Settings', hint: 'Business profile' },
];

const templateGallery = [
  {
    id: 'wave-blue',
    name: 'Wave Blue',
    description: 'Rounded corners and a flowing accent for creative studios.',
    accent: 'linear-gradient(135deg, rgba(37,99,235,0.9), rgba(129,140,248,0.9))',
  },
  {
    id: 'minimal-slate',
    name: 'Minimal Slate',
    description: 'Crisp typography and generous whitespace for consultancies.',
    accent: 'linear-gradient(135deg, rgba(15,23,42,0.95), rgba(148,163,184,0.85))',
  },
  {
    id: 'sunset',
    name: 'Sunset Gradient',
    description: 'Warm gradient headers ideal for boutique agencies.',
    accent: 'linear-gradient(135deg, #f97316, #fb7185)',
  },
];

type ClientSummary = {
  key: string;
  name: string;
  email: string;
  invoices: number;
  outstanding: number;
  lastInvoice?: string;
  status: InvoiceStatus;
  currency: string;
};

function formatFriendlyDate(value: string): string {
  if (!value) return '';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
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
  const [draft, setDraft] = useState<InvoiceDraft>(() => createEmptyDraft());
  const [recentInvoices, setRecentInvoices] = useState<InvoiceRecord[]>([]);
  const [loadingInvoices, setLoadingInvoices] = useState(true);
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  const [alertMessage, setAlertMessage] = useState<string>('');

  useEffect(() => {
    let active = true;

    async function load() {
      try {
        if (firebaseConfigured) {
          const invoices = await fetchRecentInvoices(8);
          if (!active) return;
          setRecentInvoices(invoices.length ? invoices : sampleInvoices);
        } else if (active) {
          setRecentInvoices(sampleInvoices);
        }
      } catch (error) {
        if (!active) return;
        console.error(error);
        setAlertMessage('Unable to reach Firestore. Showing sample invoices instead.');
        setRecentInvoices(sampleInvoices);
      } finally {
        if (active) {
          setLoadingInvoices(false);
        }
      }
    }

    load();

    return () => {
      active = false;
    };
  }, []);

  const statusLookup = useMemo(() => new Map(statusOptions.map((option) => [option.value, option])), []);

  const totals = useMemo(() => calculateTotals(draft.lines, draft.taxRate), [draft.lines, draft.taxRate]);

  const outstandingTotal = useMemo(
    () =>
      recentInvoices.reduce((sum, invoice) => {
        return invoice.status === 'paid' ? sum : sum + invoice.total;
      }, 0),
    [recentInvoices],
  );

  const clientSummaries = useMemo(() => {
    const summaries = new Map<string, ClientSummary>();

    for (const invoice of recentInvoices) {
      const key = invoice.clientEmail || invoice.clientName || invoice.id;
      const outstanding = invoice.status === 'paid' ? 0 : invoice.total;
      const previous = summaries.get(key);
      const candidateDate = invoice.issueDate ? new Date(invoice.issueDate) : undefined;

      if (previous) {
        const previousDate = previous.lastInvoice ? new Date(previous.lastInvoice) : undefined;
        const useCandidate = candidateDate && (!previousDate || candidateDate > previousDate);

        summaries.set(key, {
          ...previous,
          invoices: previous.invoices + 1,
          outstanding: previous.outstanding + outstanding,
          lastInvoice: useCandidate ? invoice.issueDate : previous.lastInvoice,
          status: useCandidate ? invoice.status : previous.status,
          currency: invoice.currency || previous.currency,
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

        setRecentInvoices((prev) => [offlineRecord, ...prev].slice(0, 8));
        setAlertMessage('Firebase is not configured. Stored invoice locally for this session.');
        setSaveState('success');
        setLoadingInvoices(false);
        return;
      }

      const saved = await saveInvoice({ draft: preparedDraft });
      setRecentInvoices((prev) => {
        const filtered = prev.filter((invoice) => invoice.id !== saved.id);
        return [saved, ...filtered].slice(0, 8);
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

  return (
    <div className="workspace">
      <section className="workspace__intro" id="dashboard">
        <div className="container workspace__intro-grid">
          <div>
            <span className="badge">Web workspace</span>
            <h1>Craft invoices, send them, and track the follow-up.</h1>
            <p>
              Build professional invoices directly in the browser. Every edit updates the preview instantly and can be saved to
              Firebase for your team.
            </p>
            <div className="workspace__cta">
              <button type="button" className="button button--primary" onClick={() => handleSave()} disabled={saveState === 'saving'}>
                {saveState === 'saving' ? 'Saving…' : 'Save invoice'}
              </button>
              <button type="button" className="button button--ghost" onClick={handleDownload}>
                Download PDF preview
              </button>
            </div>
            {!firebaseConfigured && (
              <p className="workspace__notice">
                Connect Firebase credentials to persist data. Until then, changes stay local and sample invoices appear below.
              </p>
            )}
            {alertMessage && (
              <div className={`workspace__alert workspace__alert--${saveState}`} role="status">
                {alertMessage}
              </div>
            )}
          </div>
        </div>
      </section>

      <div className="workspace__layout">
        <div className="container workspace__layout-inner">
          <aside className="workspace__sidebar" aria-label="Workspace navigation">
            <div className="workspace__sidebar-header">
              <h2>Workspace menu</h2>
              <p>Jump between dashboards, invoice tools, and client records in one hub.</p>
            </div>
            <nav className="workspace__nav">
              {navItems.map((item) => (
                <Link key={item.href} href={item.href} className={`workspace__nav-item${item.href === '#dashboard' ? ' workspace__nav-item--active' : ''}`} prefetch={false}>
                  <span>{item.label}</span>
                  <small>{item.hint}</small>
                </Link>
              ))}
            </nav>
            <div className="workspace__summary-card">
              <strong>Billing health</strong>
              <ul>
                <li>
                  <span>Total outstanding</span>
                  <strong>{formatCurrency(outstandingTotal, draft.currency)}</strong>
                </li>
                <li>
                  <span>Saved invoices</span>
                  <strong>{recentInvoices.length}</strong>
                </li>
                <li>
                  <span>Reminder emails</span>
                  <strong>Enabled</strong>
                </li>
              </ul>
            </div>
            <div className="workspace__sidebar-footer">
              <p>
                Need a hand? Visit the <Link href="/privacy-policy" prefetch={false}>help center</Link> or chat with finance.
              </p>
            </div>
          </aside>

          <div className="workspace__content">
            <div className="workspace__grid" id="invoice-editor">
              <section className="editor-card">
                <header className="editor-card__header">
                  <div>
                    <h2>Create an invoice</h2>
                    <p>Fill in the details, add line items, and track totals without leaving the browser.</p>
                  </div>
                  <div className="editor-card__status">
                    <label htmlFor="status">Status</label>
                    <select id="status" value={draft.status} onChange={(event) => updateDraftField('status', event.target.value as InvoiceStatus)}>
                      {statusOptions.map((option) => (
                        <option key={option.value} value={option.value}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                  </div>
                </header>

                <form className="editor-card__form" onSubmit={handleSave}>
                  <div className="editor-card__grid">
                    <div>
                      <label htmlFor="businessName">Your business</label>
                      <input
                        id="businessName"
                        type="text"
                        value={draft.businessName}
                        placeholder="Atlas Studio"
                        onChange={(event) => updateDraftField('businessName', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="businessAddress">Business address</label>
                      <input
                        id="businessAddress"
                        type="text"
                        value={draft.businessAddress}
                        placeholder="88 Harbor Lane, Portland, OR"
                        onChange={(event) => updateDraftField('businessAddress', event.target.value)}
                      />
                    </div>
                  </div>

                  <div className="editor-card__grid">
                    <div>
                      <label htmlFor="clientName">Client name</label>
                      <input
                        id="clientName"
                        type="text"
                        value={draft.clientName}
                        placeholder="Northwind Co."
                        onChange={(event) => updateDraftField('clientName', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="clientEmail">Client email</label>
                      <input
                        id="clientEmail"
                        type="email"
                        value={draft.clientEmail}
                        placeholder="billing@client.com"
                        onChange={(event) => updateDraftField('clientEmail', event.target.value)}
                      />
                    </div>
                  </div>

                  <div className="editor-card__grid editor-card__grid--compact">
                    <div>
                      <label htmlFor="issueDate">Issue date</label>
                      <input id="issueDate" type="date" value={draft.issueDate} onChange={(event) => updateDraftField('issueDate', event.target.value)} />
                    </div>
                    <div>
                      <label htmlFor="dueDate">Due date</label>
                      <input id="dueDate" type="date" value={draft.dueDate} onChange={(event) => updateDraftField('dueDate', event.target.value)} />
                    </div>
                    <div>
                      <label htmlFor="currency">Currency</label>
                      <select id="currency" value={draft.currency} onChange={(event) => updateDraftField('currency', event.target.value)}>
                        {currencyOptions.map((currency) => (
                          <option key={currency} value={currency}>
                            {currency}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
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
                  </div>

                  <div className="line-items">
                    <div className="line-items__header">
                      <h3>Line items</h3>
                      <button type="button" onClick={addLine} className="button button--ghost">
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

                  <div>
                    <label htmlFor="notes">Notes</label>
                    <textarea
                      id="notes"
                      rows={3}
                      value={draft.notes}
                      placeholder="Add payment instructions or thank-you notes."
                      onChange={(event) => updateDraftField('notes', event.target.value)}
                    />
                  </div>

                  <footer className="editor-card__footer">
                    <div>
                      <strong>Subtotal:</strong>
                      <span>{formatCurrency(totals.subtotal, draft.currency)}</span>
                    </div>
                    <div>
                      <strong>Tax:</strong>
                      <span>{formatCurrency(totals.taxAmount, draft.currency)}</span>
                    </div>
                    <div>
                      <strong>Total:</strong>
                      <span>{formatCurrency(totals.total, draft.currency)}</span>
                    </div>
                    <button type="submit" className="button button--primary" disabled={saveState === 'saving'}>
                      {saveState === 'saving' ? 'Saving…' : 'Save invoice'}
                    </button>
                  </footer>
                </form>
              </section>

              <aside className="preview-card" id="invoice-preview">
                <div className="preview-card__header">
                  <span className={`status-pill status-pill--${draft.status}`}>{statusLookup.get(draft.status)?.label}</span>
                  <div>
                    <strong>{draft.businessName || 'Your business'}</strong>
                    <span>{draft.businessAddress}</span>
                  </div>
                </div>
                <div className="preview-card__meta">
                  <div>
                    <span>Bill to</span>
                    <strong>{draft.clientName || 'Client name'}</strong>
                    <span>{draft.clientEmail}</span>
                  </div>
                  <div>
                    <span>Issued</span>
                    <strong>{formatFriendlyDate(draft.issueDate)}</strong>
                    <span>Due {formatFriendlyDate(draft.dueDate)}</span>
                  </div>
                </div>
                <div className="preview-card__table">
                  <div className="preview-card__table-head">
                    <span>Description</span>
                    <span>Qty</span>
                    <span>Rate</span>
                    <span>Total</span>
                  </div>
                  <div className="preview-card__table-body">
                    {draft.lines.map((line) => (
                      <div key={line.id} className="preview-card__row">
                        <span>{line.description || 'Line item'}</span>
                        <span>{line.quantity}</span>
                        <span>{formatCurrency(line.rate, draft.currency)}</span>
                        <span>{formatCurrency(line.rate * line.quantity, draft.currency)}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <div className="preview-card__totals">
                  <div>
                    <span>Subtotal</span>
                    <strong>{formatCurrency(totals.subtotal, draft.currency)}</strong>
                  </div>
                  <div>
                    <span>Tax</span>
                    <strong>{formatCurrency(totals.taxAmount, draft.currency)}</strong>
                  </div>
                  <div>
                    <span>Total due</span>
                    <strong>{formatCurrency(totals.total, draft.currency)}</strong>
                  </div>
                </div>
                {draft.notes && <p className="preview-card__notes">{draft.notes}</p>}
                <div className="preview-card__actions">
                  <button type="button" className="button button--ghost" onClick={handleDownload}>
                    Download preview
                  </button>
                  <Link href="#recent" className="button button--primary">
                    View recent invoices
                  </Link>
                </div>
              </aside>
            </div>

            <section className="workspace__recent" id="recent">
              <header className="workspace__recent-header">
                <div>
                  <h2>Recent invoices</h2>
                  <p>Monitor status changes, due dates, and totals at a glance.</p>
                </div>
                <Link href="/" className="button button--ghost" prefetch={false}>
                  Back to marketing site
                </Link>
              </header>

              {loadingInvoices ? (
                <div className="recent-grid recent-grid--loading">
                  {Array.from({ length: 4 }).map((_, index) => (
                    <div key={index} className="recent-card recent-card--placeholder" />
                  ))}
                </div>
              ) : (
                <div className="recent-grid">
                  {recentInvoices.map((invoice) => (
                    <article key={invoice.id} className="recent-card">
                      <div className="recent-card__row">
                        <div>
                          <h3>{invoice.clientName}</h3>
                          <span>{invoice.clientEmail}</span>
                        </div>
                        <span className={`status-pill status-pill--${invoice.status}`}>
                          {statusLookup.get(invoice.status)?.label}
                        </span>
                      </div>
                      <div className="recent-card__row recent-card__row--meta">
                        <div>
                          <span>Issued</span>
                          <strong>{formatFriendlyDate(invoice.issueDate)}</strong>
                        </div>
                        <div>
                          <span>Due</span>
                          <strong>{formatFriendlyDate(invoice.dueDate)}</strong>
                        </div>
                        <div>
                          <span>Total</span>
                          <strong>{formatCurrency(invoice.total, invoice.currency)}</strong>
                        </div>
                      </div>
                      {invoice.notes && <p className="recent-card__notes">{invoice.notes}</p>}
                    </article>
                  ))}
                </div>
              )}
            </section>

            <section className="workspace__templates" id="templates">
              <header className="workspace__section-header">
                <div>
                  <h2>Template gallery</h2>
                  <p>Choose a visual language before sending the next invoice.</p>
                </div>
                <button type="button" className="button button--ghost">Browse all</button>
              </header>
              <div className="template-grid">
                {templateGallery.map((template) => (
                  <article key={template.id} className="template-card">
                    <div className="template-card__preview" style={{ background: template.accent }}>
                      <span>{template.name}</span>
                    </div>
                    <div className="template-card__body">
                      <strong>{template.name}</strong>
                      <p>{template.description}</p>
                      <button type="button" className="button button--primary">Use template</button>
                    </div>
                  </article>
                ))}
              </div>
            </section>

            <section className="workspace__clients" id="clients">
              <header className="workspace__section-header">
                <div>
                  <h2>Clients</h2>
                  <p>Track outstanding balances and follow-up dates for key accounts.</p>
                </div>
                <button type="button" className="button button--ghost">Add client</button>
              </header>
              {clientSummaries.length ? (
                <div className="clients-grid">
                  {clientSummaries.map((client) => (
                    <article key={client.key} className="client-card">
                      <div className="client-card__header">
                        <div>
                          <h3>{client.name}</h3>
                          {client.email && <span>{client.email}</span>}
                        </div>
                        <span className={`status-pill status-pill--${client.status}`}>
                          {statusLookup.get(client.status)?.label}
                        </span>
                      </div>
                      <div className="client-card__meta">
                        <div>
                          <span>Outstanding</span>
                          <strong>{formatCurrency(client.outstanding, client.currency || draft.currency)}</strong>
                        </div>
                        <div>
                          <span>Invoices</span>
                          <strong>{client.invoices}</strong>
                        </div>
                        <div>
                          <span>Last invoice</span>
                          <strong>{formatFriendlyDate(client.lastInvoice ?? '')}</strong>
                        </div>
                      </div>
                    </article>
                  ))}
                </div>
              ) : (
                <div className="workspace__empty">Save an invoice to start building your client directory.</div>
              )}
            </section>

            <section className="workspace__settings" id="settings">
              <header className="workspace__section-header">
                <div>
                  <h2>Workspace settings</h2>
                  <p>Update your default business profile, taxes, and automation rules.</p>
                </div>
              </header>
              <div className="settings-card">
                <dl className="settings-card__grid">
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
                    <dd>Enabled — send 3 days before due date</dd>
                  </div>
                  <div>
                    <dt>PDF language</dt>
                    <dd>English + Japanese</dd>
                  </div>
                </dl>
                <div className="settings-card__actions">
                  <button type="button" className="button button--primary">Update profile</button>
                  <button type="button" className="button button--ghost">Manage automations</button>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
