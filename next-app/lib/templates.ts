export type RGB = [number, number, number];

export type TemplatePdfPalette = {
  header: RGB;
  headerText: RGB;
  bodyText: RGB;
  mutedText: RGB;
  badgeBackground: RGB;
  badgeText: RGB;
  tableHeader: RGB;
  tableHeaderText: RGB;
  tableStripe: RGB;
  border: RGB;
  notesBackground: RGB;
  accentBar?: RGB;
};

export type TemplateColumnLabels = {
  description?: string;
  descriptionSecondary?: string;
  quantity?: string;
  rate?: string;
  amount?: string;
};

export type TemplateLabelKey =
  | 'invoiceTitle'
  | 'billTo'
  | 'issueDate'
  | 'dueDate'
  | 'statusLabel'
  | 'statusValue'
  | 'currency'
  | 'description'
  | 'quantity'
  | 'rate'
  | 'amount'
  | 'subtotal'
  | 'tax'
  | 'total'
  | 'notes';

export type TemplateLabelOverrides = Partial<Record<TemplateLabelKey, string>>;

export const DEFAULT_TEMPLATE_ID = 'villa-coastal';

export type TemplateStructure = {
  headerLayout: 'standard' | 'japanese' | 'compact';
  totalsStyle: 'table' | 'underline' | 'side-panel' | 'badge' | 'stacked' | 'japanese';
  infoLayout: 'standard' | 'split' | 'japanese';
  lineItemStyle:
    | 'default'
    | 'striped'
    | 'striped-light'
    | 'outlined'
    | 'ledger'
    | 'separated'
    | 'japanese';
  columnLabels?: TemplateColumnLabels;
  labelOverrides?: TemplateLabelOverrides;
  showPaymentDetails: boolean;
  paymentDetailsLabel?: string;
  paymentDetailsValue?: string;
  paymentLinkLabel?: string;
  showThankYou: boolean;
  thankYouLabel?: string;
};

const defaultTemplateStructure: TemplateStructure = {
  headerLayout: 'standard',
  totalsStyle: 'side-panel',
  infoLayout: 'standard',
  lineItemStyle: 'striped',
  showPaymentDetails: false,
  showThankYou: false,
};

const templateStructures: Record<string, TemplateStructure> = {
  'villa-coastal': {
    headerLayout: 'standard',
    totalsStyle: 'side-panel',
    infoLayout: 'split',
    lineItemStyle: 'striped-light',
    columnLabels: {
      quantity: 'Nights',
    },
    showPaymentDetails: false,
    showThankYou: true,
    thankYouLabel: 'We appreciate your stay with us.',
  },
  'atelier-minimal': {
    headerLayout: 'standard',
    totalsStyle: 'underline',
    infoLayout: 'split',
    lineItemStyle: 'outlined',
    showPaymentDetails: false,
    showThankYou: false,
  },
  'royal-balance': {
    headerLayout: 'standard',
    totalsStyle: 'badge',
    infoLayout: 'standard',
    lineItemStyle: 'striped',
    showPaymentDetails: false,
    showThankYou: true,
    thankYouLabel: 'Thank you for your business.',
  },
  'harbour-slate': {
    headerLayout: 'standard',
    totalsStyle: 'table',
    infoLayout: 'split',
    lineItemStyle: 'separated',
    showPaymentDetails: false,
    showThankYou: false,
  },
  seikyu: {
    headerLayout: 'japanese',
    totalsStyle: 'japanese',
    infoLayout: 'japanese',
    lineItemStyle: 'japanese',
    columnLabels: {
      descriptionSecondary: '品目',
      quantity: '数量',
      rate: '単価',
      amount: '金額',
    },
    labelOverrides: {
      invoiceTitle: '請求書 / Invoice',
      billTo: '請求先 / Bill to',
      issueDate: '発行日 / Issued',
      dueDate: '支払期日 / Due',
      statusLabel: 'ステータス / Status',
      currency: '通貨 / Currency',
      subtotal: '小計 / Subtotal',
      tax: '税額 / Tax',
      total: '合計 / Total',
      notes: '備考 / Notes',
    },
    showPaymentDetails: true,
    paymentDetailsLabel: 'Payment details',
    paymentDetailsValue: 'Bank transfer — due on receipt',
    paymentLinkLabel: 'Stripe決済リンク（テストモード） / Stripe checkout link (test mode)',
    showThankYou: true,
    thankYouLabel: 'いつもありがとうございます。',
  },
  'aqua-ledger': {
    headerLayout: 'standard',
    totalsStyle: 'stacked',
    infoLayout: 'standard',
    lineItemStyle: 'striped',
    showPaymentDetails: false,
    showThankYou: false,
  },
  'classic-ledger': {
    headerLayout: 'standard',
    totalsStyle: 'underline',
    infoLayout: 'standard',
    lineItemStyle: 'ledger',
    showPaymentDetails: false,
    showThankYou: true,
    thankYouLabel: 'Authorised signature',
  },
};

