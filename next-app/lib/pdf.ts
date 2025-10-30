'use client';

import { formatFriendlyDate } from './format';
import { InvoiceDraft, InvoiceStatus, formatCurrency } from './invoices';
import { InvoiceTemplate } from './templates';

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

type GenerateInvoicePdfOptions = {
  draft: InvoiceDraft;
  totals: Totals;
  template: InvoiceTemplate;
  locale: string;
  currency: string;
  statusLookup: Map<InvoiceStatus, string>;
  translate: TranslateFn;
};

type RGBTuple = [number, number, number];

type PdfMakeStatic = {
  vfs: Record<string, string>;
  fonts: Record<string, { normal: string; bold: string; italics: string; bolditalics: string }>;
  createPdf: (definition: unknown) => {
    getBlob: (callback: (blob: Blob) => void) => void;
  };
};

const FONT_SOURCES = {
  regular: [
    '/fonts/NotoSansJP-Regular.otf',
    'https://fonts.gstatic.com/ea/notosansjp/v5/NotoSansJP-Regular.otf',
  ],
  bold: [
    '/fonts/NotoSansJP-Bold.otf',
    'https://fonts.gstatic.com/ea/notosansjp/v5/NotoSansJP-Bold.otf',
  ],
} as const;

let pdfMakePromise: Promise<PdfMakeStatic> | null = null;
const fontCache = new Map<string, string>();

