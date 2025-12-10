'use client';

import { forwardRef } from 'react';
import { InvoiceDraft, InvoiceStatus, formatCurrency } from '../../lib/invoices';
import { InvoiceTemplate } from '../../lib/templates';
import { formatFriendlyDate } from '../../lib/format';

const statusFallback = new Map<InvoiceStatus, string>([
  ['draft', 'Draft'],
  ['sent', 'Sent'],
  ['paid', 'Paid'],
  ['overdue', 'Overdue'],
]);

type Totals = {
  subtotal: number;
  taxAmount: number;
  total: number;
};

type TranslateFn = (key: string, fallback: string, options?: Record<string, unknown>) => string;

type InvoicePreviewProps = {
  draft: InvoiceDraft;
  totals: Totals;
  template: InvoiceTemplate;
  locale: string;
  currency: string;
  statusLookup: Map<InvoiceStatus, string>;
  t: TranslateFn;
  className?: string;
};

const InvoicePreview = forwardRef<HTMLDivElement, InvoicePreviewProps>(
  (
    {
      draft,
      totals,
      template,
      locale,
      currency,
      statusLookup,
      t,
      className,
    },
    ref,
  ) => {
    const isSeikyu = template.id === 'seikyu';
    const statusText = statusLookup.get(draft.status) ?? statusFallback.get(draft.status) ?? draft.status;
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
      <div
        ref={ref}
        className={`preview${className ? ` ${className}` : ''}`}
        data-template={template.id}
      >
        <header className="preview__header" style={{ background: template.accent }}>
          <div className="preview__header-info">
            <span className="preview__eyebrow">{template.name}</span>
            <strong>{draft.businessName || t('workspace.preview.businessPlaceholder', 'Your business name')}</strong>
            <span>{draft.businessAddress || t('workspace.preview.addressPlaceholder', 'Add your business address')}</span>
            <span className="preview__tagline">{template.description}</span>
          </div>
          <div className="preview__badge">
            <span>{t('workspace.preview.totalDue', 'Total due')}</span>
            <strong>{formatCurrency(totals.total, currency, locale)}</strong>
            <small>
              {t('workspace.preview.status', 'Status')}: {statusText}
            </small>
          </div>
        </header>

        <div className="preview__body">
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
                <span>{formatCurrency(line.rate, currency, locale)}</span>
                <span>{formatCurrency(line.quantity * line.rate, currency, locale)}</span>
              </div>
            ))}
          </div>

          {template.id === 'aqua-ledger' && (
            <div className="preview__summary-card">
              <header>
                <span>{t('workspace.preview.paymentSummary', 'Payment summary')}</span>
                <strong>{formatCurrency(totals.total, currency, locale)}</strong>
              </header>
              <ul>
                <li>
                  <span>{t('workspace.summary.subtotal', 'Subtotal')}</span>
                  <strong>{formatCurrency(totals.subtotal, currency, locale)}</strong>
                </li>
                <li>
                  <span>{t('workspace.summary.tax', 'Tax')}</span>
                  <strong>{formatCurrency(totals.taxAmount, currency, locale)}</strong>
                </li>
                <li>
                  <span>{t('workspace.preview.status', 'Status')}</span>
                  <strong>{statusText}</strong>
                </li>
              </ul>
            </div>
          )}

          <div className="preview__totals">
            <div>
              <span>{subtotalLabel}</span>
              <strong>{formatCurrency(totals.subtotal, currency, locale)}</strong>
            </div>
            <div>
              <span>{taxLabel}</span>
              <strong>{formatCurrency(totals.taxAmount, currency, locale)}</strong>
            </div>
            <div>
              <span>{totalLabel}</span>
              <strong>{formatCurrency(totals.total, currency, locale)}</strong>
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
                {t('workspace.preview.notesHint', 'Please remit payment before the due date.')}
              </small>
            )}
          </div>

        </div>
      </div>
    );
  },
);

InvoicePreview.displayName = 'InvoicePreview';

export default InvoicePreview;
