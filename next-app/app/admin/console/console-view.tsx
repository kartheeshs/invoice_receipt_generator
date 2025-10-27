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

type TimelineEntry = {
  id: string;
  label: string;
  total: string;
  status: InvoiceStatus;
  when: string;
};

function buildTimeline(invoices: InvoiceRecord[]): TimelineEntry[] {
  return invoices
    .map((invoice) => ({
      id: invoice.id,
      label: `${invoice.clientName || 'Client'} — ${describeStatus(invoice.status)}`,
      total: formatCurrency(invoice.total, invoice.currency),
      status: invoice.status,
      when: invoice.createdAt || invoice.issueDate,
    }))
    .sort((a, b) => new Date(b.when ?? '').getTime() - new Date(a.when ?? '').getTime())
    .slice(0, 8);
}

export default function AdminConsolePage() {
  const [invoices, setInvoices] = useState<InvoiceRecord[]>(sampleInvoices);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

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
        setError('Live data unavailable. Displaying sample invoices.');
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
  }, []);

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

  const timeline = useMemo(() => buildTimeline(invoices), [invoices]);

  return (
    <div className="admin-console">
      <div className="admin-console__masthead">
        <div className="container">
          <span className="badge">Administrator area</span>
          <h1>Easy Invoice GM7 admin console</h1>
          <p>
            Audit activity, monitor system health, and keep the support desk flowing smoothly. Workspace users cannot access
            this page.
          </p>
          <div className="admin-console__actions">
            <Link className="button button--primary" href="/login" prefetch={false}>
              Switch to member login
            </Link>
            <Link className="button button--ghost" href="/app" prefetch={false}>
              Open billing workspace
            </Link>
          </div>
          {error && <div className="alert alert--warning">{error}</div>}
          {!firebaseConfigured && (
            <div className="alert alert--muted">
              Connect Firebase credentials to populate the console with live workspace data.
            </div>
          )}
        </div>
      </div>

      <div className="container admin-console__grid">
        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>Key metrics</h2>
              <p>Track usage pulses and pipeline volume for your workspace fleet.</p>
            </div>
            <span className="panel__meta">{loading ? 'Loading…' : `Updated ${new Date().toLocaleTimeString()}`}</span>
          </header>
          <div className="workspace-metrics">
            {adminVitals.map((metric: AdminVital) => (
              <article key={metric.label} className="metric-card metric-card--compact">
                <strong className="metric-value">{metric.value}</strong>
                <span className="metric-label">{metric.label}</span>
                <small>{metric.delta}</small>
              </article>
            ))}
            <article className="metric-card metric-card--compact">
              <strong className="metric-value">{formatCurrency(outstanding, invoices[0]?.currency || 'USD')}</strong>
              <span className="metric-label">Outstanding receivables</span>
              <small>Across unpaid invoices</small>
            </article>
            <article className="metric-card metric-card--compact">
              <strong className="metric-value">{formatCurrency(paidThisMonth, invoices[0]?.currency || 'USD')}</strong>
              <span className="metric-label">Collected this month</span>
              <small>Paid invoices only</small>
            </article>
          </div>
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>System health</h2>
              <p>Service-level snapshots for integrations that power invoice delivery.</p>
            </div>
          </header>
          <ul className="admin-health">
            {adminHealthChecks.map((check: AdminHealthCheck) => (
              <li key={check.name}>
                <div>
                  <strong>{check.name}</strong>
                  <span>{check.detail}</span>
                </div>
                <span className={`status-pill status-pill--${check.status === 'Operational' ? 'success' : 'warning'}`}>
                  {check.status}
                </span>
              </li>
            ))}
          </ul>
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>Recent activity</h2>
              <p>Newest invoice updates from all connected workspaces.</p>
            </div>
            <Link className="panel__meta" href="/app" prefetch={false}>
              View workspace timeline
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
                      <span className={`status-pill status-pill--${entry.status}`}>{describeStatus(entry.status)}</span>
                    </div>
                    <p>{entry.total}</p>
                    <small>{entry.when ? new Date(entry.when).toLocaleString() : 'Unknown'}</small>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state">No invoice activity yet. Create invoices to populate the feed.</div>
          )}
        </section>

        <section className="panel">
          <header className="panel__header">
            <div>
              <h2>Support queue</h2>
              <p>Requests flagged by billing teams that need a response.</p>
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
