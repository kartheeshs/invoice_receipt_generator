import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  IconButton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DownloadIcon from '@mui/icons-material/Download';
import EditIcon from '@mui/icons-material/Edit';
import dayjs from 'dayjs';
import { useNavigate } from 'react-router-dom';
import { useInvoices } from '../hooks/useInvoices';
import { useSubscription } from '../contexts/SubscriptionContext';
import { downloadInvoice } from '../services/pdfGenerator';

export default function InvoicesPage() {
  const navigate = useNavigate();
  const { invoices, loading, refresh } = useInvoices();
  const { subscription, requestDownloadPermission, limit } = useSubscription();
  const remaining = Math.max(limit - (subscription?.monthlyDownloadCount ?? 0), 0);

  const handleDownload = async (invoiceId: string) => {
    const invoice = invoices.find((item) => item.id === invoiceId);
    if (!invoice) return;
    const permission = await requestDownloadPermission();
    if (permission.allowed) {
      downloadInvoice(invoice);
      await refresh();
    }
  };

  return (
    <Stack spacing={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <div>
          <Typography variant="h4" fontWeight={700} gutterBottom>
            請求書一覧
          </Typography>
          <Typography variant="body1" color="text.secondary">
            保存済みの請求書を管理し、PDFをダウンロードしましょう。
          </Typography>
        </div>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => navigate('/invoices/new')}>
          新規作成
        </Button>
      </Box>

      {subscription?.plan !== 'premium' && (
        <Alert severity={remaining > 0 ? 'info' : 'warning'}>
          無料プランの残りダウンロード可能数: {remaining} / {limit} 件
        </Alert>
      )}

      <Card sx={{ borderRadius: 3 }}>
        <CardContent>
          {loading ? (
            <Box display="flex" justifyContent="center" py={6}>
              <CircularProgress />
            </Box>
          ) : invoices.length === 0 ? (
            <Box py={6} textAlign="center">
              <Typography color="text.secondary">まだ請求書がありません。まずは新規作成しましょう。</Typography>
            </Box>
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>請求書番号</TableCell>
                  <TableCell>顧客名</TableCell>
                  <TableCell>発行日</TableCell>
                  <TableCell align="right">金額 (税込)</TableCell>
                  <TableCell align="right">操作</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {invoices.map((invoice) => {
                  const subtotal = invoice.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
                  const tax = subtotal * (invoice.taxRate / 100);
                  const total = subtotal + tax;
                  return (
                    <TableRow key={invoice.id} hover>
                      <TableCell>{invoice.invoiceNumber}</TableCell>
                      <TableCell>{invoice.clientName}</TableCell>
                      <TableCell>{dayjs(invoice.issueDate).format('YYYY/MM/DD')}</TableCell>
                      <TableCell align="right">¥{total.toLocaleString()}</TableCell>
                      <TableCell align="right">
                        <IconButton color="primary" onClick={() => navigate(`/invoices/${invoice.id}`)}>
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          color="secondary"
                          onClick={() => {
                            if (!invoice.id) return;
                            void handleDownload(invoice.id);
                          }}
                        >
                          <DownloadIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </Stack>
  );
}
