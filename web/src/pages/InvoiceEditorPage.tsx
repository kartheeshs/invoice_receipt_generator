import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Snackbar,
  Stack,
  Typography
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';
import DownloadIcon from '@mui/icons-material/Download';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useAuth } from '../contexts/AuthContext';
import InvoiceForm from '../components/InvoiceForm';
import { createEmptyInvoice } from '../utils/defaultInvoice';
import { InvoiceFormValues } from '../types/invoice';
import { getInvoice, saveInvoice } from '../services/invoiceService';
import { useSubscription } from '../contexts/SubscriptionContext';
import { downloadInvoice } from '../services/pdfGenerator';

export default function InvoiceEditorPage() {
  const { invoiceId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { requestDownloadPermission, subscription, limit } = useSubscription();

  const [invoice, setInvoice] = useState<InvoiceFormValues>(() => createEmptyInvoice());
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{ message: string; severity: 'success' | 'error' | 'info' } | null>(null);

  useEffect(() => {
    if (!invoiceId || !user) return;
    setLoading(true);
    getInvoice(user.uid, invoiceId)
      .then((data) => {
        if (data) {
          setInvoice(data);
        }
      })
      .finally(() => setLoading(false));
  }, [invoiceId, user]);

  const remaining = useMemo(() => {
    if (subscription?.plan === 'premium') return Infinity;
    return Math.max(limit - (subscription?.monthlyDownloadCount ?? 0), 0);
  }, [subscription, limit]);

  const handleSave = async (): Promise<InvoiceFormValues | null> => {
    if (!user) return null;
    try {
      setLoading(true);
      const saved = await saveInvoice(user.uid, invoice);
      setInvoice(saved);
      setSnackbar({ message: '請求書を保存しました。', severity: 'success' });
      if (!invoiceId) {
        navigate(`/invoices/${saved.id}`, { replace: true });
      }
      return saved;
    } catch (error) {
      console.error(error);
      setSnackbar({ message: '保存中にエラーが発生しました。', severity: 'error' });
      return null;
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async () => {
    const ensuredInvoice = invoice.id ? invoice : await handleSave();
    if (!ensuredInvoice) return;
    setLoading(true);
    try {
      const permission = await requestDownloadPermission();
      if (permission.allowed) {
        downloadInvoice(ensuredInvoice);
        setSnackbar({ message: 'PDFを生成しました。', severity: 'success' });
      } else {
        setSnackbar({ message: 'ダウンロード上限に達しました。プレミアムプランをご検討ください。', severity: 'info' });
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Stack spacing={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <Stack spacing={1}>
          <Button startIcon={<ArrowBackIcon />} onClick={() => navigate(-1)} sx={{ alignSelf: 'flex-start' }}>
            戻る
          </Button>
          <Typography variant="h4" fontWeight={700}>
            {invoiceId ? '請求書を編集' : '請求書を新規作成'}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            必要な情報を入力し、PDFをダウンロードしましょう。
          </Typography>
        </Stack>
        <Stack direction="row" spacing={2}>
          <Button variant="outlined" startIcon={<SaveIcon />} onClick={handleSave} disabled={loading}>
            保存
          </Button>
          <Button variant="contained" startIcon={<DownloadIcon />} onClick={handleDownload} disabled={loading}>
            PDFダウンロード
          </Button>
        </Stack>
      </Box>

      {subscription?.plan !== 'premium' && (
        <Alert severity={remaining > 0 ? 'info' : 'warning'}>
          ダウンロード可能数: {remaining} / {limit} 件
        </Alert>
      )}

      <InvoiceForm value={invoice} onChange={setInvoice} />

      <Snackbar
        open={Boolean(snackbar)}
        autoHideDuration={4000}
        onClose={() => setSnackbar(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        {snackbar ? <Alert severity={snackbar.severity}>{snackbar.message}</Alert> : null}
      </Snackbar>
    </Stack>
  );
}
