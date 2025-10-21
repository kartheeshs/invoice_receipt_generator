import dayjs from 'dayjs';
import { InvoiceFormValues } from '../types/invoice';

export function generateId() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return Math.random().toString(36).slice(2, 10);
}

export function createEmptyInvoice(): InvoiceFormValues {
  return {
    companyName: '',
    companyAddress: '',
    companyPhone: '',
    clientName: '',
    clientAddress: '',
    invoiceNumber: `INV-${dayjs().format('YYYYMMDD-HHmm')}`,
    issueDate: dayjs().format('YYYY-MM-DD'),
    dueDate: dayjs().add(14, 'day').format('YYYY-MM-DD'),
    notes: '',
    taxRate: 10,
    stampNeeded: false,
    items: [
      {
        id: generateId(),
        name: '',
        description: '',
        quantity: 1,
        unitPrice: 0
      }
    ]
  };
}
