import { InvoiceDraft, InvoiceLine, formatCurrency } from './invoices';

type Totals = {
  subtotal: number;
  taxAmount: number;
  total: number;
};

type PdfLabels = {
  invoiceTitle: string;
  billTo: string;
  issueDate: string;
  dueDate: string;
  description: string;
  quantity: string;
  rate: string;
  amount: string;
  subtotal: string;
  tax: string;
  total: string;
  notes: string;
};

type PdfOptions = {
  draft: InvoiceDraft;
  totals: Totals;
  locale: string;
  currency: string;
  labels: PdfLabels;
};

function escapePdfText(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

function formatDisplayDate(value: string | undefined, locale: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  try {
    return new Intl.DateTimeFormat(locale, { year: 'numeric', month: 'short', day: 'numeric' }).format(parsed);
  } catch (error) {
    return value;
  }
}

function writeText(ops: string[], text: string, x: number, y: number, size = 12, font = 'F1'): void {
  if (!text) return;
  ops.push('BT');
  ops.push(`/${font} ${size} Tf`);
  ops.push(`1 0 0 1 ${x.toFixed(2)} ${y.toFixed(2)} Tm`);
  ops.push(`(${escapePdfText(text)}) Tj`);
  ops.push('ET');
}

function writeMultiline(
  ops: string[],
  lines: string[],
  x: number,
  startY: number,
  size = 10,
  font = 'F1',
  leading = 14,
): number {
  let y = startY;
  lines.forEach((line) => {
    if (line.trim().length > 0) {
      writeText(ops, line, x, y, size, font);
      y -= leading;
    }
  });
  return y;
}

function buildPdfStream(objects: string[]): Uint8Array {
  const encoder = new TextEncoder();
  const header = '%PDF-1.4\n';
  const chunks: Uint8Array[] = [encoder.encode(header)];
  const offsets: string[] = ['0000000000 65535 f \n'];
  let position = header.length;

  objects.forEach((object) => {
    const chunk = encoder.encode(`${object}\n`);
    offsets.push(`${String(position).padStart(10, '0')} 00000 n \n`);
    chunks.push(chunk);
    position += chunk.length;
  });

  const startxref = position;
  const xref = `xref\n0 ${objects.length + 1}\n${offsets.join('')}trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${startxref}\n%%EOF`;
  chunks.push(encoder.encode(xref));

  const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const pdfBytes = new Uint8Array(totalLength);
  let offset = 0;
  chunks.forEach((chunk) => {
    pdfBytes.set(chunk, offset);
    offset += chunk.length;
  });

  return pdfBytes;
}

function buildContentStream(draft: InvoiceDraft, totals: Totals, locale: string, currency: string, labels: PdfLabels): string {
  const ops: string[] = [];
  const pageWidth = 595.28;
  const pageHeight = 841.89;
  const margin = 56;

  let y = pageHeight - margin;
  writeText(ops, labels.invoiceTitle, margin, y, 22, 'F2');

  y -= 28;
  const businessName = draft.businessName.trim() || '—';
  writeText(ops, businessName, margin, y, 12, 'F2');

  y -= 16;
  const addressLines = draft.businessAddress ? draft.businessAddress.split(/\r?\n/) : [];
  if (addressLines.length > 0) {
    y = writeMultiline(ops, addressLines, margin, y, 10, 'F1');
  }

  const infoX = pageWidth - margin - 200;
  writeText(
    ops,
    `${labels.issueDate}: ${formatDisplayDate(draft.issueDate, locale)}`,
    infoX,
    pageHeight - margin - 8,
    10,
    'F1',
  );
  writeText(
    ops,
    `${labels.dueDate}: ${formatDisplayDate(draft.dueDate, locale)}`,
    infoX,
    pageHeight - margin - 24,
    10,
    'F1',
  );

  y = Math.min(y, pageHeight - margin - 90);
  writeText(ops, labels.billTo, margin, y, 12, 'F2');
  y -= 16;
  writeText(ops, draft.clientName.trim() || '—', margin, y, 11, 'F1');
  if (draft.clientEmail.trim()) {
    y -= 14;
    writeText(ops, draft.clientEmail.trim(), margin, y, 10, 'F1');
  }

  y -= 22;
  const headerY = y;
  writeText(ops, labels.description, margin, headerY, 10, 'F2');
  writeText(ops, labels.quantity, margin + 300, headerY, 10, 'F2');
  writeText(ops, labels.rate, margin + 380, headerY, 10, 'F2');
  writeText(ops, labels.amount, margin + 460, headerY, 10, 'F2');

  y = headerY - 18;
  const lines = draft.lines.length ? draft.lines : ([] as InvoiceLine[]);
  lines.forEach((line) => {
    const description = line.description.trim() || '—';
    const quantity = line.quantity.toFixed(2).replace(/\.00$/, '');
    const rate = formatCurrency(line.rate, currency, locale);
    const lineTotal = formatCurrency(line.quantity * line.rate, currency, locale);
    writeText(ops, description, margin, y, 10, 'F1');
    writeText(ops, quantity, margin + 300, y, 10, 'F1');
    writeText(ops, rate, margin + 380, y, 10, 'F1');
    writeText(ops, lineTotal, margin + 460, y, 10, 'F1');
    y -= 16;
  });

  y -= 12;
  writeText(ops, labels.subtotal, margin + 320, y, 10, 'F2');
  writeText(ops, formatCurrency(totals.subtotal, currency, locale), margin + 460, y, 10, 'F1');
  y -= 14;
  writeText(ops, labels.tax, margin + 320, y, 10, 'F2');
  writeText(ops, formatCurrency(totals.taxAmount, currency, locale), margin + 460, y, 10, 'F1');
  y -= 18;
  writeText(ops, labels.total, margin + 320, y, 12, 'F2');
  writeText(ops, formatCurrency(totals.total, currency, locale), margin + 460, y, 12, 'F2');

  if (draft.notes.trim()) {
    y -= 28;
    writeText(ops, labels.notes, margin, y, 11, 'F2');
    y -= 16;
    writeMultiline(ops, draft.notes.split(/\r?\n/), margin, y, 10, 'F1');
  }

  return ops.join('\n');
}

export function generateInvoicePdf({ draft, totals, locale, currency, labels }: PdfOptions): Blob {
  const content = buildContentStream(draft, totals, locale, currency, labels);
  const encoder = new TextEncoder();
  const contentBytes = encoder.encode(content);

  const pageWidth = 595.28;
  const pageHeight = 841.89;

  const objects: string[] = [
    '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj',
    '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj',
    `3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >> endobj`,
    `4 0 obj << /Length ${contentBytes.length} >> stream\n${content}\nendstream\nendobj`,
    '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj',
    '6 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj',
  ];

  const pdfBytes = buildPdfStream(objects);
  return new Blob([pdfBytes], { type: 'application/pdf' });
}
