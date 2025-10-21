import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Divider,
  Grid,
  Stack,
  Typography
} from '@mui/material';
import WorkspacePremiumIcon from '@mui/icons-material/WorkspacePremium';
import ManageAccountsIcon from '@mui/icons-material/ManageAccounts';
import LogoutIcon from '@mui/icons-material/Logout';
import { useAuth } from '../contexts/AuthContext';
import { useSubscription } from '../contexts/SubscriptionContext';
import { createCheckoutSession, createCustomerPortal } from '../services/stripe';

export default function SettingsPage() {
  const { user, signOutUser } = useAuth();
  const { subscription, limit, refresh } = useSubscription();
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (window.location.hash === '#billing') {
      const element = document.getElementById('billing-section');
      element?.scrollIntoView({ behavior: 'smooth' });
    }
  }, []);

  const handleUpgrade = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const { url } = await createCheckoutSession(user.uid, user.email);
      window.location.href = url;
    } catch (error) {
      console.error(error);
      setMessage('決済ページを開けませんでした。サーバー設定を確認してください。');
    } finally {
      setLoading(false);
    }
  };

  const handleManageBilling = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const { url } = await createCustomerPortal(user.uid);
      window.location.href = url;
    } catch (error) {
      console.error(error);
      setMessage('カスタマーポータルを開けませんでした。');
    } finally {
      setLoading(false);
    }
  };

  const isPremium = subscription?.plan === 'premium';

  return (
    <Stack spacing={4}>
      <Box>
        <Typography variant="h4" fontWeight={700} gutterBottom>
          設定
        </Typography>
        <Typography variant="body1" color="text.secondary">
          アカウント情報と契約プランを管理します。
        </Typography>
      </Box>

      {message && <Alert severity="warning">{message}</Alert>}

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, height: '100%' }}>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6" fontWeight={600}>
                  アカウント
                </Typography>
                <Chip label={isPremium ? 'プレミアム' : '無料'} color={isPremium ? 'secondary' : 'default'} />
              </Stack>
              <Typography variant="body1" fontWeight={600}>
                {user?.displayName ?? '未設定'}
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={3}>
                {user?.email}
              </Typography>
              <Button variant="outlined" startIcon={<LogoutIcon />} onClick={signOutUser}>
                ログアウト
              </Button>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, height: '100%' }} id="billing-section">
            <CardContent>
              <Stack direction="row" alignItems="center" spacing={2} mb={2}>
                <WorkspacePremiumIcon color="secondary" />
                <Typography variant="h6" fontWeight={600}>
                  プラン・請求
                </Typography>
              </Stack>
              <Typography variant="body1" color="text.secondary" mb={2}>
                無料プランでは毎月{limit}件までPDFをダウンロードできます。プレミアムプラン（月額¥500）で無制限ダウンロード、カスタムロゴ、優先サポートをご利用いただけます。
              </Typography>
              <Divider sx={{ my: 2 }} />
              <Stack spacing={2}>
                <Typography variant="subtitle1" fontWeight={600}>
                  現在の利用状況
                </Typography>
                <Typography variant="body2">
                  今月のダウンロード数: {subscription?.monthlyDownloadCount ?? 0} 件
                </Typography>
                {subscription?.currentPeriodEnd && (
                  <Typography variant="body2" color="text.secondary">
                    リセット予定日: {new Date(subscription.currentPeriodEnd).toLocaleDateString('ja-JP')}
                  </Typography>
                )}
                <Stack direction="row" spacing={2}>
                  {!isPremium ? (
                    <Button variant="contained" startIcon={<WorkspacePremiumIcon />} onClick={handleUpgrade} disabled={loading}>
                      プレミアムにアップグレード
                    </Button>
                  ) : (
                    <Button variant="contained" onClick={handleManageBilling} startIcon={<ManageAccountsIcon />} disabled={loading}>
                      請求情報を管理
                    </Button>
                  )}
                  <Button variant="outlined" onClick={refresh} disabled={loading}>
                    契約情報を同期
                  </Button>
                </Stack>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Stack>
  );
}
