import { InvoiceDraft, InvoiceLine, formatCurrency } from './invoices';
import { getInvoiceTemplate, type InvoiceTemplate, type TemplatePdfPalette, type RGB } from './templates';

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
  statusLabel: string;
  statusValue: string;
  currency: string;
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
  templateId: string;
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

function colorToPdf(color: RGB): string {
  return color.map((channel) => (channel / 255).toFixed(3)).join(' ');
}

function setFillColor(ops: string[], color: RGB): void {
  ops.push(`${colorToPdf(color)} rg`);
}

function setStrokeColor(ops: string[], color: RGB): void {
  ops.push(`${colorToPdf(color)} RG`);
}

function drawRect(ops: string[], x: number, y: number, width: number, height: number, color: RGB): void {
  ops.push('q');
  setFillColor(ops, color);
  ops.push(`${x.toFixed(2)} ${y.toFixed(2)} ${width.toFixed(2)} ${height.toFixed(2)} re`);
  ops.push('f');
  ops.push('Q');
}

function writeText(
  ops: string[],
  text: string,
  x: number,
  y: number,
  size = 12,
  font = 'F1',
  color?: RGB,
): void {
  if (!text) return;
  ops.push('BT');
  if (color) {
    setFillColor(ops, color);
  }
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
  color?: RGB,
): number {
  let y = startY;
  lines.forEach((line) => {
    if (line.trim().length > 0) {
      writeText(ops, line, x, y, size, font, color);
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

function buildContentStream(
  draft: InvoiceDraft,
  totals: Totals,
  locale: string,
  currency: string,
  labels: PdfLabels,
  template: InvoiceTemplate,
): string {
  const palette: TemplatePdfPalette = template.pdfPalette;
  const ops: string[] = [];
  const pageWidth = 595.28;
  const pageHeight = 841.89;
  const margin = 56;
  const contentWidth = pageWidth - margin * 2;
  const headerHeight = 96;
  const headerPadding = 18;
  const accentWidth = palette.accentBar ? 14 : 0;
  const headerY = pageHeight - margin - headerHeight;

  drawRect(ops, margin, headerY, contentWidth, headerHeight, palette.header);
  if (palette.accentBar) {
    drawRect(ops, pageWidth - margin - accentWidth, headerY, accentWidth, headerHeight, palette.accentBar);
  }

  const headerX = margin + headerPadding;
  let headerTextY = headerY + headerHeight - headerPadding;
  writeText(ops, labels.invoiceTitle, headerX, headerTextY, 20, 'F2', palette.headerText);
  headerTextY -= 22;

  const businessName = draft.businessName.trim() || '—';
  writeText(ops, businessName, headerX, headerTextY, 12, 'F2', palette.headerText);
  headerTextY -= 16;

  const addressLines = draft.businessAddress ? draft.businessAddress.split(/\r?\n/) : [];
  if (addressLines.length > 0) {
    headerTextY = writeMultiline(ops, addressLines, headerX, headerTextY, 10, 'F1', 13, palette.headerText) + 8;
  }

  const badgeWidth = 180;
  const badgeHeight = 72;
  const badgeX = pageWidth - margin - badgeWidth - (palette.accentBar ? accentWidth + 10 : 0);
  const badgeY = headerY + headerHeight - badgeHeight - headerPadding + 6;
  drawRect(ops, badgeX, badgeY, badgeWidth, badgeHeight, palette.badgeBackground);
  writeText(ops, labels.total, badgeX + 14, badgeY + badgeHeight - 18, 10, 'F1', palette.mutedText);
  writeText(ops, formatCurrency(totals.total, currency, locale), badgeX + 14, badgeY + badgeHeight - 38, 16, 'F2', palette.badgeText);
  const statusString = `${labels.statusLabel}: ${labels.statusValue}`;
  writeText(ops, statusString, badgeX + 14, badgeY + 16, 9, 'F1', palette.mutedText);

  writeText(
    ops,
    `${labels.issueDate}: ${formatDisplayDate(draft.issueDate, locale)}`,
    badgeX,
    headerY + 18,
    9,
    'F1',
    palette.headerText,
  );
  writeText(
    ops,
    `${labels.dueDate}: ${formatDisplayDate(draft.dueDate, locale)}`,
    badgeX,
    headerY + 4,
    9,
    'F1',
    palette.headerText,
  );

  let y = headerY - 28;
  writeText(ops, labels.billTo, margin, y, 11, 'F2', palette.bodyText);
  y -= 16;
  writeText(ops, draft.clientName.trim() || '—', margin, y, 11, 'F1', palette.bodyText);
  if (draft.clientEmail.trim()) {
    y -= 14;
    writeText(ops, draft.clientEmail.trim(), margin, y, 10, 'F1', palette.mutedText);
  }
  if (draft.clientAddress.trim()) {
    y -= 14;
    y = writeMultiline(ops, draft.clientAddress.split(/\r?\n/), margin, y, 10, 'F1', 13, palette.mutedText);
  }

  const metaColumnX = pageWidth - margin - 200;
  let metaY = headerY - 28;
  writeText(ops, labels.issueDate, metaColumnX, metaY, 9, 'F1', palette.mutedText);
  metaY -= 12;
  writeText(ops, formatDisplayDate(draft.issueDate, locale), metaColumnX, metaY, 10, 'F1', palette.bodyText);
  metaY -= 16;
  writeText(ops, labels.dueDate, metaColumnX, metaY, 9, 'F1', palette.mutedText);
  metaY -= 12;
  writeText(ops, formatDisplayDate(draft.dueDate, locale), metaColumnX, metaY, 10, 'F1', palette.bodyText);
  metaY -= 16;
  writeText(ops, labels.currency, metaColumnX, metaY, 9, 'F1', palette.mutedText);
  metaY -= 12;
  writeText(ops, draft.currency, metaColumnX, metaY, 10, 'F1', palette.bodyText);

  y -= 24;
  const tableHeaderY = y;
  drawRect(ops, margin, tableHeaderY, contentWidth, 24, palette.tableHeader);
  const descX = margin + 12;
  const qtyX = margin + 290;
  const rateX = margin + 360;
  const amountX = pageWidth - margin - 90;
  const headerBaseline = tableHeaderY + 16;
  writeText(ops, labels.description, descX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, labels.quantity, qtyX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, labels.rate, rateX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, labels.amount, amountX, headerBaseline, 10, 'F2', palette.tableHeaderText);

  let rowY = tableHeaderY - 8;
  const rowHeight = 20;
  const lines = draft.lines.length ? draft.lines : ([] as InvoiceLine[]);
  lines.forEach((line, index) => {
    const stripeY = rowY - rowHeight + 6;
    if (palette.tableStripe && index % 2 === 0) {
      drawRect(ops, margin, stripeY, contentWidth, rowHeight, palette.tableStripe);
    }
    const description = line.description.trim() || '—';
    const quantity = line.quantity.toFixed(2).replace(/\.00$/, '');
    const rate = formatCurrency(line.rate, currency, locale);
    const lineTotal = formatCurrency(line.quantity * line.rate, currency, locale);
    writeText(ops, description, descX, rowY, 10, 'F1', palette.bodyText);
    writeText(ops, quantity, qtyX, rowY, 10, 'F1', palette.bodyText);
    writeText(ops, rate, rateX, rowY, 10, 'F1', palette.bodyText);
    writeText(ops, lineTotal, amountX, rowY, 10, 'F1', palette.bodyText);
    rowY -= rowHeight;
  });

  rowY -= 8;
  drawRect(ops, margin, rowY + 6, contentWidth, 0.6, palette.border);

  const subtotalY = rowY - 6;
  writeText(ops, labels.subtotal, amountX - 110, subtotalY, 10, 'F1', palette.mutedText);
  writeText(ops, formatCurrency(totals.subtotal, currency, locale), amountX, subtotalY, 10, 'F1', palette.bodyText);

  const taxY = subtotalY - 16;
  writeText(ops, labels.tax, amountX - 110, taxY, 10, 'F1', palette.mutedText);
  writeText(ops, formatCurrency(totals.taxAmount, currency, locale), amountX, taxY, 10, 'F1', palette.bodyText);

  const totalY = taxY - 22;
  writeText(ops, labels.total, amountX - 110, totalY, 12, 'F2', palette.header);
  writeText(ops, formatCurrency(totals.total, currency, locale), amountX, totalY, 12, 'F2', palette.header);

  let notesY = totalY - 28;
  if (draft.notes.trim()) {
    const noteLines = draft.notes.split(/\r?\n/);
    const noteHeight = noteLines.length * 14 + 30;
    const notesBoxY = notesY - noteHeight + 10;
    drawRect(ops, margin, notesBoxY, contentWidth, noteHeight, palette.notesBackground);
    writeText(ops, labels.notes, margin + 12, notesBoxY + noteHeight - 20, 10, 'F2', palette.mutedText);
    writeMultiline(ops, noteLines, margin + 12, notesBoxY + noteHeight - 36, 10, 'F1', 14, palette.bodyText);
    notesY = notesBoxY - 16;
  }

  if (template.supportsJapanese) {
    const hankoSize = 70;
    const hankoX = pageWidth - margin - hankoSize;
    const hankoY = notesY - hankoSize - 16;
    const hankoFill: RGB = [255, 255, 255];
    drawRect(ops, hankoX, hankoY, hankoSize, hankoSize, hankoFill);
    setStrokeColor(ops, palette.border);
    ops.push('q');
    ops.push(`${hankoX.toFixed(2)} ${hankoY.toFixed(2)} ${hankoSize.toFixed(2)} ${hankoSize.toFixed(2)} re`);
    ops.push('S');
    ops.push('Q');
    writeText(ops, '印', hankoX + hankoSize / 2 - 8, hankoY + hankoSize / 2 + 6, 18, 'F2', palette.bodyText);
    writeText(ops, 'Authorised seal', hankoX + 4, hankoY - 8, 9, 'F1', palette.mutedText);
  }

  return ops.join('\n');
}

export function generateInvoicePdf({ draft, totals, locale, currency, labels, templateId }: PdfOptions): Blob {
  const template = getInvoiceTemplate(templateId);
  const content = buildContentStream(draft, totals, locale, currency, labels, template);
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
