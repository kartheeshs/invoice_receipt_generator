'use client';

import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import {
  InvoiceDraft,
  InvoiceLine,
  InvoiceRecord,
  InvoiceStatus,
  calculateTotals,
  cleanLines,
  createEmptyDraft,
  createEmptyLine,
  formatCurrency,
} from '../../lib/invoices';
import { firebaseConfigured, fetchRecentInvoices, saveInvoice } from '../../lib/firebase';
import { sampleInvoices } from '../../lib/sample-data';
import { useTranslation } from '../../lib/i18n';
import { formatFriendlyDate } from '../../lib/format';
import { generateInvoicePdf } from '../../lib/pdf';
import { DEFAULT_TEMPLATE_ID, invoiceTemplates } from '../../lib/templates';
import {
  CLIENT_STORAGE_KEY,
  createClientId,
  clientDirectory,
  loadManagedClients,
  persistManagedClients,
  type ClientDirectoryEntry,
  type ManagedClient,
} from '../../lib/clients';
import { clearSession, loadSession, SESSION_STORAGE_KEY, type StoredSession } from '../../lib/auth';
import LanguageSwitcher from '../components/language-switcher';
import InvoicePreview from '../components/invoice-preview';
import AdSlot from '../components/ad-slot';
import {
  FREE_PLAN_DOWNLOAD_LIMIT,
  SubscriptionState,
  downloadsRemaining,
  downloadWindowReset,
  ensureSubscriptionWindow,
  incrementDownloadCount,
  loadSubscriptionState,
  markSubscriptionPlan,
  persistSubscriptionState,
} from '../../lib/subscription';

type SectionId = 'dashboard' | 'invoices' | 'templates' | 'clients' | 'activity' | 'settings';

type Section = {
  id: SectionId;
  label: string;
  description: string;
  icon: string;
};

type ClientSummary = {
  key: string;
  name: string;
  email: string | undefined;
  invoices: number;
  outstanding: number;
  lastInvoice?: string;
  status: InvoiceStatus;
  currency: string;
};

type ClientDetail = {
  summary: ClientSummary;
  source: 'manual' | 'invoice';
  manualRecord: ManagedClient | null;
  invoices: InvoiceRecord[];
  address?: string;
  phone?: string;
  notes?: string;
  company?: string;
};

type ClientFormState = {
  id?: string;
  name: string;
  email: string;
  address: string;
  company: string;
  phone: string;
  notes: string;
};

const EMPTY_CLIENT_FORM: ClientFormState = {
  id: undefined,
  name: '',
  email: '',
  address: '',
  company: '',
  phone: '',
  notes: '',
};

const sections: Section[] = [
  { id: 'dashboard', label: 'Overview', description: 'Pulse of your billing workspace', icon: '📊' },
  { id: 'invoices', label: 'Invoices', description: 'Compose and preview drafts', icon: '🧾' },
  { id: 'templates', label: 'Templates', description: 'Switch the invoice look & feel', icon: '🎨' },
  { id: 'clients', label: 'Clients', description: 'Track customer history', icon: '👥' },
  { id: 'activity', label: 'Activity', description: 'Monitor timeline & reminders', icon: '🕒' },
  { id: 'settings', label: 'Settings', description: 'Default business preferences', icon: '⚙️' },
];

const statusOptions: { value: InvoiceStatus; label: string }[] = [
  { value: 'draft', label: 'Draft' },
  { value: 'sent', label: 'Sent' },
  { value: 'paid', label: 'Paid' },
  { value: 'overdue', label: 'Overdue' },
];

const FALLBACK_CURRENCIES = [
  'USD',
  'EUR',
  'GBP',
  'AUD',
  'CAD',
  'JPY',
  'SGD',
  'NZD',
  'CHF',
  'CNY',
  'HKD',
  'INR',
  'SEK',
  'NOK',
  'DKK',
  'ZAR',
  'BRL',
  'MXN',
  'KRW',
  'IDR',
  'PHP',
  'THB',
  'AED',
  'SAR',
];

function resolveCurrencyCodes(): string[] {
  if (typeof Intl !== 'undefined' && 'supportedValuesOf' in Intl && typeof Intl.supportedValuesOf === 'function') {
    try {
      const values = Intl.supportedValuesOf('currency');
      if (Array.isArray(values) && values.length) {
        return values as string[];
      }
    } catch {
      // ignored — fall back to curated list
    }
  }

  return FALLBACK_CURRENCIES;
}

const stripePublishableKey =
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ?? 'pk_test_51SMrPSRuLo7evHJI5TuYsmpqHAtIOGahp0NCsder674sXQ7wDrgNomfKKmZWyB6fFgREw88cprnFjJmcfIXu628L00o5NvgAzJ';

type StripeClient = {
  redirectToCheckout: (options: { sessionId: string }) => Promise<{ error?: { message?: string } }>;
};

declare global {
  interface Window {
    Stripe?: (publishableKey: string) => StripeClient | null;
  }
}

let stripeClientPromise: Promise<StripeClient | null> | null = null;

