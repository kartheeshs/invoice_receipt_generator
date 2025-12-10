import { DEFAULT_TEMPLATE_ID } from './templates';

export type InvoiceStatus = 'draft' | 'sent' | 'paid' | 'overdue';

export interface InvoiceLine {
  id: string;
  description: string;
  quantity: number;
  rate: number;
}

export interface InvoiceDraft {
  clientName: string;
  clientEmail: string;
  clientAddress: string;
  businessName: string;
  businessAddress: string;
  templateId: string;
  issueDate: string;
  dueDate: string;
  currency: string;
  status: InvoiceStatus;
  taxRate: number;
  notes: string;
  lines: InvoiceLine[];
}

export interface InvoiceRecord extends InvoiceDraft {
  id: string;
  createdAt: string;
  subtotal: number;
  taxAmount: number;
  total: number;
}

export function formatISODate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function createEmptyLine(): InvoiceLine {
  return {
    id: typeof crypto !== 'undefined' && 'randomUUID' in crypto ? crypto.randomUUID() : Math.random().toString(36).slice(2),
    description: '',
    quantity: 1,
    rate: 0,
  };
}

export function createEmptyDraft(): InvoiceDraft {
  const today = new Date();
  const dueDate = new Date(today);
  dueDate.setDate(dueDate.getDate() + 14);

  return {
    clientName: '',
    clientEmail: '',
    clientAddress: '',
    businessName: '',
    businessAddress: '',
    templateId: DEFAULT_TEMPLATE_ID,
    issueDate: formatISODate(today),
    dueDate: formatISODate(dueDate),
    currency: 'USD',
    status: 'draft',
    taxRate: 0.07,
    notes: '',
    lines: [createEmptyLine()],
  };
}

export function describeStatus(status: InvoiceStatus): string {
  switch (status) {
    case 'draft':
      return 'Draft';
    case 'sent':
      return 'Sent';
    case 'paid':
      return 'Paid';
    case 'overdue':
      return 'Overdue';
    default:
      return status;
  }
}

export function calculateTotals(lines: InvoiceLine[], taxRate: number): {
  subtotal: number;
  taxAmount: number;
  total: number;
} {
  const subtotal = lines.reduce((sum, line) => sum + normaliseNumber(line.quantity) * normaliseNumber(line.rate), 0);
  const taxAmount = subtotal * Math.max(0, taxRate);
  const total = subtotal + taxAmount;

  return {
    subtotal,
    taxAmount,
    total,
  };
}

export function formatCurrency(value: number, currency: string, locale = 'en-US'): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      currencyDisplay: 'narrowSymbol',
    }).format(value);
  } catch (error) {
    return `${currency} ${value.toFixed(2)}`;
  }
}

export function normaliseNumber(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Number(value));
}

export function cleanLines(lines: InvoiceLine[]): InvoiceLine[] {
  return lines
    .map((line) => ({
      ...line,
      description: line.description.trim(),
      quantity: Number.isFinite(line.quantity) && line.quantity > 0 ? Number(line.quantity) : 1,
      rate: Number.isFinite(line.rate) && line.rate >= 0 ? Number(line.rate) : 0,
    }))
    .filter((line) => line.description.length > 0 || line.rate > 0);
}
