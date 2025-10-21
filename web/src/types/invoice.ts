export type InvoiceItem = {
  id: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
};

export type InvoiceFormValues = {
  id?: string;
  companyName: string;
  companyAddress: string;
  companyPhone?: string;
  clientName: string;
  clientAddress: string;
  invoiceNumber: string;
  issueDate: string;
  dueDate: string;
  notes?: string;
  taxRate: number;
  items: InvoiceItem[];
  stampNeeded: boolean;
  createdAt?: string;
  updatedAt?: string;
};

export type InvoiceRecord = InvoiceFormValues & {
  userId: string;
  createdAt: string;
  updatedAt: string;
};

export type SubscriptionPlan = 'free' | 'premium';

export type SubscriptionInfo = {
  plan: SubscriptionPlan;
  monthlyDownloadCount: number;
  currentPeriodEnd?: string;
};
