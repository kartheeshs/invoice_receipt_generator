'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  adminVitals,
  adminHealthChecks,
  adminSupportQueue,
  type AdminHealthCheck,
  type AdminSupportTicket,
  type AdminVital,
} from '../../../lib/admin';
import { InvoiceRecord, describeStatus, formatCurrency, type InvoiceStatus } from '../../../lib/invoices';
import { firebaseConfigured, fetchRecentInvoices } from '../../../lib/firebase';
import { sampleInvoices } from '../../../lib/sample-data';
import { useTranslation } from '../../../lib/i18n';

type TimelineEntry = {
  id: string;
  label: string;
  total: string;
  status: InvoiceStatus;
  statusLabel: string;
  when: string;
};

export default function AdminConsolePage() {
  const [invoices, setInvoices] = useState<InvoiceRecord[]>(sampleInvoices);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const { locale, t } = useTranslation();

  useEffect(() => {
    let active = true;

    async function load() {
      if (!firebaseConfigured) {
        setLoading(false);
        return;
      }

      try {
        const latest = await fetchRecentInvoices(12);
        if (!active) return;
        setInvoices(latest.length ? latest : sampleInvoices);
      } catch (err) {
        console.error(err);
        if (!active) return;
        setError(t('admin.console.errorSample', 'Live data unavailable. Displaying sample invoices.'));
        setInvoices(sampleInvoices);
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    load();

    return () => {
      active = false;
    };
  }, [t]);

  const outstanding = useMemo(
    () => invoices.filter((invoice) => invoice.status !== 'paid').reduce((sum, invoice) => sum + invoice.total, 0),
    [invoices],
  );

  const paidThisMonth = useMemo(() => {
    const now = new Date();
    return invoices
      .filter((invoice) => {
        if (invoice.status !== 'paid') return false;
        const issued = invoice.createdAt ? new Date(invoice.createdAt) : new Date(invoice.issueDate);
        return issued.getMonth() === now.getMonth() && issued.getFullYear() === now.getFullYear();
      })
      .reduce((sum, invoice) => sum + invoice.total, 0);
  }, [invoices]);

  const timeline = useMemo<TimelineEntry[]>(() => {
    return invoices
      .map((invoice) => {
        const statusLabel = t(`workspace.status.${invoice.status}`, describeStatus(invoice.status));
        const clientLabel = invoice.clientName || t('workspace.table.clientPlaceholder', 'Client');
        return {
          id: invoice.id,
          label: `${clientLabel} — ${statusLabel}`,
          total: formatCurrency(invoice.total, invoice.currency || 'USD', locale),
          status: invoice.status,
          statusLabel,
          when: invoice.createdAt || invoice.issueDate,
        };
      })
      .sort((a, b) => new Date(b.when ?? '').getTime() - new Date(a.when ?? '').getTime())
      .slice(0, 8);
  }, [invoices, locale, t]);

  const primaryCurrency = invoices[0]?.currency || 'USD';
  const updatedLabel = t('admin.console.metrics.updated', 'Updated {time}', {
    time: new Date().toLocaleTimeString(locale),
  });

  return (
    <div className="admin-console">
      <div className="admin-console__masthead">
        <div className="container">
          <span className="badge">{t('admin.console.badge', 'Administrator area')}</span>
          <h1>{t('admin.console.title', 'Easy Invoice GM7 admin console')}</h1>
          <p>{t('admin.console.description', 'Audit activity, monitor system health, and keep the support desk flowing smoothly. Workspace users cannot access this page.')}</p>
          <div className="admin-console__actions">
            <Link className="button button--primary" href="/login" prefetch={false}>
              {t('admin.console.switchMember', 'Switch to member login')}
            </Link>
            <Link className="button button--ghost" href="/app" prefetch={false}>
              {t('admin.console.openWorkspace', 'Open billing workspace')}
            </Link>
          </div>
          {error && <div className="alert alert--warning">{error}</div>}
          {!firebaseConfigured && (
            <div className="alert alert--muted">{t('admin.console.missingFirebase', 'Connect Firebase credentials to populate the console with live workspace data.')}</div>
          )}
        </div>
      </div>

      <div className="container admin-console__grid">
        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('admin.console.metrics.heading', 'Key metrics')}</h2>
              <p>{t('admin.console.metrics.description', 'Track usage pulses and pipeline volume for your workspace fleet.')}</p>
            </div>
            <span className="panel__meta">{loading ? t('admin.console.metrics.loading', 'Loading…') : updatedLabel}</span>
          </header>
          <div className="workspace-metrics">
            {adminVitals.map((metric: AdminVital) => (
              <article key={metric.key} className="metric-card metric-card--compact">
                <strong className="metric-value">{metric.value}</strong>
                <span className="metric-label">{t(`admin.metrics.${metric.key}`, metric.label)}</span>
                <small>{t(`admin.metrics.${metric.key}Delta`, metric.delta)}</small>
              </article>
            ))}
            <article className="metric-card metric-card--compact">
              <strong className="metric-value">{formatCurrency(outstanding, primaryCurrency, locale)}</strong>
              <span className="metric-label">{t('admin.metrics.outstanding', 'Outstanding receivables')}</span>
              <small>{t('admin.metrics.outstandingHint', 'Across unpaid invoices')}</small>
            </article>
            <article className="metric-card metric-card--compact">
              <strong className="metric-value">{formatCurrency(paidThisMonth, primaryCurrency, locale)}</strong>
              <span className="metric-label">{t('admin.metrics.paid', 'Collected this month')}</span>
              <small>{t('admin.metrics.paidHint', 'Paid invoices only')}</small>
            </article>
          </div>
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('admin.console.health.heading', 'System health')}</h2>
              <p>{t('admin.console.health.description', 'Service-level snapshots for integrations that power invoice delivery.')}</p>
            </div>
          </header>
          <ul className="admin-health">
            {adminHealthChecks.map((check: AdminHealthCheck) => (
              <li key={check.key}>
                <div>
                  <strong>{t(`admin.health.${check.key}.name`, check.name)}</strong>
                  <span>{t(`admin.health.${check.key}.detail`, check.detail)}</span>
                </div>
                <span
                  className={`status-pill status-pill--${check.status === 'Operational' ? 'success' : check.status === 'Degraded' ? 'warning' : 'info'}`}
                >
                  {t(`admin.health.status.${check.status.toLowerCase()}`, check.status)}
                </span>
              </li>
            ))}
          </ul>
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('admin.console.activity.heading', 'Recent activity')}</h2>
              <p>{t('admin.console.activity.description', 'Newest invoice updates from all connected workspaces.')}</p>
            </div>
            <Link className="panel__meta" href="/app" prefetch={false}>
              {t('admin.console.activity.viewWorkspace', 'View workspace timeline')}
            </Link>
          </header>
          {timeline.length ? (
            <ul className="timeline timeline--dense">
              {timeline.map((entry) => (
                <li key={entry.id}>
                  <div className="timeline__marker" />
                  <div className="timeline__body">
                    <div className="timeline__title">
                      <strong>{entry.label}</strong>
                      <span className={`status-pill status-pill--${entry.status}`}>{entry.statusLabel}</span>
                    </div>
                    <p>{entry.total}</p>
                    <small>
                      {entry.when
                        ? new Date(entry.when).toLocaleString(locale)
                        : t('admin.console.activity.unknown', 'Unknown')}
                    </small>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state">
              {t('admin.console.activity.empty', 'No invoice activity yet. Create invoices to populate the feed.')}
            </div>
          )}
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('admin.console.support.heading', 'Support queue')}</h2>
              <p>{t('admin.console.support.description', 'Requests flagged by billing teams that need a response.')}</p>
            </div>
          </header>
          <ul className="admin-support">
            {adminSupportQueue.map((ticket: AdminSupportTicket) => (
              <li key={ticket.contact}>
                <div>
                  <strong>{ticket.contact}</strong>
                  <span>{ticket.summary}</span>
                </div>
                <small>{ticket.updated}</small>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}
