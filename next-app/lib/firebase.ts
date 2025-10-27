import { InvoiceDraft, InvoiceLine, InvoiceRecord, calculateTotals, cleanLines } from './invoices';

const config = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY?.trim() ?? '',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN?.trim() ?? '',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID?.trim() ?? '',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET?.trim() ?? '',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID?.trim() ?? '',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID?.trim() ?? '',
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID?.trim() ?? '',
};

export const firebaseConfig = config;
export const firebaseConfigured = Boolean(config.projectId && config.apiKey);
export const firebaseApiKey = config.apiKey;

const baseUrl = firebaseConfigured
  ? `https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents`
  : '';

const invoicesUrl = firebaseConfigured ? `${baseUrl}/invoices` : '';
const runQueryUrl = firebaseConfigured ? `${baseUrl}:runQuery` : '';

type FirestoreValue = {
  stringValue?: string;
  doubleValue?: number;
  integerValue?: string;
  booleanValue?: boolean;
  mapValue?: { fields: Record<string, FirestoreValue> };
  arrayValue?: { values: FirestoreValue[] };
  timestampValue?: string;
};

type FirestoreDocument = {
  name: string;
  fields: Record<string, FirestoreValue>;
  createTime?: string;
  updateTime?: string;
};

function buildNumber(value: number): FirestoreValue {
  return { doubleValue: Number.isFinite(value) ? Number(value) : 0 };
}

function buildString(value: string): FirestoreValue {
  return { stringValue: value ?? '' };
}

function withApiKey(url: string): string {
  if (!firebaseApiKey) {
    return url;
  }
  return url.includes('?') ? `${url}&key=${firebaseApiKey}` : `${url}?key=${firebaseApiKey}`;
}

function encodeLine(line: InvoiceLine): FirestoreValue {
  return {
    mapValue: {
      fields: {
        id: buildString(line.id),
        description: buildString(line.description),
        quantity: buildNumber(line.quantity),
        rate: buildNumber(line.rate),
      },
    },
  };
}

function decodeString(value?: FirestoreValue): string {
  if (!value) {
    return '';
  }
  if (value.stringValue !== undefined) {
    return value.stringValue;
  }
  return '';
}

function decodeNumber(value?: FirestoreValue): number {
  if (!value) {
    return 0;
  }
  if (typeof value.doubleValue === 'number') {
    return value.doubleValue;
  }
  if (value.integerValue !== undefined) {
    const parsed = Number(value.integerValue);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function decodeLines(value?: FirestoreValue): InvoiceLine[] {
  if (!value || !value.arrayValue) {
    return [];
  }
  return (value.arrayValue.values ?? [])
    .map((entry) => {
      const fields = entry.mapValue?.fields ?? {};
      return {
        id: decodeString(fields.id),
        description: decodeString(fields.description),
        quantity: decodeNumber(fields.quantity) || 1,
        rate: decodeNumber(fields.rate),
      } satisfies InvoiceLine;
    })
    .filter((line) => line.description.length > 0 || line.rate > 0);
}

function decodeTimestamp(value?: FirestoreValue, fallback?: string): string {
  if (value?.timestampValue) {
    return value.timestampValue;
  }
  return fallback ?? new Date().toISOString();
}

function parseDocument(document: FirestoreDocument): InvoiceRecord | null {
  const fields = document.fields ?? {};
  const id = document.name.split('/').pop();
  if (!id) {
    return null;
  }

  const lines = decodeLines(fields.lines);
  const status = (decodeString(fields.status) || 'draft') as InvoiceDraft['status'];
  const draftBase: Omit<InvoiceRecord, 'id' | 'createdAt' | 'subtotal' | 'taxAmount' | 'total'> = {
    clientName: decodeString(fields.clientName),
    clientEmail: decodeString(fields.clientEmail),
    businessName: decodeString(fields.businessName),
    businessAddress: decodeString(fields.businessAddress),
    issueDate: decodeString(fields.issueDate),
    dueDate: decodeString(fields.dueDate),
    currency: decodeString(fields.currency) || 'USD',
    status,
    taxRate: decodeNumber(fields.taxRate),
    notes: decodeString(fields.notes),
    lines,
  };

  const subtotal = decodeNumber(fields.subtotal);
  const taxAmount = decodeNumber(fields.taxAmount);
  const total = decodeNumber(fields.total);
  const createdAt = decodeTimestamp(fields.createdAt, document.createTime);

  return {
    id,
    ...draftBase,
    subtotal,
    taxAmount,
    total,
    createdAt,
  };
}

export async function fetchRecentInvoices(limit = 6): Promise<InvoiceRecord[]> {
  if (!firebaseConfigured) {
    throw new Error('Firebase configuration is missing');
  }

  const body = {
    structuredQuery: {
      from: [{ collectionId: 'invoices' }],
      orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
      limit,
    },
  };

  const response = await fetch(withApiKey(runQueryUrl), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error(`Failed to load invoices: ${response.statusText}`);
  }

  const payload = await response.json();
  if (!Array.isArray(payload)) {
    return [];
  }

  const invoices: InvoiceRecord[] = [];
  for (const entry of payload) {
    const document = entry.document as FirestoreDocument | undefined;
    if (!document) continue;
    const parsed = parseDocument(document);
    if (parsed) {
      invoices.push(parsed);
    }
  }

  return invoices;
}

export interface SaveInvoiceOptions {
  draft: InvoiceDraft;
}

export async function saveInvoice({ draft }: SaveInvoiceOptions): Promise<InvoiceRecord> {
  if (!firebaseConfigured) {
    throw new Error('Firebase configuration is missing');
  }

  const cleanedLines = cleanLines(draft.lines);
  const totals = calculateTotals(cleanedLines, draft.taxRate);
  const createdAt = new Date().toISOString();
  const documentId = typeof crypto !== 'undefined' && 'randomUUID' in crypto ? crypto.randomUUID() : `invoice-${Date.now()}`;

  const fields: Record<string, FirestoreValue> = {
    clientName: buildString(draft.clientName.trim()),
    clientEmail: buildString(draft.clientEmail.trim()),
    businessName: buildString(draft.businessName.trim()),
    businessAddress: buildString(draft.businessAddress.trim()),
    issueDate: buildString(draft.issueDate),
    dueDate: buildString(draft.dueDate),
    currency: buildString(draft.currency),
    status: buildString(draft.status),
    taxRate: buildNumber(draft.taxRate),
    notes: buildString(draft.notes.trim()),
    subtotal: buildNumber(totals.subtotal),
    taxAmount: buildNumber(totals.taxAmount),
    total: buildNumber(totals.total),
    createdAt: { timestampValue: createdAt },
    lines: {
      arrayValue: {
        values: cleanedLines.map((line) => encodeLine(line)),
      },
    },
  };

  const response = await fetch(withApiKey(`${invoicesUrl}?documentId=${documentId}`), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });

  if (!response.ok) {
    throw new Error(`Failed to save invoice: ${response.statusText}`);
  }

  const payload = (await response.json()) as FirestoreDocument;
  const record = parseDocument(payload);
  if (record) {
    return record;
  }

  return {
    id: documentId,
    ...draft,
    lines: cleanedLines,
    subtotal: totals.subtotal,
    taxAmount: totals.taxAmount,
    total: totals.total,
    createdAt,
  };
}