function rgbToHex(tuple: RGBTuple | undefined, fallback = '#000000'): string {
  if (!tuple) {
    return fallback;
  }
  return `#${tuple.map((component) => component.toString(16).padStart(2, '0')).join('')}`;
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = '';
  const bytes = new Uint8Array(buffer);
  const chunkSize = 0x8000;
  for (let index = 0; index < bytes.length; index += chunkSize) {
    const chunk = bytes.subarray(index, index + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
}

async function fetchFontBase64(url: string): Promise<string | null> {
  try {
    const response = await fetch(url, { mode: 'cors' });
    if (!response.ok) {
      return null;
    }
    const buffer = await response.arrayBuffer();
    return arrayBufferToBase64(buffer);
  } catch (error) {
    console.warn(`Unable to load font from ${url}`, error);
    return null;
  }
}

async function loadFontFromSources(sources: readonly string[]): Promise<string> {
  for (const source of sources) {
    const cached = fontCache.get(source);
    if (cached) {
      return cached;
    }
    const data = await fetchFontBase64(source);
    if (data) {
      fontCache.set(source, data);
      return data;
    }
  }
  throw new Error('Failed to load font data for PDF generation.');
}

async function loadPdfMake(): Promise<PdfMakeStatic> {
  if (pdfMakePromise) {
    return pdfMakePromise;
  }
  if (typeof window === 'undefined') {
    throw new Error('PDF generation is only available in the browser.');
  }
  pdfMakePromise = new Promise((resolve, reject) => {
    if ((window as typeof window & { pdfMake?: PdfMakeStatic }).pdfMake) {
      resolve((window as typeof window & { pdfMake?: PdfMakeStatic }).pdfMake as PdfMakeStatic);
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/pdfmake@0.2.10/build/pdfmake.min.js';
    script.async = true;
    script.onload = () => {
      const pdfMake = (window as typeof window & { pdfMake?: PdfMakeStatic }).pdfMake;
      if (!pdfMake) {
        reject(new Error('pdfMake failed to initialise.'));
        return;
      }
      resolve(pdfMake);
    };
    script.onerror = () => reject(new Error('Failed to load pdfMake library.'));
    document.head.appendChild(script);
  });
  return pdfMakePromise;
}

async function ensureFonts(pdfMake: PdfMakeStatic): Promise<void> {
  if (pdfMake.vfs && pdfMake.vfs['NotoSansJP-Regular.otf']) {
    return;
  }
  const [regular, bold] = await Promise.all([
    loadFontFromSources(FONT_SOURCES.regular),
    loadFontFromSources(FONT_SOURCES.bold),
  ]);
  if (!pdfMake.vfs) {
    pdfMake.vfs = {};
  }
  pdfMake.vfs['NotoSansJP-Regular.otf'] = regular;
  pdfMake.vfs['NotoSansJP-Bold.otf'] = bold;
  pdfMake.fonts = {
    ...(pdfMake.fonts || {}),
    InvoiceFont: {
      normal: 'NotoSansJP-Regular.otf',
      bold: 'NotoSansJP-Bold.otf',
      italics: 'NotoSansJP-Regular.otf',
      bolditalics: 'NotoSansJP-Bold.otf',
    },
  };
}

function buildHeader(options: GenerateInvoicePdfOptions) {
  const { draft, totals, template, locale, currency, statusLookup, translate } = options;
  const palette = template.pdfPalette;
  const businessName =
    draft.businessName || translate('workspace.preview.businessPlaceholder', 'Your business name');
  const businessAddress =
    draft.businessAddress ||
    translate('workspace.preview.addressPlaceholder', 'Add your business address');
  const tagline = template.tagline ?? template.description;
  const statusText = statusLookup.get(draft.status) ?? statusFallback.get(draft.status) ?? draft.status;
  const headerColor = rgbToHex(palette.header, '#0b366b');
  const headerText = rgbToHex(palette.headerText, '#ffffff');
  const badgeBackground = rgbToHex(palette.badgeBackground, '#ffffff');
  const badgeText = rgbToHex(palette.badgeText, '#0b366b');
  const borderColor = rgbToHex(palette.border, '#e2e8f0');

  const totalLabel = translate('workspace.preview.totalDue', 'Total due');
  const statusLabel = translate('workspace.preview.status', 'Status');

  const leftStack = [
    { text: template.name, style: 'headerEyebrow', color: headerText },
    { text: businessName, style: 'headerBusiness', color: headerText },
    { text: businessAddress, style: 'headerAddress', color: headerText },
  ];
  if (tagline) {
    leftStack.push({ text: tagline, style: 'headerTagline', color: headerText });
  }

  const rightStack = [
    { text: totalLabel, style: 'badgeLabel', color: badgeText },
    { text: formatCurrency(totals.total, currency, locale), style: 'badgeAmount', color: badgeText },
    { text: `${statusLabel}: ${statusText}`, style: 'badgeStatus', color: badgeText },
  ];

  return {
    table: {
      widths: ['*', 180],
      body: [
        [
          { stack: leftStack, border: [false, false, false, false] },
          {
            stack: rightStack,
            border: [false, false, false, false],
            fillColor: badgeBackground,
            margin: [0, 0, 0, 0],
            layout: 'noBorders',
          },
        ],
      ],
    },
    layout: {
      fillColor: () => headerColor,
      hLineWidth: () => 0,
      vLineWidth: () => 0,
      paddingLeft: () => 26,
      paddingRight: () => 26,
      paddingTop: () => 24,
      paddingBottom: () => 24,
    },
    margin: [0, 0, 0, 28],
  };
}

function buildInfoSection(options: GenerateInvoicePdfOptions) {
  const { draft, template, locale, translate } = options;
  const isSeikyu = template.id === 'seikyu';

  const billToLabel = isSeikyu
    ? translate('workspace.preview.billToDual', '請求先 / Bill to')
    : translate('workspace.preview.billTo', 'Bill to');
  const issuedLabel = isSeikyu
    ? translate('workspace.preview.issuedDual', '発行日 / Issued')
    : translate('workspace.preview.issued', 'Issued');
  const dueLabel = isSeikyu
    ? translate('workspace.preview.dueDual', '支払期日 / Due')
    : translate('workspace.preview.due', 'Due');

  const clientName =
    draft.clientName || translate('workspace.preview.clientPlaceholder', 'Client name');
  const clientEmail =
    draft.clientEmail || translate('workspace.preview.emailPlaceholder', 'client@email.com');
  const clientAddress = draft.clientAddress;

  const issueText = formatFriendlyDate(draft.issueDate, locale);
  const dueText = formatFriendlyDate(draft.dueDate, locale);

  const clientStack = [
    { text: billToLabel, style: 'sectionLabel' },
    { text: clientName, style: 'sectionValueStrong', margin: [0, 8, 0, 2] },
    { text: clientEmail, style: 'sectionValue' },
  ];
  if (clientAddress) {
    clientStack.push({ text: clientAddress, style: 'sectionValue', margin: [0, 4, 0, 0] });
  }

  return {
    columns: [
      { width: '*', stack: clientStack },
      {
        width: 'auto',
        stack: [
          { text: issuedLabel, style: 'sectionLabel' },
          { text: issueText, style: 'sectionValueStrong', margin: [0, 8, 0, 0] },
        ],
      },
      {
        width: 'auto',
        stack: [
          { text: dueLabel, style: 'sectionLabel' },
          { text: dueText, style: 'sectionValueStrong', margin: [0, 8, 0, 0] },
        ],
      },
    ],
    columnGap: 24,
    margin: [0, 0, 0, 26],
  };
}

function buildLineItems(options: GenerateInvoicePdfOptions) {
  const { draft, template, locale, currency, translate } = options;
  const palette = template.pdfPalette;
  const isSeikyu = template.id === 'seikyu';

  const labels = {
    description: isSeikyu
      ? translate('workspace.preview.descriptionDual', '品目 / Item')
      : translate('workspace.preview.description', 'Description'),
    quantity: isSeikyu
      ? translate('workspace.preview.quantityDual', '数量 / Qty')
      : translate('workspace.preview.quantity', 'Qty'),
    rate: isSeikyu
      ? translate('workspace.preview.rateDual', '単価 / Rate')
      : translate('workspace.preview.rate', 'Rate'),
    amount: isSeikyu
      ? translate('workspace.preview.amountDual', '金額 / Total')
      : translate('workspace.preview.amount', 'Amount'),
  };

  const tableHeaderColor = rgbToHex(palette.tableHeader, '#1d5fbf');
  const tableHeaderText = rgbToHex(palette.tableHeaderText, '#ffffff');
  const stripeColor = rgbToHex(palette.tableStripe, '#f1f5f9');
  const borderColor = rgbToHex(palette.border, '#cbd5e1');

  const body = [
    [
      { text: labels.description, style: 'tableHeader', color: tableHeaderText },
      { text: labels.quantity, style: 'tableHeader', color: tableHeaderText, alignment: 'right' },
      { text: labels.rate, style: 'tableHeader', color: tableHeaderText, alignment: 'right' },
      { text: labels.amount, style: 'tableHeader', color: tableHeaderText, alignment: 'right' },
    ],
  ];

  draft.lines.forEach((line) => {
    const description = line.description ||
      (isSeikyu
        ? translate('workspace.preview.linePlaceholderJa', 'Service item')
        : translate('workspace.preview.linePlaceholder', 'Line description'));
    body.push([
      { text: description, style: 'tableCell' },
      { text: `${line.quantity}`, style: 'tableNumber' },
      { text: formatCurrency(line.rate, currency, locale), style: 'tableNumber' },
      { text: formatCurrency(line.quantity * line.rate, currency, locale), style: 'tableNumberStrong' },
    ]);
  });

  return {
    table: {
      headerRows: 1,
      widths: ['*', 60, 70, 90],
      body,
    },
    layout: {
      fillColor: (rowIndex: number) => {
        if (rowIndex === 0) {
          return tableHeaderColor;
        }
        return rowIndex % 2 === 1 ? stripeColor : null;
      },
      hLineColor: () => borderColor,
      vLineColor: () => borderColor,
      hLineWidth: () => 0.8,
      vLineWidth: () => 0.8,
      paddingLeft: () => 14,
      paddingRight: () => 14,
      paddingTop: () => 12,
      paddingBottom: () => 12,
    },
    margin: [0, 0, 0, 28],
  };
}

function buildTotals(options: GenerateInvoicePdfOptions) {
  const { totals, template, currency, locale, draft, statusLookup, translate } = options;
  const palette = template.pdfPalette;
  const isSeikyu = template.id === 'seikyu';
  const statusText = statusLookup.get(draft.status) ?? statusFallback.get(draft.status) ?? draft.status;
  const statusLabel = translate('workspace.preview.status', 'Status');

  const subtotalLabel = isSeikyu
    ? translate('workspace.preview.subtotalDual', '小計 / Subtotal')
    : translate('workspace.summary.subtotal', 'Subtotal');
  const taxLabel = isSeikyu
    ? translate('workspace.preview.taxDual', '税額 / Tax')
    : translate('workspace.summary.tax', 'Tax');
  const totalLabel = isSeikyu
    ? translate('workspace.preview.totalDual', '合計 / Total')
    : translate('workspace.summary.total', 'Total');

  const rows = [
    [subtotalLabel, formatCurrency(totals.subtotal, currency, locale), false],
    [taxLabel, formatCurrency(totals.taxAmount, currency, locale), false],
    [totalLabel, formatCurrency(totals.total, currency, locale), true],
  ] as const;

  const table = {
    table: {
      widths: ['*', 'auto'],
      body: rows.map(([label, value, bold]) => [
        { text: label, style: bold ? 'totalLabelStrong' : 'totalLabel' },
        { text: value, style: bold ? 'totalValueStrong' : 'totalValue' },
      ]),
    },
    layout: 'noBorders',
  };

  const statusNote = {
    text: `${statusLabel}: ${statusText}`,
    style: 'statusNote',
    margin: [0, 12, 0, 0],
  };

  if (template.id === 'aqua-ledger') {
    const badgeBackground = rgbToHex(palette.badgeBackground, '#ecfeff');
    const badgeText = rgbToHex(palette.badgeText, '#0f766e');
    const subtotalText = formatCurrency(totals.subtotal, currency, locale);
    const taxText = formatCurrency(totals.taxAmount, currency, locale);
    const summaryCard = {
      width: '*',
      table: {
        body: [
          [{ text: translate('workspace.preview.paymentSummary', 'Payment summary'), style: 'cardHeader', color: badgeText }],
          [{ text: formatCurrency(totals.total, currency, locale), style: 'cardAmount', color: badgeText }],
          [{ text: `${subtotalLabel}: ${subtotalText}`, style: 'cardDetail', color: badgeText }],
          [{ text: `${taxLabel}: ${taxText}`, style: 'cardDetail', color: badgeText }],
        ],
      },
      layout: {
        fillColor: () => badgeBackground,
        hLineWidth: () => 0,
        vLineWidth: () => 0,
        paddingLeft: () => 18,
        paddingRight: () => 18,
        paddingTop: () => 16,
        paddingBottom: () => 16,
      },
      margin: [0, 0, 0, 0],
    };

    return {
      columns: [
        summaryCard,
        { width: 220, stack: [table, statusNote] },
      ],
      columnGap: 26,
      margin: [0, 0, 0, 28],
    };
  }

  return {
    stack: [
      { alignment: 'right', ...table },
      { alignment: 'right', ...statusNote },
    ],
    margin: [0, 0, 0, 28],
  };
}

function buildNotes(options: GenerateInvoicePdfOptions) {
  const { draft, template, translate } = options;
  const palette = template.pdfPalette;
  const isSeikyu = template.id === 'seikyu';
  const notesBackground = rgbToHex(palette.notesBackground, '#f8fafc');
  const borderColor = rgbToHex(palette.border, '#cbd5e1');

  const notesLabel = isSeikyu
    ? translate('workspace.preview.notesDual', '備考 / Notes')
    : translate('workspace.preview.notes', 'Notes');
  const notesBody =
    draft.notes ||
    translate('workspace.preview.notesPlaceholder', 'Add payment instructions or a thank you message.');

  if (isSeikyu) {
    const hankoLabel = translate('workspace.preview.hankoLabel', '印');
    const hankoCaption = translate('workspace.preview.hankoCaption', 'Authorised seal');
    const notesHint = translate('workspace.preview.notesHint', 'Please remit payment before the due date.');
    return {
      table: {
        widths: ['*'],
        body: [
          [
            {
              columns: [
                {
                  width: '*',
                  stack: [
                    { text: notesLabel, style: 'notesLabel' },
                    { text: notesBody, style: 'notesBody', margin: [0, 10, 0, 8] },
                    { text: notesHint, style: 'notesHint' },
                  ],
                },
                {
                  width: 120,
                  stack: [
                    {
                      canvas: [
                        {
                          type: 'ellipse',
                          x: 50,
                          y: 36,
                          r1: 32,
                          r2: 32,
                          lineWidth: 1.5,
                          lineColor: borderColor,
                        },
                      ],
                      height: 72,
                    },
                    { text: hankoLabel, style: 'hankoLabel', alignment: 'center', margin: [0, -52, 0, 4] },
                    { text: hankoCaption, style: 'hankoCaption', alignment: 'center' },
                  ],
                },
              ],
              border: [false, false, false, false],
            },
          ],
        ],
      },
      layout: {
        fillColor: () => notesBackground,
        hLineWidth: () => 0,
        vLineWidth: () => 0,
        paddingLeft: () => 20,
        paddingRight: () => 20,
        paddingTop: () => 20,
        paddingBottom: () => 20,
      },
    };
  }

  return {
    table: {
      widths: ['*'],
      body: [
        [
          {
            stack: [
              { text: notesLabel, style: 'notesLabel' },
              { text: notesBody, style: 'notesBody', margin: [0, 10, 0, 0] },
            ],
            border: [false, false, false, false],
          },
        ],
      ],
    },
    layout: {
      fillColor: () => notesBackground,
      hLineWidth: () => 0,
      vLineWidth: () => 0,
      paddingLeft: () => 20,
      paddingRight: () => 20,
      paddingTop: () => 20,
      paddingBottom: () => 20,
    },
  };
}

function buildDocDefinition(options: GenerateInvoicePdfOptions) {
  const palette = options.template.pdfPalette;
  const bodyColor = rgbToHex(palette.bodyText, '#0f172a');
  const mutedColor = rgbToHex(palette.mutedText, '#475569');

  return {
    pageSize: 'A4',
    pageMargins: [42, 64, 42, 64],
    defaultStyle: {
      font: 'InvoiceFont',
      color: bodyColor,
      fontSize: 11,
    },
    styles: {
      headerEyebrow: { fontSize: 14, bold: true, margin: [0, 0, 0, 6] },
      headerBusiness: { fontSize: 20, bold: true, margin: [0, 4, 0, 4] },
      headerAddress: { fontSize: 12, margin: [0, 2, 0, 4] },
      headerTagline: { fontSize: 11, opacity: 0.92 },
      badgeLabel: { fontSize: 11, margin: [0, 0, 0, 4] },
      badgeAmount: { fontSize: 22, bold: true, margin: [0, 2, 0, 6] },
      badgeStatus: { fontSize: 10 },
      sectionLabel: { fontSize: 10, bold: true, color: mutedColor, margin: [0, 0, 0, 2] },
      sectionValue: { fontSize: 11 },
      sectionValueStrong: { fontSize: 12, bold: true },
      tableHeader: { fontSize: 11, bold: true },
      tableCell: { fontSize: 11 },
      tableNumber: { fontSize: 11, alignment: 'right' },
      tableNumberStrong: { fontSize: 11, bold: true, alignment: 'right' },
      totalLabel: { fontSize: 11, color: mutedColor, margin: [0, 0, 0, 4] },
      totalLabelStrong: { fontSize: 12, bold: true, color: mutedColor, margin: [0, 6, 0, 4] },
      totalValue: { fontSize: 11, alignment: 'right' },
      totalValueStrong: { fontSize: 13, bold: true, alignment: 'right' },
      statusNote: { fontSize: 10, color: mutedColor },
      cardHeader: { fontSize: 12, bold: true },
      cardAmount: { fontSize: 18, bold: true, margin: [0, 8, 0, 10] },
      cardDetail: { fontSize: 10, margin: [0, 2, 0, 0] },
      notesLabel: { fontSize: 12, bold: true },
      notesBody: { fontSize: 11, lineHeight: 1.4 },
      notesHint: { fontSize: 10, color: mutedColor },
      hankoLabel: { fontSize: 20, bold: true },
      hankoCaption: { fontSize: 9, color: mutedColor },
    },
    content: [
      buildHeader(options),
      buildInfoSection(options),
      buildLineItems(options),
      buildTotals(options),
      buildNotes(options),
    ],
  };
}

export async function generateInvoicePdf(options: GenerateInvoicePdfOptions): Promise<Blob> {
  const pdfMake = await loadPdfMake();
  await ensureFonts(pdfMake);
  const definition = buildDocDefinition(options);
  return new Promise((resolve, reject) => {
    try {
      pdfMake.createPdf(definition).getBlob((blob: Blob) => {
        resolve(blob);
      });
    } catch (error) {
      reject(error);
    }
  });
}
