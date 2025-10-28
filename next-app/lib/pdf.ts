import { InvoiceDraft, InvoiceLine, formatCurrency } from './invoices';
import { getInvoiceTemplate, type InvoiceTemplate, type TemplatePdfPalette } from './templates';

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

type PdfImageResource = {
  name: string;
  data: Uint8Array;
  width: number;
  height: number;
  displayWidth: number;
  displayHeight: number;
};

function escapePdfText(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

function encodePdfString(value: string): string {
  let isAscii = true;
  for (const char of value) {
    if (char.charCodeAt(0) > 0x7f) {
      isAscii = false;
      break;
    }
  }

  if (isAscii) {
    return `(${escapePdfText(value)})`;
  }

  const bytes: number[] = [0xfe, 0xff];
  for (const char of value) {
    const codePoint = char.codePointAt(0);
    if (codePoint === undefined) continue;
    if (codePoint <= 0xffff) {
      bytes.push((codePoint >> 8) & 0xff, codePoint & 0xff);
    } else {
      let remaining = codePoint - 0x10000;
      const high = 0xd800 + ((remaining >> 10) & 0x3ff);
      const low = 0xdc00 + (remaining & 0x3ff);
      bytes.push((high >> 8) & 0xff, high & 0xff, (low >> 8) & 0xff, low & 0xff);
    }
  }

  return `<${bytes.map((byte) => byte.toString(16).padStart(2, '0')).join('').toUpperCase()}>`;
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

function colorToPdf(color: [number, number, number]): string {
  return color.map((channel) => (channel / 255).toFixed(3)).join(' ');
}

function setFillColor(ops: string[], color: [number, number, number]): void {
  ops.push(`${colorToPdf(color)} rg`);
}

function setStrokeColor(ops: string[], color: [number, number, number]): void {
  ops.push(`${colorToPdf(color)} RG`);
}

function drawRect(ops: string[], x: number, y: number, width: number, height: number, color: [number, number, number]): void {
  ops.push('q');
  setFillColor(ops, color);
  ops.push(`${x.toFixed(2)} ${y.toFixed(2)} ${width.toFixed(2)} ${height.toFixed(2)} re`);
  ops.push('f');
  ops.push('Q');
}

function strokeRect(
  ops: string[],
  x: number,
  y: number,
  width: number,
  height: number,
  color: [number, number, number],
  strokeWidth = 0.6,
): void {
  ops.push('q');
  setStrokeColor(ops, color);
  ops.push(`${strokeWidth.toFixed(2)} w`);
  ops.push(`${x.toFixed(2)} ${y.toFixed(2)} ${width.toFixed(2)} ${height.toFixed(2)} re`);
  ops.push('S');
  ops.push('Q');
}

function drawLine(
  ops: string[],
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  color: [number, number, number],
  width = 0.6,
): void {
  ops.push('q');
  setStrokeColor(ops, color);
  ops.push(`${width.toFixed(2)} w`);
  ops.push(`${x1.toFixed(2)} ${y1.toFixed(2)} m`);
  ops.push(`${x2.toFixed(2)} ${y2.toFixed(2)} l`);
  ops.push('S');
  ops.push('Q');
}

function writeText(
  ops: string[],
  text: string,
  x: number,
  y: number,
  size = 12,
  font = 'F1',
  color?: [number, number, number],
): void {
  if (!text) return;
  ops.push('BT');
  if (color) {
    setFillColor(ops, color);
  }
  ops.push(`/${font} ${size} Tf`);
  ops.push(`1 0 0 1 ${x.toFixed(2)} ${y.toFixed(2)} Tm`);
  ops.push(`${encodePdfString(text)} Tj`);
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
  color?: [number, number, number],
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

function decodeDataUrl(dataUrl: string | undefined): { mime: string; data: Uint8Array } | null {
  if (!dataUrl) return null;
  const match = /^data:(?<mime>[^;]+);base64,(?<data>.+)$/u.exec(dataUrl.trim());
  if (!match?.groups) {
    return null;
  }
  const { mime, data } = match.groups;
  try {
    let binary: string;
    if (typeof atob === 'function') {
      binary = atob(data);
    } else if (typeof Buffer !== 'undefined') {
      binary = Buffer.from(data, 'base64').toString('binary');
    } else {
      throw new Error('No base64 decoder available');
    }
    const buffer = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i += 1) {
      buffer[i] = binary.charCodeAt(i);
    }
    return { mime, data: buffer };
  } catch (error) {
    console.error('Failed to decode image data url', error);
    return null;
  }
}

function parseJpegDimensions(bytes: Uint8Array): { width: number; height: number } | null {
  let index = 0;
  while (index + 9 < bytes.length) {
    if (bytes[index] === 0xff) {
      const marker = bytes[index + 1];
      const isStartOfFrame = marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc;
      if (isStartOfFrame) {
        const height = (bytes[index + 5] << 8) + bytes[index + 6];
        const width = (bytes[index + 7] << 8) + bytes[index + 8];
        if (width > 0 && height > 0) {
          return { width, height };
        }
        return null;
      }
      if (marker === 0xd9 || marker === 0xda) {
        break;
      }
      const length = (bytes[index + 2] << 8) + bytes[index + 3];
      index += length + 2;
    } else {
      index += 1;
    }
  }
  return null;
}

function prepareImageResource(name: string, dataUrl: string | undefined, maxDimension = 120): PdfImageResource | null {
  const decoded = decodeDataUrl(dataUrl);
  if (!decoded) return null;
  if (!decoded.mime.includes('jpeg') && !decoded.mime.includes('jpg')) {
    console.warn('Skipping non-JPEG image asset');
    return null;
  }
  const size = parseJpegDimensions(decoded.data);
  if (!size) {
    console.warn('Unable to parse JPEG dimensions');
    return null;
  }
  const scale = Math.min(1, maxDimension / Math.max(size.width, size.height));
  const displayWidth = Math.max(24, Math.round(size.width * scale));
  const displayHeight = Math.max(24, Math.round(size.height * scale));
  return {
    name,
    data: decoded.data,
    width: size.width,
    height: size.height,
    displayWidth,
    displayHeight,
  };
}

type ContentResult = {
  content: string;
  images: PdfImageResource[];
};

function renderTotals(
  ops: string[],
  structure: InvoiceTemplate['structure'],
  palette: TemplatePdfPalette,
  totals: Totals,
  labels: PdfLabels,
  currency: string,
  locale: string,
  margin: number,
  contentWidth: number,
  startY: number,
  pageWidth: number,
): number {
  const formattedSubtotal = formatCurrency(totals.subtotal, currency, locale);
  const formattedTax = formatCurrency(totals.taxAmount, currency, locale);
  const formattedTotal = formatCurrency(totals.total, currency, locale);

  const labelColor = palette.mutedText;
  const valueColor = palette.bodyText;
  const strongColor = palette.header;

  const amountX = pageWidth - margin - 28;
  const labelX = amountX - 135;

  switch (structure.totalsStyle) {
    case 'table': {
      const tableWidth = 260;
      const tableHeight = 84;
      const tableX = margin + contentWidth - tableWidth;
      const tableY = startY - tableHeight;
      drawRect(ops, tableX, tableY, tableWidth, tableHeight, palette.notesBackground);
      strokeRect(ops, tableX, tableY, tableWidth, tableHeight, palette.border, 0.8);
      drawLine(ops, tableX, tableY + tableHeight - 28, tableX + tableWidth, tableY + tableHeight - 28, palette.border, 0.6);
      drawLine(ops, tableX, tableY + tableHeight - 56, tableX + tableWidth, tableY + tableHeight - 56, palette.border, 0.6);
      writeText(ops, labels.subtotal, tableX + 16, tableY + tableHeight - 10, 10, 'F1', labelColor);
      writeText(ops, formattedSubtotal, tableX + tableWidth - 16, tableY + tableHeight - 10, 10, 'F1', valueColor);
      writeText(ops, labels.tax, tableX + 16, tableY + tableHeight - 38, 10, 'F1', labelColor);
      writeText(ops, formattedTax, tableX + tableWidth - 16, tableY + tableHeight - 38, 10, 'F1', valueColor);
      writeText(ops, labels.total, tableX + 16, tableY + 20, 12, 'F2', strongColor);
      writeText(ops, formattedTotal, tableX + tableWidth - 16, tableY + 20, 12, 'F2', strongColor);
      return tableY - 18;
    }
    case 'underline': {
      const subtotalY = startY - 6;
      writeText(ops, labels.subtotal, labelX, subtotalY, 10, 'F1', labelColor);
      writeText(ops, formattedSubtotal, amountX, subtotalY, 10, 'F1', valueColor);
      const taxY = subtotalY - 16;
      writeText(ops, labels.tax, labelX, taxY, 10, 'F1', labelColor);
      writeText(ops, formattedTax, amountX, taxY, 10, 'F1', valueColor);
      const totalY = taxY - 22;
      drawLine(ops, labelX, totalY + 12, amountX + 40, totalY + 12, palette.border, 0.8);
      writeText(ops, labels.total, labelX, totalY, 12, 'F2', strongColor);
      writeText(ops, formattedTotal, amountX, totalY, 12, 'F2', strongColor);
      return totalY - 20;
    }
    case 'side-panel': {
      const panelWidth = 220;
      const panelHeight = 120;
      const panelX = margin + contentWidth - panelWidth;
      const panelY = startY - panelHeight;
      drawRect(ops, panelX, panelY, panelWidth, panelHeight, palette.notesBackground);
      strokeRect(ops, panelX, panelY, panelWidth, panelHeight, palette.border, 0.8);
      let cursorY = panelY + panelHeight - 20;
      writeText(ops, labels.subtotal, panelX + 16, cursorY, 10, 'F1', labelColor);
      writeText(ops, formattedSubtotal, panelX + panelWidth - 16, cursorY, 10, 'F1', valueColor);
      cursorY -= 20;
      writeText(ops, labels.tax, panelX + 16, cursorY, 10, 'F1', labelColor);
      writeText(ops, formattedTax, panelX + panelWidth - 16, cursorY, 10, 'F1', valueColor);
      cursorY -= 28;
      drawRect(ops, panelX + 12, cursorY - 10, panelWidth - 24, 36, palette.badgeBackground);
      writeText(ops, labels.total, panelX + 20, cursorY + 6, 12, 'F2', strongColor);
      writeText(ops, formattedTotal, panelX + panelWidth - 20, cursorY + 6, 12, 'F2', strongColor);
      return panelY - 24;
    }
    case 'badge': {
      const badgeWidth = 200;
      const badgeHeight = 60;
      const badgeX = margin + contentWidth - badgeWidth;
      const badgeY = startY - badgeHeight;
      drawRect(ops, badgeX, badgeY, badgeWidth, badgeHeight, palette.badgeBackground);
      writeText(ops, labels.total, badgeX + 16, badgeY + badgeHeight - 18, 10, 'F1', labelColor);
      writeText(ops, formattedTotal, badgeX + 16, badgeY + badgeHeight - 34, 16, 'F2', strongColor);
      const detailY = badgeY - 16;
      writeText(ops, `${labels.subtotal}: ${formattedSubtotal}`, badgeX, detailY, 9, 'F1', labelColor);
      writeText(ops, `${labels.tax}: ${formattedTax}`, badgeX, detailY - 14, 9, 'F1', labelColor);
      return detailY - 26;
    }
    case 'stacked': {
      const rowHeight = 36;
      const rowWidth = 260;
      const panelX = margin + contentWidth - rowWidth;
      let cursorY = startY;
      const rows: Array<{ label: string; value: string; emphasize?: boolean }> = [
        { label: labels.subtotal, value: formattedSubtotal },
        { label: labels.tax, value: formattedTax },
        { label: labels.total, value: formattedTotal, emphasize: true },
      ];
      rows.forEach((row, index) => {
        const top = cursorY - rowHeight;
        const background = row.emphasize
          ? palette.badgeBackground
          : index % 2 === 0
            ? palette.notesBackground
            : palette.tableStripe ?? palette.notesBackground;
        drawRect(ops, panelX, top, rowWidth, rowHeight, background);
        if (!row.emphasize) {
          strokeRect(ops, panelX, top, rowWidth, rowHeight, palette.border, 0.5);
        }
        writeText(ops, row.label, panelX + 16, top + rowHeight - 12, 10, 'F1', row.emphasize ? strongColor : labelColor);
        writeText(ops, row.value, panelX + rowWidth - 16, top + rowHeight - 12, 11, row.emphasize ? 'F2' : 'F1', strongColor);
        cursorY = top - 8;
      });
      return cursorY - 12;
    }
    case 'japanese': {
      const summaryHeight = 96;
      const summaryY = startY - summaryHeight;
      drawRect(ops, margin, summaryY, contentWidth, summaryHeight, palette.notesBackground);
      strokeRect(ops, margin, summaryY, contentWidth, summaryHeight, palette.border, 0.8);
      const leftX = margin + 16;
      const rightX = margin + contentWidth - 16;
      writeText(ops, labels.subtotal, leftX, summaryY + summaryHeight - 14, 11, 'F1', labelColor);
      writeText(ops, formattedSubtotal, rightX, summaryY + summaryHeight - 14, 11, 'F1', valueColor);
      writeText(ops, labels.tax, leftX, summaryY + summaryHeight - 36, 11, 'F1', labelColor);
      writeText(ops, formattedTax, rightX, summaryY + summaryHeight - 36, 11, 'F1', valueColor);
      drawLine(ops, margin + 12, summaryY + 30, margin + contentWidth - 12, summaryY + 30, palette.border, 0.8);
      writeText(ops, labels.total, leftX, summaryY + 20, 13, 'F2', strongColor);
      writeText(ops, formattedTotal, rightX, summaryY + 20, 13, 'F2', strongColor);
      return summaryY - 28;
    }
    default: {
      const boxWidth = 240;
      const boxHeight = 72;
      const boxX = margin + contentWidth - boxWidth;
      const boxY = startY - boxHeight;
      drawRect(ops, boxX, boxY, boxWidth, boxHeight, palette.notesBackground);
      writeText(ops, labels.subtotal, boxX + 16, boxY + boxHeight - 16, 10, 'F1', labelColor);
      writeText(ops, formattedSubtotal, boxX + boxWidth - 16, boxY + boxHeight - 16, 10, 'F1', valueColor);
      writeText(ops, labels.tax, boxX + 16, boxY + boxHeight - 32, 10, 'F1', labelColor);
      writeText(ops, formattedTax, boxX + boxWidth - 16, boxY + boxHeight - 32, 10, 'F1', valueColor);
      writeText(ops, labels.total, boxX + 16, boxY + 20, 12, 'F2', strongColor);
      writeText(ops, formattedTotal, boxX + boxWidth - 16, boxY + 20, 12, 'F2', strongColor);
      return boxY - 24;
    }
  }
}

function buildContentStream(
  draft: InvoiceDraft,
  totals: Totals,
  locale: string,
  currency: string,
  labels: PdfLabels,
  template: InvoiceTemplate,
  logoImage?: PdfImageResource | null,
  sealImage?: PdfImageResource | null,
): ContentResult {
  const palette: TemplatePdfPalette = template.pdfPalette;
  const structure = template.structure;
  const resolvedLabels: PdfLabels = { ...labels, ...(structure.labelOverrides ?? {}) };
  const ops: string[] = [];
  const images: PdfImageResource[] = [];
  const pageWidth = 595.28;
  const pageHeight = 841.89;
  const margin = 56;
  const contentWidth = pageWidth - margin * 2;
  const headerHeight =
    structure.headerLayout === 'japanese'
      ? 148
      : structure.headerLayout === 'standard'
        ? 128
        : 100;
  const headerPadding = 18;
  const accentWidth = palette.accentBar ? 14 : 0;
  const headerY = pageHeight - margin - headerHeight;

  drawRect(ops, margin, headerY, contentWidth, headerHeight, palette.header);
  if (palette.accentBar) {
    drawRect(ops, pageWidth - margin - accentWidth, headerY, accentWidth, headerHeight, palette.accentBar);
  }

  const headerX = margin + headerPadding;
  let headerTextY = headerY + headerHeight - headerPadding;
  const invoiceLabel = resolvedLabels.invoiceTitle;
  writeText(ops, invoiceLabel, headerX, headerTextY, structure.headerLayout === 'standard' ? 22 : 20, 'F2', palette.headerText);
  headerTextY -= structure.headerLayout === 'standard' ? 26 : 22;

  const businessName = draft.businessName.trim() || '—';
  writeText(ops, businessName, headerX, headerTextY, 13, 'F2', palette.headerText);
  headerTextY -= 18;

  const addressLines = draft.businessAddress ? draft.businessAddress.split(/\r?\n/) : [];
  if (addressLines.length > 0) {
    headerTextY = writeMultiline(ops, addressLines, headerX, headerTextY, 10, 'F1', 13, palette.headerText) + 8;
  }

  if (structure.headerLayout === 'standard' && template.tagline) {
    writeText(ops, template.tagline, headerX, headerY + 18, 10, 'F1', palette.headerText);
  }

  const badgeWidth = structure.headerLayout === 'standard' ? 210 : 190;
  const badgeHeight = structure.headerLayout === 'japanese' ? 64 : 72;
  const gapBetweenLogoAndBadge = logoImage ? 10 : 0;
  const asideRight = pageWidth - margin - (palette.accentBar ? accentWidth + 10 : 0);
  const badgeX = asideRight - badgeWidth;
  const badgeY =
    structure.headerLayout === 'japanese'
      ? headerY + headerHeight - badgeHeight - 20
      : headerY + headerHeight - badgeHeight - headerPadding + 6;

  if (logoImage) {
    const logoX = badgeX - logoImage.displayWidth - gapBetweenLogoAndBadge;
    const logoY = headerY + headerHeight - logoImage.displayHeight - headerPadding;
    ops.push('q');
    ops.push(`${logoImage.displayWidth.toFixed(2)} 0 0 ${logoImage.displayHeight.toFixed(2)} ${logoX.toFixed(2)} ${logoY.toFixed(2)} cm`);
    ops.push(`/${logoImage.name} Do`);
    ops.push('Q');
    images.push({ ...logoImage });
  }

  drawRect(ops, badgeX, badgeY, badgeWidth, badgeHeight, palette.badgeBackground);
  writeText(ops, resolvedLabels.total, badgeX + 14, badgeY + badgeHeight - 20, 10, 'F1', palette.mutedText);
  writeText(ops, formatCurrency(totals.total, currency, locale), badgeX + 14, badgeY + badgeHeight - 36, 16, 'F2', palette.badgeText);
  const statusString = `${resolvedLabels.statusLabel}: ${resolvedLabels.statusValue}`;
  writeText(ops, statusString, badgeX + 14, badgeY + 16, 9, 'F1', palette.mutedText);

  const metaBoxY = badgeY - 34;
  writeText(
    ops,
    `${resolvedLabels.issueDate}: ${formatDisplayDate(draft.issueDate, locale)}`,
    badgeX,
    metaBoxY,
    9,
    'F1',
    palette.headerText,
  );
  writeText(
    ops,
    `${resolvedLabels.dueDate}: ${formatDisplayDate(draft.dueDate, locale)}`,
    badgeX,
    metaBoxY - 14,
    9,
    'F1',
    palette.headerText,
  );

  let y = headerY - 28;
  const clientColumnX = margin;
  const businessColumnX = structure.infoLayout === 'split' ? margin + contentWidth / 2 : pageWidth - margin - 220;

  writeText(ops, resolvedLabels.billTo, clientColumnX, y, 11, 'F2', palette.bodyText);
  y -= 16;
  writeText(ops, draft.clientName.trim() || '—', clientColumnX, y, 11, 'F1', palette.bodyText);
  if (draft.clientEmail.trim()) {
    y -= 14;
    writeText(ops, draft.clientEmail.trim(), clientColumnX, y, 10, 'F1', palette.mutedText);
  }
  if (draft.clientAddress.trim()) {
    y -= 14;
    y = writeMultiline(ops, draft.clientAddress.split(/\r?\n/), clientColumnX, y, 10, 'F1', 13, palette.mutedText) + 8;
  }

  let businessInfoY = headerY - 28;
  if (structure.infoLayout === 'split') {
    writeText(ops, resolvedLabels.currency, businessColumnX, businessInfoY, 9, 'F1', palette.mutedText);
    businessInfoY -= 12;
    writeText(ops, draft.currency, businessColumnX, businessInfoY, 10, 'F1', palette.bodyText);
    businessInfoY -= 18;
    writeText(ops, resolvedLabels.issueDate, businessColumnX, businessInfoY, 9, 'F1', palette.mutedText);
    businessInfoY -= 12;
    writeText(ops, formatDisplayDate(draft.issueDate, locale), businessColumnX, businessInfoY, 10, 'F1', palette.bodyText);
    businessInfoY -= 18;
    writeText(ops, resolvedLabels.dueDate, businessColumnX, businessInfoY, 9, 'F1', palette.mutedText);
    businessInfoY -= 12;
    writeText(ops, formatDisplayDate(draft.dueDate, locale), businessColumnX, businessInfoY, 10, 'F1', palette.bodyText);
    businessInfoY -= 18;
    writeText(ops, draft.businessName.trim() || '—', businessColumnX, businessInfoY, 11, 'F2', palette.bodyText);
    if (draft.businessAddress.trim()) {
      businessInfoY -= 14;
      businessInfoY = writeMultiline(
        ops,
        draft.businessAddress.split(/\r?\n/),
        businessColumnX,
        businessInfoY,
        10,
        'F1',
        13,
        palette.mutedText,
      ) + 8;
    }
  } else if (structure.infoLayout === 'japanese') {
    const issueBlockY = y - 12;
    writeText(ops, resolvedLabels.issueDate, businessColumnX, issueBlockY, 10, 'F1', palette.mutedText);
    writeText(ops, formatDisplayDate(draft.issueDate, locale), businessColumnX + 110, issueBlockY, 10, 'F1', palette.bodyText);
    writeText(ops, resolvedLabels.dueDate, businessColumnX, issueBlockY - 16, 10, 'F1', palette.mutedText);
    writeText(ops, formatDisplayDate(draft.dueDate, locale), businessColumnX + 110, issueBlockY - 16, 10, 'F1', palette.bodyText);
    writeText(ops, resolvedLabels.currency, businessColumnX, issueBlockY - 32, 10, 'F1', palette.mutedText);
    writeText(ops, draft.currency, businessColumnX + 110, issueBlockY - 32, 10, 'F1', palette.bodyText);
    businessInfoY = issueBlockY - 48;
    y = issueBlockY - 48;
  } else {
    let metaY = headerY - 28;
    writeText(ops, resolvedLabels.issueDate, businessColumnX, metaY, 9, 'F1', palette.mutedText);
    metaY -= 12;
    writeText(ops, formatDisplayDate(draft.issueDate, locale), businessColumnX, metaY, 10, 'F1', palette.bodyText);
    metaY -= 16;
    writeText(ops, resolvedLabels.dueDate, businessColumnX, metaY, 9, 'F1', palette.mutedText);
    metaY -= 12;
    writeText(ops, formatDisplayDate(draft.dueDate, locale), businessColumnX, metaY, 10, 'F1', palette.bodyText);
    metaY -= 16;
    writeText(ops, resolvedLabels.currency, businessColumnX, metaY, 9, 'F1', palette.mutedText);
    metaY -= 12;
    writeText(ops, draft.currency, businessColumnX, metaY, 10, 'F1', palette.bodyText);
  }

  const tableTopY = Math.min(y, businessInfoY) - 24;
  const tableHeaderY = tableTopY;
  drawRect(ops, margin, tableHeaderY, contentWidth, 24, palette.tableHeader);
  const isJapaneseLayout = structure.lineItemStyle === 'japanese' || structure.infoLayout === 'japanese';
  const descX = margin + 12;
  const qtyX = margin + (isJapaneseLayout ? 260 : 290);
  const rateX = margin + (isJapaneseLayout ? 330 : 360);
  const amountX = pageWidth - margin - (isJapaneseLayout ? 80 : 90);
  const headerBaseline = tableHeaderY + 16;
  const columnLabels: {
    description: string;
    quantity: string;
    rate: string;
    amount: string;
    descriptionSecondary?: string;
  } = {
    description: resolvedLabels.description,
    quantity: resolvedLabels.quantity,
    rate: resolvedLabels.rate,
    amount: resolvedLabels.amount,
    ...(structure.columnLabels ?? {}),
  };
  writeText(ops, columnLabels.description, descX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, columnLabels.quantity, qtyX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, columnLabels.rate, rateX, headerBaseline, 10, 'F2', palette.tableHeaderText);
  writeText(ops, columnLabels.amount, amountX, headerBaseline, 10, 'F2', palette.tableHeaderText);

  let rowY = tableHeaderY - 8;
  const rowHeight = 22;
  const lines = draft.lines.length ? draft.lines : ([] as InvoiceLine[]);
  const useStriping = ['striped', 'striped-light', 'japanese'].includes(structure.lineItemStyle);
  lines.forEach((line, index) => {
    const rowTop = rowY - rowHeight + 8;
    if (useStriping && palette.tableStripe && index % 2 === 0) {
      drawRect(ops, margin, rowTop, contentWidth, rowHeight, palette.tableStripe);
    }
    if (structure.lineItemStyle === 'outlined') {
      strokeRect(ops, margin, rowTop, contentWidth, rowHeight, palette.border, 0.5);
      drawLine(ops, qtyX - 16, rowTop, qtyX - 16, rowTop + rowHeight, palette.border, 0.4);
      drawLine(ops, rateX - 16, rowTop, rateX - 16, rowTop + rowHeight, palette.border, 0.4);
    }
    if (structure.lineItemStyle === 'ledger') {
      drawLine(ops, margin, rowTop, margin + contentWidth, rowTop, palette.border, 0.6);
    }
    const description = line.description.trim() || '—';
    const quantity = line.quantity.toFixed(2).replace(/\.00$/, '');
    const rate = formatCurrency(line.rate, currency, locale);
    const lineTotal = formatCurrency(line.quantity * line.rate, currency, locale);
    writeText(ops, description, descX, rowY, 10, 'F1', palette.bodyText);
    if (columnLabels.descriptionSecondary) {
      writeText(ops, columnLabels.descriptionSecondary, descX, rowY - 11, 7, 'F1', palette.mutedText);
    }
    writeText(ops, quantity, qtyX, rowY, 10, 'F1', palette.bodyText);
    writeText(ops, rate, rateX, rowY, 10, 'F1', palette.bodyText);
    writeText(ops, lineTotal, amountX, rowY, 10, 'F1', palette.bodyText);
    if (structure.lineItemStyle === 'separated') {
      drawLine(ops, margin, rowTop, margin + contentWidth, rowTop, palette.border, 0.4);
    }
    rowY -= rowHeight;
  });

  rowY -= 10;
  if (structure.lineItemStyle !== 'ledger' && structure.lineItemStyle !== 'outlined') {
    drawRect(ops, margin, rowY + 8, contentWidth, 0.6, palette.border);
  }

  const totalsStartY = rowY - 10;
  let notesY = renderTotals(
    ops,
    structure,
    palette,
    totals,
    resolvedLabels,
    currency,
    locale,
    margin,
    contentWidth,
    totalsStartY,
    pageWidth,
  );

  if (draft.notes.trim()) {
    const noteLines = draft.notes.split(/\r?\n/);
    const noteHeight = noteLines.length * 14 + 30;
    const notesBoxY = notesY - noteHeight + 10;
    drawRect(ops, margin, notesBoxY, contentWidth, noteHeight, palette.notesBackground);
    writeText(ops, resolvedLabels.notes, margin + 12, notesBoxY + noteHeight - 20, 10, 'F2', palette.mutedText);
    writeMultiline(ops, noteLines, margin + 12, notesBoxY + noteHeight - 36, 10, 'F1', 14, palette.bodyText);
    notesY = notesBoxY - 18;
  }

  if (structure.showPaymentDetails && structure.paymentDetailsLabel && structure.paymentDetailsValue) {
    const paymentBoxHeight = 52;
    const paymentY = notesY;
    drawRect(ops, margin, paymentY - paymentBoxHeight, contentWidth, paymentBoxHeight, palette.tableStripe ?? palette.notesBackground);
    writeText(ops, structure.paymentDetailsLabel, margin + 12, paymentY - 14, 10, 'F2', palette.mutedText);
    writeText(ops, structure.paymentDetailsValue, margin + 12, paymentY - 30, 11, 'F1', palette.bodyText);
    notesY = paymentY - paymentBoxHeight - 18;
  }

  if (structure.showThankYou && structure.thankYouLabel) {
    writeText(ops, structure.thankYouLabel, margin, notesY, 11, 'F2', palette.mutedText);
    notesY -= 24;
  }

  if (template.supportsJapanese) {
    const hankoSize = 70;
    const hankoX = pageWidth - margin - hankoSize;
    const hankoY = notesY - hankoSize - 10;
    if (sealImage) {
      ops.push('q');
      ops.push(`${sealImage.displayWidth.toFixed(2)} 0 0 ${sealImage.displayHeight.toFixed(2)} ${(
        hankoX + (hankoSize - sealImage.displayWidth) / 2
      ).toFixed(2)} ${(
        hankoY + (hankoSize - sealImage.displayHeight) / 2
      ).toFixed(2)} cm`);
      ops.push(`/${sealImage.name} Do`);
      ops.push('Q');
      images.push({ ...sealImage });
      strokeRect(ops, hankoX, hankoY, hankoSize, hankoSize, palette.border, 0.8);
    } else {
      drawRect(ops, hankoX, hankoY, hankoSize, hankoSize, [255, 255, 255]);
      strokeRect(ops, hankoX, hankoY, hankoSize, hankoSize, palette.border, 0.8);
      writeText(ops, '印', hankoX + hankoSize / 2 - 8, hankoY + hankoSize / 2 + 6, 18, 'F2', palette.bodyText);
    }
    writeText(ops, 'Authorised seal', hankoX + 4, hankoY - 8, 9, 'F1', palette.mutedText);
  } else if (sealImage) {
    const sealSize = 64;
    const sealX = pageWidth - margin - sealSize;
    const sealY = notesY - sealSize - 12;
    ops.push('q');
    ops.push(`${sealImage.displayWidth.toFixed(2)} 0 0 ${sealImage.displayHeight.toFixed(2)} ${(
      sealX + (sealSize - sealImage.displayWidth) / 2
    ).toFixed(2)} ${(
      sealY + (sealSize - sealImage.displayHeight) / 2
    ).toFixed(2)} cm`);
    ops.push(`/${sealImage.name} Do`);
    ops.push('Q');
    images.push({ ...sealImage });
  }

  return { content: ops.join('\n'), images };
}

function createImageObject(objectNumber: number, image: PdfImageResource): string {
  const stream = Array.from(image.data)
    .map((byte) => String.fromCharCode(byte))
    .join('');
  const encoded = `<< /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${image.data.length} >>\nstream\n${stream}\nendstream`;
  return `${objectNumber} 0 obj ${encoded} endobj`;
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

export function generateInvoicePdf({ draft, totals, locale, currency, labels, templateId }: PdfOptions): Blob {
  const template = getInvoiceTemplate(templateId);
  const logo = prepareImageResource('ImLogo', draft.businessLogo, 110);
  const seal = prepareImageResource('ImSeal', draft.businessSeal, template.supportsJapanese ? 70 : 64);
  const { content, images } = buildContentStream(draft, totals, locale, currency, labels, template, logo, seal);
  const encoder = new TextEncoder();
  const contentBytes = encoder.encode(content);

  const pageWidth = 595.28;
  const pageHeight = 841.89;

  const objects: string[] = [];
  objects.push('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  objects.push('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');

  let resourceDictionary = '/Font << /F1 5 0 R /F2 6 0 R >>';
  if (images.length > 0) {
    const xObjectEntries = images
      .map((image, index) => `/${image.name} ${7 + index} 0 R`)
      .join(' ');
    resourceDictionary += ` /XObject << ${xObjectEntries} >>`;
  }

  objects.push(
    `3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Contents 4 0 R /Resources << ${resourceDictionary} >> >> endobj`,
  );
  objects.push(`4 0 obj << /Length ${contentBytes.length} >> stream\n${content}\nendstream\nendobj`);
  objects.push('5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
  objects.push('6 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj');

  images.forEach((image, index) => {
    objects.push(createImageObject(7 + index, image));
  });

  const pdfBytes = buildPdfStream(objects);
  return new Blob([pdfBytes], { type: 'application/pdf' });
}
