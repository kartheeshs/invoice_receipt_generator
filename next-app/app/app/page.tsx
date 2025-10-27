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
import { useTranslation } from '../../lib/i18n';
import { generateInvoicePdf } from '../../lib/pdf';
import { invoiceTemplates } from '../../lib/templates';
import { matchClients, type ClientDirectoryEntry } from '../../lib/clients';
import { clearSession, loadSession, SESSION_STORAGE_KEY, type StoredSession } from '../../lib/auth';
import LanguageSwitcher from '../components/language-switcher';

type SectionId = 'dashboard' | 'invoices' | 'templates' | 'clients' | 'activity' | 'settings';

type Section = {
  id: SectionId;
  label: string;
  description: string;
  icon: string;
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

const currencyOptions = ['USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY', 'SGD'];

function formatFriendlyDate(value?: string, locale?: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString(locale, {
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
  const [draft, setDraft] = useState<InvoiceDraft>(() => createEmptyDraft());
  const [recentInvoices, setRecentInvoices] = useState<InvoiceRecord[]>([]);
  const [loadingInvoices, setLoadingInvoices] = useState<boolean>(true);
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  const [alertMessage, setAlertMessage] = useState<string>('');
  const [invoiceView, setInvoiceView] = useState<'edit' | 'preview'>('edit');
  const [downloadingPdf, setDownloadingPdf] = useState<boolean>(false);
  const [session, setSession] = useState<StoredSession | null>(null);
  const [clientMatches, setClientMatches] = useState<ClientDirectoryEntry[]>([]);
  const [showClientMatches, setShowClientMatches] = useState<boolean>(false);
  const { language, locale, t } = useTranslation();
  const formId = 'invoice-editor-form';
  const isSignedIn = Boolean(session);
  const isAdmin = session?.role === 'admin';
  const sessionDisplayName = session?.displayName ?? session?.email ?? '';

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }
    setSession(loadSession());
    const handleStorage = (event: StorageEvent) => {
      if (event.key === SESSION_STORAGE_KEY) {
        setSession(loadSession());
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => {
      window.removeEventListener('storage', handleStorage);
    };
  }, []);

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
        setAlertMessage(t('workspace.alert.offline', 'Unable to reach Firestore. Displaying sample invoices.'));
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
  }, [t]);

  const totals = useMemo(() => calculateTotals(draft.lines, draft.taxRate), [draft.lines, draft.taxRate]);
  const localizedSections = useMemo(
    () =>
      sections.map((section) => ({
        ...section,
        label: t(`workspace.nav.${section.id}`, section.label),
        description: t(`workspace.section.${section.id}.description`, section.description),
      })),
    [t],
  );
  const localizedTemplates = useMemo(
    () =>
      invoiceTemplates.map((template) => ({
        ...template,
        name: t(`workspace.template.${template.id}.name`, template.name),
        description: t(`workspace.template.${template.id}.description`, template.description),
        bestFor: t(`workspace.template.${template.id}.bestFor`, template.bestFor),
        highlights: template.highlights.map((highlight, index) =>
          t(`workspace.template.${template.id}.highlights.${index}`, highlight),
        ),
      })),
    [t],
  );
  const localizedStatusOptions = useMemo(
    () => statusOptions.map((option) => ({ ...option, label: t(`workspace.status.${option.value}`, option.label) })),
    [t],
  );
  const statusLookup = useMemo(() => new Map(localizedStatusOptions.map((option) => [option.value, option.label])), [localizedStatusOptions]);
  const selectedTemplateId = draft.templateId || invoiceTemplates[0]?.id || 'villa-coastal';
  const activeTemplate = useMemo(
    () => localizedTemplates.find((template) => template.id === selectedTemplateId) ?? localizedTemplates[0],
    [localizedTemplates, selectedTemplateId],
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
      .map((invoice) => {
        const statusLabel =
          statusLookup.get(invoice.status) ?? t(`workspace.status.${invoice.status}`, invoice.status);
        const clientName = invoice.clientName || t('workspace.table.clientPlaceholder', 'Client');
        return {
          id: invoice.id,
          title: `${clientName} — ${statusLabel}`,
          amount: formatCurrency(invoice.total, invoice.currency, locale),
          timestamp: invoice.createdAt || invoice.issueDate,
          status: invoice.status,
        };
      })
      .sort((a, b) => {
        const dateA = new Date(a.timestamp ?? '').getTime();
        const dateB = new Date(b.timestamp ?? '').getTime();
        return dateB - dateA;
      });
  }, [locale, recentInvoices, statusLookup, t]);

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

  function handleSignOut() {
    clearSession();
    setSession(null);
    setAlertMessage(
      t('workspace.alert.signedOut', 'Signed out. Sign in again to sync invoices with Firebase.'),
    );
    setSaveState('success');
  }

  function handleClientNameChange(value: string) {
    updateDraftField('clientName', value);
    if (value.trim().length >= 2) {
      const matches = matchClients(value).slice(0, 5);
      setClientMatches(matches);
      setShowClientMatches(matches.length > 0);
    } else {
      setShowClientMatches(false);
    }
  }

  function applyClientMatch(entry: ClientDirectoryEntry) {
    setDraft((prev) => ({
      ...prev,
      clientName: entry.name,
      clientEmail: entry.email,
      clientAddress: entry.address,
    }));
    setClientMatches([]);
    setShowClientMatches(false);
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
      clientAddress: draft.clientAddress.trim(),
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
        setAlertMessage(t('workspace.alert.offlineStored', 'Firebase is not configured. Stored invoice locally for this session.'));
        setSaveState('success');
        setLoadingInvoices(false);
        return;
      }

      const saved = await saveInvoice({ draft: preparedDraft });
      setRecentInvoices((prev) => {
        const filtered = prev.filter((invoice) => invoice.id !== saved.id);
        return [saved, ...filtered].slice(0, 12);
      });
      setAlertMessage(t('workspace.alert.success', 'Invoice saved to Firestore.'));
      setSaveState('success');
    } catch (error) {
      console.error(error);
      setAlertMessage(error instanceof Error ? error.message : t('workspace.alert.error', 'Unable to save invoice.'));
      setSaveState('error');
    }
  }

  async function handleDownload() {
    if (typeof window === 'undefined') {
      console.warn('Download is only available in the browser.');
      return;
    }

    try {
      setDownloadingPdf(true);
      const cleanedLines = cleanLines(draft.lines);
      const pdfDraft: InvoiceDraft = { ...draft, lines: cleanedLines.length ? cleanedLines : draft.lines };
      const pdfTotals = calculateTotals(pdfDraft.lines, pdfDraft.taxRate);
      const pdfLabel = (key: string, fallback: string) => t(key, fallback);
      const statusValue = statusLookup.get(draft.status) ?? draft.status;
      const pdfLabels = {
        invoiceTitle: pdfLabel('workspace.pdf.invoiceTitle', 'Invoice'),
        billTo: pdfLabel('workspace.pdf.billTo', 'Bill to'),
        issueDate: pdfLabel('workspace.pdf.issueDate', 'Issue date'),
        dueDate: pdfLabel('workspace.pdf.dueDate', 'Due date'),
        statusLabel: pdfLabel('workspace.pdf.status', 'Status'),
        statusValue,
        currency: pdfLabel('workspace.pdf.currency', 'Currency'),
        description: pdfLabel('workspace.pdf.description', 'Description'),
        quantity: pdfLabel('workspace.pdf.quantity', 'Qty'),
        rate: pdfLabel('workspace.pdf.rate', 'Rate'),
        amount: pdfLabel('workspace.pdf.amount', 'Amount'),
        subtotal: pdfLabel('workspace.pdf.subtotal', 'Subtotal'),
        tax: pdfLabel('workspace.pdf.tax', 'Tax'),
        total: pdfLabel('workspace.pdf.total', 'Total'),
        notes: pdfLabel('workspace.pdf.notes', 'Notes'),
      };

      const blob = generateInvoicePdf({
        draft: pdfDraft,
        totals: pdfTotals,
        locale,
        currency: draft.currency,
        labels: pdfLabels,
        templateId: selectedTemplateId,
      });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      const safeClient = pdfDraft.clientName.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'invoice';
      link.href = url;
      link.download = `${safeClient}-${pdfDraft.issueDate || 'draft'}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      setAlertMessage(t('workspace.alert.downloaded', 'Invoice PDF downloaded.'));
      setSaveState('success');
    } catch (error) {
      console.error(error);
      setAlertMessage(t('workspace.alert.error', 'Unable to save invoice.'));
      setSaveState('error');
    } finally {
      setDownloadingPdf(false);
    }
  }

  function handleSelectTemplate(templateId: string) {
    setDraft((prev) => ({ ...prev, templateId }));
  }

  function renderTemplateThumbnails({ showDetails = false }: { showDetails?: boolean } = {}) {
    return (
      <div className={`template-thumbnail-grid${showDetails ? ' template-thumbnail-grid--detailed' : ''}`}>
        {localizedTemplates.map((template) => {
          const isActive = template.id === selectedTemplateId;
          const primaryHighlight = template.highlights[0] ?? template.description;
          return (
            <button
              key={template.id}
              type="button"
              onClick={() => handleSelectTemplate(template.id)}
              className={`template-thumbnail${isActive ? ' template-thumbnail--active' : ''}`}
              aria-pressed={isActive}
            >
              <span className="template-thumbnail__preview" style={{ background: template.accent }} aria-hidden="true">
                <span className="template-thumbnail__preview-header">{template.name}</span>
                <span className="template-thumbnail__preview-body" />
                <span className="template-thumbnail__preview-footer">{primaryHighlight}</span>
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
              <span className="metric-label">{t('workspace.dashboard.outstanding', 'Outstanding balance')}</span>
              <span className="metric-icon">💳</span>
            </header>
            <strong className="metric-value">{formatCurrency(outstandingTotal, draft.currency, locale)}</strong>
            <p>
              {recentInvoices.length
                ? t('workspace.dashboard.trackCount', `${recentInvoices.length} invoices tracked`, { count: recentInvoices.length })
                : t('workspace.dashboard.noInvoices', 'No invoices yet')}
            </p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.paid', 'Paid this month')}</span>
              <span className="metric-icon">✅</span>
            </header>
            <strong className="metric-value">{formatCurrency(paidThisMonth, draft.currency, locale)}</strong>
            <p>{t('workspace.dashboard.reconciled', 'Auto-reconciled with client receipts')}</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.paymentTime', 'Average payment time')}</span>
              <span className="metric-icon">⏱️</span>
            </header>
            <strong className="metric-value">{t('workspace.dashboard.paymentDuration', '9.4 days')}</strong>
            <p>{t('workspace.dashboard.paymentDelta', 'Down 2.1 days vs last month')}</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.templates', 'Templates in use')}</span>
              <span className="metric-icon">🖌️</span>
            </header>
            <strong className="metric-value">{localizedTemplates.length}</strong>
            <p>{t('workspace.dashboard.templatesHint', 'Switch templates from the gallery')}</p>
          </article>
        </div>

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.recent.heading', 'Recent invoices')}</h2>
              <p>{t('workspace.recent.description', 'Monitor drafts, sent documents, and payments at a glance.')}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
              {t('workspace.actions.createInvoice', 'Create invoice')}
            </button>
          </header>
          {loadingInvoices ? (
            <div className="empty-state">{t('workspace.recent.loading', 'Loading invoices…')}</div>
          ) : recentInvoices.length ? (
            <div className="table">
              <div className="table__row table__row--head">
                <span>{t('workspace.table.client', 'Client')}</span>
                <span>{t('workspace.table.status', 'Status')}</span>
                <span>{t('workspace.table.issued', 'Issued')}</span>
                <span>{t('workspace.table.due', 'Due')}</span>
                <span>{t('workspace.table.total', 'Total')}</span>
              </div>
              {recentInvoices.map((invoice) => (
                <div key={invoice.id} className="table__row">
                  <span>
                    <strong>{invoice.clientName || t('workspace.table.clientPlaceholder', 'Client')}</strong>
                    <small>{invoice.clientEmail || '—'}</small>
                  </span>
                  <span>
                    <span className={`status-pill status-pill--${invoice.status}`}>{statusLookup.get(invoice.status)}</span>
                  </span>
                  <span>{formatFriendlyDate(invoice.issueDate, locale)}</span>
                  <span>{formatFriendlyDate(invoice.dueDate, locale)}</span>
                  <span>{formatCurrency(invoice.total, invoice.currency, locale)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">{t('workspace.recent.empty', 'Save your first invoice to populate the dashboard.')}</div>
          )}
        </div>

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.templates.spotlight', 'Template spotlight')}</h2>
              <p>{t('workspace.templates.spotlightDescription', 'Highlighting the most popular template with clients this week.')}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('templates')}>
              {t('workspace.templates.browse', 'Browse gallery')}
            </button>
          </header>
          <div className="template-spotlight">
            <div className="template-spotlight__preview" style={{ background: localizedTemplates[0].accent }}>
              <span>{localizedTemplates[0].name}</span>
            </div>
            <div className="template-spotlight__body">
              <strong>{localizedTemplates[0].name}</strong>
              <p>{localizedTemplates[0].description}</p>
              <ul>
                {localizedTemplates[0].highlights.map((highlight) => (
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
              <h2>{t('workspace.invoice.heading', 'Invoice workspace')}</h2>
              <p>{t('workspace.invoice.description', 'Toggle between editing your draft and reviewing the formatted preview.')}</p>
            </div>
            <div className="view-toggle" role="group" aria-label={t('workspace.invoice.viewLabel', 'Invoice workspace view')}>
              <button
                type="button"
                className={`view-toggle__button${invoiceView === 'edit' ? ' view-toggle__button--active' : ''}`}
                onClick={() => setInvoiceView('edit')}
                aria-pressed={invoiceView === 'edit'}
              >
                ✏️ {t('workspace.view.edit', 'Edit draft')}
              </button>
              <button
                type="button"
                className={`view-toggle__button${invoiceView === 'preview' ? ' view-toggle__button--active' : ''}`}
                onClick={() => setInvoiceView('preview')}
                aria-pressed={invoiceView === 'preview'}
              >
                👀 {t('workspace.view.preview', 'Preview')}
              </button>
            </div>
          </header>

          <div className="panel__section">
            <header className="panel__section-header">
              <div>
                <h3>{t('workspace.nav.templates', 'Templates')}</h3>
                <p>{t('workspace.templates.instructions', 'Select a template thumbnail to style your invoice.')}</p>
              </div>
              <span className="badge">
                {t('workspace.templates.count', `${localizedTemplates.length} options`, {
                  count: localizedTemplates.length,
                })}
              </span>
            </header>
            {renderTemplateThumbnails()}
          </div>

          {invoiceView === 'edit' ? (
            <form id={formId} className="invoice-form" onSubmit={handleSave}>
              <div className="invoice-form__grid">
                <section className="editor-card invoice-form__card">
                  <header className="editor-card__header">
                    <div>
                      <h2>{t('workspace.section.business', 'Business & client')}</h2>
                      <p>{t('workspace.section.businessDescription', 'Details shown at the top of every invoice.')}</p>
                    </div>
                  </header>
                  <div className="editor-card__grid">
                    <div>
                      <label htmlFor="businessName">{t('workspace.field.businessName', 'Business name')}</label>
                      <input
                        id="businessName"
                        type="text"
                        value={draft.businessName}
                        placeholder={t('workspace.placeholder.businessName', 'Atlas Studio')}
                        onChange={(event) => updateDraftField('businessName', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="businessAddress">{t('workspace.field.businessAddress', 'Business address')}</label>
                      <input
                        id="businessAddress"
                        type="text"
                        value={draft.businessAddress}
                        placeholder={t('workspace.placeholder.businessAddress', '88 Harbor Lane, Portland, OR')}
                        onChange={(event) => updateDraftField('businessAddress', event.target.value)}
                      />
                    </div>
                    <div className="client-field">
                      <label htmlFor="clientName">{t('workspace.field.clientName', 'Client name')}</label>
                      <input
                        id="clientName"
                        type="text"
                        value={draft.clientName}
                        placeholder={t('workspace.placeholder.clientName', 'Northwind Co.')}
                        autoComplete="organization"
                        aria-autocomplete="list"
                        aria-expanded={showClientMatches}
                        aria-controls="client-suggestions"
                        onChange={(event) => handleClientNameChange(event.target.value)}
                        onFocus={() => {
                          if (draft.clientName.trim().length >= 2) {
                            const matches = matchClients(draft.clientName).slice(0, 5);
                            setClientMatches(matches);
                            setShowClientMatches(matches.length > 0);
                          }
                        }}
                        onBlur={() => {
                          setTimeout(() => setShowClientMatches(false), 120);
                        }}
                      />
                      <p className="input-hint">{t('workspace.clients.autofillHint', 'Start typing to autofill saved client details.')}</p>
                      {showClientMatches && clientMatches.length > 0 && (
                        <ul id="client-suggestions" className="client-suggestions" role="listbox">
                          {clientMatches.map((entry) => (
                            <li key={entry.email} role="option">
                              <button
                                type="button"
                                onMouseDown={(event) => event.preventDefault()}
                                onClick={() => applyClientMatch(entry)}
                              >
                                <span>{entry.name}</span>
                                <small>{entry.email}</small>
                                <small>{entry.address}</small>
                              </button>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>
                    <div>
                      <label htmlFor="clientEmail">{t('workspace.field.clientEmail', 'Client email')}</label>
                      <input
                        id="clientEmail"
                        type="email"
                        value={draft.clientEmail}
                        placeholder={t('workspace.placeholder.clientEmail', 'client@email.com')}
                        onChange={(event) => updateDraftField('clientEmail', event.target.value)}
                      />
                    </div>
                    <div className="editor-card__full">
                      <label htmlFor="clientAddress">{t('workspace.field.clientAddress', 'Client address')}</label>
                      <textarea
                        id="clientAddress"
                        value={draft.clientAddress}
                        placeholder={t('workspace.placeholder.clientAddress', 'Via Tammaricella 128, Rome, Italy')}
                        rows={2}
                        onChange={(event) => updateDraftField('clientAddress', event.target.value)}
                      />
                    </div>
                  </div>
                </section>
                <section className="editor-card invoice-form__card">
                  <header className="editor-card__header">
                    <div>
                      <h2>{t('workspace.section.terms', 'Invoice terms')}</h2>
                      <p>{t('workspace.section.termsDescription', 'Dates, currency, and tax rates applied to the totals.')}</p>
                    </div>
                  </header>
                  <div className="editor-card__grid editor-card__grid--compact">
                    <div>
                      <label htmlFor="issueDate">{t('workspace.field.issueDate', 'Issue date')}</label>
                      <input
                        id="issueDate"
                        type="date"
                        value={draft.issueDate?.slice(0, 10) || ''}
                        onChange={(event) => updateDraftField('issueDate', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="dueDate">{t('workspace.field.dueDate', 'Due date')}</label>
                      <input
                        id="dueDate"
                        type="date"
                        value={draft.dueDate?.slice(0, 10) || ''}
                        onChange={(event) => updateDraftField('dueDate', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="currency">{t('workspace.field.currency', 'Currency')}</label>
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
                    <div>
                      <label htmlFor="status">{t('workspace.field.status', 'Status')}</label>
                      <select
                        id="status"
                        value={draft.status}
                        onChange={(event) => updateDraftField('status', event.target.value as InvoiceStatus)}
                      >
                        {localizedStatusOptions.map((option) => (
                          <option key={option.value} value={option.value}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label htmlFor="taxRate">{t('workspace.field.tax', 'Tax rate')}</label>
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
                  </div>
                  <div>
                    <label htmlFor="notes">{t('workspace.section.notes', 'Notes')}</label>
                    <textarea
                      id="notes"
                      value={draft.notes}
                      placeholder={t('workspace.notes.placeholder', 'Share payment instructions or a thank you.')}
                      rows={3}
                      onChange={(event) => updateDraftField('notes', event.target.value)}
                    />
                  </div>
                </section>
              </div>

              <section className="editor-card invoice-form__card invoice-form__card--full">
                <div className="line-items">
                  <div className="line-items__header">
                    <div>
                      <h2>{t('workspace.section.lines', 'Line items')}</h2>
                      <p>{t('workspace.section.linesDescription', 'Outline the services, quantity, and rate for this invoice.')}</p>
                    </div>
                    <button type="button" className="button button--ghost" onClick={addLine}>
                      {t('workspace.lines.add', 'Add line')}
                    </button>
                  </div>
                  <div className="line-items__table">
                    <div className="line-items__row line-items__row--head">
                      <span>{t('workspace.lines.description', 'Description')}</span>
                      <span>{t('workspace.lines.quantity', 'Qty')}</span>
                      <span>{t('workspace.lines.rate', 'Rate')}</span>
                      <span>{t('workspace.lines.amount', 'Amount')}</span>
                      <span className="sr-only">{t('workspace.lines.remove', 'Remove')}</span>
                    </div>
                    {draft.lines.map((line, index) => {
                      const lineTotal = formatCurrency(line.quantity * line.rate, draft.currency, locale);
                      return (
                        <div key={line.id} className="line-items__row">
                          <div>
                            <label htmlFor={`description-${line.id}`} className="sr-only">
                              {t('workspace.lines.description', 'Description')} {index + 1}
                            </label>
                            <input
                              id={`description-${line.id}`}
                              type="text"
                              value={line.description}
                              placeholder={t('workspace.lines.descriptionPlaceholder', 'Service provided')}
                              onChange={(event) => updateLine(line.id, 'description', event.target.value)}
                            />
                          </div>
                          <div>
                            <label htmlFor={`quantity-${line.id}`} className="sr-only">
                              {t('workspace.lines.quantity', 'Qty')} {index + 1}
                            </label>
                            <input
                              id={`quantity-${line.id}`}
                              type="number"
                              min="1"
                              value={line.quantity}
                              onChange={(event) => updateLine(line.id, 'quantity', event.target.value)}
                            />
                          </div>
                          <div>
                            <label htmlFor={`rate-${line.id}`} className="sr-only">
                              {t('workspace.lines.rate', 'Rate')} {index + 1}
                            </label>
                            <input
                              id={`rate-${line.id}`}
                              type="number"
                              min="0"
                              step="0.01"
                              value={line.rate}
                              onChange={(event) => updateLine(line.id, 'rate', event.target.value)}
                            />
                          </div>
                          <div className="line-items__amount" aria-live="polite">
                            {lineTotal}
                          </div>
                          <button
                            type="button"
                            onClick={() => removeLine(line.id)}
                            aria-label={`${t('workspace.lines.remove', 'Remove')} ${index + 1}`}
                          >
                            ×
                          </button>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </section>

              <section className="editor-card invoice-form__card invoice-form__summary">
                <div className="invoice-form__summary-totals">
                  <div className="invoice-form__summary-row">
                    <span>{t('workspace.summary.subtotal', 'Subtotal')}</span>
                    <strong>{formatCurrency(totals.subtotal, draft.currency, locale)}</strong>
                  </div>
                  <div className="invoice-form__summary-row">
                    <span>{t('workspace.summary.tax', 'Tax')}</span>
                    <strong>{formatCurrency(totals.taxAmount, draft.currency, locale)}</strong>
                  </div>
                  <div className="invoice-form__summary-row invoice-form__summary-row--emphasis">
                    <span>{t('workspace.summary.total', 'Total')}</span>
                    <strong>{formatCurrency(totals.total, draft.currency, locale)}</strong>
                  </div>
                </div>
                <div className="invoice-form__actions">
                  <button type="button" className="button button--ghost" onClick={() => setInvoiceView('preview')}>
                    {t('workspace.actions.preview', 'Preview invoice')}
                  </button>
                  <button type="submit" className="button button--primary" disabled={saveState === 'saving'}>
                    {saveState === 'saving'
                      ? t('workspace.actions.saving', 'Saving…')
                      : t('workspace.actions.save', 'Save invoice')}
                  </button>
                </div>
              </section>
            </form>
          ) : (
            <div className="preview" data-template={activeTemplate.id}>
              <header className="preview__header" style={{ background: activeTemplate.accent }}>
                <div className="preview__header-info">
                  <span className="preview__eyebrow">{activeTemplate.name}</span>
                  <strong>
                    {draft.businessName || t('workspace.preview.businessPlaceholder', 'Your business name')}
                  </strong>
                  <span>{draft.businessAddress || t('workspace.preview.addressPlaceholder', 'Add your business address')}</span>
                  <span className="preview__tagline">{activeTemplate.description}</span>
                </div>
                <div className="preview__badge">
                  <span>{t('workspace.preview.totalDue', 'Total due')}</span>
                  <strong>{formatCurrency(totals.total, draft.currency, locale)}</strong>
                  <small>
                    {t('workspace.preview.status', 'Status')}: {statusLookup.get(draft.status)}
                  </small>
                </div>
              </header>

              <div className="preview__body">
                {(() => {
                  const isSeikyu = activeTemplate.id === 'seikyu';
                  const billToLabel = isSeikyu
                    ? t('workspace.preview.billToDual', '請求先 / Bill to')
                    : t('workspace.preview.billTo', 'Bill to');
                  const issuedLabel = isSeikyu
                    ? t('workspace.preview.issuedDual', '発行日 / Issued')
                    : t('workspace.preview.issued', 'Issued');
                  const dueLabel = isSeikyu
                    ? t('workspace.preview.dueDual', '支払期日 / Due')
                    : t('workspace.preview.due', 'Due');
                  const descriptionLabel = isSeikyu
                    ? t('workspace.preview.descriptionDual', '品目 / Item')
                    : t('workspace.preview.description', 'Description');
                  const quantityLabel = isSeikyu
                    ? t('workspace.preview.quantityDual', '数量 / Qty')
                    : t('workspace.preview.quantity', 'Qty');
                  const rateLabel = isSeikyu
                    ? t('workspace.preview.rateDual', '単価 / Rate')
                    : t('workspace.preview.rate', 'Rate');
                  const amountLabel = isSeikyu
                    ? t('workspace.preview.amountDual', '金額 / Total')
                    : t('workspace.preview.amount', 'Amount');
                  const subtotalLabel = isSeikyu
                    ? t('workspace.preview.subtotalDual', '小計 / Subtotal')
                    : t('workspace.summary.subtotal', 'Subtotal');
                  const taxLabel = isSeikyu
                    ? t('workspace.preview.taxDual', '税額 / Tax')
                    : t('workspace.summary.tax', 'Tax');
                  const totalLabel = isSeikyu
                    ? t('workspace.preview.totalDual', '合計 / Total')
                    : t('workspace.summary.total', 'Total');

                  return (
                    <>
                      <div className="preview__meta">
                        <div>
                          <span className="preview__label">{billToLabel}</span>
                          <strong>{draft.clientName || t('workspace.preview.clientPlaceholder', 'Client name')}</strong>
                          <span>{draft.clientEmail || t('workspace.preview.emailPlaceholder', 'client@email.com')}</span>
                          {draft.clientAddress && <span className="preview__address">{draft.clientAddress}</span>}
                        </div>
                        <div>
                          <span className="preview__label">{issuedLabel}</span>
                          <strong>{formatFriendlyDate(draft.issueDate, locale)}</strong>
                        </div>
                        <div>
                          <span className="preview__label">{dueLabel}</span>
                          <strong>{formatFriendlyDate(draft.dueDate, locale)}</strong>
                        </div>
                      </div>

                      <div className="preview__table">
                        <div className="preview__table-row preview__table-row--head">
                          <span>{descriptionLabel}</span>
                          <span>{quantityLabel}</span>
                          <span>{rateLabel}</span>
                          <span>{amountLabel}</span>
                        </div>
                        {draft.lines.map((line) => (
                          <div key={line.id} className="preview__table-row">
                            <span>
                              {line.description ||
                                (isSeikyu
                                  ? t('workspace.preview.linePlaceholderJa', 'Service item')
                                  : t('workspace.preview.linePlaceholder', 'Line description'))}
                            </span>
                            <span>{line.quantity}</span>
                            <span>{formatCurrency(line.rate, draft.currency, locale)}</span>
                            <span>{formatCurrency(line.quantity * line.rate, draft.currency, locale)}</span>
                          </div>
                        ))}
                      </div>

                      {activeTemplate.id === 'aqua-ledger' && (
                        <div className="preview__summary-card">
                          <header>
                            <span>{t('workspace.preview.paymentSummary', 'Payment summary')}</span>
                            <strong>{formatCurrency(totals.total, draft.currency, locale)}</strong>
                          </header>
                          <ul>
                            <li>
                              <span>{t('workspace.summary.subtotal', 'Subtotal')}</span>
                              <strong>{formatCurrency(totals.subtotal, draft.currency, locale)}</strong>
                            </li>
                            <li>
                              <span>{t('workspace.summary.tax', 'Tax')}</span>
                              <strong>{formatCurrency(totals.taxAmount, draft.currency, locale)}</strong>
                            </li>
                            <li>
                              <span>{t('workspace.preview.status', 'Status')}</span>
                              <strong>{statusLookup.get(draft.status)}</strong>
                            </li>
                          </ul>
                        </div>
                      )}

                      <div className="preview__totals">
                        <div>
                          <span>{subtotalLabel}</span>
                          <strong>{formatCurrency(totals.subtotal, draft.currency, locale)}</strong>
                        </div>
                        <div>
                          <span>{taxLabel}</span>
                          <strong>{formatCurrency(totals.taxAmount, draft.currency, locale)}</strong>
                        </div>
                        <div>
                          <span>{totalLabel}</span>
                          <strong>{formatCurrency(totals.total, draft.currency, locale)}</strong>
                        </div>
                      </div>

                      {isSeikyu && (
                        <div className="preview__hanko">
                          <span>{t('workspace.preview.hankoLabel', '印')}</span>
                          <small>{t('workspace.preview.hankoCaption', 'Authorised seal')}</small>
                        </div>
                      )}

                      <div className="preview__notes">
                        <strong>
                          {isSeikyu
                            ? t('workspace.preview.notesDual', '備考 / Notes')
                            : t('workspace.preview.notes', 'Notes')}
                        </strong>
                        <p>
                          {draft.notes ||
                            t('workspace.preview.notesPlaceholder', 'Add payment instructions or a thank you message.')}
                        </p>
                        {isSeikyu && (
                          <small>
                            {t(
                              'workspace.preview.notesHint',
                              'Please remit payment before the due date.',
                            )}
                          </small>
                        )}
                      </div>
                    </>
                  );
                })()}
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
              <h2>{t('workspace.templates.galleryHeading', 'Template gallery')}</h2>
              <p>
                {t('workspace.templates.galleryDescription', 'Explore each template layout before applying it to your invoice.')}
              </p>
            </div>
            <span className="badge">
              {t('workspace.templates.count', `${localizedTemplates.length} options`, {
                count: localizedTemplates.length,
              })}
            </span>
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
              <h2>{t('workspace.clients.heading', 'Client insights')}</h2>
              <p>{t('workspace.clients.description', 'Outstanding balances and recent invoice activity per client.')}</p>
            </div>
            <button type="button" className="button button--ghost">
              {t('workspace.clients.add', 'Add client')}
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
                      <dt>{t('workspace.clients.outstanding', 'Outstanding')}</dt>
                      <dd>{formatCurrency(client.outstanding, client.currency || draft.currency, locale)}</dd>
                    </div>
                    <div>
                      <dt>{t('workspace.clients.invoices', 'Invoices')}</dt>
                      <dd>{client.invoices}</dd>
                    </div>
                    <div>
                      <dt>{t('workspace.clients.lastInvoice', 'Last invoice')}</dt>
                      <dd>{formatFriendlyDate(client.lastInvoice, locale)}</dd>
                    </div>
                  </dl>
                </article>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              {t('workspace.clients.empty', 'Save an invoice to build the client directory.')}
            </div>
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
              <h2>{t('workspace.activity.heading', 'Activity timeline')}</h2>
              <p>{t('workspace.activity.description', 'Review invoice saves, reminders, and payments from newest to oldest.')}</p>
            </div>
            <Link className="button button--ghost" href="/admin/console" prefetch={false}>
              {t('workspace.activity.viewAdmin', 'View admin console')}
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
                    <small>{formatFriendlyDate(item.timestamp, locale)}</small>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state">
              {t('workspace.activity.empty', 'Activity will appear once invoices are saved.')}
            </div>
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
              <h2>{t('workspace.settings.heading', 'Workspace settings')}</h2>
              <p>{t('workspace.settings.description', 'Default information used across every new invoice.')}</p>
            </div>
          </header>
          <dl className="settings-grid">
            <div>
              <dt>{t('workspace.settings.businessName', 'Business name')}</dt>
              <dd>{draft.businessName || t('workspace.placeholder.businessName', 'Atlas Studio')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.businessAddress', 'Business address')}</dt>
              <dd>{draft.businessAddress || t('workspace.placeholder.businessAddress', '88 Harbor Lane, Portland, OR')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.currencyDefault', 'Default currency')}</dt>
              <dd>{draft.currency}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.taxDefault', 'Default tax rate')}</dt>
              <dd>{(draft.taxRate * 100).toFixed(1)}%</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.reminders', 'Reminder emails')}</dt>
              <dd>{t('workspace.settings.reminderDetails', 'Enabled — 3 days before due date')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.template', 'Template')}</dt>
              <dd>
                {localizedTemplates.find((template) => template.id === selectedTemplateId)?.name ||
                  localizedTemplates[0].name}
              </dd>
            </div>
          </dl>
          <div className="settings-actions">
            <button type="button" className="button button--primary">
              {t('workspace.settings.updateProfile', 'Update profile')}
            </button>
            <button type="button" className="button button--ghost">
              {t('workspace.settings.manageAutomations', 'Manage automations')}
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

  const activeMeta = localizedSections.find((section) => section.id === activeSection);

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
            <span>{t('workspace.shell.brandSubtitle', 'Billing workspace')}</span>
          </div>
        </div>
        <nav
          className="workspace-topbar__nav"
          aria-label={t('workspace.nav.label', 'Workspace sections')}
        >
          {localizedSections.map((section) => (
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
        <div className="workspace-topbar__controls">
          <LanguageSwitcher variant="compact" />
          <div className="workspace-user-menu" role="group" aria-label={t('workspace.userMenu.label', 'Account actions')}>
            {isSignedIn ? (
              <>
                <span className="workspace-user-menu__name">{sessionDisplayName}</span>
                {isAdmin && (
                  <Link className="workspace-user-menu__link" href="/admin/console" prefetch={false}>
                    {t('workspace.actions.adminConsole', 'Admin console')}
                  </Link>
                )}
                <button type="button" className="workspace-user-menu__button" onClick={handleSignOut}>
                  {t('workspace.actions.signOut', 'Sign out')}
                </button>
              </>
            ) : (
              <Link className="workspace-user-menu__button" href="/login" prefetch={false}>
                {t('workspace.actions.signIn', 'Sign in')}
              </Link>
            )}
          </div>
        </div>
      </div>

      <div className="workspace-shell__main">
        <header className="workspace-shell__header">
          <div>
            <span>{activeMeta?.icon}</span>
            <div>
              <h1>{activeMeta?.label}</h1>
              <p>{activeMeta?.description}</p>
              {!firebaseConfigured && (
                <span className="workspace-shell__hint">{t('workspace.hint', 'Connected to demo data until Firebase credentials are added.')}</span>
              )}
            </div>
          </div>
          {activeSection !== 'invoices' ? (
            <div className="workspace-shell__actions">
              <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
                {t('workspace.actions.createInvoice', 'Create invoice')}
              </button>
              <button type="button" className="button button--primary" onClick={() => setActiveSection('dashboard')}>
                {t('workspace.actions.viewDashboard', 'View dashboard')}
              </button>
            </div>
          ) : (
            <div className="workspace-shell__actions">
              <button type="button" className="button button--ghost" onClick={handleDownload} disabled={downloadingPdf}>
                {downloadingPdf
                  ? t('workspace.actions.downloading', 'Generating…')
                  : t('workspace.actions.download', 'Download PDF')}
              </button>
              <button
                type="submit"
                form={formId}
                className="button button--primary"
                disabled={saveState === 'saving'}
              >
                {saveState === 'saving' ? t('workspace.actions.saving', 'Saving…') : t('workspace.actions.save', 'Save invoice')}
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