export type TemplateTier = 'free' | 'premium';

export type InvoiceTemplate = {
  id: string;
  name: string;
  description: string;
  accent: string;
  accentSoft: string;
  bestFor: string;
  highlights: string[];
  pdfPalette: TemplatePdfPalette;
  tagline?: string;
  structure?: TemplateStructure;
  supportsJapanese?: boolean;
  tier: TemplateTier;
};

function rgb(hex: string): RGB {
  const normalized = hex.replace('#', '').trim();
  const bigint = Number.parseInt(normalized, 16);
  return [
    (bigint >> 16) & 255,
    (bigint >> 8) & 255,
    bigint & 255,
  ];
}

export const invoiceTemplates: InvoiceTemplate[] = [
  {
    id: DEFAULT_TEMPLATE_ID,
    name: 'Villa Coastal',
    description:
      'Deep azure header, booking summary capsule, and anchored totals designed after boutique resort receipts.',
    accent: 'linear-gradient(135deg, #0b366b 0%, #1d5fbf 55%, #3ca1ff 100%)',
    accentSoft: 'rgba(29, 95, 191, 0.12)',
    bestFor: 'Hotels, villas, and hospitality teams who want a polished stay summary.',
    highlights: [
      'Wide coastal masthead',
      'Booking and payment badge',
      'Lightweight dividers for itinerary rows',
    ],
    pdfPalette: {
      header: rgb('#0b366b'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#0f172a'),
      mutedText: rgb('#1e3a8a'),
      badgeBackground: rgb('#e0f2ff'),
      badgeText: rgb('#0b366b'),
      tableHeader: rgb('#1d5fbf'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#eef6ff'),
      border: rgb('#c8d9f5'),
      notesBackground: rgb('#f2f8ff'),
      accentBar: rgb('#1d5fbf'),
    },
    structure: templateStructures[DEFAULT_TEMPLATE_ID],
    tier: 'free',
  },
  {
    id: 'atelier-minimal',
    name: 'Atelier Minimal',
    description: 'High-contrast monochrome layout with right-aligned metadata and crisp signature footer.',
    accent: 'linear-gradient(135deg, #0f172a 0%, #1f2937 65%, #4b5563 100%)',
    accentSoft: 'rgba(15, 23, 42, 0.08)',
    bestFor: 'Studios and consultants who prefer a timeless, ink-friendly invoice.',
    highlights: ['Neutral typography', 'Right-aligned metadata column', 'Signature-ready totals'],
    pdfPalette: {
      header: rgb('#0f172a'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#111827'),
      mutedText: rgb('#475569'),
      badgeBackground: rgb('#f8fafc'),
      badgeText: rgb('#0f172a'),
      tableHeader: rgb('#111827'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#f3f4f6'),
      border: rgb('#e2e8f0'),
      notesBackground: rgb('#f8fafc'),
    },
    structure: templateStructures['atelier-minimal'],
    tier: 'premium',
  },
  {
    id: 'royal-balance',
    name: 'Royal Balance',
    description: 'Magenta-to-violet gradient bar with balance badge and contrasting totals ribbon.',
    accent: 'linear-gradient(135deg, #392f87 0%, #7e22ce 55%, #f472b6 100%)',
    accentSoft: 'rgba(126, 34, 206, 0.16)',
    bestFor: 'Creative agencies presenting premium retainers or campaign fees.',
    highlights: ['Gradient hero header', 'Balance due capsule', 'Soft pink notes panel'],
    pdfPalette: {
      header: rgb('#392f87'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#2d0a44'),
      mutedText: rgb('#be185d'),
      badgeBackground: rgb('#fdf2f8'),
      badgeText: rgb('#be185d'),
      tableHeader: rgb('#7e22ce'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#f5d0fe'),
      border: rgb('#e9d5ff'),
      notesBackground: rgb('#fdf2f8'),
      accentBar: rgb('#f472b6'),
    },
    structure: templateStructures['royal-balance'],
    tier: 'premium',
  },
  {
    id: 'harbour-slate',
    name: 'Harbour Slate',
    description: 'Cool grey-blue masthead, reservation details, and signature strip inspired by travel folios.',
    accent: 'linear-gradient(135deg, #012a4a 0%, #1d4e89 60%, #5fa8d3 100%)',
    accentSoft: 'rgba(29, 78, 137, 0.14)',
    bestFor: 'Travel operators and hospitality teams issuing folios or receipts.',
    highlights: ['Stay summary columns', 'Authorised signature pad', 'Subtle blue table header'],
    pdfPalette: {
      header: rgb('#012a4a'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#0f172a'),
      mutedText: rgb('#1d4e89'),
      badgeBackground: rgb('#e7effb'),
      badgeText: rgb('#1d4e89'),
      tableHeader: rgb('#1d4e89'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#e2e8f0'),
      border: rgb('#cbd5e1'),
      notesBackground: rgb('#f1f5f9'),
      accentBar: rgb('#5fa8d3'),
    },
    structure: templateStructures['harbour-slate'],
    tier: 'premium',
  },
  {
    id: 'seikyu',
    name: 'Seikyūsho',
    description: 'Dual-language headings, hanko placeholder, and tax summary for Japanese invoices.',
    accent: 'linear-gradient(135deg, #ef4444 0%, #f97316 100%)',
    accentSoft: 'rgba(239, 68, 68, 0.12)',
    bestFor: 'Teams invoicing Japanese clients with bilingual requirements.',
    highlights: ['Hanko-ready footer', 'Tax summary rows', 'Bilingual column labels'],
    pdfPalette: {
      header: rgb('#ef4444'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#111827'),
      mutedText: rgb('#b91c1c'),
      badgeBackground: rgb('#fff7ed'),
      badgeText: rgb('#b91c1c'),
      tableHeader: rgb('#ef4444'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#ffe4e6'),
      border: rgb('#fecaca'),
      notesBackground: rgb('#fff7ed'),
      accentBar: rgb('#f97316'),
    },
    structure: templateStructures.seikyu,
    supportsJapanese: true,
    tier: 'premium',
  },
  {
    id: 'aqua-ledger',
    name: 'Aqua Ledger',
    description: 'Modern teal banner with alternating table rows and slim metadata columns.',
    accent: 'linear-gradient(135deg, #0f766e 0%, #14b8a6 55%, #22d3ee 100%)',
    accentSoft: 'rgba(20, 184, 166, 0.16)',
    bestFor: 'Product teams and SaaS companies sending professional invoices.',
    highlights: ['Balance status capsule', 'Alternating aqua table striping', 'Footer payment reminder'],
    pdfPalette: {
      header: rgb('#0f766e'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#064e3b'),
      mutedText: rgb('#0f766e'),
      badgeBackground: rgb('#ecfeff'),
      badgeText: rgb('#0f766e'),
      tableHeader: rgb('#0f766e'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#d1fae5'),
      border: rgb('#a7f3d0'),
      notesBackground: rgb('#ecfdf5'),
      accentBar: rgb('#14b8a6'),
    },
    structure: templateStructures['aqua-ledger'],
    tier: 'premium',
  },
  {
    id: 'classic-ledger',
    name: 'Classic Ledger',
    description: 'Pure structure without colour, ideal for legal or finance teams who need crisp print results.',
    accent: 'linear-gradient(135deg, #1f2937 0%, #4b5563 100%)',
    accentSoft: 'rgba(31, 41, 55, 0.08)',
    bestFor: 'Law firms and accountants who require a colourless ledger layout.',
    highlights: ['Ledger table alignment', 'Script signature line', 'Totalling emphasis'],
    pdfPalette: {
      header: rgb('#111827'),
      headerText: rgb('#ffffff'),
      bodyText: rgb('#111827'),
      mutedText: rgb('#6b7280'),
      badgeBackground: rgb('#f3f4f6'),
      badgeText: rgb('#111827'),
      tableHeader: rgb('#111827'),
      tableHeaderText: rgb('#ffffff'),
      tableStripe: rgb('#f3f4f6'),
      border: rgb('#d1d5db'),
      notesBackground: rgb('#f9fafb'),
    },
    structure: templateStructures['classic-ledger'],
    tier: 'premium',
  },
];

export function getInvoiceTemplate(id: string): InvoiceTemplate & { structure: TemplateStructure } {
  const template = invoiceTemplates.find((entry) => entry.id === id) ?? invoiceTemplates[0];
  const structure = template.structure ?? templateStructures[template.id] ?? defaultTemplateStructure;
  return {
    ...template,
    structure,
  };
}
