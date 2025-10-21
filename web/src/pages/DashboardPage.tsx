import {
  Box,
  Button,
  Card,
  CardContent,
  Grid,
  LinearProgress,
  Stack,
  Typography
} from '@mui/material';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import PictureAsPdfIcon from '@mui/icons-material/PictureAsPdf';
import { useNavigate } from 'react-router-dom';
import { useInvoices } from '../hooks/useInvoices';
import { useSubscription } from '../contexts/SubscriptionContext';

export default function DashboardPage() {
  const navigate = useNavigate();
  const { invoices } = useInvoices();
  const { subscription, limit } = useSubscription();

  const usage = subscription?.plan === 'premium'
    ? 0
    : ((subscription?.monthlyDownloadCount ?? 0) / limit) * 100;

  return (
    <Stack spacing={4}>
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <Box>
          <Typography variant="h4" fontWeight={700} gutterBottom>
            ダッシュボード
          </Typography>
          <Typography variant="body1" color="text.secondary">
            最新の請求書状況と利用状況を確認しましょう。
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddCircleIcon />}
          size="large"
          onClick={() => navigate('/invoices/new')}
        >
          請求書を作成
        </Button>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 12px 24px rgba(31,80,154,0.1)' }}>
            <CardContent>
              <Typography variant="overline" color="primary">
                保存済み請求書
              </Typography>
              <Typography variant="h3" fontWeight={700} mt={1}>
                {invoices.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                過去の請求書はいつでも再編集できます。
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ borderRadius: 3 }}>
            <CardContent>
              <Typography variant="overline" color="primary">
                今月のダウンロード
              </Typography>
              <Typography variant="h3" fontWeight={700} mt={1}>
                {subscription?.monthlyDownloadCount ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {subscription?.plan === 'premium'
                  ? 'プレミアムプランで無制限にダウンロード可能'
                  : `無料プランでは月${limit}件までダウンロードできます。`}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ borderRadius: 3 }}>
            <CardContent>
              <Typography variant="overline" color="primary">
                プラン状況
              </Typography>
              <Typography variant="h5" fontWeight={700} mt={1}>
                {subscription?.plan === 'premium' ? 'プレミアム' : '無料'}
              </Typography>
              {subscription?.plan !== 'premium' ? (
                <Box mt={2}>
                  <LinearProgress variant="determinate" value={Math.min(usage, 100)} />
                  <Typography variant="caption" color="text.secondary">
                    残り {Math.max(limit - (subscription?.monthlyDownloadCount ?? 0), 0)} / {limit} 件
                  </Typography>
                </Box>
              ) : (
                <Typography variant="body2" color="text.secondary">
                  無制限ダウンロードと優先サポートがご利用いただけます。
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card sx={{ borderRadius: 3 }}>
        <CardContent>
          <Stack direction="row" alignItems="center" spacing={3}>
            <PictureAsPdfIcon color="primary" sx={{ fontSize: 48 }} />
            <Box>
              <Typography variant="h6" fontWeight={600}>
                日本の商習慣に沿ったPDFレイアウト
              </Typography>
              <Typography variant="body2" color="text.secondary" mt={1}>
                自社情報、振込先、収入印紙枠などを備えた請求書テンプレートを標準搭載。税率や消費税額も自動計算されます。
              </Typography>
            </Box>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  );
}
