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
          if (invoices.length) {
            setRecentInvoices(invoices);
          } else {
            setRecentInvoices(sampleInvoices);
          }
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

  const totals = useMemo(() => calculateTotals(draft.lines, draft.taxRate), [draft.lines, draft.taxRate]);

  function updateDraftField<K extends keyof InvoiceDraft>(field: K, value: InvoiceDraft[K]) {
    setDraft((prev) => ({ ...prev, [field]: value }));
  }

  function updateLine(id: string, field: keyof InvoiceLine, value: string) {
    setDraft((prev) => ({
      ...prev,
      lines: prev.lines.map((line) => (line.id === id ? ensureLine(line, field, value) : line)),
    }));
  }

  function addLine() {
    setDraft((prev) => ({ ...prev, lines: [...prev.lines, createEmptyLine()] }));
  }

  function removeLine(id: string) {
    setDraft((prev) => {
      const nextLines = prev.lines.filter((line) => line.id !== id);
      return {
        ...prev,
        lines: nextLines.length ? nextLines : [createEmptyLine()],
      };
    });
  }

  async function handleSave(event?: FormEvent) {
    event?.preventDefault();
    const preparedLines = cleanLines(draft.lines);
    if (!preparedLines.length) {
      setAlertMessage('Add at least one line item before saving.');
      setSaveState('error');
      return;
    }

    setSaveState('saving');
    setAlertMessage('');
    try {
      let record: InvoiceRecord;
      if (firebaseConfigured) {
        record = await saveInvoice({ draft: { ...draft, lines: preparedLines } });
      } else {
        const fallbackTotals = calculateTotals(preparedLines, draft.taxRate);
        record = {
          id: `local-${Date.now()}`,
          ...draft,
          lines: preparedLines,
          subtotal: fallbackTotals.subtotal,
          taxAmount: fallbackTotals.taxAmount,
          total: fallbackTotals.total,
          createdAt: new Date().toISOString(),
        };
      }

      setRecentInvoices((current) => [record, ...current].slice(0, 8));
      setDraft((prev) => ({
        ...createEmptyDraft(),
        currency: prev.currency,
        businessName: prev.businessName,
        businessAddress: prev.businessAddress,
      }));
      setSaveState('success');
      setAlertMessage('Invoice saved successfully.');
    } catch (error) {
      console.error(error);
      setSaveState('error');
      setAlertMessage(error instanceof Error ? error.message : 'Failed to save invoice.');
    }
  }

  function handleDownload() {
    const printableLines = cleanLines(draft.lines);
    const hasLines = printableLines.length > 0;
    const lines = hasLines ? printableLines : draft.lines;
    const computedTotals = calculateTotals(lines, draft.taxRate);
    const title = draft.clientName ? `Invoice-${draft.clientName.replace(/\s+/g, '-')}` : 'Invoice-draft';

    const popup = window.open('', '_blank', 'width=900,height=700');
    if (!popup) {
      setAlertMessage('Allow pop-ups to download the PDF preview.');
      return;
    }

    popup.document.write(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>${title}</title>
  <style>
    body { font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 2.5rem; color: #111827; }
    h1 { font-size: 1.8rem; margin-bottom: 0.5rem; }
    .meta { display: flex; justify-content: space-between; gap: 2rem; margin-bottom: 2rem; }
    .meta section { flex: 1; }
    table { width: 100%; border-collapse: collapse; margin-top: 1.5rem; }
    th, td { text-align: left; padding: 0.75rem 0.6rem; border-bottom: 1px solid #E5E7EB; font-size: 0.95rem; }
    th { background: #F3F4F6; font-weight: 600; }
    tfoot td { border-bottom: none; font-weight: 600; }
    .totals { margin-top: 1.5rem; width: 340px; margin-left: auto; }
    .totals div { display: flex; justify-content: space-between; padding: 0.4rem 0; }
  </style>
</head>
<body>
  <header>
    <h1>Invoice</h1>
    <div class="meta">
      <section>
        <strong>From</strong>
        <p>${draft.businessName || 'Your business'}</p>
        <p>${draft.businessAddress || ''}</p>
      </section>
      <section>
        <strong>Bill to</strong>
        <p>${draft.clientName || ''}</p>
        <p>${draft.clientEmail || ''}</p>
      </section>
      <section>
        <strong>Dates</strong>
        <p>Issued: ${formatFriendlyDate(draft.issueDate)}</p>
        <p>Due: ${formatFriendlyDate(draft.dueDate)}</p>
      </section>
    </div>
  </header>
  <table>
    <thead>
      <tr>
        <th>Description</th>
        <th style="width: 100px;">Qty</th>
        <th style="width: 140px;">Rate</th>
        <th style="width: 160px;">Line total</th>
      </tr>
    </thead>
    <tbody>
      ${lines
        .map(
          (line) => `
        <tr>
          <td>${line.description || 'Line item'}</td>
          <td>${line.quantity}</td>
          <td>${formatCurrency(line.rate, draft.currency)}</td>
          <td>${formatCurrency(line.quantity * line.rate, draft.currency)}</td>
        </tr>`
        )
        .join('')}
    </tbody>
  </table>
  <div class="totals">
    <div><span>Subtotal</span><span>${formatCurrency(computedTotals.subtotal, draft.currency)}</span></div>
    <div><span>Tax (${(draft.taxRate * 100).toFixed(1)}%)</span><span>${formatCurrency(computedTotals.taxAmount, draft.currency)}</span></div>
    <div><span>Total</span><span>${formatCurrency(computedTotals.total, draft.currency)}</span></div>
  </div>
  <p style="margin-top: 1.5rem;">${draft.notes || ''}</p>
  <script>window.print();</script>
</body>
</html>`);
    popup.document.close();
  }

  return (
    <div className="workspace">
      <section className="workspace__intro">
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
          <aside>
            <div className="workspace__summary-card">
              <strong>Key metrics</strong>
              <ul>
                <li>
                  <span>Total outstanding</span>
                  <strong>
                    {formatCurrency(
                      recentInvoices.filter((invoice) => invoice.status !== 'paid').reduce((total, invoice) => total + invoice.total, 0),
                      draft.currency,
                    )}
                  </strong>
                </li>
                <li>
                  <span>Average payment time</span>
                  <strong>5.3 days</strong>
                </li>
                <li>
                  <span>Templates in use</span>
                  <strong>4</strong>
                </li>
              </ul>
            </div>
          </aside>
        </div>
      </section>

      <div className="container workspace__grid">
        <section className="editor-card">
          <header className="editor-card__header">
            <div>
              <h2>Create an invoice</h2>
              <p>Fill in the details, add line items, and track totals without leaving the browser.</p>
            </div>
            <div className="editor-card__status">
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
                <input
                  id="issueDate"
                  type="date"
                  value={draft.issueDate}
                  onChange={(event) => updateDraftField('issueDate', event.target.value)}
                />
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

        <aside className="preview-card">
          <div className="preview-card__header">
            <span className={`status-pill status-pill--${draft.status}`}>{statusOptions.find((option) => option.value === draft.status)?.label}</span>
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

      <section className="container workspace__recent" id="recent">
        <header className="workspace__recent-header">
          <div>
            <h2>Recent invoices</h2>
            <p>Monitor status changes, due dates, and totals at a glance.</p>
          </div>
          <Link href="/" className="button button--ghost">
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
                  <span className={`status-pill status-pill--${invoice.status}`}>{statusOptions.find((option) => option.value === invoice.status)?.label}</span>
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
    </div>
  );
}
