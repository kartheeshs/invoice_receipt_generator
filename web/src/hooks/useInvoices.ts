import { useCallback, useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { InvoiceRecord } from '../types/invoice';
import { listInvoices } from '../services/invoiceService';

export function useInvoices() {
  const { user } = useAuth();
  const [invoices, setInvoices] = useState<InvoiceRecord[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    const results = await listInvoices(user.uid);
    setInvoices(results);
    setLoading(false);
  }, [user]);

  useEffect(() => {
    if (!user) {
      setInvoices([]);
      return;
    }
    void refresh();
  }, [user, refresh]);

  return { invoices, loading, refresh };
}