function loadStripeClient(): Promise<StripeClient | null> {
  if (!stripePublishableKey) {
    return Promise.resolve(null);
  }
  if (stripeClientPromise) {
    return stripeClientPromise;
  }
  stripeClientPromise = new Promise((resolve, reject) => {
    if (typeof window === 'undefined') {
      resolve(null);
      return;
    }
    if (typeof window.Stripe === 'function') {
      resolve(window.Stripe(stripePublishableKey) ?? null);
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://js.stripe.com/v3/';
    script.async = true;
    script.onload = () => {
      resolve(typeof window.Stripe === 'function' ? window.Stripe(stripePublishableKey) ?? null : null);
    };
    script.onerror = () => reject(new Error('Stripe.js failed to load.'));
    document.head.appendChild(script);
  });
  return stripeClientPromise;
}

function ensureLine(line: InvoiceLine, field: keyof InvoiceLine, value: string): InvoiceLine {
  if (field === 'description') {
    return { ...line, description: value };
  }

  const numeric = Number(value);
  if (field === 'quantity') {
    return { ...line, quantity: Number.isFinite(numeric) && numeric > 0 ? numeric : line.quantity };
  }

  return { ...line, rate: Number.isFinite(numeric) && numeric >= 0 ? numeric : line.rate };
}

export default function WorkspacePage() {
  const [activeSection, setActiveSection] = useState<SectionId>('dashboard');
  const [draft, setDraft] = useState<InvoiceDraft>(() => createEmptyDraft());
  const [recentInvoices, setRecentInvoices] = useState<InvoiceRecord[]>([]);
  const [loadingInvoices, setLoadingInvoices] = useState<boolean>(true);
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  type ToastStatus = 'info' | 'success' | 'error' | 'loading';
  type Toast = { id: string; status: ToastStatus; message: string };

  const toastTimers = useRef<Map<string, ReturnType<typeof setTimeout>>>(new Map());
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [invoiceView, setInvoiceView] = useState<'edit' | 'preview'>('edit');
  const [downloadingPdf, setDownloadingPdf] = useState<boolean>(false);
  const [subscription, setSubscription] = useState<SubscriptionState>(() => loadSubscriptionState());
  const [subscribing, setSubscribing] = useState<boolean>(false);
  const [session, setSession] = useState<StoredSession | null>(null);
  const [clientMatches, setClientMatches] = useState<ClientDirectoryEntry[]>([]);
  const [showClientMatches, setShowClientMatches] = useState<boolean>(false);
  const [showSavedInvoices, setShowSavedInvoices] = useState<boolean>(false);
  const [managedClients, setManagedClients] = useState<ManagedClient[]>([]);
  const [showClientManager, setShowClientManager] = useState<boolean>(false);
  const [selectedClientId, setSelectedClientId] = useState<string | 'new' | null>(null);
  const [clientSearch, setClientSearch] = useState<string>('');
  const [clientForm, setClientForm] = useState<ClientFormState>(EMPTY_CLIENT_FORM);
  const [clientFormError, setClientFormError] = useState<string>('');
  const previewRef = useRef<HTMLDivElement | null>(null);
  const { language, locale, t } = useTranslation();
  const formId = 'invoice-editor-form';
  const updateManagedClientState = useCallback(
    (updater: ManagedClient[] | ((clients: ManagedClient[]) => ManagedClient[])) => {
      setManagedClients((current) => {
        const next =
          typeof updater === 'function'
            ? (updater as (clients: ManagedClient[]) => ManagedClient[])(current)
            : updater;
        persistManagedClients(next);
        return next;
      });
    },
    [persistManagedClients],
  );
  const startCreateClient = useCallback(
    (preset?: Partial<ClientFormState>) => {
      setClientForm({ ...EMPTY_CLIENT_FORM, ...preset });
      setClientFormError('');
      setSelectedClientId('new');
      setShowClientManager(true);
    },
    [],
  );
  const openClientManagerFor = useCallback((clientId: string) => {
    setClientFormError('');
    setSelectedClientId(clientId);
    setShowClientManager(true);
  }, []);
  const closeClientManager = useCallback(() => {
    setShowClientManager(false);
    setClientSearch('');
    setClientMatches([]);
    setShowClientMatches(false);
    setSelectedClientId(null);
    setClientFormError('');
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
    const timer = toastTimers.current.get(id);
    if (timer) {
      clearTimeout(timer);
      toastTimers.current.delete(id);
    }
  }, []);

  const showToast = useCallback(
    (
      message: string,
      status: ToastStatus,
      { id, duration = 4000 }: { id?: string; duration?: number } = {},
    ): string => {
      const toastId = id ?? `toast-${Date.now()}-${Math.random().toString(16).slice(2)}`;
      setToasts((prev) => {
        const filtered = prev.filter((toast) => toast.id !== toastId);
        return [...filtered, { id: toastId, message, status }];
      });

      const existingTimer = toastTimers.current.get(toastId);
      if (existingTimer) {
        clearTimeout(existingTimer);
        toastTimers.current.delete(toastId);
      }

      if (duration && duration > 0) {
        const timer = setTimeout(() => {
          removeToast(toastId);
        }, duration);
        toastTimers.current.set(toastId, timer);
      }

      return toastId;
    },
    [removeToast],
  );

  const dismissToast = useCallback((id: string) => {
    removeToast(id);
  }, [removeToast]);
  const currencyOptions = useMemo(() => {
    const codes = new Set(resolveCurrencyCodes());
    for (const currency of FALLBACK_CURRENCIES) {
      codes.add(currency);
    }
    if (draft.currency) {
      codes.add(draft.currency.toUpperCase());
    }

    const validCodes = Array.from(codes).filter((code) => /^[A-Z]{3}$/u.test(code));
    validCodes.sort((a, b) => a.localeCompare(b));

    let currencyNames: Intl.DisplayNames | null = null;
    if (typeof Intl.DisplayNames === 'function') {
      try {
        currencyNames = new Intl.DisplayNames([locale], { type: 'currency' });
      } catch {
        currencyNames = null;
      }
    }

    return validCodes.map((code) => {
      const readable = currencyNames?.of(code);
      return {
        code,
        label: readable && readable !== code ? `${code} — ${readable}` : code,
      };
    });
  }, [draft.currency, locale]);
  const isSignedIn = Boolean(session);
  const isAdmin = session?.role === 'admin';
  const sessionDisplayName = session?.displayName ?? session?.email ?? '';

  const syncSubscription = useCallback(
    (updater: SubscriptionState | ((current: SubscriptionState) => SubscriptionState)) => {
      setSubscription((current) => {
        const next = typeof updater === 'function' ? (updater as (state: SubscriptionState) => SubscriptionState)(current) : updater;
        persistSubscriptionState(next);
        return next;
      });
    },
    [],
  );

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }
    const initial = loadSubscriptionState();
    syncSubscription(initial);
  }, [syncSubscription]);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }
    const url = new URL(window.location.href);
    const status = url.searchParams.get('subscription');
    if (!status) {
      return;
    }
    url.searchParams.delete('subscription');
    window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`);
    setSubscribing(false);

    if (status === 'success') {
      syncSubscription((current) => markSubscriptionPlan(current, 'premium'));
      showToast(
        t('workspace.subscription.success', 'Premium plan activated. Unlimited templates and downloads unlocked.'),
        'success',
      );
      setSaveState('success');
    } else if (status === 'canceled') {
      showToast(t('workspace.subscription.canceled', 'Subscription checkout was canceled.'), 'info');
      setSaveState('idle');
    }
  }, [showToast, syncSubscription, t]);

  useEffect(() => {
    const ensured = ensureSubscriptionWindow(subscription);
    if (
      ensured.downloadCount !== subscription.downloadCount ||
      ensured.windowStart !== subscription.windowStart ||
      ensured.plan !== subscription.plan
    ) {
      syncSubscription(ensured);
    }
  }, [subscription, syncSubscription]);

  useEffect(() => {
    if (!selectedClientId || selectedClientId === 'new') {
      return;
    }

    if (selectedManualClient) {
      setClientForm({
        id: selectedManualClient.id,
        name: selectedManualClient.name,
        email: selectedManualClient.email,
        address: selectedManualClient.address,
        company: selectedManualClient.company ?? '',
        phone: selectedManualClient.phone ?? '',
        notes: selectedManualClient.notes ?? '',
      });
      setClientFormError('');
    }
  }, [selectedClientId, selectedManualClient]);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }
    setSession(loadSession());
    const handleStorage = (event: StorageEvent) => {
      if (event.key === SESSION_STORAGE_KEY) {
        setSession(loadSession());
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => {
      window.removeEventListener('storage', handleStorage);
    };
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    setManagedClients(loadManagedClients());

    const handleStorage = (event: StorageEvent) => {
      if (event.key === CLIENT_STORAGE_KEY) {
        setManagedClients(loadManagedClients());
      }
    };

    window.addEventListener('storage', handleStorage);
    return () => {
      window.removeEventListener('storage', handleStorage);
    };
  }, [loadManagedClients]);

  useEffect(() => {
    const timers = toastTimers.current;
    return () => {
      timers.forEach((timer) => clearTimeout(timer));
      timers.clear();
    };
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined' || typeof document === 'undefined' || !showSavedInvoices) {
      return;
    }
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setShowSavedInvoices(false);
      }
    };
    const originalOverflow = document.body.style.overflow;
    window.addEventListener('keydown', handleKeyDown);
    document.body.style.overflow = 'hidden';
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    document.body.style.overflow = originalOverflow;
    };
  }, [showSavedInvoices]);

  useEffect(() => {
    if (typeof window === 'undefined' || typeof document === 'undefined' || !showClientManager) {
      return;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setShowClientManager(false);
      }
    };

    const originalOverflow = document.body.style.overflow;
    window.addEventListener('keydown', handleKeyDown);
    document.body.style.overflow = 'hidden';

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = originalOverflow;
    };
  }, [showClientManager]);

  useEffect(() => {
    let active = true;

    async function loadInvoices() {
      try {
        if (firebaseConfigured) {
          const invoices = await fetchRecentInvoices(12);
          if (!active) return;
          setRecentInvoices(invoices.length ? invoices : sampleInvoices);
        } else if (active) {
          setRecentInvoices(sampleInvoices);
        }
      } catch (error) {
        console.error(error);
        if (!active) return;
        showToast(t('workspace.alert.offline', 'Unable to reach Firestore. Displaying sample invoices.'), 'error');
        setSaveState('error');
        setRecentInvoices(sampleInvoices);
      } finally {
        if (active) {
          setLoadingInvoices(false);
        }
      }
    }

    loadInvoices();

    return () => {
      active = false;
    };
  }, [showToast, t]);

  useEffect(() => {
    if (!showClientManager || selectedClientId) {
      return;
    }

    const first = clientPanelEntries[0];
    if (first) {
      setSelectedClientId(first.summary.key);
    }
  }, [clientPanelEntries, selectedClientId, showClientManager]);

  const totals = useMemo(() => calculateTotals(draft.lines, draft.taxRate), [draft.lines, draft.taxRate]);
  const printableLines = useMemo(() => {
    const sanitized = cleanLines(draft.lines);
    return sanitized.length ? sanitized : draft.lines;
  }, [draft.lines]);
  const previewDraft = useMemo(
    () => ({
      ...draft,
      lines: printableLines,
    }),
    [draft, printableLines],
  );
  const previewTotals = useMemo(
    () => calculateTotals(printableLines, draft.taxRate),
    [printableLines, draft.taxRate],
  );
  const localizedSections = useMemo(
    () =>
      sections.map((section) => ({
        ...section,
        label: t(`workspace.nav.${section.id}`, section.label),
        description: t(`workspace.section.${section.id}.description`, section.description),
      })),
    [t],
  );
  const localizedTemplates = useMemo(
    () =>
      invoiceTemplates.map((template) => ({
        ...template,
        name: t(`workspace.template.${template.id}.name`, template.name),
        description: t(`workspace.template.${template.id}.description`, template.description),
        bestFor: t(`workspace.template.${template.id}.bestFor`, template.bestFor),
        highlights: template.highlights.map((highlight, index) =>
          t(`workspace.template.${template.id}.highlights.${index}`, highlight),
        ),
      })),
    [t],
  );
  const localizedStatusOptions = useMemo(
    () => statusOptions.map((option) => ({ ...option, label: t(`workspace.status.${option.value}`, option.label) })),
    [t],
  );
  const statusLookup = useMemo(() => new Map(localizedStatusOptions.map((option) => [option.value, option.label])), [localizedStatusOptions]);
  const selectedTemplateId = useMemo(() => {
    const candidate = draft.templateId || DEFAULT_TEMPLATE_ID;
    const template = invoiceTemplates.find((entry) => entry.id === candidate);
    if (subscription.plan !== 'premium' && template && template.tier === 'premium') {
      return DEFAULT_TEMPLATE_ID;
    }
    return candidate;
  }, [draft.templateId, subscription.plan]);
  const activeTemplate = useMemo(
    () => localizedTemplates.find((template) => template.id === selectedTemplateId) ?? localizedTemplates[0],
    [localizedTemplates, selectedTemplateId],
  );

  useEffect(() => {
    if (draft.templateId !== selectedTemplateId) {
      setDraft((prev) => ({ ...prev, templateId: selectedTemplateId }));
    }
  }, [draft.templateId, selectedTemplateId]);

  const remainingDownloads = downloadsRemaining(subscription);
  const downloadResetsAt = downloadWindowReset(subscription);
  const downloadResetLabel = formatFriendlyDate(new Date(downloadResetsAt).toISOString(), locale);
  const freePlanLimitReached =
    subscription.plan !== 'premium' && Number.isFinite(remainingDownloads) && remainingDownloads <= 0;

  const outstandingTotal = useMemo(
    () =>
      recentInvoices.reduce((sum, invoice) => {
        return invoice.status === 'paid' ? sum : sum + invoice.total;
      }, 0),
    [recentInvoices],
  );

  const paidThisMonth = useMemo(() => {
    const now = new Date();
    const month = now.getMonth();
    const year = now.getFullYear();
    return recentInvoices
      .filter((invoice) => {
        if (invoice.status !== 'paid') return false;
        const issued = invoice.createdAt ? new Date(invoice.createdAt) : new Date(invoice.issueDate);
        return issued.getMonth() === month && issued.getFullYear() === year;
      })
      .reduce((sum, invoice) => sum + invoice.total, 0);
  }, [recentInvoices]);

  const clientComputation = useMemo(() => {
    const summaryMap = new Map<string, ClientSummary>();
    const detailMap = new Map<string, ClientDetail>();
    const manualEmailMap = new Map<string, ManagedClient>();
    const directoryMap = new Map<string, ClientDirectoryEntry>();

    const addDirectoryEntry = (entry: ClientDirectoryEntry) => {
      const name = entry.name?.trim();
      if (!name) {
        return;
      }

      const emailValue = entry.email?.trim() ?? '';
      const key = `${emailValue.toLowerCase()}::${name.toLowerCase()}`;
      if (!directoryMap.has(key)) {
        directoryMap.set(key, {
          name,
          email: emailValue,
          address: entry.address?.trim() ?? '',
          notes: entry.notes,
          phone: entry.phone,
        });
      }
    };

    for (const entry of clientDirectory) {
      addDirectoryEntry(entry);
    }

    for (const client of managedClients) {
      if (client.email) {
        manualEmailMap.set(client.email.trim().toLowerCase(), client);
      }

      const summary: ClientSummary = {
        key: client.id,
        name: client.name,
        email: client.email,
        invoices: 0,
        outstanding: 0,
        lastInvoice: undefined,
        status: 'draft',
        currency: draft.currency,
      };

      summaryMap.set(client.id, summary);

      detailMap.set(client.id, {
        summary,
        source: 'manual',
        manualRecord: client,
        invoices: [],
        address: client.address,
        phone: client.phone,
        notes: client.notes,
        company: client.company,
      });

      addDirectoryEntry({
        name: client.name,
        email: client.email,
        address: client.address,
        notes: client.notes,
        phone: client.phone,
      });
    }

    const sortedInvoices = [...recentInvoices].sort((a, b) => {
      const dateA = new Date(a.issueDate ?? a.createdAt ?? '').getTime();
      const dateB = new Date(b.issueDate ?? b.createdAt ?? '').getTime();
      return dateB - dateA;
    });

    for (const invoice of sortedInvoices) {
      const emailKey = invoice.clientEmail?.trim().toLowerCase();
      const manualMatch = emailKey ? manualEmailMap.get(emailKey) ?? null : null;
      const key = manualMatch ? manualMatch.id : invoice.clientEmail || invoice.clientName || invoice.id;
      const existingSummary = summaryMap.get(key);
      const outstanding = invoice.status === 'paid' ? 0 : invoice.total;
      const candidateDate = invoice.issueDate ? new Date(invoice.issueDate) : undefined;
      const previousDate = existingSummary?.lastInvoice ? new Date(existingSummary.lastInvoice) : undefined;
      const shouldReplace = candidateDate && (!previousDate || candidateDate > previousDate);

      const nextSummary: ClientSummary = {
        key,
        name: manualMatch?.name || invoice.clientName || t('workspace.table.clientPlaceholder', 'Client'),
        email: manualMatch?.email || invoice.clientEmail,
        invoices: (existingSummary?.invoices ?? 0) + 1,
        outstanding: (existingSummary?.outstanding ?? 0) + outstanding,
        lastInvoice: shouldReplace ? invoice.issueDate : existingSummary?.lastInvoice,
        status: shouldReplace ? invoice.status : existingSummary?.status ?? invoice.status,
        currency: invoice.currency || existingSummary?.currency || draft.currency,
      };

      summaryMap.set(key, nextSummary);

      const existingDetail = detailMap.get(key);
      const invoices = existingDetail ? existingDetail.invoices.slice(0) : [];
      invoices.push(invoice);
      invoices.sort((a, b) => {
        const dateA = new Date(a.issueDate ?? a.createdAt ?? '').getTime();
        const dateB = new Date(b.issueDate ?? b.createdAt ?? '').getTime();
        return dateB - dateA;
      });

      const detail: ClientDetail = {
        summary: nextSummary,
        source: existingDetail?.source ?? (manualMatch ? 'manual' : 'invoice'),
        manualRecord: existingDetail?.manualRecord ?? manualMatch,
        invoices: invoices.slice(0, 10),
        address: invoice.clientAddress || existingDetail?.address || manualMatch?.address,
        phone: existingDetail?.phone ?? manualMatch?.phone,
        notes: existingDetail?.notes ?? manualMatch?.notes,
        company: existingDetail?.company ?? manualMatch?.company,
      };

      detailMap.set(key, detail);

      addDirectoryEntry({
        name: nextSummary.name,
        email: nextSummary.email ?? '',
        address: detail.address ?? '',
        notes: detail.notes,
        phone: detail.phone,
      });
    }

    return {
      list: Array.from(summaryMap.values()).sort((a, b) => b.outstanding - a.outstanding),
      details: detailMap,
      directory: Array.from(directoryMap.values()),
    };
  }, [managedClients, recentInvoices, draft.currency, t]);

  const clientSummaries = clientComputation.list;
  const clientDetails = clientComputation.details;
  const clientDirectoryEntries = clientComputation.directory;
  const clientPanelEntries = useMemo(() => {
    const searchTerm = clientSearch.trim().toLowerCase();
    return clientSummaries
      .map((summary) => ({
        summary,
        detail: clientDetails.get(summary.key) ?? null,
      }))
      .filter((entry) => {
        if (!searchTerm) {
          return true;
        }
        const email = entry.summary.email ?? '';
        return (
          entry.summary.name.toLowerCase().includes(searchTerm) ||
          email.toLowerCase().includes(searchTerm)
        );
      })
      .sort((a, b) => a.summary.name.localeCompare(b.summary.name));
  }, [clientSummaries, clientDetails, clientSearch]);
  const selectedClientDetail =
    selectedClientId && selectedClientId !== 'new' ? clientDetails.get(selectedClientId) ?? null : null;
  const selectedManualClient = useMemo(() => {
    if (!selectedClientId || selectedClientId === 'new') {
      return null;
    }
    if (selectedClientDetail?.manualRecord) {
      return selectedClientDetail.manualRecord;
    }
    return managedClients.find((client) => client.id === selectedClientId) ?? null;
  }, [managedClients, selectedClientDetail, selectedClientId]);

  const activityFeed = useMemo(() => {
    return recentInvoices
      .map((invoice) => {
        const statusLabel =
          statusLookup.get(invoice.status) ?? t(`workspace.status.${invoice.status}`, invoice.status);
        const clientName = invoice.clientName || t('workspace.table.clientPlaceholder', 'Client');
        return {
          id: invoice.id,
          title: `${clientName} — ${statusLabel}`,
          amount: formatCurrency(invoice.total, invoice.currency, locale),
          timestamp: invoice.createdAt || invoice.issueDate,
          status: invoice.status,
        };
      })
      .sort((a, b) => {
        const dateA = new Date(a.timestamp ?? '').getTime();
        const dateB = new Date(b.timestamp ?? '').getTime();
        return dateB - dateA;
      });
  }, [locale, recentInvoices, statusLookup, t]);

  function updateDraftField<K extends keyof InvoiceDraft>(field: K, value: InvoiceDraft[K]) {
    setDraft((prev) => ({ ...prev, [field]: value }));
  }

  function addLine() {
    setDraft((prev) => ({ ...prev, lines: [...prev.lines, createEmptyLine()] }));
  }

  function updateLine(id: string, field: keyof InvoiceLine, value: string) {
    setDraft((prev) => ({
      ...prev,
      lines: prev.lines.map((line) => (line.id === id ? ensureLine(line, field, value) : line)),
    }));
  }

  function removeLine(id: string) {
    setDraft((prev) => {
      const remaining = prev.lines.filter((line) => line.id !== id);
      return {
        ...prev,
        lines: remaining.length ? remaining : [createEmptyLine()],
      };
    });
  }

  function handleSignOut() {
    clearSession();
    setSession(null);
    showToast(t('workspace.alert.signedOut', 'Signed out. Sign in again to sync invoices with Firebase.'), 'success');
    setSaveState('success');
  }

  function findClientMatches(query: string): ClientDirectoryEntry[] {
    const trimmed = query.trim().toLowerCase();
    if (!trimmed) {
      return [];
    }

    return clientDirectoryEntries
      .filter((entry) => {
        const nameMatch = entry.name.toLowerCase().includes(trimmed);
        const emailMatch = entry.email?.toLowerCase().includes(trimmed);
        return nameMatch || Boolean(emailMatch);
      })
      .slice(0, 5);
  }

  function handleClientNameChange(value: string) {
    updateDraftField('clientName', value);
    if (value.trim().length >= 2) {
      const matches = findClientMatches(value);
      setClientMatches(matches);
      setShowClientMatches(matches.length > 0);
    } else {
      setShowClientMatches(false);
    }
  }

  function applyClientMatch(entry: ClientDirectoryEntry) {
    setDraft((prev) => ({
      ...prev,
      clientName: entry.name,
      clientEmail: entry.email,
      clientAddress: entry.address,
    }));
    setClientMatches([]);
    setShowClientMatches(false);
  }

  function handleClientFieldChange(field: keyof ClientFormState, value: string) {
    setClientForm((prev) => ({ ...prev, [field]: value }));
    setClientFormError('');
  }

  function applyClientToDraftFields(payload: { name: string; email?: string; address?: string }) {
    setDraft((prev) => ({
      ...prev,
      clientName: payload.name,
      clientEmail: payload.email ?? '',
      clientAddress: payload.address ?? '',
    }));
    setShowClientManager(false);
    showToast(t('workspace.clients.applied', 'Client details added to the invoice.'), 'success');
  }

  function handleClientSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmedName = clientForm.name.trim();
    if (!trimmedName) {
      setClientFormError(t('workspace.clients.errorName', 'Enter a client name to continue.'));
      return;
    }

    const trimmedEmail = clientForm.email.trim();
    if (trimmedEmail) {
      const duplicate = managedClients.some(
        (client) =>
          client.id !== selectedManualClient?.id &&
          client.email &&
          client.email.toLowerCase() === trimmedEmail.toLowerCase(),
      );
      if (duplicate) {
        setClientFormError(t('workspace.clients.errorDuplicate', 'A client with this email already exists.'));
        return;
      }
    }

    const now = new Date().toISOString();

    if (selectedClientId === 'new' || !selectedManualClient) {
      const newClient: ManagedClient = {
        id: createClientId(),
        name: trimmedName,
        email: trimmedEmail,
        address: clientForm.address.trim(),
        company: clientForm.company.trim() || undefined,
        phone: clientForm.phone.trim() || undefined,
        notes: clientForm.notes.trim() || undefined,
        createdAt: now,
        updatedAt: now,
      };
      updateManagedClientState((prev) => [newClient, ...prev]);
      showToast(t('workspace.clients.added', 'Client saved to your directory.'), 'success');
      setSelectedClientId(newClient.id);
    } else {
      const updatedClient: ManagedClient = {
        ...selectedManualClient,
        name: trimmedName,
        email: trimmedEmail,
        address: clientForm.address.trim(),
        company: clientForm.company.trim() || undefined,
        phone: clientForm.phone.trim() || undefined,
        notes: clientForm.notes.trim() || undefined,
        updatedAt: now,
      };
      updateManagedClientState((prev) =>
        prev.map((client) => (client.id === updatedClient.id ? updatedClient : client)),
      );
      showToast(t('workspace.clients.updated', 'Client details updated.'), 'success');
      setSelectedClientId(updatedClient.id);
    }

    setClientFormError('');
  }

  function handleDeleteClient() {
    if (!selectedManualClient) {
      return;
    }
    updateManagedClientState((prev) => prev.filter((client) => client.id !== selectedManualClient.id));
    showToast(t('workspace.clients.removed', 'Client removed from your directory.'), 'success');
    setSelectedClientId(null);
    setClientForm({ ...EMPTY_CLIENT_FORM });
  }

  function handleUseClientDetail(detail: ClientDetail) {
    applyClientToDraftFields({
      name: detail.summary.name,
      email: detail.summary.email ?? detail.manualRecord?.email ?? '',
      address: detail.address ?? detail.manualRecord?.address ?? '',
    });
  }

  function handleUseClientForm() {
    applyClientToDraftFields({
      name: clientForm.name.trim(),
      email: clientForm.email.trim(),
      address: clientForm.address.trim(),
    });
  }

  function handleConvertDetail(detail: ClientDetail) {
    startCreateClient({
      name: detail.summary.name,
      email: detail.summary.email ?? detail.manualRecord?.email ?? '',
      address: detail.address ?? detail.manualRecord?.address ?? '',
      notes: detail.notes ?? '',
      company: detail.company ?? '',
      phone: detail.phone ?? '',
    });
  }

  async function handleSave(event?: FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    if (saveState === 'saving') {
      return;
    }

    setSaveState('saving');
    const savingToastId = showToast(t('workspace.toast.saving', 'Saving invoice…'), 'loading', {
      duration: 0,
    });

    const cleanedLines = cleanLines(draft.lines);
    const ensuredLines = cleanedLines.length ? cleanedLines : [createEmptyLine()];
    const preparedDraft: InvoiceDraft = {
      ...draft,
      clientName: draft.clientName.trim(),
      clientEmail: draft.clientEmail.trim(),
      clientAddress: draft.clientAddress.trim(),
      businessName: draft.businessName.trim(),
      businessAddress: draft.businessAddress.trim(),
      notes: draft.notes.trim(),
      lines: ensuredLines,
    };

    setDraft(preparedDraft);

    try {
      const computedTotals = calculateTotals(preparedDraft.lines, preparedDraft.taxRate);

      if (!firebaseConfigured) {
        const offlineRecord: InvoiceRecord = {
          id: `local-${Date.now()}`,
          ...preparedDraft,
          subtotal: computedTotals.subtotal,
          taxAmount: computedTotals.taxAmount,
          total: computedTotals.total,
          createdAt: new Date().toISOString(),
        };

        setRecentInvoices((prev) => [offlineRecord, ...prev].slice(0, 12));
        showToast(
          t('workspace.alert.offlineStored', 'Firebase is not configured. Stored invoice locally for this session.'),
          'success',
          { id: savingToastId },
        );
        setSaveState('success');
        setLoadingInvoices(false);
        return;
      }

      const saved = await saveInvoice({ draft: preparedDraft });
      setRecentInvoices((prev) => {
        const filtered = prev.filter((invoice) => invoice.id !== saved.id);
        return [saved, ...filtered].slice(0, 12);
      });
      showToast(t('workspace.alert.success', 'Invoice saved to Firestore.'), 'success', {
        id: savingToastId,
      });
      setSaveState('success');
    } catch (error) {
      console.error(error);
      showToast(
        error instanceof Error ? error.message : t('workspace.alert.error', 'Unable to save invoice.'),
        'error',
        {
          id: savingToastId,
          duration: 5000,
        },
      );
      setSaveState('error');
    }
  }

  async function handleDownload() {
    if (typeof window === 'undefined') {
      console.warn('Download is only available in the browser.');
      return;
    }

    const now = Date.now();
    const normalisedState = ensureSubscriptionWindow(subscription, now);
    if (
      normalisedState.downloadCount !== subscription.downloadCount ||
      normalisedState.windowStart !== subscription.windowStart ||
      normalisedState.plan !== subscription.plan
    ) {
      syncSubscription(normalisedState);
    }

    if (normalisedState.plan !== 'premium' && normalisedState.downloadCount >= FREE_PLAN_DOWNLOAD_LIMIT) {
      const resetDateIso = new Date(downloadWindowReset(normalisedState)).toISOString();
      const resetLabel = formatFriendlyDate(resetDateIso, locale);
      showToast(
        t(
          'workspace.subscription.limitReached',
          'Free plan limit reached for this 15-day window. Refreshes on {resetDate}. Upgrade for unlimited exports.',
          { resetDate: resetLabel },
        ),
        'error',
        { duration: 6000 },
      );
      setSaveState('error');
      return;
    }

    let downloadToastId: string | null = null;
    try {
      setDownloadingPdf(true);
      downloadToastId = showToast(t('workspace.toast.downloading', 'Generating PDF…'), 'loading', {
        duration: 0,
      });
      const blob = await generateInvoicePdf({
        draft: previewDraft,
        totals: previewTotals,
        template: activeTemplate,
        locale,
        currency: previewDraft.currency,
        statusLookup,
        translate: t,
      });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      const safeClient =
        previewDraft.clientName.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'invoice';
      link.href = url;
      link.download = `${safeClient}-${previewDraft.issueDate || 'draft'}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      if (normalisedState.plan !== 'premium') {
        const updatedState = incrementDownloadCount(normalisedState, now);
        syncSubscription(updatedState);
        const remaining = downloadsRemaining(updatedState);
        const resetDateIso = new Date(downloadWindowReset(updatedState)).toISOString();
        const resetLabel = formatFriendlyDate(resetDateIso, locale);
        const baseMessage = t('workspace.alert.downloaded', 'Invoice PDF downloaded.');
        const detailMessage =
          remaining > 0 && Number.isFinite(remaining)
            ? t(
                'workspace.subscription.remaining',
                '{remaining} downloads left in this 15-day window (resets on {resetDate}).',
                { remaining, resetDate: resetLabel },
              )
            : t(
                'workspace.subscription.noneRemaining',
                'No free downloads left until {resetDate}. Limits reset every 15 days.',
                { resetDate: resetLabel },
              );
        showToast(`${baseMessage} ${detailMessage}`, 'success', {
          id: downloadToastId ?? undefined,
          duration: 5000,
        });
      } else {
        showToast(t('workspace.alert.downloaded', 'Invoice PDF downloaded.'), 'success', {
          id: downloadToastId ?? undefined,
        });
      }
      setSaveState('success');
    } catch (error) {
      console.error(error);
      showToast(t('workspace.alert.error', 'Unable to save invoice.'), 'error', {
        id: downloadToastId ?? undefined,
        duration: 5000,
      });
      setSaveState('error');
    } finally {
      setDownloadingPdf(false);
    }
  }

  function handleSelectTemplate(templateId: string) {
    const template = invoiceTemplates.find((entry) => entry.id === templateId);
    if (!template) {
      return;
    }
    if (subscription.plan !== 'premium' && template.tier === 'premium') {
      showToast(
        t(
          'workspace.subscription.templateLocked',
          'Upgrade to the Premium plan to use this template and unlock unlimited downloads.',
        ),
        'error',
        { duration: 5000 },
      );
      setSaveState('error');
      return;
    }
    setDraft((prev) => ({ ...prev, templateId }));
  }

  async function handleStartSubscription() {
    try {
      setSubscribing(true);
      const stripe = await loadStripeClient();
      if (!stripe) {
        throw new Error(t('workspace.subscription.missingStripe', 'Stripe failed to initialise.'));
      }
      const response = await fetch('/api/subscription/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      if (!response.ok) {
        throw new Error(t('workspace.subscription.checkoutError', 'Unable to start Stripe checkout right now.'));
      }
      const payload = (await response.json()) as { sessionId?: string; url?: string };
      if (payload.sessionId) {
        const { error } = await stripe.redirectToCheckout({ sessionId: payload.sessionId });
        if (error) {
          throw new Error(error.message ?? 'Stripe redirect failed.');
        }
      } else if (payload.url) {
        window.location.assign(payload.url);
      } else {
        throw new Error('Stripe session could not be created.');
      }
    } catch (error) {
      console.error(error);
      setSubscribing(false);
      showToast(
        error instanceof Error
          ? error.message
          : t('workspace.subscription.checkoutError', 'Unable to start Stripe checkout right now.'),
        'error',
        { duration: 5000 },
      );
      setSaveState('error');
    }
  }

  function renderTemplateThumbnails({ showDetails = false }: { showDetails?: boolean } = {}) {
    return (
      <div className={`template-thumbnail-grid${showDetails ? ' template-thumbnail-grid--detailed' : ''}`}>
        {localizedTemplates.map((template) => {
          const isActive = template.id === selectedTemplateId;
          const isLocked = subscription.plan !== 'premium' && template.tier === 'premium';
          const primaryHighlight = template.highlights[0] ?? template.description;
          return (
            <button
              key={template.id}
              type="button"
              onClick={() => handleSelectTemplate(template.id)}
              className={`template-thumbnail${isActive ? ' template-thumbnail--active' : ''}${
                isLocked ? ' template-thumbnail--locked' : ''
              }`}
              aria-pressed={isActive}
              aria-disabled={isLocked}
              title={
                isLocked
                  ? t('workspace.subscription.templateLockedTitle', 'Premium template — upgrade to apply')
                  : undefined
              }
            >
              {isLocked && (
                <span className="template-thumbnail__lock" aria-hidden="true">
                  🔒 {t('workspace.subscription.premiumBadge', 'Premium')}
                </span>
              )}
              <span className="template-thumbnail__preview" style={{ background: template.accent }} aria-hidden="true">
                <span className="template-thumbnail__preview-header">{template.name}</span>
                <span className="template-thumbnail__preview-body" />
                <span className="template-thumbnail__preview-footer">{primaryHighlight}</span>
              </span>
              <span className="template-thumbnail__label">
                <strong>{template.name}</strong>
                <small>{template.bestFor}</small>
              </span>
              {showDetails && (
                <ul className="template-thumbnail__highlights">
                  {template.highlights.map((highlight) => (
                    <li key={highlight}>{highlight}</li>
                  ))}
                </ul>
              )}
            </button>
          );
        })}
      </div>
    );
  }

  function renderDashboard() {
    return (
      <div className="workspace-section">
        <div className="workspace-metrics">
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.outstanding', 'Outstanding balance')}</span>
              <span className="metric-icon">💳</span>
            </header>
            <strong className="metric-value">{formatCurrency(outstandingTotal, draft.currency, locale)}</strong>
            <p>
              {recentInvoices.length
                ? t('workspace.dashboard.trackCount', `${recentInvoices.length} invoices tracked`, { count: recentInvoices.length })
                : t('workspace.dashboard.noInvoices', 'No invoices yet')}
            </p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.paid', 'Paid this month')}</span>
              <span className="metric-icon">✅</span>
            </header>
            <strong className="metric-value">{formatCurrency(paidThisMonth, draft.currency, locale)}</strong>
            <p>{t('workspace.dashboard.reconciled', 'Auto-reconciled with client receipts')}</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.paymentTime', 'Average payment time')}</span>
              <span className="metric-icon">⏱️</span>
            </header>
            <strong className="metric-value">{t('workspace.dashboard.paymentDuration', '9.4 days')}</strong>
            <p>{t('workspace.dashboard.paymentDelta', 'Down 2.1 days vs last month')}</p>
          </article>
          <article className="metric-card">
            <header>
              <span className="metric-label">{t('workspace.dashboard.templates', 'Templates in use')}</span>
              <span className="metric-icon">🖌️</span>
            </header>
            <strong className="metric-value">{localizedTemplates.length}</strong>
            <p>{t('workspace.dashboard.templatesHint', 'Switch templates from the gallery')}</p>
          </article>
        </div>

        <AdSlot
          label={t('ads.workspace.dashboardLeaderboard', 'Dashboard leaderboard (970×250)')}
          description={t(
            'ads.workspace.dashboardLeaderboardDescription',
            'Perfect for sponsor campaigns, webinar promotions, or integration announcements in the workspace overview.',
          )}
          className="workspace-ad"
        />

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.recent.heading', 'Recent invoices')}</h2>
              <p>{t('workspace.recent.description', 'Monitor drafts, sent documents, and payments at a glance.')}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
              {t('workspace.actions.createInvoice', 'Create invoice')}
            </button>
          </header>
          {loadingInvoices ? (
            <div className="empty-state">{t('workspace.recent.loading', 'Loading invoices…')}</div>
          ) : recentInvoices.length ? (
            <div className="table">
              <div className="table__row table__row--head">
                <span>{t('workspace.table.client', 'Client')}</span>
                <span>{t('workspace.table.status', 'Status')}</span>
                <span>{t('workspace.table.issued', 'Issued')}</span>
                <span>{t('workspace.table.due', 'Due')}</span>
                <span>{t('workspace.table.total', 'Total')}</span>
              </div>
              {recentInvoices.map((invoice) => (
                <div key={invoice.id} className="table__row">
                  <span>
                    <strong>{invoice.clientName || t('workspace.table.clientPlaceholder', 'Client')}</strong>
                    <small>{invoice.clientEmail || '—'}</small>
                  </span>
                  <span>
                    <span className={`status-pill status-pill--${invoice.status}`}>{statusLookup.get(invoice.status)}</span>
                  </span>
                  <span>{formatFriendlyDate(invoice.issueDate, locale)}</span>
                  <span>{formatFriendlyDate(invoice.dueDate, locale)}</span>
                  <span>{formatCurrency(invoice.total, invoice.currency, locale)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">{t('workspace.recent.empty', 'Save your first invoice to populate the dashboard.')}</div>
          )}
        </div>

        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.templates.spotlight', 'Template spotlight')}</h2>
              <p>{t('workspace.templates.spotlightDescription', 'Highlighting the most popular template with clients this week.')}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => setActiveSection('templates')}>
              {t('workspace.templates.browse', 'Browse gallery')}
            </button>
          </header>
          <div className="template-spotlight">
            <div className="template-spotlight__preview" style={{ background: localizedTemplates[0].accent }}>
              <span>{localizedTemplates[0].name}</span>
            </div>
            <div className="template-spotlight__body">
              <strong>{localizedTemplates[0].name}</strong>
              <p>{localizedTemplates[0].description}</p>
              <ul>
                {localizedTemplates[0].highlights.map((highlight) => (
                  <li key={highlight}>{highlight}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </div>
    );
  }


  function renderInvoices() {
    return (
      <div className="workspace-section">
        <div
          aria-hidden="true"
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            pointerEvents: 'none',
            visibility: 'hidden',
            width: 'auto',
            height: 'auto',
            zIndex: -1,
          }}
        >
          <InvoicePreview
            ref={previewRef}
            draft={previewDraft}
            totals={previewTotals}
            template={activeTemplate}
            locale={locale}
            currency={previewDraft.currency}
            statusLookup={statusLookup}
            t={t}
          />
        </div>
        <AdSlot
          label={t('ads.workspace.editorBanner', 'Workspace banner (970×250)')}
          description={t(
            'ads.workspace.editorBannerDescription',
            'Feature sponsor campaigns or upgrade prompts before the invoice editor.',
          )}
          className="workspace-ad workspace-ad--banner"
        />
        <section className="panel panel--stack">
          <header className="panel__header panel__header--stacked">
            <div>
              <h2>{t('workspace.invoice.heading', 'Invoice workspace')}</h2>
              <p>
                {t(
                  'workspace.invoice.description',
                  'Toggle between editing your draft and reviewing the formatted preview.',
                )}
              </p>
            </div>
          </header>
              <div className="panel__section">
                <header className="panel__section-header">
                  <div>
                    <h3>{t('workspace.nav.templates', 'Templates')}</h3>
                    <p>{t('workspace.templates.instructions', 'Select a template thumbnail to style your invoice.')}</p>
                  </div>
                  <span className="badge">
                    {t('workspace.templates.count', `${localizedTemplates.length} options`, {
                      count: localizedTemplates.length,
                    })}
                  </span>
                </header>
                {renderTemplateThumbnails()}
                {subscription.plan !== 'premium' && (
                  <p className={`download-hint${freePlanLimitReached ? ' download-hint--warning' : ''}`} role="status">
                    {freePlanLimitReached
                      ? t(
                          'workspace.subscription.freeLimitHint',
                          'Free plan limit reached for this 15-day window. Next refresh on {resetDate}. Upgrade for unlimited PDFs.',
                          { resetDate: downloadResetLabel },
                        )
                      : t(
                          'workspace.subscription.freeHint',
                          '{remaining} downloads left in this 15-day window (resets on {resetDate}).',
                          {
                            remaining: Math.max(0, Number.isFinite(remainingDownloads) ? remainingDownloads : 0),
                            resetDate: downloadResetLabel,
                          },
                        )}
                  </p>
                )}
              </div>

              {invoiceView === 'edit' ? (
                <form id={formId} className="invoice-form" onSubmit={handleSave}>
                  <div className="invoice-form__grid">
                    <section className="editor-card invoice-form__card">
                  <header className="editor-card__header">
                    <div>
                      <h2>{t('workspace.section.business', 'Business & client')}</h2>
                      <p>{t('workspace.section.businessDescription', 'Details shown at the top of every invoice.')}</p>
                    </div>
                  </header>
                  <div className="editor-card__grid">
                    <div>
                      <label htmlFor="businessName">{t('workspace.field.businessName', 'Business name')}</label>
                      <input
                        id="businessName"
                        type="text"
                        value={draft.businessName}
                        placeholder={t('workspace.placeholder.businessName', 'Atlas Studio')}
                        onChange={(event) => updateDraftField('businessName', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="businessAddress">{t('workspace.field.businessAddress', 'Business address')}</label>
                      <input
                        id="businessAddress"
                        type="text"
                        value={draft.businessAddress}
                        placeholder={t('workspace.placeholder.businessAddress', '88 Harbor Lane, Portland, OR')}
                        onChange={(event) => updateDraftField('businessAddress', event.target.value)}
                      />
                    </div>
                    <div className="client-field">
                      <label htmlFor="clientName">{t('workspace.field.clientName', 'Client name')}</label>
                      <input
                        id="clientName"
                        type="text"
                        value={draft.clientName}
                        placeholder={t('workspace.placeholder.clientName', 'Northwind Co.')}
                        autoComplete="organization"
                        aria-autocomplete="list"
                        aria-expanded={showClientMatches}
                        aria-controls="client-suggestions"
                        onChange={(event) => handleClientNameChange(event.target.value)}
                        onFocus={() => {
                          if (draft.clientName.trim().length >= 2) {
                            const matches = findClientMatches(draft.clientName);
                            setClientMatches(matches);
                            setShowClientMatches(matches.length > 0);
                          }
                        }}
                        onBlur={() => {
                          setTimeout(() => setShowClientMatches(false), 120);
                        }}
                      />
                      <p className="input-hint">{t('workspace.clients.autofillHint', 'Start typing to autofill saved client details.')}</p>
                      {showClientMatches && clientMatches.length > 0 && (
                        <ul id="client-suggestions" className="client-suggestions" role="listbox">
                          {clientMatches.map((entry) => (
                            <li key={entry.email} role="option">
                              <button
                                type="button"
                                onMouseDown={(event) => event.preventDefault()}
                                onClick={() => applyClientMatch(entry)}
                              >
                                <span>{entry.name}</span>
                                <small>{entry.email}</small>
                                <small>{entry.address}</small>
                              </button>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>
                    <div>
                      <label htmlFor="clientEmail">{t('workspace.field.clientEmail', 'Client email')}</label>
                      <input
                        id="clientEmail"
                        type="email"
                        value={draft.clientEmail}
                        placeholder={t('workspace.placeholder.clientEmail', 'client@email.com')}
                        onChange={(event) => updateDraftField('clientEmail', event.target.value)}
                      />
                    </div>
                    <div className="editor-card__full">
                      <label htmlFor="clientAddress">{t('workspace.field.clientAddress', 'Client address')}</label>
                      <textarea
                        id="clientAddress"
                        value={draft.clientAddress}
                        placeholder={t('workspace.placeholder.clientAddress', 'Via Tammaricella 128, Rome, Italy')}
                        rows={2}
                        onChange={(event) => updateDraftField('clientAddress', event.target.value)}
                      />
                    </div>
                  </div>
                </section>
                <section className="editor-card invoice-form__card">
                  <header className="editor-card__header">
                    <div>
                      <h2>{t('workspace.section.terms', 'Invoice terms')}</h2>
                      <p>{t('workspace.section.termsDescription', 'Dates, currency, and tax rates applied to the totals.')}</p>
                    </div>
                  </header>
                  <div className="editor-card__grid editor-card__grid--compact">
                    <div>
                      <label htmlFor="issueDate">{t('workspace.field.issueDate', 'Issue date')}</label>
                      <input
                        id="issueDate"
                        type="date"
                        value={draft.issueDate?.slice(0, 10) || ''}
                        onChange={(event) => updateDraftField('issueDate', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="dueDate">{t('workspace.field.dueDate', 'Due date')}</label>
                      <input
                        id="dueDate"
                        type="date"
                        value={draft.dueDate?.slice(0, 10) || ''}
                        onChange={(event) => updateDraftField('dueDate', event.target.value)}
                      />
                    </div>
                    <div>
                      <label htmlFor="currency">{t('workspace.field.currency', 'Currency')}</label>
                      <select
                        id="currency"
                        value={draft.currency.toUpperCase()}
                        onChange={(event) => {
                          const next = event.target.value.trim().toUpperCase();
                          if (/^[A-Z]{3}$/u.test(next)) {
                            updateDraftField('currency', next);
                          }
                        }}
                      >
                        {currencyOptions.map((option) => (
                          <option key={option.code} value={option.code}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label htmlFor="status">{t('workspace.field.status', 'Status')}</label>
                      <select
                        id="status"
                        value={draft.status}
                        onChange={(event) => updateDraftField('status', event.target.value as InvoiceStatus)}
                      >
                        {localizedStatusOptions.map((option) => (
                          <option key={option.value} value={option.value}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label htmlFor="taxRate">{t('workspace.field.tax', 'Tax rate')}</label>
                      <div className="input-with-addon">
                        <input
                          id="taxRate"
                          type="number"
                          value={draft.taxRate}
                          min="0"
                          step="0.1"
                          onChange={(event) => updateDraftField('taxRate', Number(event.target.value))}
                        />
                        <span className="input-addon">%</span>
                      </div>
                    </div>
                  </div>
                  <div>
                    <label htmlFor="notes">{t('workspace.section.notes', 'Notes')}</label>
                    <textarea
                      id="notes"
                      value={draft.notes}
                      placeholder={t('workspace.notes.placeholder', 'Share payment instructions or a thank you.')}
                      rows={3}
                      onChange={(event) => updateDraftField('notes', event.target.value)}
                    />
                  </div>
                </section>
              </div>

              <section className="editor-card invoice-form__card invoice-form__card--full">
                <div className="line-items">
                  <div className="line-items__header">
                    <div>
                      <h2>{t('workspace.section.lines', 'Line items')}</h2>
                      <p>{t('workspace.section.linesDescription', 'Outline the services, quantity, and rate for this invoice.')}</p>
                    </div>
                    <button type="button" className="button button--ghost" onClick={addLine}>
                      {t('workspace.lines.add', 'Add line')}
                    </button>
                  </div>
                  <div className="line-items__table">
                    <div className="line-items__row line-items__row--head">
                      <span>{t('workspace.lines.description', 'Description')}</span>
                      <span>{t('workspace.lines.quantity', 'Qty')}</span>
                      <span>{t('workspace.lines.rate', 'Rate')}</span>
                      <span>{t('workspace.lines.amount', 'Amount')}</span>
                      <span className="sr-only">{t('workspace.lines.remove', 'Remove')}</span>
                    </div>
                    {draft.lines.map((line, index) => {
                      const lineTotal = formatCurrency(line.quantity * line.rate, draft.currency, locale);
                      return (
                        <div key={line.id} className="line-items__row">
                          <div>
                            <label htmlFor={`description-${line.id}`} className="sr-only">
                              {t('workspace.lines.description', 'Description')} {index + 1}
                            </label>
                            <input
                              id={`description-${line.id}`}
                              type="text"
                              value={line.description}
                              placeholder={t('workspace.lines.descriptionPlaceholder', 'Service provided')}
                              onChange={(event) => updateLine(line.id, 'description', event.target.value)}
                            />
                          </div>
                          <div>
                            <label htmlFor={`quantity-${line.id}`} className="sr-only">
                              {t('workspace.lines.quantity', 'Qty')} {index + 1}
                            </label>
                            <input
                              id={`quantity-${line.id}`}
                              type="number"
                              min="1"
                              value={line.quantity}
                              onChange={(event) => updateLine(line.id, 'quantity', event.target.value)}
                            />
                          </div>
                          <div>
                            <label htmlFor={`rate-${line.id}`} className="sr-only">
                              {t('workspace.lines.rate', 'Rate')} {index + 1}
                            </label>
                            <input
                              id={`rate-${line.id}`}
                              type="number"
                              min="0"
                              step="0.01"
                              value={line.rate}
                              onChange={(event) => updateLine(line.id, 'rate', event.target.value)}
                            />
                          </div>
                          <div className="line-items__amount" aria-live="polite">
                            {lineTotal}
                          </div>
                          <button
                            type="button"
                            onClick={() => removeLine(line.id)}
                            aria-label={`${t('workspace.lines.remove', 'Remove')} ${index + 1}`}
                          >
                            ×
                          </button>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </section>

              <section className="editor-card invoice-form__card invoice-form__summary">
                <div className="invoice-form__summary-totals">
                  <div className="invoice-form__summary-row">
                    <span>{t('workspace.summary.subtotal', 'Subtotal')}</span>
                    <strong>{formatCurrency(totals.subtotal, draft.currency, locale)}</strong>
                  </div>
                  <div className="invoice-form__summary-row">
                    <span>{t('workspace.summary.tax', 'Tax')}</span>
                    <strong>{formatCurrency(totals.taxAmount, draft.currency, locale)}</strong>
                  </div>
                  <div className="invoice-form__summary-row invoice-form__summary-row--emphasis">
                    <span>{t('workspace.summary.total', 'Total')}</span>
                    <strong>{formatCurrency(totals.total, draft.currency, locale)}</strong>
                  </div>
                </div>
              </section>
            </form>
          ) : (
            <InvoicePreview
              draft={previewDraft}
              totals={previewTotals}
              template={activeTemplate}
              locale={locale}
              currency={previewDraft.currency}
              statusLookup={statusLookup}
              t={t}
            />
          )}
          <div
            className="workspace-action-dock"
            role="region"
            aria-label={t('workspace.invoice.actions', 'Invoice actions')}
          >
            <div
              className="workspace-action-dock__toggle"
              role="group"
              aria-label={t('workspace.invoice.viewLabel', 'Invoice workspace view')}
            >
              <button
                type="button"
                className={`workspace-action-dock__toggle-button${
                  invoiceView === 'edit' ? ' workspace-action-dock__toggle-button--active' : ''
                }`}
                onClick={() => setInvoiceView('edit')}
                aria-pressed={invoiceView === 'edit'}
              >
                ✏️ {t('workspace.view.edit', 'Edit draft')}
              </button>
              <button
                type="button"
                className={`workspace-action-dock__toggle-button${
                  invoiceView === 'preview' ? ' workspace-action-dock__toggle-button--active' : ''
                }`}
                onClick={() => setInvoiceView('preview')}
                aria-pressed={invoiceView === 'preview'}
              >
                👀 {t('workspace.view.preview', 'Preview')}
              </button>
            </div>
            <div className="workspace-action-dock__buttons">
              <button
                type="button"
                className="button button--ghost"
                onClick={() => setShowSavedInvoices(true)}
              >
                📂 {t('workspace.actions.savedInvoices', 'Saved invoices')}
              </button>
              <button
                type="button"
                className="button button--ghost"
                onClick={handleDownload}
                disabled={downloadingPdf}
              >
                {downloadingPdf
                  ? t('workspace.actions.downloading', 'Generating…')
                  : t('workspace.actions.download', 'Download PDF')}
              </button>
              <button
                type="submit"
                form={formId}
                className="button button--primary"
                disabled={saveState === 'saving'}
              >
                {saveState === 'saving'
                  ? t('workspace.actions.saving', 'Saving…')
                  : t('workspace.actions.save', 'Save invoice')}
              </button>
            </div>
          </div>
        </section>
      </div>
    );
  }

  function renderClientForm(mode: 'create' | 'edit') {
    const isCreate = mode === 'create';
    const title = isCreate
      ? t('workspace.clients.formTitleCreate', 'Add client to directory')
      : t('workspace.clients.formTitleEdit', 'Edit client details');
    const subtitle = isCreate
      ? t('workspace.clients.formSubtitleCreate', 'Store frequent contacts so you can reuse them while drafting invoices.')
      : t('workspace.clients.formSubtitleEdit', 'Update saved contact information to keep future invoices accurate.');
    const submitLabel = isCreate
      ? t('workspace.clients.formSubmitCreate', 'Save client')
      : t('workspace.clients.formSubmitEdit', 'Update client');

    return (
      <form className="client-form" onSubmit={handleClientSubmit} noValidate>
        <header className="client-form__header">
          <div>
            <h3>{title}</h3>
            <p>{subtitle}</p>
          </div>
          <button
            type="button"
            className="button button--ghost"
            onClick={handleUseClientForm}
            disabled={!clientForm.name.trim()}
          >
            {t('workspace.clients.useInInvoice', 'Use in invoice')}
          </button>
        </header>
        <div className="client-form__grid">
          <label className="client-form__field">
            <span>{t('workspace.field.clientName', 'Client name')}</span>
            <input
              type="text"
              value={clientForm.name}
              onChange={(event) => handleClientFieldChange('name', event.target.value)}
              placeholder={t('workspace.placeholder.clientName', 'Northwind Co.')}
              required
            />
          </label>
          <label className="client-form__field">
            <span>{t('workspace.field.clientEmail', 'Client email')}</span>
            <input
              type="email"
              value={clientForm.email}
              onChange={(event) => handleClientFieldChange('email', event.target.value)}
              placeholder={t('workspace.placeholder.clientEmail', 'client@email.com')}
            />
          </label>
          <label className="client-form__field">
            <span>{t('workspace.clients.company', 'Company')}</span>
            <input
              type="text"
              value={clientForm.company}
              onChange={(event) => handleClientFieldChange('company', event.target.value)}
              placeholder={t('workspace.clients.companyPlaceholder', 'Department or business unit (optional)')}
            />
          </label>
          <label className="client-form__field">
            <span>{t('workspace.clients.phone', 'Phone')}</span>
            <input
              type="tel"
              value={clientForm.phone}
              onChange={(event) => handleClientFieldChange('phone', event.target.value)}
              placeholder={t('workspace.clients.phonePlaceholder', '+1 555-0100')}
            />
          </label>
          <label className="client-form__field client-form__field--full">
            <span>{t('workspace.field.clientAddress', 'Client address')}</span>
            <textarea
              rows={3}
              value={clientForm.address}
              onChange={(event) => handleClientFieldChange('address', event.target.value)}
              placeholder={t('workspace.placeholder.clientAddress', 'Via Tammaricella 128, Rome, Italy')}
            />
          </label>
          <label className="client-form__field client-form__field--full">
            <span>{t('workspace.clients.notes', 'Notes')}</span>
            <textarea
              rows={3}
              value={clientForm.notes}
              onChange={(event) => handleClientFieldChange('notes', event.target.value)}
              placeholder={t('workspace.clients.notesPlaceholder', 'Preferred payment terms, languages, or reminders')}
            />
          </label>
        </div>
        {clientFormError && (
          <div className="client-form__error" role="alert">
            {clientFormError}
          </div>
        )}
        <div className="client-form__actions">
          <button type="button" className="button button--ghost" onClick={closeClientManager}>
            {t('workspace.clients.cancel', 'Close')}
          </button>
          <div className="client-form__actions-secondary">
            {mode === 'edit' && (
              <button type="button" className="button button--ghost" onClick={handleDeleteClient}>
                {t('workspace.clients.delete', 'Remove client')}
              </button>
            )}
            <button type="submit" className="button button--primary">
              {submitLabel}
            </button>
          </div>
        </div>
      </form>
    );
  }

  function renderClientDetail(detail: ClientDetail) {
    const invoiceCountLabel = t('workspace.clients.invoiceCount', '{count} invoices', {
      count: detail.summary.invoices,
    });
    const outstandingLabel = formatCurrency(
      detail.summary.outstanding,
      detail.summary.currency || draft.currency,
      locale,
    );

    return (
      <div className="client-detail">
        <header className="client-detail__header">
          <div>
            <h3>{detail.summary.name}</h3>
            <p>{detail.summary.email || t('workspace.clients.noEmail', 'No email on record')}</p>
            {detail.address && <span>{detail.address}</span>}
          </div>
          <div className="client-detail__actions">
            <button type="button" className="button button--ghost" onClick={() => handleUseClientDetail(detail)}>
              {t('workspace.clients.useInInvoice', 'Use in invoice')}
            </button>
            {detail.source === 'invoice' && !detail.manualRecord && (
              <button type="button" className="button button--primary" onClick={() => handleConvertDetail(detail)}>
                {t('workspace.clients.saveToDirectory', 'Save to directory')}
              </button>
            )}
          </div>
        </header>
        <dl className="client-detail__stats">
          <div>
            <dt>{t('workspace.clients.outstanding', 'Outstanding')}</dt>
            <dd>{outstandingLabel}</dd>
          </div>
          <div>
            <dt>{t('workspace.clients.invoices', 'Invoices')}</dt>
            <dd>{invoiceCountLabel}</dd>
          </div>
          <div>
            <dt>{t('workspace.clients.lastInvoice', 'Last invoice')}</dt>
            <dd>
              {detail.summary.lastInvoice
                ? formatFriendlyDate(detail.summary.lastInvoice, locale)
                : t('workspace.clients.none', 'Not yet issued')}
            </dd>
          </div>
          <div>
            <dt>{t('workspace.clients.status', 'Latest status')}</dt>
            <dd>
              <span className={`status-pill status-pill--${detail.summary.status}`}>
                {statusLookup.get(detail.summary.status) ?? detail.summary.status}
              </span>
            </dd>
          </div>
        </dl>
        <section className="client-detail__section">
          <h4>{t('workspace.clients.contactInfo', 'Contact details')}</h4>
          <ul className="client-detail__meta">
            {detail.company && (
              <li>
                <strong>{t('workspace.clients.company', 'Company')}:</strong> {detail.company}
              </li>
            )}
            {detail.phone && (
              <li>
                <strong>{t('workspace.clients.phone', 'Phone')}:</strong> {detail.phone}
              </li>
            )}
            {detail.notes && (
              <li>
                <strong>{t('workspace.clients.notes', 'Notes')}:</strong> {detail.notes}
              </li>
            )}
          </ul>
        </section>
        <section className="client-detail__section">
          <h4>{t('workspace.clients.recentInvoices', 'Recent invoices')}</h4>
          {detail.invoices.length ? (
            <ul className="client-detail__invoices">
              {detail.invoices.map((invoice) => (
                <li key={invoice.id}>
                  <div>
                    <strong>{formatFriendlyDate(invoice.issueDate, locale)}</strong>
                    <span>{invoice.id}</span>
                  </div>
                  <div>
                    <span>{formatCurrency(invoice.total, invoice.currency, locale)}</span>
                    <span className={`status-pill status-pill--${invoice.status}`}>
                      {statusLookup.get(invoice.status) ?? invoice.status}
                    </span>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className="client-detail__empty">
              {t('workspace.clients.noInvoices', 'No invoices recorded for this client yet.')}
            </p>
          )}
        </section>
      </div>
    );
  }

  function renderTemplateGallery() {
    const planTitle =
      subscription.plan === 'premium'
        ? t('workspace.subscription.premiumTitle', 'Premium plan active')
        : t('workspace.subscription.freeTitle', 'Free plan');
    const planDetail =
      subscription.plan === 'premium'
        ? t('workspace.subscription.premiumDetail', 'Unlimited downloads and every template are unlocked.')
        : freePlanLimitReached
        ? t(
            'workspace.subscription.freeDepleted',
            'You have used all {limit} downloads for this 15-day window. Refreshes on {resetDate}.',
            { limit: FREE_PLAN_DOWNLOAD_LIMIT, resetDate: downloadResetLabel },
          )
        : t(
            'workspace.subscription.freeDetail',
            '{remaining} of {limit} downloads left in this 15-day window (resets on {resetDate}).',
            {
              remaining: Math.max(0, Number.isFinite(remainingDownloads) ? remainingDownloads : 0),
              limit: FREE_PLAN_DOWNLOAD_LIMIT,
              resetDate: downloadResetLabel,
            },
          );

    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.templates.galleryHeading', 'Template gallery')}</h2>
              <p>
                {t('workspace.templates.galleryDescription', 'Explore each template layout before applying it to your invoice.')}
              </p>
            </div>
            <div className="panel__header-meta">
              <span className="badge">
                {t('workspace.templates.count', `${localizedTemplates.length} options`, {
                  count: localizedTemplates.length,
                })}
              </span>
            </div>
          </header>
          <div
            className={`subscription-banner${subscription.plan === 'premium' ? ' subscription-banner--premium' : ''}`}
            role="status"
            aria-live="polite"
          >
            <div className="subscription-banner__copy">
              <strong>{planTitle}</strong>
              <p>{planDetail}</p>
            </div>
            {subscription.plan === 'premium' ? (
              <span className="subscription-banner__meta">
                {t('workspace.subscription.premiumMeta', 'Thanks for supporting Easy Invoice GM7.')}
              </span>
            ) : (
              <button
                type="button"
                className="button button--primary"
                onClick={handleStartSubscription}
                disabled={subscribing}
              >
                {subscribing
                  ? t('workspace.subscription.redirecting', 'Redirecting to Stripe…')
                  : t('workspace.subscription.upgradeCta', 'Upgrade with Stripe')}
              </button>
            )}
          </div>
          {renderTemplateThumbnails({ showDetails: true })}
        </div>
      </div>
    );
  }

  function renderClients() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.clients.heading', 'Client insights')}</h2>
              <p>{t('workspace.clients.description', 'Outstanding balances and recent invoice activity per client.')}</p>
            </div>
            <button type="button" className="button button--ghost" onClick={() => startCreateClient()}>
              {t('workspace.clients.add', 'Add client')}
            </button>
          </header>
          {clientSummaries.length ? (
            <div className="cards-grid">
              {clientSummaries.map((client) => (
                <article
                  key={client.key}
                  className="client-card"
                  role="button"
                  tabIndex={0}
                  onClick={() => openClientManagerFor(client.key)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      openClientManagerFor(client.key);
                    }
                  }}
                >
                  <header>
                    <div>
                      <strong>{client.name}</strong>
                      {client.email && <span>{client.email}</span>}
                    </div>
                    <span className={`status-pill status-pill--${client.status}`}>
                      {statusLookup.get(client.status)}
                    </span>
                  </header>
                  <dl>
                    <div>
                      <dt>{t('workspace.clients.outstanding', 'Outstanding')}</dt>
                      <dd>{formatCurrency(client.outstanding, client.currency || draft.currency, locale)}</dd>
                    </div>
                    <div>
                      <dt>{t('workspace.clients.invoices', 'Invoices')}</dt>
                      <dd>{client.invoices}</dd>
                    </div>
                    <div>
                      <dt>{t('workspace.clients.lastInvoice', 'Last invoice')}</dt>
                      <dd>{formatFriendlyDate(client.lastInvoice, locale)}</dd>
                    </div>
                  </dl>
                </article>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              {t('workspace.clients.empty', 'Save an invoice to build the client directory.')}
            </div>
          )}
        </div>
      </div>
    );
  }

  function renderActivity() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.activity.heading', 'Activity timeline')}</h2>
              <p>{t('workspace.activity.description', 'Review invoice saves, reminders, and payments from newest to oldest.')}</p>
            </div>
          </header>
          {activityFeed.length ? (
            <ul className="timeline">
              {activityFeed.map((item) => (
                <li key={item.id}>
                  <div className="timeline__marker" />
                  <div className="timeline__body">
                    <div className="timeline__title">
                      <strong>{item.title}</strong>
                      <span className={`status-pill status-pill--${item.status}`}>{statusLookup.get(item.status)}</span>
                    </div>
                    <p>{item.amount}</p>
                    <small>{formatFriendlyDate(item.timestamp, locale)}</small>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state">
              {t('workspace.activity.empty', 'Activity will appear once invoices are saved.')}
            </div>
          )}
        </div>
      </div>
    );
  }

  function renderSettings() {
    return (
      <div className="workspace-section">
        <div className="panel">
          <header className="panel__header">
            <div>
              <h2>{t('workspace.settings.heading', 'Workspace settings')}</h2>
              <p>{t('workspace.settings.description', 'Default information used across every new invoice.')}</p>
            </div>
          </header>
          <dl className="settings-grid">
            <div>
              <dt>{t('workspace.settings.businessName', 'Business name')}</dt>
              <dd>{draft.businessName || t('workspace.placeholder.businessName', 'Atlas Studio')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.businessAddress', 'Business address')}</dt>
              <dd>{draft.businessAddress || t('workspace.placeholder.businessAddress', '88 Harbor Lane, Portland, OR')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.currencyDefault', 'Default currency')}</dt>
              <dd>{draft.currency}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.taxDefault', 'Default tax rate')}</dt>
              <dd>{(draft.taxRate * 100).toFixed(1)}%</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.reminders', 'Reminder emails')}</dt>
              <dd>{t('workspace.settings.reminderDetails', 'Enabled — 3 days before due date')}</dd>
            </div>
            <div>
              <dt>{t('workspace.settings.template', 'Template')}</dt>
              <dd>
                {localizedTemplates.find((template) => template.id === selectedTemplateId)?.name ||
                  localizedTemplates[0].name}
              </dd>
            </div>
          </dl>
          <div className="settings-actions">
            <button type="button" className="button button--primary">
              {t('workspace.settings.updateProfile', 'Update profile')}
            </button>
            <button type="button" className="button button--ghost">
              {t('workspace.settings.manageAutomations', 'Manage automations')}
            </button>
          </div>
        </div>
      </div>
    );
  }

  function renderActiveSection() {
    switch (activeSection) {
      case 'dashboard':
        return renderDashboard();
      case 'invoices':
        return renderInvoices();
      case 'templates':
        return renderTemplateGallery();
      case 'clients':
        return renderClients();
      case 'activity':
        return renderActivity();
      case 'settings':
        return renderSettings();
      default:
        return null;
    }
  }

  const activeMeta = localizedSections.find((section) => section.id === activeSection);

  return (
    <div className="workspace-shell workspace-shell--topnav">
      <div className="workspace-toast-stack" aria-live="polite" aria-atomic="false">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`workspace-toast workspace-toast--${toast.status}`}
            role="status"
          >
            <span className="workspace-toast__icon" aria-hidden="true">
              {toast.status === 'loading' ? (
                <span className="workspace-toast__spinner" />
              ) : toast.status === 'success' ? (
                '✔'
              ) : toast.status === 'error' ? (
                '⚠️'
              ) : (
                'ℹ️'
              )}
            </span>
            <span className="workspace-toast__message">{toast.message}</span>
            <button
              type="button"
              className="workspace-toast__close"
              onClick={() => dismissToast(toast.id)}
              aria-label={t('workspace.toast.dismiss', 'Dismiss notification')}
            >
              ×
            </button>
          </div>
        ))}
      </div>
      <div className="workspace-topbar">
        <div className="workspace-shell__brand">
          <img
            src="/easy-invoice-gm7-logo.svg"
            alt="Easy Invoice GM7"
            className="workspace-shell__logo"
            width={44}
            height={44}
          />
          <div>
            <strong>Easy Invoice GM7</strong>
            <span>{t('workspace.shell.brandSubtitle', 'Billing workspace')}</span>
          </div>
        </div>
        <nav
          className="workspace-topbar__nav"
          aria-label={t('workspace.nav.label', 'Workspace sections')}
        >
          {localizedSections.map((section) => (
            <button
              key={section.id}
              type="button"
              className={`workspace-topbar__nav-item${
                activeSection === section.id ? ' workspace-topbar__nav-item--active' : ''
              }`}
              onClick={() => setActiveSection(section.id)}
              title={section.description}
              aria-pressed={activeSection === section.id}
            >
              <span className="workspace-topbar__nav-icon" aria-hidden="true">
                {section.icon}
              </span>
              <span className="workspace-topbar__nav-label">{section.label}</span>
            </button>
          ))}
        </nav>
        <div className="workspace-topbar__controls">
          <LanguageSwitcher variant="compact" />
          <div className="workspace-user-menu" role="group" aria-label={t('workspace.userMenu.label', 'Account actions')}>
            {isSignedIn ? (
              <>
                <span className="workspace-user-menu__name">{sessionDisplayName}</span>
                {isAdmin && (
                  <Link className="workspace-user-menu__link" href="/admin/console" prefetch={false}>
                    {t('workspace.actions.adminConsole', 'Admin console')}
                  </Link>
                )}
                <button type="button" className="workspace-user-menu__button" onClick={handleSignOut}>
                  {t('workspace.actions.signOut', 'Sign out')}
                </button>
              </>
            ) : (
              <Link className="workspace-user-menu__button" href="/login" prefetch={false}>
                {t('workspace.actions.signIn', 'Sign in')}
              </Link>
            )}
          </div>
        </div>
      </div>

      <div className="workspace-shell__main">
        <header className="workspace-shell__header">
          <div>
            <span>{activeMeta?.icon}</span>
            <div>
              <h1>{activeMeta?.label}</h1>
              <p>{activeMeta?.description}</p>
              {!firebaseConfigured && (
                <span className="workspace-shell__hint">{t('workspace.hint', 'Connected to demo data until Firebase credentials are added.')}</span>
              )}
            </div>
          </div>
          {activeSection !== 'invoices' && (
            <div className="workspace-shell__actions">
              <button type="button" className="button button--ghost" onClick={() => setShowSavedInvoices(true)}>
                📂 {t('workspace.actions.savedInvoices', 'Saved invoices')}
              </button>
              <button type="button" className="button button--ghost" onClick={() => setActiveSection('invoices')}>
                {t('workspace.actions.createInvoice', 'Create invoice')}
              </button>
              <button type="button" className="button button--primary" onClick={() => setActiveSection('dashboard')}>
                {t('workspace.actions.viewDashboard', 'View dashboard')}
              </button>
            </div>
          )}
        </header>

        {renderActiveSection()}
      </div>

      {showSavedInvoices && (
        <div className="workspace-saved-overlay" role="presentation" onClick={() => setShowSavedInvoices(false)}>
          <div
            className="workspace-saved-panel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="saved-invoices-title"
            onClick={(event) => event.stopPropagation()}
          >
            <header className="workspace-saved-panel__header">
              <div>
                <h2 id="saved-invoices-title">{t('workspace.saved.heading', 'Saved invoices')}</h2>
                <p>{t('workspace.saved.description', 'Review invoices you have saved to Firebase or this session.')}</p>
              </div>
              <button
                type="button"
                className="workspace-saved-panel__close"
                onClick={() => setShowSavedInvoices(false)}
                autoFocus
                aria-label={t('workspace.saved.close', 'Close saved invoices')}
              >
                ×
              </button>
            </header>
            <div className="workspace-saved-panel__body">
              {loadingInvoices ? (
                <div className="workspace-saved-panel__empty">
                  {t('workspace.saved.loading', 'Loading saved invoices…')}
                </div>
              ) : recentInvoices.length ? (
                <ul className="workspace-saved-list">
                  {recentInvoices.map((invoice) => (
                    <li key={invoice.id} className="workspace-saved-list__item">
                      <div className="workspace-saved-list__meta">
                        <strong>{invoice.clientName || t('workspace.table.clientPlaceholder', 'Client')}</strong>
                        <span>{invoice.clientEmail || '—'}</span>
                      </div>
                      <div className="workspace-saved-list__details">
                        <span>{formatFriendlyDate(invoice.issueDate, locale)}</span>
                        <span>{formatCurrency(invoice.total, invoice.currency, locale)}</span>
                        <span className={`status-pill status-pill--${invoice.status}`}>
                          {statusLookup.get(invoice.status) ?? invoice.status}
                        </span>
                      </div>
                      <div className="workspace-saved-list__actions">
                        <button
                          type="button"
                          className="button button--ghost"
                          onClick={() => {
                            const sanitizedLines = invoice.lines.map((line) => ({
                              ...line,
                              id:
                                line.id ||
                                (typeof crypto !== 'undefined' && 'randomUUID' in crypto
                                  ? crypto.randomUUID()
                                  : `${Date.now()}-${Math.random().toString(16).slice(2)}`),
                            }));
                            const loadedDraft: InvoiceDraft = {
                              clientName: invoice.clientName,
                              clientEmail: invoice.clientEmail,
                              clientAddress: invoice.clientAddress,
                              businessName: invoice.businessName,
                              businessAddress: invoice.businessAddress,
                              templateId: invoice.templateId,
                              issueDate: invoice.issueDate,
                              dueDate: invoice.dueDate,
                              currency: invoice.currency,
                              status: invoice.status,
                              taxRate: invoice.taxRate,
                              notes: invoice.notes,
                              lines: sanitizedLines,
                            };
                            setDraft(loadedDraft);
                            setInvoiceView('edit');
                            showToast(t('workspace.saved.loaded', 'Invoice loaded into the editor.'), 'success');
                            setShowSavedInvoices(false);
                          }}
                        >
                          {t('workspace.saved.open', 'Open in workspace')}
                        </button>
                      </div>
                    </li>
                  ))}
                </ul>
              ) : (
                <div className="workspace-saved-panel__empty">
                  {t('workspace.saved.empty', 'No saved invoices yet. Save one from the editor to see it here.')}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {showClientManager && (
        <div className="workspace-clients-overlay" role="presentation" onClick={closeClientManager}>
          <div
            className="workspace-clients-panel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="client-manager-title"
            onClick={(event) => event.stopPropagation()}
          >
            <header className="workspace-clients-panel__header">
              <div>
                <h2 id="client-manager-title">{t('workspace.clients.managerTitle', 'Client directory')}</h2>
                <p>
                  {t(
                    'workspace.clients.managerDescription',
                    'View saved contacts, reopen invoice history, and add new clients to reuse later.',
                  )}
                </p>
              </div>
              <button
                type="button"
                className="workspace-clients-panel__close"
                onClick={closeClientManager}
                aria-label={t('workspace.clients.closeManager', 'Close client manager')}
              >
                ×
              </button>
            </header>
            <div className="workspace-clients-panel__body">
              <aside className="workspace-clients-panel__sidebar">
                <div className="workspace-clients-panel__search">
                  <input
                    type="search"
                    value={clientSearch}
                    onChange={(event) => setClientSearch(event.target.value)}
                    placeholder={t('workspace.clients.searchPlaceholder', 'Search clients')}
                  />
                </div>
                <ul className="workspace-clients-panel__list">
                  {clientPanelEntries.length ? (
                    clientPanelEntries.map(({ summary }) => {
                      const isActive = summary.key === selectedClientId;
                      return (
                        <li key={summary.key}>
                          <button
                            type="button"
                            className={`workspace-clients-panel__list-button${
                              isActive ? ' workspace-clients-panel__list-button--active' : ''
                            }`}
                            onClick={() => openClientManagerFor(summary.key)}
                          >
                            <strong>{summary.name}</strong>
                            <span>{summary.email || t('workspace.clients.noEmail', 'No email on record')}</span>
                            <small>{t('workspace.clients.invoiceCount', '{count} invoices', { count: summary.invoices })}</small>
                          </button>
                        </li>
                      );
                    })
                  ) : (
                    <li className="workspace-clients-panel__empty">
                      {t('workspace.clients.emptyDirectory', 'No clients saved yet. Create one to get started.')}
                    </li>
                  )}
                </ul>
                <button type="button" className="button button--ghost workspace-clients-panel__add" onClick={() => startCreateClient()}>
                  ➕ {t('workspace.clients.addShort', 'New client')}
                </button>
              </aside>
              <section className="workspace-clients-panel__detail">
                {selectedClientId === 'new'
                  ? renderClientForm('create')
                  : selectedManualClient
                  ? renderClientForm('edit')
                  : selectedClientDetail
                  ? renderClientDetail(selectedClientDetail)
                  : (
                      <div className="workspace-clients-panel__empty">
                        {t('workspace.clients.selectPrompt', 'Select a client to view details.')}
                      </div>
                    )}
              </section>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
